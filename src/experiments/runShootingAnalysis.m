function runShootingAnalysis()
% runShootingAnalysis  分析打靶法原始数据并单独生成对比/收敛图
%
%   输入：results/poisson_shooting_raw.mat
%   输出：打靶法与有限差分的误差汇总、分析说明、图表目录，以及
%         figures/poisson_shooting_comparison.* 和
%         figures/poisson_shooting_convergence.*。

    projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    addpath(genpath(fullfile(projectRoot, 'src')));
    resultsFolder = fullfile(projectRoot, 'results');
    figuresFolder = fullfile(projectRoot, 'figures');
    rawPath = fullfile(resultsFolder, 'poisson_shooting_raw.mat');
    if ~exist(figuresFolder, 'dir'), mkdir(figuresFolder); end

    raw = load(rawPath);
    nIntervals = raw.nIntervalsList(:);
    nGrid = numel(nIntervals);
    stepSize = 2 ./ nIntervals;

    maxShooting = zeros(nGrid, 1);
    l2Shooting = zeros(nGrid, 1);
    rmsShooting = zeros(nGrid, 1);
    maxFiniteDifference = zeros(nGrid, 1);
    l2FiniteDifference = zeros(nGrid, 1);
    rmsFiniteDifference = zeros(nGrid, 1);
    maxMethodDifference = zeros(nGrid, 1);
    l2MethodDifference = zeros(nGrid, 1);
    rmsMethodDifference = zeros(nGrid, 1);
    boundaryResidualInf = zeros(nGrid, 1);
    functionEvaluations = zeros(nGrid, 1);

    for iGrid = 1:nGrid
        solution = raw.rawSolutions{iGrid};
        shootingError = solution.uShooting - solution.uExact;
        finiteDifferenceError = solution.uFiniteDifference - solution.uExact;
        methodDifference = solution.uShooting - solution.uFiniteDifference;
        [maxShooting(iGrid), l2Shooting(iGrid), rmsShooting(iGrid)] = ...
            errorNorms(shootingError, zeros(size(shootingError)));
        [maxFiniteDifference(iGrid), l2FiniteDifference(iGrid), rmsFiniteDifference(iGrid)] = ...
            errorNorms(finiteDifferenceError, zeros(size(finiteDifferenceError)));
        [maxMethodDifference(iGrid), l2MethodDifference(iGrid), rmsMethodDifference(iGrid)] = ...
            errorNorms(methodDifference, zeros(size(methodDifference)));
        boundaryResidualInf(iGrid) = norm(solution.shootingMeta.boundaryResidual, inf);
        functionEvaluations(iGrid) = solution.shootingMeta.functionEvaluations;
    end

    [shootingPairwise, shootingFit] = computeOrder(stepSize, maxShooting);
    [finiteDifferencePairwise, finiteDifferenceFit] = ...
        computeOrder(stepSize, maxFiniteDifference);
    [methodDifferencePairwise, methodDifferenceFit] = ...
        computeOrder(stepSize, maxMethodDifference);

    summaryTable = table(nIntervals, stepSize, maxShooting, l2Shooting, ...
        rmsShooting, maxFiniteDifference, l2FiniteDifference, ...
        rmsFiniteDifference, maxMethodDifference, l2MethodDifference, ...
        rmsMethodDifference, boundaryResidualInf, functionEvaluations, ...
        [NaN; shootingPairwise], [NaN; finiteDifferencePairwise], ...
        [NaN; methodDifferencePairwise], ...
        repmat(shootingFit, nGrid, 1), repmat(finiteDifferenceFit, nGrid, 1), ...
        repmat(methodDifferenceFit, nGrid, 1), ...
        'VariableNames', {'N', 'h', 'maxShootingExact', 'l2ShootingExact', ...
        'rmsShootingExact', 'maxFiniteDifferenceExact', ...
        'l2FiniteDifferenceExact', 'rmsFiniteDifferenceExact', ...
        'maxShootingFiniteDifference', 'l2ShootingFiniteDifference', ...
        'rmsShootingFiniteDifference', 'shootingBoundaryResidualInf', ...
        'shootingFunctionEvaluations', 'shootingPairwiseOrder', ...
        'finiteDifferencePairwiseOrder', 'methodDifferencePairwiseOrder', ...
        'shootingFittedOrder', 'finiteDifferenceFittedOrder', ...
        'methodDifferenceFittedOrder'});
    summaryCsv = fullfile(resultsFolder, 'poisson_shooting_analysis_summary.csv');
    writetable(summaryTable, summaryCsv);

    analysisData = struct();
    analysisData.nIntervals = nIntervals;
    analysisData.stepSize = stepSize;
    analysisData.summaryTable = summaryTable;
    analysisData.shootingFittedOrder = shootingFit;
    analysisData.finiteDifferenceFittedOrder = finiteDifferenceFit;
    analysisData.methodDifferenceFittedOrder = methodDifferenceFit;
    save(fullfile(resultsFolder, 'poisson_shooting_analysis.mat'), 'analysisData');

    representativeIndex = find(nIntervals == 32, 1);
    if isempty(representativeIndex), representativeIndex = ceil(nGrid / 2); end
    makeComparisonFigure(raw.rawSolutions{representativeIndex}, figuresFolder);
    makeConvergenceFigure(stepSize, maxShooting, maxFiniteDifference, ...
        maxMethodDifference, shootingPairwise, finiteDifferencePairwise, ...
        methodDifferencePairwise, figuresFolder);

