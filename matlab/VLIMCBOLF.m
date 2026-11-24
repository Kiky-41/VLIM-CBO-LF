clc; clear; close all;

%% =========================================================
% FAIR COMPARATIVE MULTI-RUN ANALYSIS FOR ECONOMIC DISPATCH
% Fixed issues:
% 1) Same iteration length for all methods
% 2) Same objective metric for all methods
% 3) VLIM-CBO-LF perturbs dispatch P, not a/b/c
% 4) Final evaluation uses original system coefficients
% 5) Convergence curve comparable across methods
% 6) Safe figure export without toolbar issues
% 7) Statistical tests added:
%    - ANOVA
%    - Tukey HSD
%    - Friedman test
%    - Friedman post-hoc
%    - Paired t-test
%    - Wilcoxon signed-rank test
% 8) Sensitivity analysis added for VLIM-CBO-LF:
%    - beta
%    - levy scale ratio
%    - number of candidates
%% =========================================================

rng('shuffle');

%% -------------------------
% FILES
%% -------------------------
genFile = 'input42u.xlsx';
demandFile = 'power_demand42u.xlsx';

%% -------------------------
% READ DATA
%% -------------------------
genData = readtable(genFile);
demandData = readtable(demandFile);

Unit      = genData{:,1};
a0        = genData{:,2};
b0        = genData{:,3};
c0        = genData{:,4};
pmin      = genData{:,5};
pmax      = genData{:,6};
ramp_up   = genData{:,7};
ramp_down = genData{:,8};

power_demand = demandData{:,1};

nGen  = length(a0);
nHour = length(power_demand);

%% -------------------------
% GLOBAL SETTINGS
%% -------------------------
numTrials = 30;
tol = 1e-4;
maxLambdaIter = 10000;
penaltyFactor = 1e6;

methods = {'VLIM_CBO_LF','ABC','GWO','PSO','WOA'};
nMethods = length(methods);

commonIterations = 100;

%% -------------------------
% PARAMETERS
%% -------------------------

% VLIM-CBO-LF
VLIM_numCandidates = 50;
VLIM_beta = 1.5;
VLIM_levyScaleRatio = 0.08;

% ABC
ABC_numBees = 50;
ABC_limit = 10;

% GWO
GWO_numWolves = 30;

% PSO
PSO_numParticles = 50;
PSO_w = 0.5;
PSO_c1 = 1.5;
PSO_c2 = 1.5;

% WOA
WOA_numWhales = 30;

%% -------------------------
% STORAGE
%% -------------------------
Results = struct();

for m = 1:nMethods
    method = methods{m};

    Results.(method).hourlyCostMatrix = zeros(numTrials, nHour);
    Results.(method).hourlyTimeMatrix = zeros(numTrials, nHour);
    Results.(method).dailyCostVector  = zeros(numTrials, 1);
    Results.(method).dailyTimeVector  = zeros(numTrials, 1);
    Results.(method).dispatch         = zeros(numTrials, nHour, nGen);
    Results.(method).convergenceMatrix = zeros(numTrials, commonIterations);
end

%% =========================================================
% MAIN LOOP
%% =========================================================
for m = 1:nMethods
    method = methods{m};
    fprintf('\n==============================\n');
    fprintf('Running method: %s\n', method);
    fprintf('==============================\n');

    for trial = 1:numTrials
        rng(trial);

        fprintf('Method %s - Trial %d / %d\n', method, trial, numTrials);

        switch method
            case 'VLIM_CBO_LF'
                [Pday, dailyCosts, dayTimes, convVec] = solve_vlim_cbo_lf_day_fixed( ...
                    power_demand, a0, b0, c0, pmin, pmax, ramp_up, ramp_down, ...
                    commonIterations, VLIM_numCandidates, VLIM_beta, ...
                    VLIM_levyScaleRatio, penaltyFactor, tol, maxLambdaIter);

            case 'ABC'
                [Pday, dailyCosts, dayTimes, convVec] = solve_abc_day_fixed( ...
                    power_demand, a0, b0, c0, pmin, pmax, ramp_up, ramp_down, ...
                    ABC_numBees, commonIterations, ABC_limit, penaltyFactor, tol);

            case 'GWO'
                [Pday, dailyCosts, dayTimes, convVec] = solve_gwo_day_fixed( ...
                    power_demand, a0, b0, c0, pmin, pmax, ramp_up, ramp_down, ...
                    GWO_numWolves, commonIterations, penaltyFactor, tol);

            case 'PSO'
                [Pday, dailyCosts, dayTimes, convVec] = solve_pso_day_fixed( ...
                    power_demand, a0, b0, c0, pmin, pmax, ramp_up, ramp_down, ...
                    PSO_numParticles, commonIterations, PSO_w, PSO_c1, PSO_c2, ...
                    penaltyFactor, tol);

            case 'WOA'
                [Pday, dailyCosts, dayTimes, convVec] = solve_woa_day_fixed( ...
                    power_demand, a0, b0, c0, pmin, pmax, ramp_up, ramp_down, ...
                    WOA_numWhales, commonIterations, penaltyFactor, tol);
        end

        Results.(method).hourlyCostMatrix(trial, :) = dailyCosts(:)';
        Results.(method).hourlyTimeMatrix(trial, :) = dayTimes(:)';
        Results.(method).dailyCostVector(trial) = sum(dailyCosts);
        Results.(method).dailyTimeVector(trial) = sum(dayTimes);
        Results.(method).dispatch(trial,:,:) = Pday;
        Results.(method).convergenceMatrix(trial,:) = convVec(:)';
    end
