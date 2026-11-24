%% =========================================================
%  STATISTICAL TESTS FOR IMPROVED METHOD
%  File: 2 Kompilasi Data.xlsx
%  Methods: VLIM-CBO-LF, VLIM-CBO, VLIM
% ==========================================================

clc; clear; close all;

%% 1) READ DATA FROM EXCEL
filename = '2 Kompilasi Data.xlsx';
raw = readcell(filename);

% Row 2 = method names
methodNames = string(raw(2, :));
methodNames = methodNames(~ismissing(methodNames) & methodNames ~= "");

% Row 3 onward = numeric data
dataRaw = raw(3:end, 1:numel(methodNames));

[nRows, nCols] = size(dataRaw);
data = NaN(nRows, nCols);

for i = 1:nRows
    for j = 1:nCols
        val = dataRaw{i,j};
        if isnumeric(val)
            data(i,j) = val;
        elseif ischar(val) || isstring(val)
            numVal = str2double(val);
            if ~isnan(numVal)
                data(i,j) = numVal;
            end
        end
    end
end

% Remove empty rows
data(all(isnan(data),2),:) = [];

disp('======================================================');
disp('DATA YANG DIGUNAKAN');
disp('======================================================');
Tdata = array2table(data, 'VariableNames', matlab.lang.makeValidName(cellstr(methodNames)));
disp(Tdata);

%% 2) DESCRIPTIVE / BOX-WHISKER SUMMARY
minVal  = min(data);
q1Val   = prctile(data,25);
medVal  = median(data);
q3Val   = prctile(data,75);
maxVal  = max(data);
meanVal = mean(data);
stdVal  = std(data);

descTable = table(methodNames', minVal', q1Val', medVal', q3Val', maxVal', meanVal', stdVal', ...
    'VariableNames', {'Method','Min','Q1','Median','Q3','Max','Mean','StdDev'});

disp(' ');
disp('======================================================');
disp('BOX-WHISKER SUMMARY');
disp('======================================================');
disp(descTable);

%% 3) BOXPLOT
figure('Name','Boxplot Comparison','Color','w');
boxplot(data, 'Labels', cellstr(methodNames));
ylabel('Total Fuel Cost');
xlabel('Method');
title('Boxplot Total Fuel Cost');
grid on;

%% 4) SET REFERENCE METHOD
refName = "VLIM-CBO-LF";
refIdx = find(strcmp(methodNames, refName), 1);

if isempty(refIdx)
    error('Metode referensi VLIM-CBO-LF tidak ditemukan.');
end

refData = data(:, refIdx);
fprintf('\nMetode referensi untuk uji berpasangan: %s\n', methodNames(refIdx));

%% 5) NORMALITY TEST OF PAIRED DIFFERENCES
% H0: selisih berdistribusi normal
% H=0 -> gagal tolak H0 (normal)
% H=1 -> tolak H0 (tidak normal)

normalityPairs = {};
normalityH = [];
normalityP = [];
normalityDecision = strings(0,1);

for j = 1:nCols
    if j == refIdx
        continue;
    end

    d = refData - data(:,j);
    d = d(~isnan(d));

    try
        [h, p] = lillietest(d);
    catch
        h = NaN;
        p = NaN;
    end

    normalityPairs{end+1,1} = sprintf('%s - %s', methodNames(refIdx), methodNames(j));
    normalityH(end+1,1) = h;
    normalityP(end+1,1) = p;

    if isnan(h)
        normalityDecision(end+1,1) = "Test unavailable";
    elseif h == 0
        normalityDecision(end+1,1) = "Normal";
    else
        normalityDecision(end+1,1) = "Not Normal";
    end
end

normalityTable = table(normalityPairs, normalityH, normalityP, normalityDecision, ...
    'VariableNames', {'DifferencePair','RejectNormality','pValue','Conclusion'});

disp(' ');
disp('======================================================');
disp('NORMALITY TEST OF PAIRED DIFFERENCES');
disp('======================================================');
disp(normalityTable);

%% 6) PAIRED T-TEST
compNames_t = {};
tStatList   = [];
pValList_t  = [];
meanDiff_t  = [];
ciLow_t     = [];
ciHigh_t    = [];
hList_t     = [];

