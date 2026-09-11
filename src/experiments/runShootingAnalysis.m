function runShootingAnalysis()
% runShootingAnalysis  分析打靶法原始数据并单独生成对比/收敛图
%
%   输入：results/poisson_shooting_raw.mat
%   输出：打靶法与有限差分的误差汇总、分析说明、图表目录，以及
%         figures/poisson_shooting_comparison.* 和
%         figures/poisson_shooting_convergence.*。
%   本脚本不重新求解方程，不修改原始 CSV/MAT，也不接入 runAll.m。

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

    writeAnalysisReport(resultsFolder, summaryCsv, shootingFit, ...
        finiteDifferenceFit, methodDifferenceFit, boundaryResidualInf);
    writeStatsAppendix(resultsFolder, nIntervals, summaryTable);
    writeFigureCatalog(resultsFolder, summaryCsv, shootingFit, ...
        finiteDifferenceFit, methodDifferenceFit);
    fprintf('打靶法数据分析完成，汇总已写入 results/，图像已写入 figures/。\n');
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
        's--', 'Color', [0.850 0.325 0.098], 'LineWidth', 1.2, ...
        'MarkerSize', 4, 'DisplayName', '|有限差分 - 解析解|');
    semilogy(ax2, solution.x, max(abs(solution.uShooting - solution.uFiniteDifference), eps), ...
        'd-.', 'Color', [0.466 0.674 0.188], 'LineWidth', 1.2, ...
        'MarkerSize', 4, 'DisplayName', '|打靶法 - 有限差分|');
    hold(ax2, 'off');
    xlabel(ax2, 'x'); ylabel(ax2, '绝对误差（对数坐标）');
    title(ax2, '代表网格点态误差');
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
        'LineWidth', 1.3, 'MarkerFaceColor', [0.000 0.447 0.741], ...
        'DisplayName', '打靶法 - 解析解');
    hold(ax1, 'on');
    loglog(ax1, stepSize, maxFiniteDifference, 's--', ...
        'Color', [0.850 0.325 0.098], 'LineWidth', 1.3, ...
        'MarkerFaceColor', [0.850 0.325 0.098], ...
        'DisplayName', '有限差分 - 解析解');
    loglog(ax1, stepSize, maxMethodDifference, 'd-.', ...
        'Color', [0.466 0.674 0.188], 'LineWidth', 1.3, ...
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
        'Color', [0.000 0.447 0.741], 'LineWidth', 1.3, ...
        'DisplayName', '打靶法 - 解析解');
    hold(ax2, 'on');
    semilogx(ax2, hPair, finiteDifferencePairwise, 's--', ...
        'Color', [0.850 0.325 0.098], 'LineWidth', 1.3, ...
        'DisplayName', '有限差分 - 解析解');
    semilogx(ax2, hPair, methodDifferencePairwise, 'd-.', ...
        'Color', [0.466 0.674 0.188], 'LineWidth', 1.3, ...
        'DisplayName', '打靶法 - 有限差分');
    yline(ax2, 4, 'k:', 'LineWidth', 1.1, 'DisplayName', '四阶参考');
    yline(ax2, 2, 'k--', 'LineWidth', 1.1, 'DisplayName', '二阶参考');
    hold(ax2, 'off');
    set(ax2, 'XScale', 'log', 'XDir', 'reverse');
    xticks(ax2, sort(hPair));
    xlabel(ax2, '细网格步长 h'); ylabel(ax2, '相邻观测阶');
    title(ax2, '相邻网格观测阶');
    legend(ax2, 'Location', 'best');
    applyFigureStyle(ax2);
    exportFigure(fig, fullfile(figuresFolder, 'poisson_shooting_convergence'));
    close(fig);
end

