clc; clear; close all;

%% =========================================================
% STATISTICAL ANALYSIS — VLIM VARIANT COMPARISON
% Data source: Summary VLIM Variant.xlsx
%   Sheets: 'VLIM', 'VLIM-CBO', 'VLIM-CBO-LF'
%   Structure: 24 rows (hours) x 30 columns (trials)
%   Each cell = hourly fuel cost (IDR) for that trial
%   Daily cost per trial = sum over 24 hours
%
% Tests performed:
%   1. Descriptive Statistics
%   2. One-way ANOVA
%   3. Tukey HSD post-hoc
%   4. Friedman non-parametric test
%   5. Friedman post-hoc
%   6. Paired t-test (VLIM-CBO-LF as baseline vs others)
%   7. Wilcoxon signed-rank test
%% =========================================================

%% ─────────────────────────────────────────────────────────
%  1. READ DATA
%% ─────────────────────────────────────────────────────────
dataFile   = 'SummaryVLIMVariant.xlsx';
sheetNames = {'VLIM','VLIM-CBO','VLIM-CBO-LF'};
nMethods   = numel(sheetNames);
numTrials  = 30;
nHour      = 24;

dailyCostMatrix = zeros(numTrials, nMethods);

fprintf('Reading data from %s ...\n', dataFile);

for m = 1:nMethods
    fprintf('Reading sheet: %s\n', sheetNames{m});

    raw = readmatrix(dataFile, 'Sheet', sheetNames{m});

    % Remove rows that are fully NaN
    raw = raw(~all(isnan(raw),2), :);

    % Keep rows with enough numeric content
    validRows = sum(~isnan(raw), 2) >= numTrials;
    raw = raw(validRows, :);

    if size(raw,1) < nHour
        error('Sheet %s: only %d usable data rows found, expected at least %d.', ...
            sheetNames{m}, size(raw,1), nHour);
    end

    % Keep only first 24 hourly rows
    raw = raw(1:nHour, :);

    % Detect whether first column is hour index
    if size(raw,2) >= numTrials + 1
        hourlyCandidate1 = raw(:, 2:(numTrials+1)); % first col = hour index
        hourlyCandidate2 = raw(:, 1:numTrials);     % no hour index

        if all(~isnan(hourlyCandidate1), 'all')
            hourly = hourlyCandidate1;
        elseif all(~isnan(hourlyCandidate2), 'all')
            hourly = hourlyCandidate2;
        else
            if sum(isnan(hourlyCandidate1), 'all') <= sum(isnan(hourlyCandidate2), 'all')
                hourly = hourlyCandidate1;
            else
                hourly = hourlyCandidate2;
            end
        end
    elseif size(raw,2) == numTrials
        hourly = raw;
    else
        error('Sheet %s: unexpected number of columns = %d.', ...
            sheetNames{m}, size(raw,2));
    end

    if size(hourly,1) ~= nHour || size(hourly,2) ~= numTrials
        error('Sheet %s: extracted data has size %dx%d, expected %dx%d.', ...
            sheetNames{m}, size(hourly,1), size(hourly,2), nHour, numTrials);
    end

    dailyCostMatrix(:,m) = sum(hourly, 1)';
end

fprintf('Data loaded successfully.\n\n');

%% ─────────────────────────────────────────────────────────
%  2. DESCRIPTIVE STATISTICS
%% ─────────────────────────────────────────────────────────
fprintf('================ DESCRIPTIVE STATISTICS ================\n');

DescRows = {};

for m = 1:nMethods
    x = dailyCostMatrix(:,m);

    mn    = mean(x);
    sd    = std(x);
    med   = median(x);
    best  = min(x);
    worst = max(x);
    q1    = prctile(x, 25);
    q3    = prctile(x, 75);

    tCrit = tinv(0.975, numTrials - 1);
    sem   = sd / sqrt(numTrials);
    ci_lo = mn - tCrit * sem;
    ci_hi = mn + tCrit * sem;

    DescRows{end+1} = {sheetNames{m}, mn, sd, med, best, worst, ...
                       q1, q3, ci_lo, ci_hi}; %#ok<SAGROW>
end

DescTable = cell2table(vertcat(DescRows{:}), ...
    'VariableNames', {'Method','Mean','StdDev','Median', ...
    'Best','Worst','Q1','Q3','CI95_Lower','CI95_Upper'});