for j = 1:nCols
    if j == refIdx
        continue;
    end

    x = refData;
    y = data(:,j);

    valid = ~isnan(x) & ~isnan(y);
    x = x(valid);
    y = y(valid);

    if numel(x) < 2
        continue;
    end

    [h,p,ci,stats] = ttest(x, y);

    compNames_t{end+1,1} = sprintf('%s vs %s', methodNames(refIdx), methodNames(j));
    tStatList(end+1,1)   = stats.tstat;
    pValList_t(end+1,1)  = p;
    meanDiff_t(end+1,1)  = mean(x - y);
    ciLow_t(end+1,1)     = ci(1);
    ciHigh_t(end+1,1)    = ci(2);
    hList_t(end+1,1)     = h;
end

ttestTable = table(compNames_t, tStatList, pValList_t, meanDiff_t, ciLow_t, ciHigh_t, hList_t, ...
    'VariableNames', {'Comparison','tStatistic','pValue','MeanDifference','CILower','CIUpper','RejectH0'});

disp(' ');
disp('======================================================');
disp('HASIL PAIRED T-TEST');
disp('======================================================');
disp(ttestTable);

%% 7) WILCOXON SIGNED-RANK TEST
compNames_w = {};
pValList_w  = [];
signedRankStat = [];
hList_w     = [];
medianDiff_w = [];

for j = 1:nCols
    if j == refIdx
        continue;
    end

    x = refData;
    y = data(:,j);

    valid = ~isnan(x) & ~isnan(y);
    x = x(valid);
    y = y(valid);

    if numel(x) < 1
        continue;
    end

    [p,h,stats] = signrank(x, y);

    compNames_w{end+1,1}   = sprintf('%s vs %s', methodNames(refIdx), methodNames(j));
    pValList_w(end+1,1)    = p;
    hList_w(end+1,1)       = h;
    medianDiff_w(end+1,1)  = median(x - y);

    if isfield(stats, 'signedrank')
        signedRankStat(end+1,1) = stats.signedrank;
    else
        signedRankStat(end+1,1) = NaN;
    end
end

wilcoxonTable = table(compNames_w, signedRankStat, pValList_w, medianDiff_w, hList_w, ...
    'VariableNames', {'Comparison','SignedRankStatistic','pValue','MedianDifference','RejectH0'});

disp(' ');
disp('======================================================');
disp('HASIL WILCOXON SIGNED-RANK TEST');
disp('======================================================');
disp(wilcoxonTable);

%% 8) FRIEDMAN TEST
[p_friedman, tbl_friedman, stats_friedman] = friedman(data, 1, 'off');

disp(' ');
disp('======================================================');
disp('HASIL FRIEDMAN TEST');
disp('======================================================');
disp('FRIEDMAN TABLE ASLI DARI MATLAB:');
disp(tbl_friedman);

friedmanSummary = table(p_friedman, ...
    'VariableNames', {'pValue'});

disp('RINGKASAN FRIEDMAN TEST:');
disp(friedmanSummary);

if p_friedman < 0.05
    disp('Keputusan: Tolak H0 -> terdapat perbedaan signifikan antar metode.');
else
    disp('Keputusan: Gagal Tolak H0 -> tidak terdapat perbedaan signifikan antar metode.');
end

%% 9) POST-HOC WILCOXON + BONFERRONI
pairs = nchoosek(1:nCols, 2);
m = size(pairs, 1);

pairNames = {};
rawP = [];
adjP = [];
medDiff = [];
sigRaw = [];
sigAdj = [];

for k = 1:m
    i = pairs(k,1);
    j = pairs(k,2);

    x = data(:,i);
    y = data(:,j);

    valid = ~isnan(x) & ~isnan(y);
    x = x(valid);
    y = y(valid);

    if numel(x) < 1
        continue;
    end

    [p, ~, ~] = signrank(x, y);

    pAdj = min(p * m, 1);
    mdiff = median(x - y);

    pairNames{end+1,1} = sprintf('%s vs %s', methodNames(i), methodNames(j));
    rawP(end+1,1)    = p;
    adjP(end+1,1)    = pAdj;
    medDiff(end+1,1) = mdiff;
    sigRaw(end+1,1)  = p < 0.05;
    sigAdj(end+1,1)  = pAdj < 0.05;