function writeAnalysisReport(resultsFolder, summaryCsv, shootingFit, ...
        finiteDifferenceFit, methodDifferenceFit, boundaryResidualInf)
    reportPath = fullfile(resultsFolder, 'poisson_shooting_analysis_report.md');
    fileId = fopen(reportPath, 'w', 'n', 'UTF-8');
    cleanup = onCleanup(@() fclose(fileId));
    fprintf(fileId, '# 打靶法交叉验证数据分析\n\n');
    fprintf(fileId, '## 分析问题\n\n');
    fprintf(fileId, '- 原始数据：`poisson_shooting_raw.mat` 及各网格 CSV。\n');
    fprintf(fileId, '- 比较对象：打靶法 + RK4、二阶中心有限差分、解析解。\n');
    fprintf(fileId, '- 误差定义：节点上的最大绝对误差、向量二范数和 RMS；方法间差值单独统计。\n');
    fprintf(fileId, '- 统计单位：每个 N 是一次确定性数值计算，不存在独立重复样本。\n\n');
    fprintf(fileId, '## 拟合结果\n\n');
    fprintf(fileId, '| 误差序列 | 对数拟合阶 |\n|---|---:|\n');
    fprintf(fileId, '| 打靶法 - 解析解 | %.8f |\n', shootingFit);
    fprintf(fileId, '| 有限差分 - 解析解 | %.8f |\n', finiteDifferenceFit);
    fprintf(fileId, '| 打靶法 - 有限差分 | %.8f |\n', methodDifferenceFit);
    fprintf(fileId, '\n边界残差的全网格最大值为 `%.6e`。完整数值见 [%s](%s)。\n\n', ...
        max(boundaryResidualInf), 'poisson_shooting_analysis_summary.csv', summaryCsv);
    fprintf(fileId, '## Claim Candidates\n\n');
    fprintf(fileId, '- Claim: 打靶法相对解析解的误差呈现四阶收敛证据。\n');
    fprintf(fileId, '  - Source evidence: `maxShootingExact` 和 `shootingPairwiseOrder`。\n');
    fprintf(fileId, '  - Allowed wording: 在本实验网格范围内，观测阶支持四阶误差行为。\n');
    fprintf(fileId, '  - Forbidden stronger wording: 不得据此声称任意问题、任意步长下都稳定或必然四阶。\n');
    fprintf(fileId, '  - Uncertainty: 只有单次确定性计算，未估计重复运行不确定度。\n');
    fprintf(fileId, '  - Next check: 若需扩大结论，应增加独立问题或不同区间验证。\n');
    fprintf(fileId, '  - Decision: keep\n\n');
    fprintf(fileId, '- Claim: 打靶法与普通有限差分的差值主要反映有限差分误差尺度。\n');
    fprintf(fileId, '  - Source evidence: `maxShootingFiniteDifference` 与二阶参考线。\n');
    fprintf(fileId, '  - Allowed wording: 两种数值解之差按实验范围呈二阶主导趋势。\n');
    fprintf(fileId, '  - Forbidden stronger wording: 不得把方法间差值写成打靶法自身的四阶误差。\n');
    fprintf(fileId, '  - Uncertainty: 当两种误差发生抵消时，局部相邻阶可能波动。\n');
    fprintf(fileId, '  - Next check: 与 Richardson 外推解比较可进一步隔离高阶误差。\n');
    fprintf(fileId, '  - Decision: keep\n');
end

function writeStatsAppendix(resultsFolder, nIntervals, ~)
    appendixPath = fullfile(resultsFolder, 'poisson_shooting_stats_appendix.md');
    fileId = fopen(appendixPath, 'w', 'n', 'UTF-8');
    cleanup = onCleanup(@() fclose(fileId));
    fprintf(fileId, '# 统计附录：打靶法交叉验证\n\n');
    fprintf(fileId, '本实验不是随机抽样或重复试验：每个网格 N 只有一组确定性数值结果。\n');
    fprintf(fileId, '因此不进行 t 检验、Wilcoxon 检验、置信区间、效应量或多重比较校正；这些统计量在当前证据结构下没有合适的独立重复单位。\n\n');
    fprintf(fileId, '## 描述性统计\n\n');
    fprintf(fileId, '- 网格数：%d；网格序列：%s。\n', numel(nIntervals), mat2str(nIntervals.'));
    fprintf(fileId, '- 每个 N 的误差均由全部节点计算，不进行抽样、删点、平滑或异常值剔除。\n');
    fprintf(fileId, '- 收敛阶使用相邻误差比与 `log(error)` 对 `log(h)` 的最小二乘拟合。\n');
    fprintf(fileId, '- 具体数值见 `poisson_shooting_analysis_summary.csv`；本文件不重复抄录表格。\n\n');
    fprintf(fileId, '## 限制\n\n');
    fprintf(fileId, '1. 只有一个源项、一个区间和一组边界条件，不能外推到一般边值问题。\n');
    fprintf(fileId, '2. 拟合阶是数值收敛证据，不是统计显著性结论。\n');
    fprintf(fileId, '3. 对数图中零误差节点以机器精度下限显示，仅用于可视化，不改变 CSV/MAT 原始数据。\n');
    clear cleanup summaryTable;
end

function writeFigureCatalog(resultsFolder, summaryCsv, shootingFit, ...
        finiteDifferenceFit, methodDifferenceFit)
    catalogPath = fullfile(resultsFolder, 'poisson_shooting_figure_catalog.md');
    fileId = fopen(catalogPath, 'w', 'n', 'UTF-8');
    cleanup = onCleanup(@() fclose(fileId));
    fprintf(fileId, '# 打靶法图表目录\n\n');
    fprintf(fileId, '数据源：[%s](%s)。图表由 `runShootingAnalysis.m` 生成。\n\n', ...
        'poisson_shooting_analysis_summary.csv', summaryCsv);
    fprintf(fileId, '## `figures/poisson_shooting_comparison.png/.pdf`\n\n');
    fprintf(fileId, '- 用途：展示代表网格的三条解曲线及三组点态绝对误差。\n');
    fprintf(fileId, '- 读图重点：解曲线的重合程度，以及打靶法误差和有限差分误差的量级差异。\n');
    fprintf(fileId, '- 解释限制：对数误差图的零值按 `eps` 显示；不能把图上的机器精度下限当成真实误差。\n\n');
    fprintf(fileId, '## `figures/poisson_shooting_convergence.png/.pdf`\n\n');
    fprintf(fileId, '- 用途：比较三组最大误差随 h 的变化，并显示相邻观测阶。\n');
    fprintf(fileId, '- 参考拟合阶：打靶法 %.8f，有限差分 %.8f，方法间差值 %.8f。\n', ...
        shootingFit, finiteDifferenceFit, methodDifferenceFit);
    fprintf(fileId, '- 解释限制：参考线是理论阶的视觉基准，不是额外数据；单次确定性实验不支持显著性结论。\n');
end
