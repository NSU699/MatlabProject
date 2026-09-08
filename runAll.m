clear;
clc;
close all;

% runAll  项目一键入口（阶段 3、4 基础设施版本）
% 当前仅配置项目路径并运行公共层测试；算法和实验完成后继续在此处接入。
% 对应项目阶段: 第 3、4 阶段
% 作者: 项目成员   日期: 2026-09-08

projectRoot = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(projectRoot, 'src')));

fprintf('MATLAB 数值实验项目入口：开始运行公共层测试。\n');
testSummary = runAllTests();
if ~testSummary.passed
    error('runAll:TestsFailed', '公共层测试未通过，已停止后续流程。');
end
fprintf('当前阶段完成：公共层测试通过；第 15、16 题算法将在后续阶段接入。\n');

