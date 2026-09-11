function [t, yNum, meta] = rk2Solve(odeFun, tSpan, y0, nSteps)
% rk2Solve  通用固定步长改进 Euler 法（Heun 型二阶 RK）
%
%   输入: odeFun(t,y)、递增区间 tSpan、标量或向量初值 y0、正整数 nSteps。
%   输出: 时间列向量 t、每行一个节点的 yNum、含步长和函数调用次数的 meta。
%   先以起点斜率预测终点，再取起点斜率和预测终点斜率的平均值。

    [t, yNum, h] = prepareOdeGrid(odeFun, tSpan, y0, nSteps);
    for iStep = 1:nSteps
        state = yNum(iStep, :).';
        k1 = checkedOdeSlope(odeFun, t(iStep), state);
        k2 = checkedOdeSlope(odeFun, t(iStep + 1), state + h*k1);
        nextState = state + h*(k1 + k2)/2;
        if any(~isfinite(nextState))
            error('rk2Solve:NonfiniteState', '第 %d 步的数值解出现 NaN/Inf。', iStep);
        end
        yNum(iStep + 1, :) = nextState.';
    end
    meta = struct('stepSize', h, 'nSteps', nSteps, ...
        'method', '改进 Euler（RK2）', 'functionEvaluations', 2*nSteps);
end

function [t, yNum, h] = prepareOdeGrid(~,tSpan,y0,nSteps)

    nSteps=double(nSteps); h=(tSpan(2)-tSpan(1))/nSteps; t=linspace(tSpan(1),tSpan(2),nSteps+1).'; yNum=zeros(nSteps+1,numel(y0)); yNum(1,:)=double(y0(:)).';
end

function slope = checkedOdeSlope(f,time,state)
    slope = f(time,state); 

    slope=double(slope(:));
end
