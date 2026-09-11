function [t, yNum, meta] = eulerSolve(odeFun, tSpan, y0, nSteps)
% eulerSolve  通用固定步长显式 Euler 法
%
%   输入: odeFun(t,y)、递增区间 tSpan、标量或向量初值 y0、正整数 nSteps。
%   输出: 时间列向量 t、每行一个节点的 yNum、含步长和函数调用次数的 meta。
%   odeFun 接收列向量状态，更新式为 y_(n+1)=y_n+h*f(t_n,y_n)。

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

function [t, yNum, h] = prepareOdeGrid(~,tSpan,y0,nSteps)
    nSteps=double(nSteps); h=(tSpan(2)-tSpan(1))/nSteps; t=linspace(tSpan(1),tSpan(2),nSteps+1).'; yNum=zeros(nSteps+1,numel(y0)); yNum(1,:)=double(y0(:)).';
end

function slope=checkedOdeSlope(f,time,state)
    slope = f(time,state);

    slope=double(slope(:));
end
