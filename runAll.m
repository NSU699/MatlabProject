clear;
clc;
close all;

% runAll  MATLAB 数值计算项目入口

projectRoot = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(projectRoot, 'src')));

fprintf('MATLAB 数值计算项目：开始生成。\n');

fprintf('\n[1/8] 输出第15题有限差分和第16题RK4基础数据...\n');
runCoreExperiments();

fprintf('[2/8] 输出第15题误差与残差分析...\n');
runPoissonAnalysis();

fprintf('[3/8] 输出第15题 Richardson 外推数据和图表...\n');
runRichardsonExperiment();
runRichardsonFigures();

fprintf('[4/8] 输出第15题打靶法交叉验证数据、分析和图表...\n');
runShootingExperiment();
runShootingAnalysis();

fprintf('[5/8] 输出两题正式收敛数据和图表...\n');
runConvergenceExperiment();

fprintf('[6/8] 输出 Euler/RK2/RK4 精度、效率和重复计时比较...\n');
runOdeMethodComparison();

fprintf('[7/8] 输出第16题 RK4 补充分析图表...\n');
runOdeFigureAnalysis();

resultsFolder = fullfile(projectRoot, 'results');
figuresFolder = fullfile(projectRoot, 'figures');
resultFiles = dir(fullfile(resultsFolder, '*'));
figureFiles = dir(fullfile(figuresFolder, '*'));
fprintf('[8/8] 完成。\n');
fprintf('结果目录：%s（%d 项）\n', resultsFolder, numel(resultFiles));
fprintf('图表目录：%s（%d 项）\n', figuresFolder, numel(figureFiles));
