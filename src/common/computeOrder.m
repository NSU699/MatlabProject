function [pairwiseOrder, fittedOrder] = computeOrder(stepSizes, errorValues)
% computeOrder  用比值法和对数最小二乘法估计收敛阶
%
%   [pairwiseOrder, fittedOrder] = computeOrder(stepSizes, errorValues)
%   用相邻数据点的比值计算观测阶，并拟合
%   log(error) = p*log(stepSize) + C 得到整体阶数 p。
%
%   输出:
%       pairwiseOrder - 相邻数据点的观测阶
%       fittedOrder   - 全部输入数据的最小二乘拟合阶
%   如需剔除舍入误差区间，应由实验脚本先选取渐近区数据再调用本函数。
%
%   对应项目阶段: 第 4 阶段；用于第 15、16 题的双重估阶
%   作者: 项目成员   日期: 2026-09-08

    validateattributes(stepSizes, {'numeric'}, {'vector', 'real', 'finite', 'positive'});
    validateattributes(errorValues, {'numeric'}, {'vector', 'real', 'finite', 'positive'});
    stepSizes = stepSizes(:);
    errorValues = errorValues(:);
    if numel(stepSizes) ~= numel(errorValues)
        error('computeOrder:SizeMismatch', '步长和误差向量长度必须一致。');
    end
    if numel(stepSizes) < 2
        error('computeOrder:TooFewPoints', '至少需要两个步长和误差数据点。');
    end
    if any(diff(stepSizes) == 0)
        error('computeOrder:RepeatedStepSize', '步长不能重复。');
    end

    stepRatio = stepSizes(1:end-1) ./ stepSizes(2:end);
    errorRatio = errorValues(1:end-1) ./ errorValues(2:end);
    pairwiseOrder = log(errorRatio) ./ log(stepRatio);

    fitCoefficients = polyfit(log(stepSizes), log(errorValues), 1);
    fittedOrder = fitCoefficients(1);
end
