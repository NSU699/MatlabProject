function [maxError, l2Error, rmsError] = errorNorms(numericalValues, exactValues)
% errorNorms  计算数值解与精确解之间的统一误差指标
%
%   [maxError, l2Error, rmsError] = errorNorms(numericalValues, exactValues)
%   计算最大绝对误差、误差二范数和均方根误差。
%
%   输出:
%       maxError - 最大绝对误差
%       l2Error  - 误差二范数
%       rmsError - 均方根误差

    validateattributes(numericalValues, {'numeric'}, {'nonempty', 'finite'});
    validateattributes(exactValues, {'numeric'}, {'nonempty', 'finite'});

    errorValues = numericalValues(:) - exactValues(:);
    maxError = max(abs(errorValues));
    l2Error = norm(errorValues, 2);
    rmsError = sqrt(mean(abs(errorValues).^2));
end