end

function makeComparisonFigure(solution, figuresFolder)
    fig = figure('Name', '打靶法与有限差分代表网格对比', ...
        'Visible', 'off', 'Color', 'w');
    tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

    ax1 = nexttile;
    plot(ax1, solution.x, solution.uExact, 'k-', 'LineWidth', 1.8, ...
        'DisplayName', '解析解');
    hold(ax1, 'on');
    plot(ax1, solution.x, solution.uShooting, 'o-', 'Color', [0.000 0.447 0.741], ...
        'LineWidth', 1.2, 'MarkerSize', 4, 'DisplayName', '打靶法 + RK4');
    plot(ax1, solution.x, solution.uFiniteDifference, 's--', ...
        'Color', [0.850 0.325 0.098], 'LineWidth', 1.2, 'MarkerSize', 4, ...
        'DisplayName', '有限差分');
    hold(ax1, 'off');
    xlabel(ax1, 'x'); ylabel(ax1, 'u(x)');
    title(ax1, sprintf('代表网格解对比（N = %d）', solution.nIntervals));
    legend(ax1, 'Location', 'best');
    applyFigureStyle(ax1);

    ax2 = nexttile;
    semilogy(ax2, solution.x, max(abs(solution.uShooting - solution.uExact), eps), ...
        'o-', 'Color', [0.000 0.447 0.741], 'LineWidth', 1.2, ...
        'MarkerSize', 4, 'DisplayName', '|打靶法 - 解析解|');
    hold(ax2, 'on');
    semilogy(ax2, solution.x, max(abs(solution.uFiniteDifference - solution.uExact), eps), ...
        's--', 'Color', [0.850 0.325 0.098], 'LineWidth', 2.4, ...
        'MarkerSize', 4, 'DisplayName', '|有限差分 - 解析解|');
    semilogy(ax2, solution.x, max(abs(solution.uShooting - solution.uFiniteDifference), eps), ...
        'd-.', 'Color', [0.466 0.674 0.188], 'LineWidth', 1.2, ...
        'MarkerSize', 4, 'DisplayName', '|打靶法 - 有限差分|');
    hold(ax2, 'off');
    xlabel(ax2, 'x'); ylabel(ax2, '绝对误差（对数坐标）');
    title(ax2, '代表网格点态误差');
    ylim(ax2, [0, 1e-3]);
    legend(ax2, 'Location', 'best');
    applyFigureStyle(ax2);
    exportFigure(fig, fullfile(figuresFolder, 'poisson_shooting_comparison'));
    close(fig);
