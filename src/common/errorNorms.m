function metrics = errorNorms(numericalValues, exactValues)
% errorNorms  计算数值解与精确解之间的统一误差指标
%
%   metrics = errorNorms(numericalValues, exactValues)
%   将输入展平成向量后计算绝对误差和相对误差。输入可以是标量、
%   向量或矩阵，但两者尺寸必须完全一致，且不能含 NaN 或 Inf。
%
%   输出字段:
%       maxAbs     - 最大绝对误差
%       l2         - 误差二范数
%       rms        - 均方根误差
%       relativeInf- 相对无穷范数误差
%       relative2  - 相对二范数误差
%       count      - 参与计算的元素个数
%
%   对应项目阶段: 第 4 阶段；供两题误差表和收敛实验调用
%   作者: 项目成员   日期: 2026-09-08

    validateattributes(numericalValues, {'numeric'}, {'nonempty'}, mfilename, 'numericalValues', 1);
    validateattributes(exactValues, {'numeric'}, {'nonempty'}, mfilename, 'exactValues', 2);
    if ~isequal(size(numericalValues), size(exactValues))
        error('errorNorms:SizeMismatch', '数值解与精确解的尺寸必须一致。');
    end
    if any(~isfinite(numericalValues(:))) || any(~isfinite(exactValues(:)))
        error('errorNorms:NonFiniteInput', '数值解和精确解不能含 NaN 或 Inf。');
    end

    errorVector = numericalValues(:) - exactValues(:);
    exactVector = exactValues(:);
    exactInf = norm(exactVector, inf);
    exactL2 = norm(exactVector, 2);

    metrics = struct();
    metrics.maxAbs = norm(errorVector, inf);
    metrics.l2 = norm(errorVector, 2);
    metrics.rms = sqrt(mean(abs(errorVector).^2));
    metrics.relativeInf = relativeNorm(metrics.maxAbs, exactInf);
    metrics.relative2 = relativeNorm(metrics.l2, exactL2);
    metrics.count = numel(errorVector);
end

function value = relativeNorm(numerator, denominator)
    if denominator == 0
        if numerator == 0
            value = 0;
        else
            value = Inf;
        end
    else
        value = numerator / denominator;
    end
end