end

%% =========================================================
% SUMMARY TABLE
%% =========================================================
SummaryRows = [];

for m = 1:nMethods
    method = methods{m};
    dailyCost = Results.(method).dailyCostVector;
    dailyTime = Results.(method).dailyTimeVector;

    meanCost   = mean(dailyCost);
    stdCost    = std(dailyCost);
    medianCost = median(dailyCost);
    bestCost   = min(dailyCost);
    worstCost  = max(dailyCost);
    q1Cost     = prctile(dailyCost,25);
    q3Cost     = prctile(dailyCost,75);

    tCritical = tinv(0.975, numTrials - 1);
    sem = stdCost / sqrt(numTrials);
    ciLow = meanCost - tCritical * sem;
    ciUp  = meanCost + tCritical * sem;

    meanTime = mean(dailyTime);
    stdTime  = std(dailyTime);

    SummaryRows = [SummaryRows; ...
        {method, meanCost, stdCost, medianCost, bestCost, worstCost, ...
         q1Cost, q3Cost, ciLow, ciUp, meanTime, stdTime}];
end

SummaryTable = cell2table(SummaryRows, ...
    'VariableNames', {'Method','MeanDailyCost','StdDailyCost','MedianDailyCost', ...
    'BestDailyCost','WorstDailyCost','Q1','Q3','CI95_Lower','CI95_Upper', ...
    'MeanDailyTime','StdDailyTime'});

disp('================ SUMMARY ================');
disp(SummaryTable);

%% =========================================================
% SAVE RESULTS
%% =========================================================
outputExcel = 'Comparative_ED_Statistical_Results_Fixed.xlsx';
writetable(SummaryTable, outputExcel, 'Sheet', 'Summary');

for m = 1:nMethods
    method = methods{m};

    dailyTbl = table((1:numTrials)', Results.(method).dailyCostVector, Results.(method).dailyTimeVector, ...
        'VariableNames', {'Trial','DailyCost','DailyTime'});
    writetable(dailyTbl, outputExcel, 'Sheet', [method '_Daily']);

    hourlyNames = strcat("Hour_", string(1:nHour));
    hourlyTbl = array2table(Results.(method).hourlyCostMatrix, 'VariableNames', cellstr(hourlyNames));
    hourlyTbl.Trial = (1:numTrials)';
    hourlyTbl = movevars(hourlyTbl, 'Trial', 'Before', 1);
    writetable(hourlyTbl, outputExcel, 'Sheet', [method '_Hourly']);

    iterNames = strcat("Iter_", string(1:commonIterations));
    convTbl = array2table(Results.(method).convergenceMatrix, 'VariableNames', cellstr(iterNames));
    convTbl.Trial = (1:numTrials)';
    convTbl = movevars(convTbl, 'Trial', 'Before', 1);
    writetable(convTbl, outputExcel, 'Sheet', [method '_Conv']);
end

%% =========================================================
% PLOT STYLE
%% =========================================================
set(groot,'defaultFigureColor','w');
set(groot,'defaultAxesFontName','Times New Roman');
set(groot,'defaultAxesFontSize',14);
set(groot,'defaultAxesLineWidth',1.0);

clr = [
    0.0000    0.4470    0.7410
    0.8500    0.3250    0.0980
    0.9290    0.6940    0.1250
    0.4940    0.1840    0.5560
    0.4660    0.6740    0.1880
];

%% =========================================================
% CONVERGENCE COMPARISON
%% =========================================================
fig1 = figure('Color','w','Position',[120 120 980 560]);
set(fig1,'Toolbar','none');
hold on;

for m = 1:nMethods
    method = methods{m};
    convMean = mean(Results.(method).convergenceMatrix, 1);

    plot(1:length(convMean), convMean, ...
        'LineWidth', 2.2, ...
        'Color', clr(m,:), ...
        'DisplayName', strrep(method,'_','-'));
end

xlabel('Iterations', 'FontName','Times New Roman', 'FontSize',15);
ylabel('Best Objective Value', 'FontName','Times New Roman', 'FontSize',15);
%%title('Convergence curve comparison', 'FontName','Times New Roman', 'FontSize',20, 'FontWeight','normal');

lgd = legend('Location','northeast');
lgd.Box = 'on';
lgd.EdgeColor = [0.2 0.2 0.2];
lgd.LineWidth = 0.8;
lgd.Color = [1 1 1];
lgd.FontName = 'Times New Roman';
lgd.FontSize = 14;

ax1 = gca;
ax1.FontName = 'Times New Roman';
ax1.FontSize = 15;
ax1.LineWidth = 1.0;
ax1.Box = 'on';
ax1.TickDir = 'in';
ax1.TickLength = [0.012 0.012];
grid off;
xlim([1 commonIterations]);

allConv = [];
for m = 1:nMethods
    allConv = [allConv, mean(Results.(methods{m}).convergenceMatrix,1)];
