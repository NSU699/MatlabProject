function runRichardsonFigures()
% runRichardsonFigures  生成第15题 Richardson 外推科研图
%
%   读取 runRichardsonExperiment.m 产生的 CSV，生成：
%   1) 最大误差随步长的双对数图；
%   2) 相邻网格观测收敛阶图；
%   3) N=16 时的内部节点点态绝对误差图。
%   所有图均使用白底黑字，并导出 PNG 与矢量 PDF。
%
%   对应报告: 第15题 Richardson 外推算法延伸
%   作者: 项目成员   日期: 2026-09-10

    projectRoot = fileparts(mfilename('fullpath'));
    addpath(genpath(fullfile(projectRoot, 'src')));
    resultsFolder = fullfile(projectRoot, 'results');
    figuresFolder = fullfile(projectRoot, 'figures');
    if ~exist(figuresFolder, 'dir'), mkdir(figuresFolder); end

    summaryPath = fullfile(resultsFolder, 'poisson_richardson_summary.csv');
    if ~exist(summaryPath, 'file')
        error('runRichardsonFigures:MissingData', ...
            '未找到 Richardson 汇总数据，请先运行 runRichardsonExperiment。');
    end
    summary = readtable(summaryPath);
    h = summary.h;
    coarseError = summary.coarseMaxError;
    richardsonError = summary.richardsonMaxError;

    % 图1：误差随步长的双对数收敛图。
    fig = figure('Name', 'Richardson 误差收敛', 'Visible', 'off');
    ax = axes(fig);
    loglog(ax, h, coarseError, 'o-', 'Color', [0.00, 0.30, 0.75], ...
        'LineWidth', 1.8, 'MarkerSize', 6, ...
        'DisplayName', '二阶中心差分');
    hold(ax, 'on');
    loglog(ax, h, richardsonError, 's-', 'Color', [0.85, 0.20, 0.10], ...
        'LineWidth', 1.8, 'MarkerSize', 6, ...
        'DisplayName', 'Richardson 外推');
    referenceH = [min(h), max(h)];
    % 平移理论斜率线，避免它们与数值曲线重合而看不清。
    coarseReference = 0.45 * coarseError(1) * (referenceH / h(1)).^2;
    richardsonReference = 2.5 * richardsonError(1) * ...
        (referenceH / h(1)).^4;
    loglog(ax, referenceH, coarseReference, '--', ...
        'Color', [0.00, 0.30, 0.75], 'LineWidth', 1.8, ...
        'DisplayName', 'O(h^2) 参考线');
    loglog(ax, referenceH, richardsonReference, '--', ...
        'Color', [0.85, 0.20, 0.10], 'LineWidth', 1.8, ...
        'DisplayName', 'O(h^4) 参考线');
    hold(ax, 'off');
    set(ax, 'XDir', 'reverse');
    xlabel(ax, '粗网格步长 h');
    ylabel(ax, '最大绝对误差');
    title(ax, '有限差分与 Richardson 外推的误差收敛');
    legend(ax, 'Location', 'best');
    applyFigureStyle(ax);
    exportFigure(fig, fullfile(figuresFolder, 'poisson_richardson_convergence'));
    close(fig);

    % 图2：观测阶，首个没有前一组网格的值保持为空。
    fig = figure('Name', 'Richardson 观测收敛阶', 'Visible', 'off');
    ax = axes(fig);
    plot(ax, summary.coarseN, summary.coarseOrder, 'o-', ...
        'Color', [0.00, 0.30, 0.75], 'LineWidth', 1.8, 'MarkerSize', 6, ...
        'DisplayName', '二阶中心差分');
    hold(ax, 'on');
    plot(ax, summary.coarseN, summary.richardsonOrder, 's-', ...
        'Color', [0.85, 0.20, 0.10], 'LineWidth', 1.8, 'MarkerSize', 6, ...
        'DisplayName', 'Richardson 外推');
    yline(ax, 2, '--', 'Color', [0.00, 0.30, 0.75], ...
        'LineWidth', 1.1, 'DisplayName', 'p=2');
    yline(ax, 4, '--', 'Color', [0.85, 0.20, 0.10], ...
        'LineWidth', 1.1, 'DisplayName', 'p=4');
    hold(ax, 'off');
    set(ax, 'XScale', 'log', 'XTick', summary.coarseN);
    ylim(ax, [1.8, 4.2]);
    yticks(ax, 2:0.5:4);
    xlabel(ax, '粗网格区间数 N');
    ylabel(ax, '相邻网格观测收敛阶 p');
    title(ax, '观测收敛阶随网格加密的变化');
    legend(ax, 'Location', 'best');
    applyFigureStyle(ax);
    exportFigure(fig, fullfile(figuresFolder, 'poisson_richardson_order'));
    close(fig);

    % 图3：N=16 点态误差。边界误差严格为零，不放入对数纵轴。
    pointPath = fullfile(resultsFolder, 'poisson_richardson_n016_points.csv');
    points = readtable(pointPath);
    interior = points.x > min(points.x) & points.x < max(points.x);
    fig = figure('Name', 'Richardson 点态误差 N=16', 'Visible', 'off');
    ax = axes(fig);
    semilogy(ax, points.x(interior), points.coarseAbsError(interior), 'o-', ...
        'Color', [0.00, 0.30, 0.75], 'LineWidth', 1.5, 'MarkerSize', 5, ...
        'DisplayName', '二阶中心差分');
    hold(ax, 'on');
    semilogy(ax, points.x(interior), points.richardsonAbsError(interior), 's-', ...
        'Color', [0.85, 0.20, 0.10], 'LineWidth', 1.5, 'MarkerSize', 5, ...
        'DisplayName', 'Richardson 外推');
    hold(ax, 'off');
    xlabel(ax, '空间坐标 x');
    ylabel(ax, '点态绝对误差');
    title(ax, 'N=16 时内部节点的点态绝对误差');
    legend(ax, 'Location', 'best');
    applyFigureStyle(ax);
    exportFigure(fig, fullfile(figuresFolder, 'poisson_richardson_pointwise_n016'));
    close(fig);

    % 图4：N=32 点态误差。边界误差严格为零，不放入对数纵轴。
    pointPath = fullfile(resultsFolder, 'poisson_richardson_n032_points.csv');
    points = readtable(pointPath);
    interior = points.x > min(points.x) & points.x < max(points.x);
    fig = figure('Name', 'Richardson 点态误差 N=32', 'Visible', 'off');
    ax = axes(fig);
    semilogy(ax, points.x(interior), points.coarseAbsError(interior), 'o-', ...
        'Color', [0.00, 0.30, 0.75], 'LineWidth', 1.5, 'MarkerSize', 5, ...
        'DisplayName', '二阶中心差分');
    hold(ax, 'on');
    semilogy(ax, points.x(interior), points.richardsonAbsError(interior), 's-', ...
        'Color', [0.85, 0.20, 0.10], 'LineWidth', 1.5, 'MarkerSize', 5, ...
        'DisplayName', 'Richardson 外推');
    hold(ax, 'off');
    xlabel(ax, '空间坐标 x');
    ylabel(ax, '点态绝对误差');
    title(ax, 'N=32 时内部节点的点态绝对误差');
    legend(ax, 'Location', 'best');
    applyFigureStyle(ax);
    exportFigure(fig, fullfile(figuresFolder, 'poisson_richardson_pointwise_n032'));
    close(fig);

    % 图5：N=64 点态误差。边界误差严格为零，不放入对数纵轴。
    pointPath = fullfile(resultsFolder, 'poisson_richardson_n064_points.csv');
    points = readtable(pointPath);
    interior = points.x > min(points.x) & points.x < max(points.x);
    fig = figure('Name', 'Richardson 点态误差 N=64', 'Visible', 'off');
    ax = axes(fig);
    semilogy(ax, points.x(interior), points.coarseAbsError(interior), 'o-', ...
        'Color', [0.00, 0.30, 0.75], 'LineWidth', 1.5, 'MarkerSize', 5, ...
        'DisplayName', '二阶中心差分');
    hold(ax, 'on');
    semilogy(ax, points.x(interior), points.richardsonAbsError(interior), 's-', ...
        'Color', [0.85, 0.20, 0.10], 'LineWidth', 1.5, 'MarkerSize', 5, ...
        'DisplayName', 'Richardson 外推');
    hold(ax, 'off');
    xlabel(ax, '空间坐标 x');
    ylabel(ax, '点态绝对误差');
    title(ax, 'N=64 时内部节点的点态绝对误差');
    legend(ax, 'Location', 'best');
    applyFigureStyle(ax);
    exportFigure(fig, fullfile(figuresFolder, 'poisson_richardson_pointwise_n064'));
    close(fig);

    % 图6：N=128 点态误差。边界误差严格为零，不放入对数纵轴。
    pointPath = fullfile(resultsFolder, 'poisson_richardson_n128_points.csv');
    points = readtable(pointPath);
    interior = points.x > min(points.x) & points.x < max(points.x);
    fig = figure('Name', 'Richardson 点态误差 N=128', 'Visible', 'off');
    ax = axes(fig);
    semilogy(ax, points.x(interior), points.coarseAbsError(interior), 'o-', ...
        'Color', [0.00, 0.30, 0.75], 'LineWidth', 1.5, 'MarkerSize', 2, ...
        'DisplayName', '二阶中心差分');
    hold(ax, 'on');
    semilogy(ax, points.x(interior), points.richardsonAbsError(interior), 's-', ...
        'Color', [0.85, 0.20, 0.10], 'LineWidth', 1.5, 'MarkerSize', 2, ...
        'DisplayName', 'Richardson 外推');
    hold(ax, 'off');
    xlabel(ax, '空间坐标 x');
    ylabel(ax, '点态绝对误差');
    title(ax, 'N=128 时内部节点的点态绝对误差');
    legend(ax, 'Location', 'best');
    applyFigureStyle(ax);
    exportFigure(fig, fullfile(figuresFolder, 'poisson_richardson_pointwise_n128'));
    close(fig);

    % 图7：N=256 点态误差。边界误差严格为零，不放入对数纵轴。
    pointPath = fullfile(resultsFolder, 'poisson_richardson_n256_points.csv');
    points = readtable(pointPath);
    interior = points.x > min(points.x) & points.x < max(points.x);
    fig = figure('Name', 'Richardson 点态误差 N=256', 'Visible', 'off');
    ax = axes(fig);
    semilogy(ax, points.x(interior), points.coarseAbsError(interior), 'o-', ...
        'Color', [0.00, 0.30, 0.75], 'LineWidth', 1, 'MarkerSize', 1.5, ...
        'DisplayName', '二阶中心差分');
    hold(ax, 'on');
    semilogy(ax, points.x(interior), points.richardsonAbsError(interior), 's-', ...
        'Color', [0.85, 0.20, 0.10], 'LineWidth', 1, 'MarkerSize', 1.5, ...
        'DisplayName', 'Richardson 外推');
    hold(ax, 'off');
    xlabel(ax, '空间坐标 x');
    ylabel(ax, '点态绝对误差');
    title(ax, 'N=256 时内部节点的点态绝对误差');
    legend(ax, 'Location', 'best');
    applyFigureStyle(ax);
    exportFigure(fig, fullfile(figuresFolder, 'poisson_richardson_pointwise_n256'));
    close(fig);

    fprintf('Richardson 七张图已保存到 figures/。\n');
end
