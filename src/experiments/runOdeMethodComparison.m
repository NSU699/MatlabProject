function runOdeMethodComparison()
% runOdeMethodComparison  正式比较 Euler、RK2 和 RK4 的精度与效率
%
%   对同一初值问题使用相同步数序列，记录最大误差、RMS误差、观测阶、
%   右端函数调用次数和重复 timeit 计时。计时只包含求解器调用，不包含
%   解析解、误差计算、绘图和文件写入。
%
%   输出:
%       results/ode_method_comparison.csv
%       results/ode_method_timing_raw.csv
%       results/ode_method_comparison.mat
%       figures/ode_methods_*.png/.pdf

    projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    addpath(genpath(fullfile(projectRoot, 'src')));
    resultsFolder = fullfile(projectRoot, 'results');
    figuresFolder = fullfile(projectRoot, 'figures');
    if ~exist(resultsFolder, 'dir'), mkdir(resultsFolder); end
    if ~exist(figuresFolder, 'dir'), mkdir(figuresFolder); end

    %% 实验参数
    nStepsList = [6, 12, 24, 48, 96, 192, 384].';
    timingRepeats = 7;
    rhs = @(t, y) -y + t.^2 + 3;
    tSpan = [0, 3];
    y0 = 1;

    methodKeys = {'Euler'; 'RK2'; 'RK4'};
    methodNames = {'显式 Euler'; '改进 Euler（RK2）'; '经典 RK4'};
    methodSolvers = {@eulerSolve; @rk2Solve; @rk4Solve};
    theoryOrders = [1; 2; 4];
    nMethods = numel(methodSolvers);
    nCases = numel(nStepsList);

    [~, yExact, exactCheck] = ivpExactSymbolic();

    %% 精度、阶数与理论工作量
    stepSizes = zeros(nMethods, nCases);
    maxErrors = zeros(nMethods, nCases);
    rmsErrors = zeros(nMethods, nCases);
    functionEvaluations = zeros(nMethods, nCases);
    pairwiseOrders = NaN(nMethods, nCases);
    fittedOrders = zeros(nMethods, 1);

    for iMethod = 1:nMethods
        solver = methodSolvers{iMethod};
        for iCase = 1:nCases
            nSteps = nStepsList(iCase);
            [t, yNum, meta] = solver(rhs, tSpan, y0, nSteps);
            [maxErrors(iMethod, iCase), ~, rmsErrors(iMethod, iCase)] = ...
                errorNorms(yNum(:, 1), yExact(t));
            stepSizes(iMethod, iCase) = meta.stepSize;
            functionEvaluations(iMethod, iCase) = meta.functionEvaluations;
        end
        [pairOrder, fittedOrders(iMethod)] = ...
            computeOrder(stepSizes(iMethod, :).', maxErrors(iMethod, :).');
        pairwiseOrders(iMethod, 2:end) = pairOrder.';
    end

    %% 重复计时
    % 精度循环已经完成首次调用；这里仍逐组合显式预热，再做七次独立 timeit。
    % 每轮循环轮换方法顺序，降低固定先后顺序对短时计量的影响。
    timingSeconds = zeros(nMethods, nCases, timingRepeats);
    timingOrderPosition = zeros(nMethods, nCases, timingRepeats);

    for iCase = 1:nCases
        nSteps = nStepsList(iCase);
        for iMethod = 1:nMethods
            solver = methodSolvers{iMethod};
            solver(rhs, tSpan, y0, nSteps);
        end

        for iRepeat = 1:timingRepeats
            methodOrder = circshift(1:nMethods, -mod(iRepeat - 1, nMethods));
            for iPosition = 1:nMethods
                iMethod = methodOrder(iPosition);
                solver = methodSolvers{iMethod};
                timingSeconds(iMethod, iCase, iRepeat) = ...
                    timeit(@() solver(rhs, tSpan, y0, nSteps));
                timingOrderPosition(iMethod, iCase, iRepeat) = iPosition;
            end
        end
    end

    %% 汇总并保存全部原始数据
    nSummaryRows = nMethods * nCases;
    methodKeyColumn = strings(nSummaryRows, 1);
    methodNameColumn = strings(nSummaryRows, 1);
    nColumn = zeros(nSummaryRows, 1);
    hColumn = zeros(nSummaryRows, 1);
    maxErrorColumn = zeros(nSummaryRows, 1);
    rmsErrorColumn = zeros(nSummaryRows, 1);
    pairwiseOrderColumn = NaN(nSummaryRows, 1);
    fittedOrderColumn = zeros(nSummaryRows, 1);
    theoryOrderColumn = zeros(nSummaryRows, 1);
    workColumn = zeros(nSummaryRows, 1);
    timeMedianColumn = zeros(nSummaryRows, 1);
    timeMeanColumn = zeros(nSummaryRows, 1);
    timeStdColumn = zeros(nSummaryRows, 1);
    timeMinColumn = zeros(nSummaryRows, 1);
    timeMaxColumn = zeros(nSummaryRows, 1);
    timeCvColumn = zeros(nSummaryRows, 1);

    iRow = 0;
    for iMethod = 1:nMethods
        for iCase = 1:nCases
            iRow = iRow + 1;
            samples = reshape(timingSeconds(iMethod, iCase, :), [], 1);
            methodKeyColumn(iRow) = methodKeys{iMethod};
            methodNameColumn(iRow) = methodNames{iMethod};
            nColumn(iRow) = nStepsList(iCase);
            hColumn(iRow) = stepSizes(iMethod, iCase);
            maxErrorColumn(iRow) = maxErrors(iMethod, iCase);
            rmsErrorColumn(iRow) = rmsErrors(iMethod, iCase);
            pairwiseOrderColumn(iRow) = pairwiseOrders(iMethod, iCase);
            fittedOrderColumn(iRow) = fittedOrders(iMethod);
            theoryOrderColumn(iRow) = theoryOrders(iMethod);
            workColumn(iRow) = functionEvaluations(iMethod, iCase);
            timeMedianColumn(iRow) = median(samples);
            timeMeanColumn(iRow) = mean(samples);
            timeStdColumn(iRow) = std(samples);
            timeMinColumn(iRow) = min(samples);
            timeMaxColumn(iRow) = max(samples);
            timeCvColumn(iRow) = std(samples) / mean(samples);
        end
    end

    comparisonTable = table(methodKeyColumn, methodNameColumn, nColumn, hColumn, ...
        maxErrorColumn, rmsErrorColumn, pairwiseOrderColumn, fittedOrderColumn, ...
        theoryOrderColumn, workColumn, timeMedianColumn, timeMeanColumn, ...
        timeStdColumn, timeMinColumn, timeMaxColumn, timeCvColumn, ...
        'VariableNames', {'methodKey', 'methodName', 'N', 'h', 'maxError', ...
        'rmsError', 'pairwiseOrder', 'fittedOrder', 'theoryOrder', ...
        'functionEvaluations', 'timeMedianSeconds', 'timeMeanSeconds', ...
        'timeStdSeconds', 'timeMinSeconds', 'timeMaxSeconds', ...
        'timeCoefficientVariation'});

    nRawRows = nSummaryRows * timingRepeats;
    rawMethodKey = strings(nRawRows, 1);
    rawMethodName = strings(nRawRows, 1);
    rawN = zeros(nRawRows, 1);
    rawRepeat = zeros(nRawRows, 1);
    rawOrderPosition = zeros(nRawRows, 1);
    rawTime = zeros(nRawRows, 1);
    iRow = 0;
    for iCase = 1:nCases
        for iRepeat = 1:timingRepeats
            for iMethod = 1:nMethods
                iRow = iRow + 1;
                rawMethodKey(iRow) = methodKeys{iMethod};
                rawMethodName(iRow) = methodNames{iMethod};
                rawN(iRow) = nStepsList(iCase);
                rawRepeat(iRow) = iRepeat;
                rawOrderPosition(iRow) = timingOrderPosition(iMethod, iCase, iRepeat);
                rawTime(iRow) = timingSeconds(iMethod, iCase, iRepeat);
            end
        end
    end
    timingTable = table(rawMethodKey, rawMethodName, rawN, rawRepeat, ...
        rawOrderPosition, rawTime, 'VariableNames', {'methodKey', 'methodName', ...
        'N', 'repeatIndex', 'orderPosition', 'timeSeconds'});

    comparisonCsvPath = fullfile(resultsFolder, 'ode_method_comparison.csv');
    timingCsvPath = fullfile(resultsFolder, 'ode_method_timing_raw.csv');
    writetable(comparisonTable, comparisonCsvPath);
    writetable(timingTable, timingCsvPath);

    runTimestamp = datetime('now', 'TimeZone', 'UTC', ...
        'Format', 'yyyy-MM-dd HH:mm:ss Z');
    environmentInfo = struct('matlabVersion', version, 'computer', computer, ...
        'runTimestamp', char(runTimestamp), 'timingRepeats', timingRepeats);
    save(fullfile(resultsFolder, 'ode_method_comparison.mat'), ...
        'comparisonTable', 'timingTable', 'timingSeconds', ...
        'timingOrderPosition', 'nStepsList', 'theoryOrders', ...
        'environmentInfo', 'exactCheck');

    %% 图表
    colors = [0.0000, 0.4470, 0.7410; ...
              0.8500, 0.3250, 0.0980; ...
              0.0000, 0.5500, 0.3500];
    markers = {'o', 's', '^'};
    lineStyles = {'-', '--', '-.'};
    timingMedians = reshape(timeMedianColumn, nCases, nMethods).';
    timingMins = reshape(timeMinColumn, nCases, nMethods).';
    timingMaxs = reshape(timeMaxColumn, nCases, nMethods).';

    makeConvergenceFigure(nStepsList, stepSizes, maxErrors, pairwiseOrders, ...
        fittedOrders, theoryOrders, methodKeys, colors, markers, lineStyles, ...
        fullfile(figuresFolder, 'ode_methods_convergence'));
    makeWorkPrecisionFigure(functionEvaluations, maxErrors, methodKeys, ...
        colors, markers, lineStyles, ...
        fullfile(figuresFolder, 'ode_methods_work_precision'));
    makeRuntimePrecisionFigure(timingMedians, maxErrors, methodKeys, ...
        colors, markers, lineStyles, ...
        fullfile(figuresFolder, 'ode_methods_runtime_precision'));
    makeTimingFigure(nStepsList, timingMedians, timingMins, timingMaxs, ...
        methodKeys, colors, markers, lineStyles, ...
        fullfile(figuresFolder, 'ode_methods_timing_variability'));
    