end
ymin = min(allConv);
ymax = max(allConv);
if ymax > ymin
    ylim([ymin - 0.02*(ymax-ymin), ymax + 0.02*(ymax-ymin)]);
end

hold off;
save_figure_safe(fig1, 'Convergence_Comparison_Fixed');

%% =========================================================
% BOX-WHISKER
%% =========================================================
fig2 = figure('Color','w','Position',[120 120 900 520]);
set(fig2,'Toolbar','none');

dailyBox = [];
groupBox = [];
for m = 1:nMethods
    dailyBox = [dailyBox; Results.(methods{m}).dailyCostVector];
    groupBox = [groupBox; repmat(m, numTrials, 1)];
end

boxplot(dailyBox, groupBox, ...
    'Labels', strrep(methods,'_','-'), ...
    'Symbol','k+', ...
    'Widths', 0.6);

ylabel('Daily Fuel Cost', 'FontName','Times New Roman', 'FontSize',15);
%%title('Box-whisker plot of daily cost comparison', 'FontName','Times New Roman', 'FontSize',20, 'FontWeight','normal');

ax2 = gca;
ax2.FontName = 'Times New Roman';
ax2.FontSize = 15;
ax2.LineWidth = 1.0;
ax2.Box = 'on';
ax2.TickDir = 'in';
ax2.TickLength = [0.012 0.012];
grid off;

save_figure_safe(fig2, 'DailyCost_BoxWhisker_Fixed');

%% =========================================================
% BAR CHART
%% =========================================================
fig3 = figure('Color','w','Position',[120 120 900 520]);
set(fig3,'Toolbar','none');

meanVals = zeros(nMethods,1);
stdVals  = zeros(nMethods,1);
for m = 1:nMethods
    meanVals(m) = mean(Results.(methods{m}).dailyCostVector);
    stdVals(m)  = std(Results.(methods{m}).dailyCostVector);
end

bBar = bar(meanVals, 'FaceColor','flat', 'EdgeColor',[0.2 0.2 0.2], 'LineWidth',0.8);
for m = 1:nMethods
    bBar.CData(m,:) = clr(m,:);
end
hold on;
errorbar(1:nMethods, meanVals, stdVals, 'k', 'LineStyle','none', 'LineWidth',1.2, 'CapSize',8);

set(gca,'XTick',1:nMethods,'XTickLabel',strrep(methods,'_','-'));
ylabel('Mean daily fuel cost', 'FontName','Times New Roman', 'FontSize',18);
title('Mean daily cost with standard deviation', 'FontName','Times New Roman', 'FontSize',20, 'FontWeight','normal');

ax3 = gca;
ax3.FontName = 'Times New Roman';
ax3.FontSize = 15;
ax3.LineWidth = 1.0;
ax3.Box = 'on';
ax3.TickDir = 'in';
ax3.TickLength = [0.012 0.012];
grid off;
hold off;

save_figure_safe(fig3, 'MeanDailyCost_ErrorBar_Fixed');

%% =========================================================
% STATISTICAL TESTS
%% =========================================================
dailyCostMatrix = zeros(numTrials, nMethods);
for m = 1:nMethods
    dailyCostMatrix(:,m) = Results.(methods{m}).dailyCostVector;
end

% -------------------------
% ANOVA
% -------------------------
allValues = dailyCostMatrix(:);
groupNames = strings(numTrials*nMethods,1);
idx = 1;
for m = 1:nMethods
    groupNames(idx:idx+numTrials-1) = methods{m};
    idx = idx + numTrials;
end

[p_anova, ~, stats_anova] = anova1(allValues, groupNames, 'off');
ANOVA_Table = cell2table({
    'Between/Within Methods', p_anova
    }, 'VariableNames', {'Test','pValue'});

% -------------------------
% Tukey HSD
% -------------------------
tukey_results = multcompare(stats_anova, 'Display', 'off');
TukeyTable = array2table(tukey_results, ...
    'VariableNames', {'Group1','Group2','LowerCI','MeanDiff','UpperCI','pValue'});
TukeyTable.Method1 = string(methods(TukeyTable.Group1))';
TukeyTable.Method2 = string(methods(TukeyTable.Group2))';
TukeyTable = movevars(TukeyTable, {'Method1','Method2'}, 'Before', 'LowerCI');

% -------------------------
% Friedman
% -------------------------
[p_friedman, ~, stats_friedman] = friedman(dailyCostMatrix, 1, 'off');
FriedmanTable = cell2table({
    'Friedman', p_friedman
    }, 'VariableNames', {'Test','pValue'});

friedman_posthoc = multcompare(stats_friedman, 'Display', 'off');
FriedmanPosthocTable = array2table(friedman_posthoc, ...
    'VariableNames', {'Group1','Group2','LowerCI','MeanRankDiff','UpperCI','pValue'});
FriedmanPosthocTable.Method1 = string(methods(FriedmanPosthocTable.Group1))';
FriedmanPosthocTable.Method2 = string(methods(FriedmanPosthocTable.Group2))';
FriedmanPosthocTable = movevars(FriedmanPosthocTable, {'Method1','Method2'}, 'Before', 'LowerCI');

% -------------------------
% Paired t-test vs baseline
% -------------------------
baseline = dailyCostMatrix(:,1);
TTestRows = [];