disp(DescTable);

%% ─────────────────────────────────────────────────────────
%  3. ONE-WAY ANOVA
%% ─────────────────────────────────────────────────────────
fprintf('\n================ ONE-WAY ANOVA ================\n');

allValues  = dailyCostMatrix(:);
groupNames = strings(numTrials * nMethods, 1);
idx = 1;
for m = 1:nMethods
    groupNames(idx : idx + numTrials - 1) = sheetNames{m};
    idx = idx + numTrials;
end

[p_anova, tbl_anova, stats_anova] = anova1(allValues, groupNames, 'off');

ANOVAResult = cell2table({ ...
    'Between Groups', tbl_anova{2,2}, tbl_anova{2,3}, tbl_anova{2,4}, tbl_anova{2,5}, p_anova; ...
    'Within Groups',  tbl_anova{3,2}, tbl_anova{3,3}, tbl_anova{3,4}, [], []; ...
    'Total',          tbl_anova{4,2}, tbl_anova{4,3}, [], [], [] ...
    }, 'VariableNames', {'Source','SS','df','MS','F','p_Value'});

disp(ANOVAResult);
fprintf('ANOVA p-value = %.6e\n', p_anova);
if p_anova < 0.05
    fprintf('=> Significant difference exists among methods (p < 0.05)\n');
else
    fprintf('=> No significant difference (p >= 0.05)\n');
end

%% ─────────────────────────────────────────────────────────
%  4. TUKEY HSD POST-HOC
%% ─────────────────────────────────────────────────────────
fprintf('\n================ TUKEY HSD POST-HOC ================\n');

tukey_raw = multcompare(stats_anova, 'Display', 'off');

TukeyTable = array2table(tukey_raw, ...
    'VariableNames', {'Group1','Group2','LowerCI','MeanDiff','UpperCI','p_Value'});
TukeyTable.Method1 = string(sheetNames(TukeyTable.Group1))';
TukeyTable.Method2 = string(sheetNames(TukeyTable.Group2))';
TukeyTable.Significant = TukeyTable.p_Value < 0.05;
TukeyTable = movevars(TukeyTable, {'Method1','Method2'}, 'Before', 'LowerCI');

disp(TukeyTable);

%% ─────────────────────────────────────────────────────────
%  5. FRIEDMAN TEST
%% ─────────────────────────────────────────────────────────
fprintf('\n================ FRIEDMAN TEST ================\n');

[p_friedman, tbl_friedman, stats_friedman] = friedman(dailyCostMatrix, 1, 'off');

FriedmanResult = cell2table({ ...
    'Friedman', tbl_friedman{2,5}, tbl_friedman{2,3}, p_friedman ...
    }, 'VariableNames', {'Test','Chi2','df','p_Value'});

disp(FriedmanResult);
fprintf('Friedman p-value = %.6e\n', p_friedman);
if p_friedman < 0.05
    fprintf('=> Significant difference exists among methods (p < 0.05)\n');
else
    fprintf('=> No significant difference (p >= 0.05)\n');
end

%% ─────────────────────────────────────────────────────────
%  6. FRIEDMAN POST-HOC
%% ─────────────────────────────────────────────────────────
fprintf('\n================ FRIEDMAN POST-HOC ================\n');

fph_raw = multcompare(stats_friedman, 'Display', 'off');

FriedmanPosthoc = array2table(fph_raw, ...
    'VariableNames', {'Group1','Group2','LowerCI','MeanRankDiff','UpperCI','p_Value'});
FriedmanPosthoc.Method1     = string(sheetNames(FriedmanPosthoc.Group1))';
FriedmanPosthoc.Method2     = string(sheetNames(FriedmanPosthoc.Group2))';
FriedmanPosthoc.Significant = FriedmanPosthoc.p_Value < 0.05;
FriedmanPosthoc = movevars(FriedmanPosthoc, ...
    {'Method1','Method2'}, 'Before', 'LowerCI');

disp(FriedmanPosthoc);

%% ─────────────────────────────────────────────────────────
%  7. PAIRED t-TEST  (VLIM-CBO-LF as baseline = col 3)
%% ─────────────────────────────────────────────────────────
fprintf('\n================ PAIRED t-TEST (baseline: VLIM-CBO-LF) ================\n');

baselineIdx = 3;
baseline    = dailyCostMatrix(:, baselineIdx);
TTestRows   = {};