end

function makeConvergenceFigure(nSteps, h, maxError, pairwiseOrder, fittedOrder, ...
        theoryOrder, methodKeys, colors, markers, lineStyles, outputStem)
    fig = newFigure([8.0, 7.2]);
    layout = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

    axTop = nexttile(layout); hold(axTop, 'on');
    for iMethod = 1:numel(methodKeys)
        loglog(axTop, h(iMethod, :), maxError(iMethod, :), ...
            'Color', colors(iMethod, :), 'LineStyle', lineStyles{iMethod}, ...
            'Marker', markers{iMethod}, 'MarkerFaceColor', colors(iMethod, :), ...
            'LineWidth', 1.4, 'DisplayName', ...
            sprintf('%s（拟合阶 %.3f）', methodKeys{iMethod}, fittedOrder(iMethod)));
    end
    set(axTop, 'XScale', 'log', 'YScale', 'log', 'XDir', 'reverse');
    xlim(axTop, [min(h(:)) / 1.15, max(h(:)) * 1.15]);
    xlabel(axTop, '步长 h'); ylabel(axTop, '最大绝对误差');
    title(axTop, '三种方法的误差—步长关系');
    legend(axTop, 'Location', 'southwest', 'Box', 'off');
    applyFigureStyle(axTop);

    axBottom = nexttile(layout); hold(axBottom, 'on');
    for iMethod = 1:numel(methodKeys)
        semilogx(axBottom, nSteps(2:end), pairwiseOrder(iMethod, 2:end), ...
            'Color', colors(iMethod, :), 'LineStyle', lineStyles{iMethod}, ...
            'Marker', markers{iMethod}, 'MarkerFaceColor', colors(iMethod, :), ...
            'LineWidth', 1.4, 'DisplayName', methodKeys{iMethod});
        yline(axBottom, theoryOrder(iMethod), ':', ...
            'Color', colors(iMethod, :), 'LineWidth', 1.1, ...
            'HandleVisibility', 'off');
    end
    set(axBottom, 'XScale', 'log');
    xlim(axBottom, [min(nSteps(2:end)) / 1.15, max(nSteps(2:end)) * 1.15]);
    xticks(axBottom, nSteps(2:end));
    ylim(axBottom, [0.5, 4.5]);
    xlabel(axBottom, '细网格步数 N'); ylabel(axBottom, '相邻观测阶 p');
    title(axBottom, '逐级观测阶与理论阶');
    legend(axBottom, 'Location', 'eastoutside', 'Box', 'off');
    applyFigureStyle(axBottom);

    set(fig, 'Units', 'inches', 'Position', [1, 1, 8.0, 7.2], ...
        'PaperUnits', 'inches', 'PaperPosition', [0, 0, 8.0, 7.2]);
    exportFigure(fig, outputStem); close(fig);