for m = 2:nMethods
    x = baseline;
    y = dailyCostMatrix(:,m);

    [~, p_ttest, ci_ttest, stats_ttest] = ttest(x, y);

    meanDiff = mean(x - y);
    medianDiff = median(x - y);

    TTestRows = [TTestRows; ...
        {methods{1}, methods{m}, stats_ttest.tstat, p_ttest, meanDiff, medianDiff, ci_ttest(1), ci_ttest(2)}];
end

PairedTTestTable = cell2table(TTestRows, ...
    'VariableNames', {'Method1','Method2','tStatistic','pValue','MeanDifference','MedianDifference','CI_Lower','CI_Upper'});

% -------------------------
% Wilcoxon signed-rank
% -------------------------
WilcoxonRows = [];

for m = 2:nMethods
    x = baseline;
    y = dailyCostMatrix(:,m);

    p_wil = signrank(x, y);
    diffxy = x - y;

    absDiff = abs(diffxy);
    nonzeroMask = absDiff > 0;
    absDiffNZ = absDiff(nonzeroMask);
    diffNZ = diffxy(nonzeroMask);

    if isempty(absDiffNZ)
        signedRankStat = 0;
    else
        ranks = tiedrank(absDiffNZ);
        signedRankStat = sum(ranks(diffNZ > 0));
    end

    meanDiff = mean(diffxy);
    medianDiff = median(diffxy);

    WilcoxonRows = [WilcoxonRows; ...
        {methods{1}, methods{m}, signedRankStat, p_wil, meanDiff, medianDiff}];
end

WilcoxonTable = cell2table(WilcoxonRows, ...
    'VariableNames', {'Method1','Method2','SignedRankStatistic','pValue','MeanDifference','MedianDifference'});

% -------------------------
% Ranking
% -------------------------
[~, rankIdx] = sort(meanVals, 'ascend');
RankingTable = table(string(methods(rankIdx))', (1:nMethods)', ...
    'VariableNames', {'Method','Rank'});

disp('================ ANOVA ================');
disp(ANOVA_Table);
disp('================ TUKEY HSD ================');
disp(TukeyTable);
disp('================ FRIEDMAN TEST ================');
disp(FriedmanTable);
disp('================ FRIEDMAN POST-HOC ================');
disp(FriedmanPosthocTable);
disp('================ PAIRED t-TEST ================');
disp(PairedTTestTable);
disp('================ WILCOXON ================');
disp(WilcoxonTable);
disp('================ RANKING ================');
disp(RankingTable);

writetable(ANOVA_Table,           outputExcel, 'Sheet', 'ANOVA');
writetable(TukeyTable,            outputExcel, 'Sheet', 'TukeyHSD');
writetable(FriedmanTable,         outputExcel, 'Sheet', 'Friedman');
writetable(FriedmanPosthocTable,  outputExcel, 'Sheet', 'FriedmanPosthoc');
writetable(PairedTTestTable,      outputExcel, 'Sheet', 'PairedTTest');
writetable(WilcoxonTable,         outputExcel, 'Sheet', 'Wilcoxon');
writetable(RankingTable,          outputExcel, 'Sheet', 'Ranking');

fprintf('\nAll results saved to %s\n', outputExcel);

%% =========================================================
% SENSITIVITY ANALYSIS FOR VLIM-CBO-LF
%% =========================================================
fprintf('\n================ SENSITIVITY ANALYSIS ================\n');

betaList = [1.1, 1.3, 1.5, 1.7, 1.9];
scaleList = [0.02, 0.05, 0.08, 0.10, 0.15];
candidateList = [20, 30, 50, 70, 100];

numSensitivityTrials = 10;

SensitivityRows = [];

% -------------------------
% A) Sensitivity on beta
% -------------------------
for bIdx = 1:length(betaList)
    betaVal = betaList(bIdx);

    dailyCosts_beta = zeros(numSensitivityTrials,1);

    for trial = 1:numSensitivityTrials
        rng(trial);

        [~, dailyCosts_tmp, ~, ~] = solve_vlim_cbo_lf_day_fixed( ...
            power_demand, a0, b0, c0, pmin, pmax, ramp_up, ramp_down, ...
            commonIterations, VLIM_numCandidates, betaVal, ...
            VLIM_levyScaleRatio, penaltyFactor, tol, maxLambdaIter);

        dailyCosts_beta(trial) = sum(dailyCosts_tmp);
    end

    SensitivityRows = [SensitivityRows; ...
        {"beta", betaVal, mean(dailyCosts_beta), std(dailyCosts_beta), ...
         min(dailyCosts_beta), max(dailyCosts_beta)}];
end

% -------------------------
% B) Sensitivity on levyScaleRatio
% -------------------------
for sIdx = 1:length(scaleList)
    scaleVal = scaleList(sIdx);

    dailyCosts_scale = zeros(numSensitivityTrials,1);

    for trial = 1:numSensitivityTrials
        rng(trial);

        [~, dailyCosts_tmp, ~, ~] = solve_vlim_cbo_lf_day_fixed( ...
            power_demand, a0, b0, c0, pmin, pmax, ramp_up, ramp_down, ...
            commonIterations, VLIM_numCandidates, VLIM_beta, ...
            scaleVal, penaltyFactor, tol, maxLambdaIter);

        dailyCosts_scale(trial) = sum(dailyCosts_tmp);
    end

    SensitivityRows = [SensitivityRows; ...
        {"levyScaleRatio", scaleVal, mean(dailyCosts_scale), std(dailyCosts_scale), ...
         min(dailyCosts_scale), max(dailyCosts_scale)}];
