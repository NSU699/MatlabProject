function summaryTable = runPoissonAnalysis()
% runPoissonAnalysis  分析第15题有限差分结果并导出 PNG 图
%
%   从 results/poisson_all_solutions.mat 读取已保存的数值解，计算
%   最大误差、RMS误差、加权离散L2误差、代数残差、截断残差和观测阶。
%   输出全部保存到 results/ 和 figures/，不修改原始数值结果。
%
%   对应报告内容：第15题“误差、残差与收敛阶分析”。

    clearvars -except summaryTable;
    close all;
    clc;

    projectRoot = fileparts(mfilename('fullpath'));
    addpath(genpath(fullfile(projectRoot, 'src')));
    resultsFolder = fullfile(projectRoot, 'results');
    figuresFolder = fullfile(projectRoot, 'figures');
    if ~exist(figuresFolder, 'dir'), mkdir(figuresFolder); end

    dataPath = fullfile(resultsFolder, 'poisson_all_solutions.mat');
    if ~exist(dataPath, 'file')
        error('runPoissonAnalysis:MissingResults', ...
            '未找到 %s，请先运行 runAll.m 生成第15题结果。', dataPath);
    end
    data = load(dataPath, 'allSolutions', 'xDense', 'uExactDense');
    allSolutions = data.allSolutions;
    xDense = data.xDense(:);
    uExactDense = data.uExactDense(:);
    nGrid = numel(allSolutions);

    nIntervals = zeros(nGrid, 1);
    stepSize = zeros(nGrid, 1);
    maxError = zeros(nGrid, 1);
    rmsError = zeros(nGrid, 1);
    weightedL2Error = zeros(nGrid, 1);
    algebraicResidual = zeros(nGrid, 1);
    truncationResidual = zeros(nGrid, 1);
    conditionEstimate = zeros(nGrid, 1);

    for k = 1:nGrid
        solution = allSolutions{k};
        x = solution.x(:);
        uNum = solution.uNum(:);
        uExact = solution.uExactAtNodes(:);
        errorValues = uNum - uExact;
        h = solution.meta.stepSize;

        nIntervals(k) = solution.nIntervals;
        stepSize(k) = h;
        maxError(k) = max(abs(errorValues));
        rmsError(k) = sqrt(mean(errorValues .^ 2));
        weightedL2Error(k) = sqrt(h) * norm(errorValues, 2);
        algebraicResidual(k) = max(abs(solution.meta.linearResidual(:)));
        conditionEstimate(k) = solution.meta.conditionEstimate;

        % 将解析解代入同一个中心差分算子，得到截断残差。
        uExactInner = uExact(2:end-1);
        discreteSecondDerivative = ...
            (uExact(1:end-2) - 2 * uExactInner + uExact(3:end)) / h^2;
        sourceValues = exp(-x(2:end-1).^2);
        truncationResidual(k) = max(abs(discreteSecondDerivative - sourceValues));
    end

    [nIntervals, order] = sortRows(nIntervals);
    stepSize = stepSize(order);
    maxError = maxError(order);
    rmsError = rmsError(order);
    weightedL2Error = weightedL2Error(order);
    algebraicResidual = algebraicResidual(order);
    truncationResidual = truncationResidual(order);
    conditionEstimate = conditionEstimate(order);

    maxOrder = observedOrders(maxError);
    rmsOrder = observedOrders(rmsError);
    weightedL2Order = observedOrders(weightedL2Error);
    truncationOrder = observedOrders(truncationResidual);

    summaryTable = table(nIntervals, stepSize, maxError, maxOrder, ...
        rmsError, rmsOrder, weightedL2Error, weightedL2Order, ...
        algebraicResidual, truncationResidual, truncationOrder, conditionEstimate);
    writetable(summaryTable, fullfile(resultsFolder, 'poisson_analysis_summary.csv'));

    % 图1：选择四个代表性网格，避免六条阶梯曲线互相遮挡。
    selected = unique([1, ceil(nGrid / 2), nGrid - 1, nGrid]);
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 1000, 720]);
    tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    for j = 1:numel(selected)
        k = selected(j);
        solution = allSolutions{order(k)};
        nexttile;
        plot(solution.x, solution.uNum, 'o-', 'Color', [0.12, 0.47, 0.71], ...
            'LineWidth', 1.0, 'MarkerSize', 3.5, 'DisplayName', '有限差分数值解');
        hold on;
        plot(xDense, uExactDense, 'k-', 'LineWidth', 1.7, ...
            'DisplayName', '解析解');
        hold off;
        xlabel('x'); ylabel('u(x)');
        title(sprintf('N = %d，最大误差 = %.3e', nIntervals(k), maxError(k)));
        legend('Location', 'best');
        applyFigureStyle(gca);
        set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', ...
            'GridColor', [0.82, 0.82, 0.82]);
    end
    readableFigure(fig);
    exportPng(fig, fullfile(figuresFolder, 'poisson_solution_panels'));
    close(fig);

    % 图2：误差范数及二阶参考线。
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 900, 650]);
    ax = axes(fig);
    loglog(stepSize, maxError, 'o-', 'LineWidth', 1.5, 'MarkerSize', 6, ...
        'DisplayName', '最大误差');
    hold on;
    loglog(stepSize, rmsError, 's-', 'LineWidth', 1.5, 'MarkerSize', 6, ...
        'DisplayName', 'RMS误差');
    loglog(stepSize, weightedL2Error, '^-', 'LineWidth', 1.5, 'MarkerSize', 6, ...
        'DisplayName', '加权离散L2误差');
    reference = maxError(1) * (stepSize / stepSize(1)).^2;
    loglog(stepSize, reference, 'k--', 'LineWidth', 1.2, 'DisplayName', 'O(h^2)参考线');
    hold off;
    set(ax, 'XDir', 'reverse');
    xlabel('步长 h'); ylabel('误差');
    title('第15题：误差收敛与二阶参考线');
    legend('Location', 'southEast');
    applyFigureStyle(ax);
    set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', ...
        'GridColor', [0.82, 0.82, 0.82]);
    readableFigure(fig);
    exportPng(fig, fullfile(figuresFolder, 'poisson_error_convergence'));
    close(fig);

    % 图3：点态误差，使用四个代表性网格。
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 900, 650]);
    ax = axes(fig);
    colors = lines(numel(selected));
    hold(ax, 'on');
    for j = 1:numel(selected)
        k = selected(j);
        solution = allSolutions{order(k)};
        plot(ax, solution.x, solution.uNum - solution.uExactAtNodes, 'o-', ...
            'Color', colors(j, :), 'LineWidth', 1.1, 'MarkerSize', 3, ...
            'DisplayName', sprintf('N = %d', nIntervals(k)));
    end
    yline(ax, 0, 'k--', 'HandleVisibility', 'off');
    hold(ax, 'off');
    xlabel('x'); ylabel('e_h(x) = u_h(x) - u(x)');
    title('第15题：节点点态误差');
    legend(ax, 'Location', 'best');
    applyFigureStyle(ax);
    set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', ...
        'GridColor', [0.82, 0.82, 0.82]);
    readableFigure(fig);
    exportPng(fig, fullfile(figuresFolder, 'poisson_pointwise_error'));
    close(fig);

    % 图4：代数残差与截断残差分开显示，避免混淆物理含义。
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 900, 700]);
    tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    nexttile;
    semilogy(nIntervals, algebraicResidual, 'o-', 'LineWidth', 1.5, 'MarkerSize', 6);
    xlabel('区间数 N'); ylabel('||Au-b||_\infty');
    title('线性方程组代数残差');
    applyFigureStyle(gca);
    set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', ...
        'GridColor', [0.82, 0.82, 0.82]);
    nexttile;
    loglog(stepSize, truncationResidual, 'o-', 'LineWidth', 1.5, 'MarkerSize', 6, ...
        'DisplayName', '截断残差');
    hold on;
    truncReference = truncationResidual(1) * (stepSize / stepSize(1)).^2;
    loglog(stepSize, truncReference, 'k--', 'LineWidth', 1.2, 'DisplayName', 'O(h^2)参考线');
    hold off;
    set(gca, 'XDir', 'reverse');
    xlabel('步长 h'); ylabel('||	au_h||_\infty');
    title('解析解代入差分算子的截断残差');
    legend('Location', 'southEast');
    applyFigureStyle(gca);
    set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', ...
        'GridColor', [0.82, 0.82, 0.82]);
    readableFigure(fig);
    exportPng(fig, fullfile(figuresFolder, 'poisson_residuals'));
    close(fig);

    fprintf('第15题分析完成：summary CSV 和 4 张 PNG 已保存到 results/ 与 figures/。\n');
end

function [sortedValues, order] = sortRows(values)
    [sortedValues, order] = sort(values(:));
end

function orders = observedOrders(errors)
    orders = [NaN; log(errors(1:end-1) ./ errors(2:end)) ./ log(2)];
end

function exportPng(figHandle, outputStem)
    exportgraphics(figHandle, [outputStem, '.png'], 'Resolution', 300);
end

function readableFigure(figHandle)
    axesHandles = findall(figHandle, 'Type', 'axes');
    for ax = axesHandles(:).'
        set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', ...
            'GridColor', [0.82, 0.82, 0.82]);
        set(get(ax, 'Title'), 'Color', 'k');
        set(get(ax, 'XLabel'), 'Color', 'k');
        set(get(ax, 'YLabel'), 'Color', 'k');
    end
    legends = findall(figHandle, 'Type', 'legend');
    set(legends, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.2, 0.2, 0.2]);
end