end

sigRawText = strings(size(sigRaw));
sigAdjText = strings(size(sigAdj));

sigRawText(sigRaw==1) = "Yes";
sigRawText(sigRaw==0) = "No";
sigAdjText(sigAdj==1) = "Yes";
sigAdjText(sigAdj==0) = "No";

posthocWilcoxonTable = table(pairNames, rawP, adjP, medDiff, sigRawText, sigAdjText, ...
    'VariableNames', {'Comparison','RawPValue','BonferroniPValue','MedianDifference','SignificantRaw','SignificantAdjusted'});

disp(' ');
disp('======================================================');
disp('POST-HOC WILCOXON + BONFERRONI');
disp('======================================================');
disp(posthocWilcoxonTable);

%% 10) REPEATED-MEASURES ANOVA
disp(' ');
disp('======================================================');
disp('REPEATED-MEASURES ANOVA');
disp('======================================================');

try
    rmTable = array2table(data, 'VariableNames', matlab.lang.makeValidName(cellstr(methodNames)));
    WithinDesign = table((1:nCols)', 'VariableNames', {'Method'});
    validVarNames = string(rmTable.Properties.VariableNames);

    formula = sprintf('%s-%s ~ 1', validVarNames(1), validVarNames(end));
    rm = fitrm(rmTable, formula, 'WithinDesign', WithinDesign);
    ranovaTable = ranova(rm);

    disp(ranovaTable);
catch ME
    disp('Repeated-measures ANOVA tidak dapat dijalankan pada versi/toolbox MATLAB ini.');
    disp(ME.message);
end

%% 11) OPTIONAL POST-HOC AFTER FRIEDMAN
disp(' ');
disp('======================================================');
disp('POST-HOC MULTIPLE COMPARISON AFTER FRIEDMAN');
disp('======================================================');

try
    c = multcompare(stats_friedman, 'Display', 'off');
    posthocFriedmanTable = array2table(c, ...
        'VariableNames', {'Group1','Group2','LowerCI','MeanRankDiff','UpperCI','pValue'});
    disp(posthocFriedmanTable);
catch
    disp('multcompare untuk Friedman tidak dapat dijalankan pada versi MATLAB ini.');
end

%% 12) RANKING
[sortedMean, idxMean] = sort(meanVal, 'ascend');
rankingMean = table((1:nCols)', methodNames(idxMean)', sortedMean', ...
    'VariableNames', {'Rank','Method','MeanValue'});

[sortedMedian, idxMedian] = sort(medVal, 'ascend');
rankingMedian = table((1:nCols)', methodNames(idxMedian)', sortedMedian', ...
    'VariableNames', {'Rank','Method','MedianValue'});

disp(' ');
disp('======================================================');
disp('RANKING BY MEAN');
disp('======================================================');
disp(rankingMean);

disp(' ');
disp('======================================================');
disp('RANKING BY MEDIAN');
disp('======================================================');
disp(rankingMedian);

%% 13) SAVE OUTPUT TABLES
outputFile = 'hasil_uji_improved_method.xlsx';

try
    writetable(descTable, outputFile, 'Sheet', 'Descriptive');
    writetable(normalityTable, outputFile, 'Sheet', 'Normality');
    writetable(ttestTable, outputFile, 'Sheet', 'Paired_t_test');
    writetable(wilcoxonTable, outputFile, 'Sheet', 'Wilcoxon');
    writetable(posthocWilcoxonTable, outputFile, 'Sheet', 'Posthoc_Wilcoxon');
    writetable(rankingMean, outputFile, 'Sheet', 'Ranking_Mean');
    writetable(rankingMedian, outputFile, 'Sheet', 'Ranking_Median');
    fprintf('\nHasil disimpan ke file: %s\n', outputFile);
catch ME
    disp('Gagal menyimpan file Excel output.');
    disp(ME.message);
end

disp(' ');
disp('======================================================');
disp('ANALISIS SELESAI');
disp('======================================================');