function orderInfo = computeOrder(stepSizes, errors, fitMask)
% computeOrder  用比值法和对数最小二乘法估计收敛阶
%
%   orderInfo = computeOrder(stepSizes, errors, fitMask)
%   对正的步长和误差数据计算相邻点观测阶，并对 fitMask 指定的数据点
%   拟合 log(error) = p*log(stepSize) + C。第三个参数省略时，所有有效
%   数据点都用于拟合；是否剔除舍入误差区间由调用方根据实验结果决定。
%
%   输出字段:
%       pairwiseOrder - 相邻数据点的观测阶
%       fitOrder      - 最小二乘拟合斜率
%       fitIntercept  - 最小二乘拟合截距
%       fitMask       - 实际拟合掩码
%       validMask     - 有限且为正的数据掩码
%       fitStepSizes  - 实际拟合的步长
%       fitErrors     - 实际拟合的误差
%
%   对应项目阶段: 第 4 阶段；用于第 15、16 题的双重估阶
%   作者: 项目成员   日期: 2026-09-08

    validateattributes(stepSizes, {'numeric'}, {'vector', 'real', 'finite'}, mfilename, 'stepSizes', 1);
    validateattributes(errors, {'numeric'}, {'vector', 'real', 'finite'}, mfilename, 'errors', 2);
    stepSizes = stepSizes(:);
    errors = errors(:);
    if numel(stepSizes) ~= numel(errors)
        error('computeOrder:SizeMismatch', '步长和误差向量长度必须一致。');
    end
    if numel(stepSizes) < 2
        error('computeOrder:TooFewPoints', '至少需要两个步长和误差数据点。');
    end
    if any(stepSizes <= 0) || any(errors <= 0)
        error('computeOrder:NonPositiveInput', '步长和误差必须为正数。');
    end
    if any(diff(stepSizes) == 0)
        error('computeOrder:RepeatedStepSize', '步长不能重复。');
    end

    validMask = isfinite(stepSizes) & isfinite(errors) & stepSizes > 0 & errors > 0;
    if nargin < 3 || isempty(fitMask)
        fitMask = validMask;
    else
        if ~islogical(fitMask) || ~isvector(fitMask) || numel(fitMask) ~= numel(stepSizes)
            error('computeOrder:InvalidFitMask', 'fitMask 必须是与输入等长的逻辑向量。');
        end
        fitMask = fitMask(:) & validMask;
    end
    if nnz(fitMask) < 2
        error('computeOrder:TooFewFitPoints', '至少需要两个有效点进行最小二乘拟合。');
    end

    pairwiseOrder = NaN(numel(stepSizes) - 1, 1);
    stepRatio = stepSizes(1:end-1) ./ stepSizes(2:end);
    errorRatio = errors(1:end-1) ./ errors(2:end);
    positiveRatio = stepRatio > 0 & errorRatio > 0 & stepRatio ~= 1;
    pairwiseOrder(positiveRatio) = log(errorRatio(positiveRatio)) ./ log(stepRatio(positiveRatio));

    fitCoefficients = polyfit(log(stepSizes(fitMask)), log(errors(fitMask)), 1);
    orderInfo = struct();
    orderInfo.pairwiseOrder = pairwiseOrder;
    orderInfo.fitOrder = fitCoefficients(1);
    orderInfo.fitIntercept = fitCoefficients(2);
    orderInfo.fitMask = fitMask;
    orderInfo.validMask = validMask;
    orderInfo.fitStepSizes = stepSizes(fitMask);
    orderInfo.fitErrors = errors(fitMask);
end

