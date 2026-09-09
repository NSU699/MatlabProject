function [t, yNum, meta] = eulerSolve(odeFun, tSpan, y0, nSteps)
% eulerSolve  通用固定步长显式 Euler 法
%
%   输入: odeFun(t,y)、递增区间 tSpan、标量或向量初值 y0、正整数 nSteps。
%   输出: 时间列向量 t、每行一个节点的 yNum、含步长和函数调用次数的 meta。
%   odeFun 接收列向量状态，更新式为 y_(n+1)=y_n+h*f(t_n,y_n)。
%   对应报告: 第16题算法实现（阶段7）；后续方法对比
%   作者: 项目成员   日期: 2026-09-09

    [t, yNum, h] = prepareOdeGrid(odeFun, tSpan, y0, nSteps);
    for iStep = 1:nSteps
        state = yNum(iStep, :).';
        slope = checkedOdeSlope(odeFun, t(iStep), state);
        nextState = state + h*slope;
        if any(~isfinite(nextState))
            error('eulerSolve:NonfiniteState', '第 %d 步的数值解出现 NaN/Inf。', iStep);
        end
        yNum(iStep + 1, :) = nextState.';
    end
    meta = struct('stepSize', h, 'nSteps', nSteps, ...
        'method', '显式 Euler', 'functionEvaluations', nSteps);
end

function [t, yNum, h] = prepareOdeGrid(odeFun,tSpan,y0,nSteps)
    if ~isa(odeFun,'function_handle') || ~isnumeric(tSpan) || numel(tSpan)~=2 || any(~isfinite(tSpan(:))) || tSpan(2)<=tSpan(1) || ~isnumeric(y0) || ~isvector(y0) || isempty(y0) || any(~isfinite(y0(:))) || ~isscalar(nSteps) || nSteps<1 || nSteps~=fix(nSteps)
        error('eulerSolve:InvalidInput','输入参数无效。');
    end
    nSteps=double(nSteps); h=(tSpan(2)-tSpan(1))/nSteps; t=linspace(tSpan(1),tSpan(2),nSteps+1).'; yNum=zeros(nSteps+1,numel(y0)); yNum(1,:)=double(y0(:)).';
end

function slope=checkedOdeSlope(f,time,state)
    slope = f(time,state);

    if ~isnumeric(slope) || ~isvector(slope) || numel(slope) ~= numel(state) || any(~isfinite(slope(:)))
        error('eulerSolve:InvalidSlope','右端函数输出无效。');
    end

    slope=double(slope(:));
end
