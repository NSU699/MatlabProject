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

    validateattributes(stepSizes, {'numeric'}, {'vector', 'real', 'finite', 'positive'});
    validateattributes(errorValues, {'numeric'}, {'vector', 'real', 'finite', 'positive'});
    stepSizes = stepSizes(:);
    errorValues = errorValues(:);

    stepRatio = stepSizes(1:end-1) ./ stepSizes(2:end);
    errorRatio = errorValues(1:end-1) ./ errorValues(2:end);
    pairwiseOrder = log(errorRatio) ./ log(stepRatio);

    fitCoefficients = polyfit(log(stepSizes), log(errorValues), 1);
    fittedOrder = fitCoefficients(1);
end
