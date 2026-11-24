%% ANALISIS STATISTIK DATA METODE OPTIMASI
% File: 1 Kompilasi Data.xlsx
% Uji: ANOVA, Box-Whisker summary, Wilcoxon signed-rank, paired t-test

clc; clear; close all;

%% 1. BACA DATA DARI EXCEL
filename = '1 Kompilasi Data.xlsx';

% Baca seluruh isi sheet pertama
raw = readcell(filename);

% Asumsi:
% baris 2 = nama metode
% baris 3 dst = data numerik
methodNames = string(raw(2, :));
methodNames = methodNames(~ismissing(methodNames) & methodNames ~= "");

dataRaw = raw(3:end, 1:numel(methodNames));

% Konversi ke matriks numerik
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

% Hapus baris yang seluruhnya kosong
data(all(isnan(data),2),:) = [];

disp('======================================================');
disp('DATA YANG DIGUNAKAN');
disp('======================================================');
Tdata = array2table(data, 'VariableNames', matlab.lang.makeValidName(cellstr(methodNames)));
disp(Tdata);

%% 2. ANOVA SATU ARAH
% Ubah data ke format vektor untuk anova1
allValues = [];
groupLabels = [];

for j = 1:nCols
    col = data(:,j);
    col = col(~isnan(col));
    allValues = [allValues; col];
    groupLabels = [groupLabels; repmat(methodNames(j), numel(col), 1)];
end

[p_anova, tbl_anova, stats_anova] = anova1(allValues, groupLabels, 'off');

disp(' ');
disp('======================================================');
disp('HASIL ONE-WAY ANOVA');
disp('======================================================');

disp('ANOVA TABLE ASLI DARI MATLAB:');
disp(tbl_anova);

Source = string(tbl_anova(2:4,1));
SumSq  = cell2mat(tbl_anova(2:4,2));
DF     = cell2mat(tbl_anova(2:4,3));
MeanSq = [cell2mat(tbl_anova(2:3,4)); NaN];
Fvalue = [cell2mat(tbl_anova(2,5)); NaN; NaN];
Pvalue = [cell2mat(tbl_anova(2,6)); NaN; NaN];

anovaTable = table(Source, SumSq, DF, MeanSq, Fvalue, Pvalue, ...
    'VariableNames', {'Source','SumSq','DF','MeanSq','F','pValue'});

disp('RINGKASAN ANOVA TABLE:');
disp(anovaTable);

anovaSummary = table(p_anova, tbl_anova{2,5}, tbl_anova{2,3}, tbl_anova{3,3}, ...
    'VariableNames', {'pValue','FStatistic','DF_Between','DF_Within'});

disp('RINGKASAN PARAMETER ANOVA:');
disp(anovaSummary);

alpha = 0.05;
if p_anova < alpha
    decision = "Tolak H0";
    conclusion = "Terdapat perbedaan rata-rata yang signifikan antar metode";
else
    decision = "Gagal Tolak H0";
    conclusion = "Tidak terdapat perbedaan rata-rata yang signifikan antar metode";
end

anovaDecisionTable = table(alpha, p_anova, decision, conclusion, ...
    'VariableNames', {'Alpha','pValue','Decision','Conclusion'});

disp('KEPUTUSAN UJI ANOVA:');
disp(anovaDecisionTable);

%% 3. BOXPLOT
figure('Name','Boxplot Perbandingan Metode');
boxplot(allValues, groupLabels);
%title('Boxplot Total Fuel Cost per Metode');
xlabel('Method');
ylabel('Total Fuel Cost');
grid on;

%% 4. BOX-WHISKER SUMMARY TABLE
minVal  = NaN(1,nCols);
q1Val   = NaN(1,nCols);
medVal  = NaN(1,nCols);
q3Val   = NaN(1,nCols);
maxVal  = NaN(1,nCols);
meanVal = NaN(1,nCols);
stdVal  = NaN(1,nCols);

for j = 1:nCols
    col = data(:,j);
    col = col(~isnan(col));

    minVal(j)  = min(col);
    q1Val(j)   = prctile(col,25);
    medVal(j)  = median(col);
    q3Val(j)   = prctile(col,75);
    maxVal(j)  = max(col);
    meanVal(j) = mean(col);
    stdVal(j)  = std(col);
end

boxSummary = table(methodNames', minVal', q1Val', medVal', q3Val', maxVal', meanVal', stdVal', ...
    'VariableNames', {'Method','Min','Q1','Median','Q3','Max','Mean','StdDev'});

disp(' ');
disp('======================================================');
disp('BOX-WHISKER SUMMARY');
disp('======================================================');
disp(boxSummary);

%% 5. PILIH METODE REFERENSI
% Prioritas: VLIM-CBO-LF
refName = "VLIM_CBO_LF";
validNames = matlab.lang.makeValidName(cellstr(methodNames));

refIdx = find(strcmpi(validNames, refName), 1);

if isempty(refIdx)
    % Cari nama asli jika ada strip
    refIdx = find(strcmpi(methodNames, "VLIM-CBO-LF"), 1);
end

if isempty(refIdx)
    % Jika tidak ada, pakai kolom pertama
    refIdx = 1;
    fprintf('\nMetode referensi VLIM-CBO-LF tidak ditemukan. Dipakai referensi: %s\n', methodNames(refIdx));
else
    fprintf('\nMetode referensi untuk uji berpasangan: %s\n', methodNames(refIdx));
end

refData = data(:, refIdx);

%% 6. PAIRED T-TEST
compNames_t = {};
tStatList   = [];
pValList_t  = [];
meanDiff_t  = [];
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

    [h,p,~,stats] = ttest(x, y);

    compNames_t{end+1,1} = sprintf('%s vs %s', methodNames(refIdx), methodNames(j));
    tStatList(end+1,1)   = stats.tstat;
    pValList_t(end+1,1)  = p;
    meanDiff_t(end+1,1)  = mean(x - y);
    hList_t(end+1,1)     = h;
end

ttestTable = table(compNames_t, tStatList, pValList_t, meanDiff_t, hList_t, ...
    'VariableNames', {'Comparison','tStatistic','pValue','MeanDifference','RejectH0'});

disp(' ');
disp('======================================================');
disp('HASIL PAIRED T-TEST');
disp('======================================================');
disp(ttestTable);

%% 7. WILCOXON SIGNED-RANK TEST
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

%% 8. OPSIONAL: MULTIPLE COMPARISON SETELAH ANOVA
disp(' ');
disp('======================================================');
disp('POST-HOC MULTIPLE COMPARISON (OPTIONAL)');
disp('======================================================');

try
    c = multcompare(stats_anova, 'Display', 'off');
    posthocTable = array2table(c, ...
        'VariableNames', {'Group1','Group2','LowerCI','MeanDiff','UpperCI','pValue'});
    disp(posthocTable);
catch
    disp('multcompare tidak dapat dijalankan pada data ini.');
end

disp(' ');
disp('======================================================');
disp('ANALISIS SELESAI');
disp('======================================================');