end

function makeConvergenceFigure(stepSize, maxShooting, maxFiniteDifference, ...
        maxMethodDifference, shootingPairwise, finiteDifferencePairwise, ...
        methodDifferencePairwise, figuresFolder)
    fig = figure('Name', '打靶法交叉验证收敛分析', 'Visible', 'off', 'Color', 'w');
    tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

    ax1 = nexttile;
    loglog(ax1, stepSize, maxShooting, 'o-', 'Color', [0.000 0.447 0.741], ...
        'LineWidth', 1.5, 'MarkerFaceColor', [0.000 0.447 0.741], ...
        'DisplayName', '打靶法 - 解析解');
    hold(ax1, 'on');
    loglog(ax1, stepSize, maxFiniteDifference, 's--', ...
        'Color', [0.850 0.325 0.098], 'LineWidth', 3, ...
        'MarkerFaceColor', [0.850 0.325 0.098], ...
        'DisplayName', '有限差分 - 解析解');
    loglog(ax1, stepSize, maxMethodDifference, 'd-.', ...
        'Color', [0.466 0.674 0.188], 'LineWidth', 1.5, ...
        'MarkerFaceColor', [0.466 0.674 0.188], ...
        'DisplayName', '打靶法 - 有限差分');
    loglog(ax1, stepSize, maxShooting(1) * (stepSize / stepSize(1)).^4, ...
        'k:', 'LineWidth', 1.1, 'DisplayName', 'O(h^4)参考线');
    loglog(ax1, stepSize, maxFiniteDifference(1) * ...
        (stepSize / stepSize(1)).^2, 'k--', 'LineWidth', 1.1, ...
        'DisplayName', 'O(h^2)参考线');
    hold(ax1, 'off');
    set(ax1, 'XScale', 'log', 'YScale', 'log', 'XDir', 'reverse');
    xticks(ax1, sort(stepSize));
    xlabel(ax1, '步长 h'); ylabel(ax1, '最大绝对误差');
    title(ax1, '三组误差的网格收敛');
    legend(ax1, 'Location', 'best');
    applyFigureStyle(ax1);

    ax2 = nexttile;
    hPair = stepSize(2:end);
    semilogx(ax2, hPair, shootingPairwise, 'o-', ...
        'Color', [0.000 0.447 0.741], 'LineWidth', 2.2, ...
        'DisplayName', '打靶法 - 解析解');
    hold(ax2, 'on');
    semilogx(ax2, hPair, finiteDifferencePairwise, 's--', ...
        'Color', [0.850 0.325 0.098], 'LineWidth', 3.3, ...
        'DisplayName', '有限差分 - 解析解');
    semilogx(ax2, hPair, methodDifferencePairwise, 'd-.', ...
        'Color', [0.466 0.674 0.188], 'LineWidth', 2.2, ...
        'DisplayName', '打靶法 - 有限差分');
    yline(ax2, 4, 'k:', 'LineWidth', 1.1, 'DisplayName', '四阶参考');
    yline(ax2, 2, 'k--', 'LineWidth', 1.1, 'DisplayName', '二阶参考');
    hold(ax2, 'off');
    set(ax2, 'XScale', 'log', 'XDir', 'reverse');
    xticks(ax2, sort(hPair));
    xlabel(ax2, '细网格步长 h'); ylabel(ax2, '相邻观测阶');
    title(ax2, '相邻网格观测阶');
    ylim(ax2, [1.5, 4.5]);
    legend(ax2, 'Location', 'best');
    applyFigureStyle(ax2);
    exportFigure(fig, fullfile(figuresFolder, 'poisson_shooting_convergence'));
    close(fig);
end