end

% -------------------------
% C) Sensitivity on numCandidates
% -------------------------
for cIdx = 1:length(candidateList)
    candVal = candidateList(cIdx);

    dailyCosts_cand = zeros(numSensitivityTrials,1);

    for trial = 1:numSensitivityTrials
        rng(trial);

        [~, dailyCosts_tmp, ~, ~] = solve_vlim_cbo_lf_day_fixed( ...
            power_demand, a0, b0, c0, pmin, pmax, ramp_up, ramp_down, ...
            commonIterations, candVal, VLIM_beta, ...
            VLIM_levyScaleRatio, penaltyFactor, tol, maxLambdaIter);

        dailyCosts_cand(trial) = sum(dailyCosts_tmp);
    end

    SensitivityRows = [SensitivityRows; ...
        {"numCandidates", candVal, mean(dailyCosts_cand), std(dailyCosts_cand), ...
         min(dailyCosts_cand), max(dailyCosts_cand)}];
end

SensitivityTable = cell2table(SensitivityRows, ...
    'VariableNames', {'Parameter','Value','MeanDailyCost','StdDailyCost','BestDailyCost','WorstDailyCost'});

disp(SensitivityTable);
writetable(SensitivityTable, outputExcel, 'Sheet', 'Sensitivity');

% -------------------------
% Split sensitivity results
% -------------------------
paramNames = string(SensitivityTable.Parameter);

betaMask = paramNames == "beta";
scaleMask = paramNames == "levyScaleRatio";
candMask = paramNames == "numCandidates";

betaValues = SensitivityTable.Value(betaMask);
betaMeans  = SensitivityTable.MeanDailyCost(betaMask);
betaStds   = SensitivityTable.StdDailyCost(betaMask);

scaleValues = SensitivityTable.Value(scaleMask);
scaleMeans  = SensitivityTable.MeanDailyCost(scaleMask);
scaleStds   = SensitivityTable.StdDailyCost(scaleMask);

candValues = SensitivityTable.Value(candMask);
candMeans  = SensitivityTable.MeanDailyCost(candMask);
candStds   = SensitivityTable.StdDailyCost(candMask);

% -------------------------
% Figure 4: beta sensitivity
% -------------------------
fig4 = figure('Color','w','Position',[140 140 850 500]);
set(fig4,'Toolbar','none');

errorbar(betaValues, betaMeans, betaStds, '-o', ...
    'LineWidth', 1.8, 'MarkerSize', 7);

xlabel('\beta', 'FontName','Times New Roman', 'FontSize',15);
ylabel('Mean Daily Fuel Cost', 'FontName','Times New Roman', 'FontSize',15);
%%title('Sensitivity analysis of Lévy stability parameter \beta', ...
    %%'FontName','Times New Roman', 'FontSize',20, 'FontWeight','normal');

ax4 = gca;
ax4.FontName = 'Times New Roman';
ax4.FontSize = 15;
ax4.LineWidth = 1.0;
ax4.Box = 'on';
ax4.TickDir = 'in';
grid off;

save_figure_safe(fig4, 'Sensitivity_Beta');

% -------------------------
% Figure 5: scale sensitivity
% -------------------------
fig5 = figure('Color','w','Position',[140 140 850 500]);
set(fig5,'Toolbar','none');

errorbar(scaleValues, scaleMeans, scaleStds, '-o', ...
    'LineWidth', 1.8, 'MarkerSize', 7);

xlabel('Lévy Scale Ratio', 'FontName','Times New Roman', 'FontSize',15);
ylabel('Mean Daily Fuel Cost', 'FontName','Times New Roman', 'FontSize',15);
%%title('Sensitivity analysis of Lévy scale ratio', ...
    %%'FontName','Times New Roman', 'FontSize',20, 'FontWeight','normal');

ax5 = gca;
ax5.FontName = 'Times New Roman';
ax5.FontSize = 15;
ax5.LineWidth = 1.0;
ax5.Box = 'on';
ax5.TickDir = 'in';
grid off;

save_figure_safe(fig5, 'Sensitivity_Scale');

% -------------------------
% Figure 6: candidate sensitivity
% -------------------------
fig6 = figure('Color','w','Position',[140 140 850 500]);
set(fig6,'Toolbar','none');

errorbar(candValues, candMeans, candStds, '-o', ...
    'LineWidth', 1.8, 'MarkerSize', 7);

xlabel('Number of Candidates', 'FontName','Times New Roman', 'FontSize',15);
ylabel('Mean Daily Fuel Cost', 'FontName','Times New Roman', 'FontSize',15);
%%title('Sensitivity analysis of number of candidates', ...
    %%'FontName','Times New Roman', 'FontSize',20, 'FontWeight','normal');

ax6 = gca;
ax6.FontName = 'Times New Roman';
ax6.FontSize = 15;
ax6.LineWidth = 1.0;
ax6.Box = 'on';
ax6.TickDir = 'in';
grid off;

