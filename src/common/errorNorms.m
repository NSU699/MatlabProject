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
%
%   对应项目阶段: 第 4 阶段；供两题误差表和收敛实验调用
%   作者: 项目成员   日期: 2026-09-08

    validateattributes(numericalValues, {'numeric'}, {'nonempty', 'finite'});
    validateattributes(exactValues, {'numeric'}, {'nonempty', 'finite'});
    if ~isequal(size(numericalValues), size(exactValues))
        error('errorNorms:SizeMismatch', '数值解与精确解的尺寸必须一致。');
    end

    errorValues = numericalValues(:) - exactValues(:);
    maxError = max(abs(errorValues));
    l2Error = norm(errorValues, 2);
    rmsError = sqrt(mean(abs(errorValues).^2));
end
