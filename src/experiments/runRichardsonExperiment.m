function runRichardsonExperiment()
% runRichardsonExperiment  输出第15题 Richardson 外推数值结果
%
%   在多组粗细网格上计算二阶有限差分解和 Richardson 外推解，输出
%   逐点 CSV、收敛汇总 CSV 与完整 MAT 数据。本入口暂不绘图。
%
%   对应报告: 第15题 Richardson 外推算法延伸
%   作者: 项目成员   日期: 2026-09-10

    projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    addpath(genpath(fullfile(projectRoot, 'src')));

    nIntervalsList = [8, 16, 32, 64, 128, 256];
    resultsFolder = fullfile(projectRoot, 'results');
    if ~exist(resultsFolder, 'dir'), mkdir(resultsFolder); end

    nCases = numel(nIntervalsList);
    stepSizes = zeros(nCases, 1);
    coarseMaxErrors = zeros(nCases, 1);
    richardsonMaxErrors = zeros(nCases, 1);
    allRichardsonSolutions = cell(nCases, 1);

    fprintf('\n开始运行第15题 Richardson 外推实验。\n');
    for iGrid = 1:nCases
        nIntervals = nIntervalsList(iGrid);
        [x, uRichardson, meta] = richardsonExtrapolatePoisson(nIntervals);
        uExact = poissonExact(x);
        uCoarse = meta.coarseSolution;
        uFineAtCoarse = meta.fineSolutionAtCoarseNodes;
        coarseAbsError = abs(uCoarse - uExact);
        richardsonAbsError = abs(uRichardson - uExact);

        pointTable = table(x, uCoarse, uFineAtCoarse, uRichardson, uExact, ...
            coarseAbsError, richardsonAbsError, ...
            'VariableNames', {'x', 'uCoarse', 'uFineAtCoarse', ...
            'uRichardson', 'uExact', 'coarseAbsError', 'richardsonAbsError'});
        pointCsvPath = fullfile(resultsFolder, ...
            sprintf('poisson_richardson_n%03d_points.csv', nIntervals));
        writetable(pointTable, pointCsvPath);

        result = struct();
        result.nIntervals = nIntervals;
        result.x = x;
        result.uCoarse = uCoarse;
        result.uFineAtCoarse = uFineAtCoarse;
        result.uRichardson = uRichardson;
        result.uExact = uExact;
        result.coarseAbsError = coarseAbsError;
        result.richardsonAbsError = richardsonAbsError;
        result.meta = meta;
        result.pointCsvPath = pointCsvPath;
        allRichardsonSolutions{iGrid} = result;

        stepSizes(iGrid) = meta.stepSize;
        coarseMaxErrors(iGrid) = max(coarseAbsError);
        richardsonMaxErrors(iGrid) = max(richardsonAbsError);
    end

    [coarsePairwiseOrder, coarseFittedOrder] = ...
        computeOrder(stepSizes, coarseMaxErrors);
    [richardsonPairwiseOrder, richardsonFittedOrder] = ...
        computeOrder(stepSizes, richardsonMaxErrors);
    coarseOrder = [NaN; coarsePairwiseOrder];
    richardsonOrder = [NaN; richardsonPairwiseOrder];

    summaryTable = table(nIntervalsList(:), 2 * nIntervalsList(:), stepSizes, ...
        coarseMaxErrors, richardsonMaxErrors, coarseOrder, richardsonOrder, ...
        'VariableNames', {'coarseN', 'fineN', 'h', 'coarseMaxError', ...
        'richardsonMaxError', 'coarseOrder', 'richardsonOrder'});
    summaryCsvPath = fullfile(resultsFolder, 'poisson_richardson_summary.csv');
    writetable(summaryTable, summaryCsvPath);
    save(fullfile(resultsFolder, 'poisson_richardson_experiment.mat'), ...
        'nIntervalsList', 'stepSizes', 'coarseMaxErrors', ...
        'richardsonMaxErrors', 'coarsePairwiseOrder', ...
        'richardsonPairwiseOrder', 'coarseFittedOrder', ...
        'richardsonFittedOrder', 'summaryTable', 'allRichardsonSolutions');

    disp(summaryTable);
    fprintf('二阶有限差分拟合阶：%.6f\n', coarseFittedOrder);
    fprintf('Richardson 外推拟合阶：%.6f\n', richardsonFittedOrder);
    fprintf('Richardson 外推结果已保存到 results/，本实验未生成图像。\n');
end