save_figure_safe(fig6, 'Sensitivity_Candidates');

%% =========================================================
% LOCAL FUNCTIONS
%% =========================================================

function [FuelCost, totalFuelCost] = calculate_fuel_cost(P, a, b, c)
    FuelCost = (a + b .* P + c .* (P.^2)) / 1000;
    totalFuelCost = sum(FuelCost);
end

function fit = objective_with_penalty(P, demand, a, b, c, penaltyFactor)
    [~, cost] = calculate_fuel_cost(P, a, b, c);
    mismatchPenalty = abs(demand - sum(P)) * penaltyFactor;
    fit = cost + mismatchPenalty;
end

function P = lambda_dispatch(demand, b, c, pmin, pmax, tol, maxIter)
    P = zeros(length(pmin),1);
    Lambda = max(b);
    iterations = 0;

    while abs(demand - sum(P)) > tol && iterations < maxIter
        iterations = iterations + 1;
        Pnew = min(max((Lambda - b)./(2.*c), pmin), pmax);
        mismatch = demand - sum(Pnew);
        denom = sum(1./(2.*c));
        if abs(denom) < 1e-12
            break;
        end
        Lambda = Lambda + mismatch/denom;
        P = Pnew;
    end
end

function step = levy_flight(n, beta, scale)
    sigma = ( gamma(1 + beta) * sin(pi * beta / 2) / ...
        ( gamma((1 + beta) / 2) * beta * 2^((beta - 1) / 2) ) )^(1 / beta);
    u = randn(n,1) * sigma;
    v = randn(n,1);
    step = (u ./ (abs(v).^(1 / beta))) * scale;
end

function P = repair_dispatch(P, demand, pmin, pmax)
    P = min(max(P, pmin), pmax);
    totalP = sum(P);
    if totalP > 0
        P = P * (demand / totalP);
    end
    P = min(max(P, pmin), pmax);

    mismatch = demand - sum(P);
    if abs(mismatch) > 1e-6
        freeIdx = find(P > pmin + 1e-6 & P < pmax - 1e-6);
        if ~isempty(freeIdx)
            P(freeIdx) = P(freeIdx) + mismatch / numel(freeIdx);
            P = min(max(P, pmin), pmax);
        end
    end
end

function save_figure_safe(figHandle, fileBase)
    drawnow;
    try
        exportgraphics(figHandle, [fileBase '.pdf'], 'ContentType', 'vector');
        exportgraphics(figHandle, [fileBase '.png'], 'Resolution', 600);
    catch
        print(figHandle, [fileBase '.png'], '-dpng', '-r600');
        print(figHandle, [fileBase '.pdf'], '-dpdf', '-bestfit');
    end
end

%% ======================= DAY-LEVEL SOLVERS =======================

function [Pday, dailyCosts, dayTimes, convVec] = solve_vlim_cbo_lf_day_fixed( ...
    power_demand, a, b, c, pmin, pmax, ramp_up, ramp_down, ...
    numIterations, numCandidates, beta, levyScaleRatio, penaltyFactor, tol, maxLambdaIter)

    %#ok<INUSD> ramp_up ramp_down maxLambdaIter
    nHour = length(power_demand);
    nGen = length(a);

    Pday = zeros(1, nHour, nGen);
    dailyCosts = zeros(nHour,1);
    dayTimes = zeros(nHour,1);
    convVec = zeros(1,numIterations);

    baseDispatch = zeros(nGen, nHour);
    for h = 1:nHour
        baseDispatch(:,h) = lambda_dispatch(power_demand(h), b, c, pmin, pmax, tol, maxLambdaIter);
    end

    bestDailyObjective = inf;
    bestDispatch = baseDispatch;

    stepScale = levyScaleRatio * (pmax - pmin);

    for iter = 1:numIterations
        for cand = 1:numCandidates
            candidateDispatch = zeros(nGen, nHour);
            totalObj = 0;

            for h = 1:nHour
                demand = power_demand(h);

                step = levy_flight(nGen, beta, 1.0) .* stepScale;
                Pcand = baseDispatch(:,h) + step;
                Pcand = repair_dispatch(Pcand, demand, pmin, pmax);

                candidateDispatch(:,h) = Pcand;
                totalObj = totalObj + objective_with_penalty(Pcand, demand, a, b, c, penaltyFactor);
            end

            if totalObj < bestDailyObjective
                bestDailyObjective = totalObj;
                bestDispatch = candidateDispatch;
            end
        end

        convVec(iter) = bestDailyObjective;
        baseDispatch = bestDispatch;
    end

    for h = 1:nHour
        tic;
        P = bestDispatch(:,h);
        dayTimes(h) = toc;
        [~, cost] = calculate_fuel_cost(P, a, b, c);
        dailyCosts(h) = cost;
        Pday(1,h,:) = P;
    end
end