for m = 1:nMethods
    if m == baselineIdx
        continue;
    end

    comparator  = dailyCostMatrix(:, m);
    diff        = baseline - comparator;

    [~, p_tt, ci_tt, st_tt] = ttest(baseline, comparator);

    TTestRows{end+1} = { ...
        sheetNames{baselineIdx}, sheetNames{m}, ...
        st_tt.tstat, p_tt, ...
        mean(diff), median(diff), ...
        ci_tt(1), ci_tt(2), ...
        p_tt < 0.05 }; %#ok<SAGROW>
end

PairedTTest = cell2table(vertcat(TTestRows{:}), ...
    'VariableNames', {'Baseline','Comparator','t_Statistic','p_Value', ...
    'MeanDifference','MedianDifference','CI_Lower','CI_Upper','Significant'});

disp(PairedTTest);

%% ─────────────────────────────────────────────────────────
%  8. WILCOXON SIGNED-RANK TEST  (VLIM-CBO-LF as baseline)
%% ─────────────────────────────────────────────────────────
fprintf('\n================ WILCOXON SIGNED-RANK (baseline: VLIM-CBO-LF) ================\n');

WilcoxRows = {};

for m = 1:nMethods
    if m == baselineIdx
        continue;
    end

    comparator = dailyCostMatrix(:, m);
    diff       = baseline - comparator;

    p_wil = signrank(baseline, comparator);

    absDiff = abs(diff);
    nzMask  = absDiff > 0;

    if any(nzMask)
        rnks = tiedrank(absDiff(nzMask));
        W    = sum(rnks(diff(nzMask) > 0));
    else
        W = 0;
    end

    WilcoxRows{end+1} = { ...
        sheetNames{baselineIdx}, sheetNames{m}, ...
        W, p_wil, ...
        mean(diff), median(diff), ...
        p_wil < 0.05 }; %#ok<SAGROW>
end

WilcoxonTable = cell2table(vertcat(WilcoxRows{:}), ...
    'VariableNames', {'Baseline','Comparator','W_Statistic','p_Value', ...
    'MeanDifference','MedianDifference','Significant'});

disp(WilcoxonTable);

%% ─────────────────────────────────────────────────────────
%  9. RANKING BY MEAN DAILY COST
%% ─────────────────────────────────────────────────────────
fprintf('\n================ RANKING (by Mean Daily Cost) ================\n');

meanCosts = zeros(nMethods,1);
for m = 1:nMethods
    meanCosts(m) = mean(dailyCostMatrix(:,m));
end

[~, sortIdx] = sort(meanCosts, 'ascend');
RankingTable = table( ...
    string(sheetNames(sortIdx))', ...
    (1:nMethods)', ...
    meanCosts(sortIdx), ...
    'VariableNames', {'Method','Rank','MeanDailyCost'});

disp(RankingTable);

%% ─────────────────────────────────────────────────────────
%  10. SAVE ALL RESULTS TO EXCEL
%% ─────────────────────────────────────────────────────────
outputFile = 'Statistical_Analysis_VLIM_Variants.xlsx';

writetable(DescTable,         outputFile, 'Sheet', 'Descriptive');
writetable(ANOVAResult,       outputFile, 'Sheet', 'ANOVA');
writetable(TukeyTable,        outputFile, 'Sheet', 'TukeyHSD');
writetable(FriedmanResult,    outputFile, 'Sheet', 'Friedman');
writetable(FriedmanPosthoc,   outputFile, 'Sheet', 'FriedmanPosthoc');
writetable(PairedTTest,       outputFile, 'Sheet', 'PairedTTest');
writetable(WilcoxonTable,     outputFile, 'Sheet', 'Wilcoxon');
writetable(RankingTable,      outputFile, 'Sheet', 'Ranking');

fprintf('\nAll results saved to: %s\n', outputFile);

%% ─────────────────────────────────────────────────────────
%  11. FIGURES
%% ─────────────────────────────────────────────────────────
clr = [
    0.4660  0.6740  0.1880
    0.8500  0.3250  0.0980
    0.0000  0.4470  0.7410
];

set(groot,'defaultFigureColor','w');
set(groot,'defaultAxesFontName','Times New Roman');
set(groot,'defaultAxesFontSize',14);
set(groot,'defaultAxesLineWidth',1.0);

