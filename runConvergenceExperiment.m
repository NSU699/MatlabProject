function runConvergenceExperiment()
% runConvergenceExperiment  第15、16题正式收敛实验
%
%   记录最大绝对误差、RMS误差、相邻比值观测阶、对数拟合阶和 timeit 耗时，
%   输出两张 CSV 表以及两张误差 loglog 图。所有结果均由本脚本实际运行生成。

    clearvars;
    close all;
    clc;

    projectRoot = fileparts(mfilename('fullpath'));
    addpath(genpath(fullfile(projectRoot, 'src')));
    resultsFolder = fullfile(projectRoot, 'results');
    figuresFolder = fullfile(projectRoot, 'figures');
    if ~exist(resultsFolder, 'dir'), mkdir(resultsFolder); end
    if ~exist(figuresFolder, 'dir'), mkdir(figuresFolder); end

    %% 第15题：中心有限差分
    poissonN = [8, 16, 32, 64, 128, 256, 512].';
    poissonH = zeros(size(poissonN));
    poissonMax = zeros(size(poissonN));
    poissonRms = zeros(size(poissonN));
    poissonTime = zeros(size(poissonN));
    for k = 1:numel(poissonN)
        N = poissonN(k);
        poissonTime(k) = timeit(@() solvePoissonFD(N));
        [x, uNum, meta] = solvePoissonFD(N);
        [poissonMax(k), ~, poissonRms(k)] = errorNorms(uNum, poissonExact(x));
        poissonH(k) = meta.stepSize;
    end
    [poissonPair, poissonFit] = computeOrder(poissonH, poissonMax);
    poissonPairColumn = [NaN; poissonPair];
    poissonTable = table(poissonN, poissonH, poissonMax, poissonRms, ...
        poissonPairColumn, repmat(poissonFit, size(poissonN)), poissonTime, ...
        'VariableNames', {'N','h','maxError','rmsError', ...
        'pairwiseOrder','fittedOrder','timeSeconds'});
    writetable(poissonTable, fullfile(resultsFolder, 'poisson_convergence.csv'));
    makeConvergenceFigure(poissonH, poissonMax, poissonRms, 2, ...
        '第15题有限差分收敛实验', 'poisson_convergence_formal', figuresFolder);

    %% 第16题：固定步长经典RK4
    odeN = [6, 12, 24, 48, 96, 192, 384].';
    rhs = @(t, y) -y + t.^2 + 3;
    tSpan = [0, 3];
    y0 = 1;
    [~, yExact, check] = ivpExactSymbolic();
    assert(check.passed, '解析解符号验证未通过。');
    odeH = zeros(size(odeN));
    odeMax = zeros(size(odeN));
    odeRms = zeros(size(odeN));
    odeTime = zeros(size(odeN));
    for k = 1:numel(odeN)
        N = odeN(k);
        odeTime(k) = timeit(@() rk4Solve(rhs, tSpan, y0, N));
        [t, yNum, meta] = rk4Solve(rhs, tSpan, y0, N);
        [odeMax(k), ~, odeRms(k)] = errorNorms(yNum(:, 1), yExact(t));
        odeH(k) = meta.stepSize;
    end
    [odePair, odeFit] = computeOrder(odeH, odeMax);
    odePairColumn = [NaN; odePair];
    odeTable = table(odeN, odeH, odeMax, odeRms, odePairColumn, ...
        repmat(odeFit, size(odeN)), odeTime, ...
        'VariableNames', {'N','h','maxError','rmsError', ...
        'pairwiseOrder','fittedOrder','timeSeconds'});
    writetable(odeTable, fullfile(resultsFolder, 'ode_convergence.csv'));
    makeConvergenceFigure(odeH, odeMax, odeRms, 4, ...
        '第16题经典RK4收敛实验', 'ode_rk4_convergence_formal', figuresFolder);

    fprintf('正式收敛实验完成。\n');
    fprintf('第15题拟合阶：%.6f；第16题拟合阶：%.6f\n', poissonFit, odeFit);
    fprintf('表格已写入 results/，图像已写入 figures/。\n');
end

function makeConvergenceFigure(h, maxError, rmsError, theoryOrder, titleText, fileName, outputFolder)
    fig = figure('Visible', 'off', 'Color', 'w', 'Units', 'inches', ...
        'Position', [1, 1, 8.0, 5.2]);
    ax = axes(fig); hold(ax, 'on');
    loglog(ax, h, maxError, 'o-', 'LineWidth', 1.4, 'MarkerFaceColor', [0 0.447 0.741], ...
        'DisplayName', '最大绝对误差');
    loglog(ax, h, rmsError, 's--', 'LineWidth', 1.4, 'MarkerFaceColor', [0.85 0.325 0.098], ...
        'DisplayName', 'RMS误差');
    reference = maxError(1) * (h / h(1)).^theoryOrder;
    loglog(ax, h, reference, 'k:', 'LineWidth', 1.2, ...
        'DisplayName', sprintf('O(h^{%d})参考线', theoryOrder));
    % 显式锁定双对数坐标，并把每个实际步长作为刻度，避免导出时看起来像线性坐标。
    set(ax, 'XScale', 'log', 'YScale', 'log', 'XDir', 'reverse');
    xticks(ax, sort(h));
    xlabel(ax, '步长 h'); ylabel(ax, '误差'); title(ax, titleText);
    legend(ax, 'Location', 'southEast', 'Box', 'off');
    applyFigureStyle(ax);
    set(fig, 'Units', 'inches', 'Position', [1, 1, 8.0, 5.2], ...
        'PaperUnits', 'inches', 'PaperPosition', [0, 0, 8.0, 5.2]);
    set(fig, 'PaperPositionMode', 'auto');
    exportFigure(fig, fullfile(outputFolder, fileName));
    close(fig);
end