end

function makeWorkPrecisionFigure(work, maxError, methodKeys, colors, ...
        markers, lineStyles, outputStem)
    fig = newFigure([8.0, 5.2]);
    ax = axes(fig); hold(ax, 'on');
    for iMethod = 1:numel(methodKeys)
        loglog(ax, work(iMethod, :), maxError(iMethod, :), ...
            'Color', colors(iMethod, :), 'LineStyle', lineStyles{iMethod}, ...
            'Marker', markers{iMethod}, 'MarkerFaceColor', colors(iMethod, :), ...
            'LineWidth', 1.4, 'DisplayName', methodKeys{iMethod});
    end
    set(ax, 'XScale', 'log', 'YScale', 'log');
    xlim(ax, [min(work(:)) / 1.15, max(work(:)) * 1.15]);
    xlabel(ax, '右端函数调用次数'); ylabel(ax, '最大绝对误差');
    title(ax, '相同理论工作量下的精度比较');
    legend(ax, 'Location', 'southwest', 'Box', 'off');
    applyFigureStyle(ax);
    set(fig, 'Units', 'inches', 'Position', [1, 1, 8.0, 5.2], ...
        'PaperUnits', 'inches', 'PaperPosition', [0, 0, 8.0, 5.2]);
    exportFigure(fig, outputStem); close(fig);
