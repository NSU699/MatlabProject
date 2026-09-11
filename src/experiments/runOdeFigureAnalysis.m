clear;
clc;
close all;

% runOdeFigureAnalysis  基于第16题已有结果生成六张分析图
%
%   读取 results/ode_experiment.mat，生成：
%   1) 精简的数值解与解析解对照图
%   2) 有符号误差随自变量t变化图
%   3) 四阶归一化误差图 e/h^4
%   4) 最大误差与 RMS 误差的双对数收敛图
%   5) 逐级观测收敛阶图
%   6) 函数调用次数与误差的工作量-精度图
%
%   数据来源：results/ode_experiment.mat
%   输出位置：figures/ode_rk4_*.png 和 figures/ode_rk4_*.pdf

projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(genpath(fullfile(projectRoot, 'src')));
dataPath = fullfile(projectRoot, 'results', 'ode_experiment.mat');
figureFolder = fullfile(projectRoot, 'figures');
if ~exist(figureFolder, 'dir')
    mkdir(figureFolder);
end

S = load(dataPath);
out = S.out;
nCases = numel(out);
colors = [0.0000, 0.4470, 0.7410; ...
          0.8500, 0.3250, 0.0980; ...
          0.4940, 0.1840, 0.5560; ...
          0.0000, 0.6000, 0.5000];
markers = {'o', 's', '^', 'd'};
lineStyles = {'-', '--', '-.', ':'};

nSteps = zeros(nCases, 1);
stepSizes = zeros(nCases, 1);
maxErrors = zeros(nCases, 1);
rmsErrors = zeros(nCases, 1);
work = zeros(nCases, 1);
for iCase = 1:nCases
    nSteps(iCase) = out{iCase}.nSteps;
    stepSizes(iCase) = out{iCase}.meta.stepSize;
    maxErrors(iCase) = max(out{iCase}.absError(:));
    rmsErrors(iCase) = sqrt(mean(out{iCase}.absError(:).^2));
    work(iCase) = out{iCase}.meta.functionEvaluations;
end

% 图1：只保留最粗、最细网格，避免四条几乎重合的曲线互相遮挡。
fig = newFigure([8.0, 5.2]);
ax = axes(fig); hold(ax, 'on');
tDense = linspace(out{1}.t(1), out{1}.t(end), 1001).';
yDense = S.check.explicitFunction(tDense);
plot(ax, tDense, yDense, 'k-', 'LineWidth', 1.8, 'DisplayName', '解析解');
for iCase = [1, nCases]
    plot(ax, out{iCase}.t, out{iCase}.yNum(:, 1), ...
        'Color', colors(iCase, :), 'LineStyle', lineStyles{iCase}, ...
        'Marker', markers{iCase}, 'MarkerSize', 5, 'LineWidth', 1.1, ...
        'DisplayName', sprintf('RK4, N=%d', nSteps(iCase)));
end
xlabel(ax, 't'); ylabel(ax, 'y(t)');
title(ax, '第16题：数值解与解析解对照');
legend(ax, 'Location', 'northwest', 'Box', 'off');
applyProjectFigureStyle(ax, [8.0, 5.2]); exportFigure(fig, fullfile(figureFolder, 'ode_rk4_solution_comparison')); close(fig);

% 图2：有符号误差，保留零线以显示误差方向与过零位置。
fig = newFigure([8.0, 5.2]);
ax = axes(fig); hold(ax, 'on');
yline(ax, 0, 'Color', [0.25, 0.25, 0.25], 'LineWidth', 0.9, ...
    'HandleVisibility', 'off');
for iCase = 1:nCases
    signedError = out{iCase}.yNum(:, 1) - out{iCase}.yExact(:);
    plot(ax, out{iCase}.t, signedError, 'Color', colors(iCase, :), ...
        'LineStyle', lineStyles{iCase}, 'Marker', markers{iCase}, ...
        'MarkerSize', 4, 'LineWidth', 1.1, ...
        'DisplayName', sprintf('N=%d', nSteps(iCase)));
