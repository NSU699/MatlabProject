function [t, yNum, meta] = rk4Solve(odeFun, tSpan, y0, nSteps)
% rk4Solve  通用固定步长经典四阶Runge-Kutta法
%
%   输入: odeFun(t,y) 接收标量时间和列向量状态；tSpan 为递增的两端点；
%         y0 为标量或向量初值；nSteps 为正整数步数。
%   输出: t 为 nSteps + 1 行列向量；yNum 每行一个节点、每列一个分量；
%         meta 记录步长、步数、方法名和右端函数实际调用次数。
%   h = (tSpan(2) - tSpan(1)) / nSteps；四个 k 均为斜率，不含步长 h。

    [t, yNum, h] = prepareOdeGrid(tSpan, y0, nSteps);

    for iStep = 1:nSteps
        time = t(iStep);
        state = yNum(iStep, :).';
        k1 = checkedOdeSlope(odeFun, time, state);
        k2 = checkedOdeSlope(odeFun, time + h/2, state + h*k1/2);
        k3 = checkedOdeSlope(odeFun, time + h/2, state + h*k2/2);
        k4 = checkedOdeSlope(odeFun, t(iStep + 1), state + h*k3);
        nextState = state + h*(k1 + 2 * k2 + 2 * k3 + k4) / 6;

        if any(~isfinite(nextState))
            error('rk4Solve:NonfiniteState', '第 %d 步的数值解出现 NaN/Inf。', iStep);
        end

        yNum(iStep + 1, :) = nextState.';
    end

    meta = struct('stepSize', h, 'nSteps', nSteps, 'method', '经典固定步长 RK4', 'functionEvaluations', 4*nSteps);
end

function [t, yNum, h] = prepareOdeGrid(tSpan, y0, nSteps)
    tSpan = double(tSpan); nSteps = double(nSteps);
    h = (tSpan(2) - tSpan(1)) / nSteps;
    t = linspace(tSpan(1), tSpan(2), nSteps + 1).';
    yNum = zeros(nSteps + 1, numel(y0)); yNum(1,:) = double(y0(:)).';
end

function slope = checkedOdeSlope(odeFun,time,state)
    slope = odeFun(time,state);
    
    slope = double(slope(:));
end