function [Pday, dailyCosts, dayTimes, convVec] = solve_abc_day_fixed( ...
    power_demand, a, b, c, pmin, pmax, rampup, rampdown, ...
    numBees, numIterations, limit, penaltyFactor, tol)

    %#ok<INUSD> rampup rampdown tol
    nHour = length(power_demand);
    nGen = length(a);
    Pday = zeros(1, nHour, nGen);
    dailyCosts = zeros(nHour,1);
    dayTimes = zeros(nHour,1);
    convVec = zeros(1,numIterations);

    bees = rand(numBees, nGen) .* (pmax' - pmin') + pmin';
    fitness = inf(numBees,1);
    trialCounter = zeros(numBees,1);

    bestBee = zeros(nGen,1);
    bestObj = inf;

    for i = 1:numBees
        totalObj = 0;
        for h = 1:nHour
            P = repair_dispatch(bees(i,:)', power_demand(h), pmin, pmax);
            totalObj = totalObj + objective_with_penalty(P, power_demand(h), a, b, c, penaltyFactor);
        end
        fitness(i) = totalObj;
        if totalObj < bestObj
            bestObj = totalObj;
            bestBee = bees(i,:)';
        end
    end

    for iter = 1:numIterations
        for i = 1:numBees
            k = randi(numBees); while k == i, k = randi(numBees); end
            phi = -1 + 2*rand(1,nGen);
            newBee = bees(i,:) + phi .* (bees(i,:) - bees(k,:));
            newBee = min(max(newBee, pmin'), pmax');

            newFit = 0;
            for h = 1:nHour
                P = repair_dispatch(newBee', power_demand(h), pmin, pmax);
                newFit = newFit + objective_with_penalty(P, power_demand(h), a, b, c, penaltyFactor);
            end

            if newFit < fitness(i)
                bees(i,:) = newBee;
                fitness(i) = newFit;
                trialCounter(i) = 0;
            else
                trialCounter(i) = trialCounter(i) + 1;
            end

            if fitness(i) < bestObj
                bestObj = fitness(i);
                bestBee = bees(i,:)';
            end
        end

        probs = (1./(1+fitness)) ./ sum(1./(1+fitness));
        for t = 1:numBees
            i = randsample(1:numBees,1,true,probs);
            k = randi(numBees); while k == i, k = randi(numBees); end
            phi = -1 + 2*rand(1,nGen);
            newBee = bees(i,:) + phi .* (bees(i,:) - bees(k,:));
            newBee = min(max(newBee, pmin'), pmax');

            newFit = 0;
            for h = 1:nHour
                P = repair_dispatch(newBee', power_demand(h), pmin, pmax);
                newFit = newFit + objective_with_penalty(P, power_demand(h), a, b, c, penaltyFactor);
            end

            if newFit < fitness(i)
                bees(i,:) = newBee;
                fitness(i) = newFit;
                trialCounter(i) = 0;
            else
                trialCounter(i) = trialCounter(i) + 1;
            end

            if fitness(i) < bestObj
                bestObj = fitness(i);
                bestBee = bees(i,:)';
            end
        end

        for i = 1:numBees
            if trialCounter(i) >= limit
                bees(i,:) = rand(1,nGen) .* (pmax' - pmin') + pmin';
                fitness(i) = inf;
                trialCounter(i) = 0;
            end
        end

        convVec(iter) = bestObj;
    end

    for h = 1:nHour
        tic;
        P = repair_dispatch(bestBee, power_demand(h), pmin, pmax);
        dayTimes(h) = toc;
        [~, cost] = calculate_fuel_cost(P, a, b, c);
        dailyCosts(h) = cost;
        Pday(1,h,:) = P;
    end
end

function [Pday, dailyCosts, dayTimes, convVec] = solve_gwo_day_fixed( ...
    power_demand, a, b, c, pmin, pmax, rampup, rampdown, ...
    numWolves, numIterations, penaltyFactor, tol)

    %#ok<INUSD> rampup rampdown tol
    nHour = length(power_demand);
    nGen = length(a);

    Pday = zeros(1, nHour, nGen);
    dailyCosts = zeros(nHour,1);
    dayTimes = zeros(nHour,1);
    convVec = zeros(1,numIterations);

    wolves = rand(numWolves, nGen) .* (pmax' - pmin') + pmin';

    alpha = zeros(nGen,1); betaW = alpha; delta = alpha;
    alphaScore = inf; betaScore = inf; deltaScore = inf;

    for iter = 1:numIterations
        for i = 1:numWolves
            wolves(i,:) = min(max(wolves(i,:), pmin'), pmax');
            totalObj = 0;
            for h = 1:nHour
                P = repair_dispatch(wolves(i,:)', power_demand(h), pmin, pmax);
                totalObj = totalObj + objective_with_penalty(P, power_demand(h), a, b, c, penaltyFactor);
            end

            if totalObj < alphaScore
                deltaScore = betaScore; delta = betaW;
                betaScore = alphaScore; betaW = alpha;
                alphaScore = totalObj; alpha = wolves(i,:)';
            elseif totalObj < betaScore
                deltaScore = betaScore; delta = betaW;
                betaScore = totalObj; betaW = wolves(i,:)';
            elseif totalObj < deltaScore
                deltaScore = totalObj; delta = wolves(i,:)';
            end
        end

        for i = 1:numWolves
            for j = 1:nGen
                r1 = rand; r2 = rand;
                A1 = 2*r1 - 1; C1 = 2*r2;
                D_alpha = abs(C1*alpha(j) - wolves(i,j));
                X1 = alpha(j) - A1*D_alpha;

                r1 = rand; r2 = rand;
                A2 = 2*r1 - 1; C2 = 2*r2;
                D_beta = abs(C2*betaW(j) - wolves(i,j));
                X2 = betaW(j) - A2*D_beta;

                r1 = rand; r2 = rand;
                A3 = 2*r1 - 1; C3 = 2*r2;
                D_delta = abs(C3*delta(j) - wolves(i,j));
                X3 = delta(j) - A3*D_delta;

                wolves(i,j) = (X1 + X2 + X3)/3;
            end
        end

        convVec(iter) = alphaScore;
    end

    for h = 1:nHour
        tic;
        P = repair_dispatch(alpha, power_demand(h), pmin, pmax);
        dayTimes(h) = toc;
        [~, cost] = calculate_fuel_cost(P, a, b, c);
        dailyCosts(h) = cost;
        Pday(1,h,:) = P;
    end
end

function [Pday, dailyCosts, dayTimes, convVec] = solve_pso_day_fixed( ...
    power_demand, a, b, c, pmin, pmax, rampup, rampdown, ...
    numParticles, numIterations, w, c1, c2, penaltyFactor, tol)

    %#ok<INUSD> rampup rampdown tol
    nHour = length(power_demand);
    nGen = length(a);

    Pday = zeros(1, nHour, nGen);
    dailyCosts = zeros(nHour,1);
    dayTimes = zeros(nHour,1);
    convVec = zeros(1,numIterations);

    particles = rand(numParticles, nGen) .* (pmax' - pmin') + pmin';
    velocities = -1 + 2*rand(numParticles, nGen);

    personalBestPos = particles;
    personalBestScore = inf(numParticles,1);
    globalBestPos = zeros(nGen,1);
    globalBestScore = inf;

    for iter = 1:numIterations
        for i = 1:numParticles
            particles(i,:) = min(max(particles(i,:), pmin'), pmax');

            totalObj = 0;
            for h = 1:nHour
                P = repair_dispatch(particles(i,:)', power_demand(h), pmin, pmax);
                totalObj = totalObj + objective_with_penalty(P, power_demand(h), a, b, c, penaltyFactor);
            end

            if totalObj < personalBestScore(i)
                personalBestScore(i) = totalObj;
                personalBestPos(i,:) = particles(i,:);
            end

            if totalObj < globalBestScore
                globalBestScore = totalObj;
                globalBestPos = particles(i,:)';
            end
        end

        for i = 1:numParticles
            r1 = rand(1,nGen);
            r2 = rand(1,nGen);
            velocities(i,:) = w*velocities(i,:) + ...
                c1*r1.*(personalBestPos(i,:) - particles(i,:)) + ...
                c2*r2.*(globalBestPos' - particles(i,:));
            particles(i,:) = particles(i,:) + velocities(i,:);
        end

        convVec(iter) = globalBestScore;
    end

    for h = 1:nHour
        tic;
        P = repair_dispatch(globalBestPos, power_demand(h), pmin, pmax);
        dayTimes(h) = toc;
        [~, cost] = calculate_fuel_cost(P, a, b, c);
        dailyCosts(h) = cost;
        Pday(1,h,:) = P;
    end
end

function [Pday, dailyCosts, dayTimes, convVec] = solve_woa_day_fixed( ...
    power_demand, a, b, c, pmin, pmax, rampup, rampdown, ...
    numWhales, numIterations, penaltyFactor, tol)

    %#ok<INUSD> rampup rampdown tol
    nHour = length(power_demand);
    nGen = length(a);

    Pday = zeros(1, nHour, nGen);
    dailyCosts = zeros(nHour,1);
    dayTimes = zeros(nHour,1);
    convVec = zeros(1,numIterations);

    whales = rand(numWhales, nGen) .* (pmax' - pmin') + pmin';

    bestWhale = zeros(nGen,1);
    bestScore = inf;

    for iter = 1:numIterations
        a_param = 2 - 2*(iter/numIterations);

        for i = 1:numWhales
            whales(i,:) = min(max(whales(i,:), pmin'), pmax');

            totalObj = 0;
            for h = 1:nHour
                P = repair_dispatch(whales(i,:)', power_demand(h), pmin, pmax);
                totalObj = totalObj + objective_with_penalty(P, power_demand(h), a, b, c, penaltyFactor);
            end

            if totalObj < bestScore
                bestScore = totalObj;
                bestWhale = whales(i,:)';
            end
        end

        for i = 1:numWhales
            r = rand;
            if r < 0.5
                A = 2*a_param*rand - a_param;
                C = 2*rand;
                D = abs(C*bestWhale' - whales(i,:));
                whales(i,:) = bestWhale' - A*D;
            else
                spiral_b = 1;
                l = -1 + 2*rand;
                dist = abs(bestWhale' - whales(i,:));
                whales(i,:) = dist .* exp(spiral_b*l) .* cos(2*pi*l) + bestWhale';
            end
            whales(i,:) = min(max(whales(i,:), pmin'), pmax');
        end

        convVec(iter) = bestScore;
    end

    for h = 1:nHour
        tic;
        P = repair_dispatch(bestWhale, power_demand(h), pmin, pmax);
        dayTimes(h) = toc;
        [~, cost] = calculate_fuel_cost(P, a, b, c);
        dailyCosts(h) = cost;
        Pday(1,h,:) = P;
    end
end