end
xlabel(ax, 't'); ylabel(ax, '有符号误差  e_N(t)');
title(ax, 'RK4 有符号误差自变量t的变化');
legend(ax, 'Location', 'northwest', 'Box', 'off');
applyProjectFigureStyle(ax, [8.0, 5.2]); exportFigure(fig, fullfile(figureFolder, 'ode_rk4_signed_error')); close(fig);

% 图3：e/h^4，用于检查不同网格的误差形状是否趋于塌缩。
fig = newFigure([8.0, 5.2]);
ax = axes(fig); hold(ax, 'on');
for iCase = 1:nCases
    signedError = out{iCase}.yNum(:, 1) - out{iCase}.yExact(:);
    plot(ax, out{iCase}.t, signedError / stepSizes(iCase)^4, ...
        'Color', colors(iCase, :), 'LineStyle', lineStyles{iCase}, ...
        'Marker', markers{iCase}, 'MarkerSize', 4, 'LineWidth', 1.1, ...
        'DisplayName', sprintf('N=%d', nSteps(iCase)));
end
yline(ax, 0, 'Color', [0.25, 0.25, 0.25], 'LineWidth', 0.9, ...
    'HandleVisibility', 'off');
xlabel(ax, 't'); ylabel(ax, 'e_N(t) / h^4');
title(ax, '四阶归一化有符号误差');
legend(ax, 'Location', 'northwest', 'Box', 'off');
applyProjectFigureStyle(ax, [8.0, 5.2]); exportFigure(fig, fullfile(figureFolder, 'ode_rk4_scaled_error')); close(fig);

% 图4：误差随步长的双对数收敛图，加入斜率为4的参考线。
fig = newFigure([8.0, 5.2]);
ax = axes(fig); hold(ax, 'on');
loglog(ax, stepSizes, maxErrors, 'o-', 'Color', colors(1, :), ...
    'MarkerFaceColor', colors(1, :), 'LineWidth', 1.4, ...
    'DisplayName', '最大绝对误差');
loglog(ax, stepSizes, rmsErrors, 's--', 'Color', colors(2, :), ...
    'MarkerFaceColor', colors(2, :), 'LineWidth', 1.4, ...
    'DisplayName', 'RMS误差');
reference = maxErrors(end) * (stepSizes / stepSizes(end)).^4;
loglog(ax, stepSizes, reference, 'k:', 'LineWidth', 1.2, ...
    'DisplayName', '斜率 4 参考线');
set(ax, 'XScale', 'log', 'YScale', 'log', 'XDir', 'reverse');
pairwiseOrder = log(maxErrors(1:end-1) ./ maxErrors(2:end)) ./ ...
    log(stepSizes(1:end-1) ./ stepSizes(2:end));
fitMax = polyfit(log(stepSizes), log(maxErrors), 1);
fitRms = polyfit(log(stepSizes), log(rmsErrors), 1);
xlabel(ax, '步长 h'); ylabel(ax, '误差');
title(ax, sprintf('RK4 双对数收敛图（拟合阶：最大 %.4f，RMS %.4f）', ...
    fitMax(1), fitRms(1)));
legend(ax, 'Location', 'southwest', 'Box', 'off');
applyProjectFigureStyle(ax, [8.0, 5.2]); exportFigure(fig, fullfile(figureFolder, 'ode_rk4_convergence')); close(fig);

% 图5：逐级观测阶，只有三个点，因此作为诊断图而非单独的统计推断。
fig = newFigure([8.0, 5.2]);
ax = axes(fig); hold(ax, 'on');
fineSteps = nSteps(2:end);
orderMax = pairwiseOrder;
orderRms = log(rmsErrors(1:end-1) ./ rmsErrors(2:end)) ./ ...
    log(stepSizes(1:end-1) ./ stepSizes(2:end));
plot(ax, fineSteps, orderMax, 'o-', 'Color', colors(1, :), ...
    'MarkerFaceColor', colors(1, :), 'LineWidth', 1.4, ...
    'DisplayName', '最大误差观测阶');