%% Figure 1: Box-Whisker
fig1 = figure('Color','w','Position',[100 100 800 520]);
set(fig1,'Toolbar','none');

groupVec = [];
costVec  = [];
for m = 1:nMethods
    costVec  = [costVec;  dailyCostMatrix(:,m)]; %#ok<AGROW>
    groupVec = [groupVec; repmat(m, numTrials, 1)]; %#ok<AGROW>
end

h_bp = boxplot(costVec, groupVec, ...
    'Labels',  strrep(sheetNames,'_','-'), ...
    'Symbol',  'k+', ...
    'Widths',  0.55, ...
    'Colors',  clr);
set(h_bp, 'LineWidth', 1.4);

ylabel('Daily Fuel Cost (IDR)', 'FontName','Times New Roman','FontSize',15);

ax1 = gca;
ax1.FontName   = 'Times New Roman';
ax1.FontSize   = 15;
ax1.LineWidth  = 1.0;
ax1.Box        = 'on';
ax1.TickDir    = 'in';
ax1.TickLength = [0.012 0.012];
grid off;

save_figure_safe(fig1, 'BoxWhisker_VLIM_Variants');

%% Figure 2: Mean + 95% CI
fig2 = figure('Color','w','Position',[100 100 780 520]);
set(fig2,'Toolbar','none');

meanVals = zeros(nMethods,1);
ciVals   = zeros(nMethods,1);
for m = 1:nMethods
    x = dailyCostMatrix(:,m);
    meanVals(m) = mean(x);
    ciVals(m)   = tinv(0.975, numTrials-1) * std(x) / sqrt(numTrials);
end

bBar = bar(meanVals, 'FaceColor','flat', ...
    'EdgeColor',[0.2 0.2 0.2], 'LineWidth',0.9);
for m = 1:nMethods
    bBar.CData(m,:) = clr(m,:);
end
hold on;
errorbar(1:nMethods, meanVals, ciVals, ...
    'k', 'LineStyle','none', 'LineWidth',1.3, 'CapSize',9);
hold off;

set(gca,'XTick',1:nMethods,'XTickLabel',strrep(sheetNames,'_','-'));
ylabel('Mean Daily Fuel Cost (IDR)','FontName','Times New Roman','FontSize',15);

ax2 = gca;
ax2.FontName   = 'Times New Roman';
ax2.FontSize   = 15;
ax2.LineWidth  = 1.0;
ax2.Box        = 'on';
ax2.TickDir    = 'in';
ax2.TickLength = [0.012 0.012];
grid off;

save_figure_safe(fig2, 'MeanCI_VLIM_Variants');

%% Figure 3: Scatter Distribution
fig3 = figure('Color','w','Position',[100 100 820 520]);
set(fig3,'Toolbar','none');
hold on;

for m = 1:nMethods
    x = dailyCostMatrix(:,m);
    jitter = (rand(numTrials,1) - 0.5) * 0.18;
    scatter(repmat(m, numTrials, 1) + jitter, x, ...
        28, clr(m,:), 'filled', 'MarkerFaceAlpha', 0.55);
    scatter(m, mean(x), 80, clr(m,:), 'd', 'filled', 'LineWidth',1.2);
end

set(gca,'XTick',1:nMethods,'XTickLabel',strrep(sheetNames,'_','-'));
ylabel('Daily Fuel Cost (IDR)','FontName','Times New Roman','FontSize',15);

ax3 = gca;
ax3.FontName   = 'Times New Roman';
ax3.FontSize   = 15;
ax3.LineWidth  = 1.0;
ax3.Box        = 'on';
ax3.TickDir    = 'in';
ax3.TickLength = [0.012 0.012];
grid off;
hold off;

save_figure_safe(fig3, 'Scatter_VLIM_Variants');

fprintf('\nDone. Figures saved as PNG and PDF.\n');

%% ─────────────────────────────────────────────────────────
%  LOCAL FUNCTIONS
%% ─────────────────────────────────────────────────────────
function save_figure_safe(figHandle, fileBase)
    drawnow;
    try
        exportgraphics(figHandle, [fileBase '.pdf'], 'ContentType','vector');
        exportgraphics(figHandle, [fileBase '.png'], 'Resolution',600);
    catch
        print(figHandle, [fileBase '.png'], '-dpng', '-r600');
        print(figHandle, [fileBase '.pdf'], '-dpdf', '-bestfit');
    end
end