end

function makeRuntimePrecisionFigure(timingMedian, maxError, methodKeys, ...
        colors, markers, lineStyles, outputStem)
    fig = newFigure([8.0, 5.2]);
    ax = axes(fig); hold(ax, 'on');
    for iMethod = 1:numel(methodKeys)
        loglog(ax, timingMedian(iMethod, :), maxError(iMethod, :), ...
            'Color', colors(iMethod, :), 'LineStyle', lineStyles{iMethod}, ...
            'Marker', markers{iMethod}, 'MarkerFaceColor', colors(iMethod, :), ...
            'LineWidth', 1.4, 'DisplayName', methodKeys{iMethod});
    end
    set(ax, 'XScale', 'log', 'YScale', 'log');
    xlim(ax, [min(timingMedian(:)) / 1.15, max(timingMedian(:)) * 1.15]);
    xlabel(ax, '求解器中位运行时间（s）'); ylabel(ax, '最大绝对误差');
    title(ax, '实测运行时间—精度关系');
    legend(ax, 'Location', 'northeast', 'Box', 'off');
    applyFigureStyle(ax);
    set(fig, 'Units', 'inches', 'Position', [1, 1, 8.0, 5.2], ...
        'PaperUnits', 'inches', 'PaperPosition', [0, 0, 8.0, 5.2]);
    exportFigure(fig, outputStem); close(fig);
end

function makeTimingFigure(nSteps, timingMedian, timingMin, timingMax, ...
        methodKeys, colors, markers, lineStyles, outputStem)
    fig = newFigure([8.0, 5.2]);
    ax = axes(fig); hold(ax, 'on');
    for iMethod = 1:numel(methodKeys)
        lowerRange = timingMedian(iMethod, :) - timingMin(iMethod, :);
        upperRange = timingMax(iMethod, :) - timingMedian(iMethod, :);
        errorbar(ax, nSteps, timingMedian(iMethod, :), lowerRange, upperRange, ...
            'Color', colors(iMethod, :), 'LineStyle', lineStyles{iMethod}, ...
            'Marker', markers{iMethod}, 'MarkerFaceColor', colors(iMethod, :), ...
            'LineWidth', 1.2, 'CapSize', 7, 'DisplayName', methodKeys{iMethod});
    end
    set(ax, 'XScale', 'log', 'YScale', 'log');
    xlim(ax, [min(nSteps) / 1.15, max(nSteps) * 1.15]);
    ylim(ax, [min(timingMin(:)) / 1.15, max(timingMax(:)) * 1.25]);
    xticks(ax, nSteps);
    xlabel(ax, '步数 N'); ylabel(ax, '求解器运行时间（s）');
    title(ax, '重复计时的中位数与极差');
    legend(ax, 'Location', 'northwest', 'Box', 'off');
    applyFigureStyle(ax);
    set(fig, 'Units', 'inches', 'Position', [1, 1, 8.0, 5.2], ...
        'PaperUnits', 'inches', 'PaperPosition', [0, 0, 8.0, 5.2]);
    exportFigure(fig, outputStem); close(fig);
end

function fig = newFigure(sizeInches)
    fig = figure('Visible', 'off', 'Color', 'w', 'Units', 'inches', ...
        'Position', [1, 1, sizeInches(1), sizeInches(2)]);
end