plot(ax, fineSteps, orderRms, 's--', 'Color', colors(2, :), ...
    'MarkerFaceColor', colors(2, :), 'LineWidth', 1.4, ...
    'DisplayName', 'RMS误差观测阶');
yline(ax, 4, '--', 'Color', [0, 0, 0], 'LineWidth', 1.8, ...
    'DisplayName', '理论阶 p=4');
xlabel(ax, '细网格步数'); ylabel(ax, '观测收敛阶 p');
title(ax, 'RK4 逐级观测收敛阶');
xticks(ax, fineSteps);
ylim(ax, [3.99, 4.15]);
legend(ax, 'Location', 'northeast', 'Box', 'off');
applyProjectFigureStyle(ax, [8.0, 5.2]); exportFigure(fig, fullfile(figureFolder, 'ode_rk4_observed_order')); close(fig);

% 图6：函数调用次数是当前结果中可复核的工作量指标，不冒充运行时间。
fig = newFigure([8.0, 5.2]);
ax = axes(fig); hold(ax, 'on');
loglog(ax, work, maxErrors, 'o-', 'Color', colors(3, :), ...
    'MarkerFaceColor', colors(3, :), 'LineWidth', 1.4, ...
    'DisplayName', '最大绝对误差');
workReference = maxErrors(end) * (work / work(end)).^(-4);
loglog(ax, work, workReference, 'k:', 'LineWidth', 1.2, ...
    'DisplayName', '斜率 -4 参考线');
set(ax, 'XScale', 'log', 'YScale', 'log');
xlabel(ax, '右端函数调用次数（工作量指标）'); ylabel(ax, '最大绝对误差');
title(ax, 'RK4 工作量—精度关系');
legend(ax, 'Location', 'southwest', 'Box', 'off');
applyProjectFigureStyle(ax, [8.0, 5.2]); exportFigure(fig, fullfile(figureFolder, 'ode_rk4_work_precision')); close(fig);

fprintf('第16题六张分析图已生成到：%s\n', figureFolder);
fprintf('最大误差拟合阶：%.6f；RMS误差拟合阶：%.6f\n', fitMax(1), fitRms(1));
fprintf('最大误差逐级观测阶：'); fprintf(' %.6f', orderMax); fprintf('\n');

function fig = newFigure(sizeInches)
    fig = figure('Visible', 'off', 'Color', 'w', ...
        'Units', 'inches', 'Position', [1, 1, sizeInches(1), sizeInches(2)]);
    set(fig, 'PaperUnits', 'inches', 'PaperPosition', [0, 0, sizeInches(1), sizeInches(2)]);
    set(fig, 'DefaultAxesFontName', 'Microsoft YaHei', ...
        'DefaultTextFontName', 'Microsoft YaHei', 'DefaultAxesFontSize', 10);
end

function applyProjectFigureStyle(axHandle, sizeInches)
    applyFigureStyle(axHandle);
    figHandle = ancestor(axHandle, 'figure');
    set(axHandle, 'Color', 'w', 'XColor', [0.10, 0.10, 0.10], ...
        'YColor', [0.10, 0.10, 0.10], 'GridColor', [0.75, 0.75, 0.75], ...
        'MinorGridColor', [0.88, 0.88, 0.88], 'GridAlpha', 0.35, ...
        'MinorGridAlpha', 0.20);
    set(findall(figHandle, 'Type', 'text'), 'Color', [0.10, 0.10, 0.10]);
    legendHandles = findall(figHandle, 'Type', 'legend');
    set(legendHandles, 'TextColor', [0.10, 0.10, 0.10], ...
        'Color', 'w', 'EdgeColor', 'none');
    set(figHandle, 'Units', 'inches', ...
        'Position', [1, 1, sizeInches(1), sizeInches(2)], ...
        'PaperUnits', 'inches', ...
        'PaperPosition', [0, 0, sizeInches(1), sizeInches(2)]);
end
