function runCoreExperiments()
% runCoreExperiments  输出第15题和第16题的基础数据及基础图表
%
%   第15题保存多网格有限差分节点数据；第16题保存 RK4 节点数据、
%   符号解析解和基础误差图。该函数由根目录入口 runAll.m 调用。

    projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    addpath(genpath(fullfile(projectRoot, 'src')));
    resultsFolder = fullfile(projectRoot, 'results');
    figuresFolder = fullfile(projectRoot, 'figures');
    if ~exist(resultsFolder, 'dir'), mkdir(resultsFolder); end
    if ~exist(figuresFolder, 'dir'), mkdir(figuresFolder); end

    %% 第15题：有限差分基础数据
    nIntervalsList = [8, 16, 32, 64, 128, 256];
    sourceFun = @(x) exp(-x.^2);
    boundaryValues = [0, 0];
    xSpan = [-1, 1];
    xDense = linspace(xSpan(1), xSpan(2), 2001).';
    uExactDense = poissonExact(xDense);
    allSolutions = cell(size(nIntervalsList));

    for iGrid = 1:numel(nIntervalsList)
        nIntervals = nIntervalsList(iGrid);
        [x, uNum, meta] = solvePoissonFD(nIntervals, sourceFun, ...
            boundaryValues, xSpan);
        uExactAtNodes = poissonExact(x);
        pointTable = table(x, uNum, uExactAtNodes, ...
            'VariableNames', {'x', 'uNum', 'uExact'});
        writetable(pointTable, fullfile(resultsFolder, sprintf( ...
            'poisson_n%03d_points.csv', nIntervals)));
        solution = struct('nIntervals', nIntervals, 'x', x, ...
            'uNum', uNum, 'uExactAtNodes', uExactAtNodes, 'meta', meta);
        save(fullfile(resultsFolder, sprintf('poisson_n%03d.mat', ...
            nIntervals)), 'solution');
        allSolutions{iGrid} = solution;

        fig = figure('Name', sprintf('Poisson N=%d', nIntervals), ...
            'Visible', 'off');
        ax = axes(fig);
        stairs(ax, x, uNum, 'o-', 'LineWidth', 1.2, 'MarkerSize', 4, ...
            'DisplayName', sprintf('有限差分数值解（N=%d）', nIntervals));
        hold(ax, 'on');
        plot(ax, xDense, uExactDense, '-', 'LineWidth', 1.8, ...
            'DisplayName', '解析解');
        hold(ax, 'off');
        xlabel(ax, 'x'); ylabel(ax, 'u(x)');
        title(ax, sprintf('一维泊松问题：N = %d', nIntervals));
        legend(ax, 'Location', 'best');
        applyFigureStyle(ax);
        exportFigure(fig, fullfile(figuresFolder, sprintf( ...
            'poisson_compare_n%03d', nIntervals)));
        close(fig);
    end

    fig = figure('Name', 'Poisson 网格收敛总览', 'Visible', 'off');
    ax = axes(fig); hold(ax, 'on');
    colorOrder = lines(numel(nIntervalsList));
    for iGrid = 1:numel(nIntervalsList)
        solution = allSolutions{iGrid};
        stairs(ax, solution.x, solution.uNum, '-', ...
            'Color', colorOrder(iGrid, :), 'LineWidth', 1.1, ...
            'DisplayName', sprintf('数值解 N=%d', solution.nIntervals));
    end
    plot(ax, xDense, uExactDense, 'k-', 'LineWidth', 2.0, ...
        'DisplayName', '解析解');
    hold(ax, 'off');
    xlabel(ax, 'x'); ylabel(ax, 'u(x)');
    title(ax, '不同网格下有限差分数值解与解析解');
    legend(ax, 'Location', 'best');
    applyFigureStyle(ax);
    exportFigure(fig, fullfile(figuresFolder, 'poisson_grid_convergence'));
    close(fig);
    save(fullfile(resultsFolder, 'poisson_all_solutions.mat'), ...
        'nIntervalsList', 'xDense', 'uExactDense', 'allSolutions');

    %% 第16题：RK4 基础数据
    rhs = @(t, y) -y + t.^2 + 3;
    tSpan = [0, 3];
    y0 = 1;
    nList = [6, 12, 24, 48];
    dense = linspace(0, 3, 1001).';
    [ySym, yExact, check] = ivpExactSymbolic();
    out = cell(numel(nList), 1);
    fig = figure('Name', '第16题 RK4 基础实验', 'Visible', 'off');
    tiledlayout(fig, 2, 1);
    nexttile;
    hold on;
    plot(dense, yExact(dense), 'k-', 'LineWidth', 1.8, ...
        'DisplayName', '解析解');
    for i = 1:numel(nList)
        [t, y, meta] = rk4Solve(rhs, tSpan, y0, nList(i));
        e = abs(y(:, 1) - yExact(t));
        out{i} = struct('nSteps', nList(i), 't', t, 'yNum', y, ...
            'yExact', yExact(t), 'absError', e, 'meta', meta);
        plot(t, y(:, 1), 'o-', ...
            'DisplayName', sprintf('RK4 N = %d', nList(i)));
    end
    hold off;
    xlabel('t'); ylabel('y(t)'); title('第16题：RK4数值解与解析解');
    legend('Location', 'best'); applyFigureStyle(gca);
    nexttile;
    hold on;
    for i = 1:numel(out)
        semilogy(out{i}.t, max(out{i}.absError, eps), ...
            'DisplayName', sprintf('N = %d', out{i}.nSteps));
    end
    hold off;
    xlabel('t'); ylabel('绝对误差'); title('RK4绝对误差');
    legend('Location', 'best'); applyFigureStyle(gca);
    exportFigure(fig, fullfile(figuresFolder, 'ode_rk4_basic'));
    close(fig);
    save(fullfile(resultsFolder, 'ode_experiment.mat'), ...
        'out', 'ySym', 'check');
end
