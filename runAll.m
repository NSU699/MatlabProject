clear;
clc;
close all;

% runAll  项目一键入口

projectRoot = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(projectRoot, 'src')));

%%  公共层测试部分
fprintf('MATLAB 数值实验项目入口：开始运行公共层测试。\n');
% runAllTests 在断言失败时直接报错；正常返回即表示测试通过。
runAllTests();
fprintf('公共层测试通过.\n');

%%  第15题部分
%   对 nIntervals = 8、16、32、64、128、256 分别求解一维泊松问题，
%   输出离散点表、单组数值/解析解对比图，以及全部网格的总览图。
%   数值解保留为离散节点值；绘图时用 stairs 显示其阶梯形状。
% 实验参数集中定义，便于复现实验
fprintf('开始运行第 15 题有限差分实验。\n')
nIntervalsList = [8, 16, 32, 64, 128, 256];
sourceFun = @(x) exp(-x.^2);
boundaryValues = [0, 0];
xSpan = [-1, 1];
xDense = linspace(xSpan(1), xSpan(2), 2001).';
uExactDense = poissonExact(xDense);

resultsFolder = fullfile(projectRoot, 'results');
figuresFolder = fullfile(projectRoot, 'figures');
if ~exist(resultsFolder, 'dir'), mkdir(resultsFolder); end
if ~exist(figuresFolder, 'dir'), mkdir(figuresFolder); end

allSolutions = cell(size(nIntervalsList));

for iGrid = 1:numel(nIntervalsList)
    nIntervals = nIntervalsList(iGrid);
    [x, uNum, meta] = solvePoissonFD(nIntervals, sourceFun, boundaryValues, xSpan);
    uExactAtNodes = poissonExact(x);

    % 保存离散点表；表中每一行对应实际计算/保留的一个节点
    pointTable = table(x, uNum, uExactAtNodes, ...
        'VariableNames', {'x', 'uNum', 'uExact'});
    csvPath = fullfile(resultsFolder, sprintf('poisson_n%03d_points.csv', nIntervals));
    writetable(pointTable, csvPath);

    solution = struct();
    solution.nIntervals = nIntervals;
    solution.x = x;
    solution.uNum = uNum;
    solution.uExactAtNodes = uExactAtNodes;
    solution.meta = meta;
    solution.csvPath = csvPath;
    matPath = fullfile(resultsFolder, sprintf('poisson_n%03d.mat', nIntervals));
    save(matPath, 'solution');
    allSolutions{iGrid} = solution;

    fprintf('\n--- nIntervals = %d：离散数值表 ---\n', nIntervals);
    disp(pointTable(:, {'x', 'uNum'}));

    % 单个网格的数值解/解析解对比图
    fig = figure('Name', sprintf('Poisson nIntervals=%d', nIntervals), 'Visible', 'off');
    ax = axes(fig);
    stairs(ax, x, uNum, 'o-', 'LineWidth', 1.2, 'MarkerSize', 4, ...
        'DisplayName', sprintf('有限差分数值解（N=%d）', nIntervals));
    hold(ax, 'on');
    plot(ax, xDense, uExactDense, '-', 'LineWidth', 1.8, ...
        'DisplayName', '解析解');
    hold(ax, 'off');
    xlabel(ax, 'x');
    ylabel(ax, 'u(x)');
    title(ax, sprintf('一维泊松问题：N = %d', nIntervals));
    legend(ax, 'Location', 'best');
    applyFigureStyle(ax);
    set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'GridColor', [0.8, 0.8, 0.8]);
    singleStem = fullfile(figuresFolder, sprintf('poisson_compare_n%03d', nIntervals));
    exportFigure(fig, singleStem);
    close(fig);
end

% 全部网格与解析解总览图
overview = figure('Name', 'Poisson 网格收敛总览', 'Visible', 'off');
axOverview = axes(overview);
hold(axOverview, 'on');
colorOrder = lines(numel(nIntervalsList));
for iGrid = 1:numel(nIntervalsList)
    solution = allSolutions{iGrid};
    stairs(axOverview, solution.x, solution.uNum, '-', 'Color', colorOrder(iGrid, :), ...
        'LineWidth', 1.1, 'DisplayName', sprintf('数值解 N=%d', solution.nIntervals));
end
plot(axOverview, xDense, uExactDense, 'k-', 'LineWidth', 2.0, ...
    'DisplayName', '解析解');
hold(axOverview, 'off');
xlabel(axOverview, 'x');
ylabel(axOverview, 'u(x)');
title(axOverview, '不同网格下有限差分数值解与解析解');
legend(axOverview, 'Location', 'best');
applyFigureStyle(axOverview);
set(axOverview, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'GridColor', [0.8, 0.8, 0.8]);
exportFigure(overview, fullfile(figuresFolder, 'poisson_grid_convergence'));

save(fullfile(resultsFolder, 'poisson_all_solutions.mat'), ...
    'nIntervalsList', 'xDense', 'uExactDense', 'allSolutions');
fprintf('\n第 15 题实验完成：结果已保存到 results/，图像已保存到 figures/。\n');

%% 第16题部分
fprintf('开始运行第 16 题 RK4、符号解与基础误差实验。\n');

rhs = @(t,y) - y + t .^ 2 + 3;
tSpan = [0, 3];
y0 = 1;
nList = [6, 12, 24, 48];
dense = linspace(0, 3, 1001).';
[ySym, yExact, check] = ivpExactSymbolic();

assert(check.passed);
out = cell(numel(nList), 1);
fig = figure('Visible', 'off');

tiledlayout(2, 1);
nexttile;
hold on;
plot(dense, yExact(dense), 'k-', 'LineWidth', 1.8, 'DisplayName', '解析解');

for i = 1:numel(nList) 
    [t, y, meta] = rk4Solve(rhs, tSpan, y0, nList(i));
    e = abs(y(:,1) - yExact(t));
    out{i} = struct('nSteps', nList(i), 't', t, 'yNum', y, 'yExact', yExact(t), 'absError', e, 'meta', meta);
    plot(t, y(:, 1), 'o-','DisplayName', sprintf('RK4 N = %d', nList(i)));
end

hold off;
xlabel('t');
ylabel('y(t)');
title('第16题：RK4数值解与解析解');
legend('Location','best');

applyFigureStyle(gca);
nexttile;
hold on;

for i = 1:numel(out)
    semilogy(out{i}.t, max(out{i}.absError,eps), 'DisplayName', sprintf('N = %d', out{i}.nSteps));
end

hold off;
xlabel('t');
ylabel('绝对误差');
title('RK4绝对误差');
legend('Location', 'best');
applyFigureStyle(gca);
exportFigure(fig,fullfile(projectRoot, 'figures', 'ode_rk4_basic'));
close(fig);
save(fullfile(projectRoot, 'results', 'ode_experiment.mat'), 'out', 'ySym', 'check');

%% 正式收敛实验
% 按方案要求使用长步长序列，输出两张误差表和两张 loglog 图。
fprintf('开始运行第 15、16 题正式收敛实验。\n');
runConvergenceExperiment();
fprintf('第 16 题基础实验完成：结果已保存到 results/，图像已保存到 figures/。\n');
