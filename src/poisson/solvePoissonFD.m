function [x, uNum, meta] = solvePoissonFD(nIntervals, sourceFun, boundaryValues, xSpan)
% solvePoissonFD  用二阶中心差分法求解一维泊松边值问题
%
%   求解 u''(x) = sourceFun(x)，并满足两端 Dirichlet 边界条件。
%   有限差分法将连续的常微分方程转换为离散的线性方程组：
%   (u_(i - 1) - 2 * u_i + u_(i + 1)) / h ^ 2 = exp(-(x_i) ^ 2)
%   这里阶段误差为 O(h ^ 2)

    if nargin < 1 || isempty(nIntervals), nIntervals = 32; end
    if nargin < 2 || isempty(sourceFun), sourceFun = @(x) exp(-x.^2); end
    if nargin < 3 || isempty(boundaryValues), boundaryValues = [0, 0]; end
    if nargin < 4 || isempty(xSpan), xSpan = [-1, 1]; end
    validateattributes(nIntervals, {'numeric'}, {'scalar', 'integer', '>=', 2});
    validateattributes(boundaryValues, {'numeric'}, {'vector', 'numel', 2, 'finite'});
    validateattributes(xSpan, {'numeric'}, {'vector', 'numel', 2, 'finite'});
    if xSpan(2) <= xSpan(1), error('solvePoissonFD:InvalidInterval', '区间右端必须大于左端。'); end
    if ~isa(sourceFun, 'function_handle'), error('solvePoissonFD:InvalidSource', '源项必须是函数句柄。'); end

    h = (xSpan(2) - xSpan(1)) / nIntervals;
    x = linspace(xSpan(1), xSpan(2), nIntervals + 1).';
    xInner = x(2:end-1);
    nInner = nIntervals - 1;
    mainDiagonal = -2 * ones(nInner, 1);
    offDiagonal = ones(nInner, 1);
    A = spdiags([offDiagonal, mainDiagonal, offDiagonal], [-1, 0, 1], nInner, nInner) / h^2;
    rhs = sourceFun(xInner);
    rhs = rhs(:);
    if numel(rhs) ~= nInner || any(~isfinite(rhs))
        error('solvePoissonFD:InvalidSourceOutput', '源项输出必须是有限的内部节点列向量。');
    end
    rhs(1) = rhs(1) - boundaryValues(1) / h^2;
    rhs(end) = rhs(end) - boundaryValues(2) / h^2;
    uInner = A \ rhs;
    uNum = [boundaryValues(1); uInner; boundaryValues(2)]; % 由有限差分法所得的解

    meta.stepSize = h; %  子区间跨度
    meta.nIntervals = nIntervals; % 子区间数量
    meta.matrix = A; % 稀疏三对角线矩阵
    meta.rhs = rhs; % 右端项 
    meta.sourceValues = sourceFun(xInner); % 区间内点处函数值
    meta.matrixSize = size(A);
    meta.linearResidual = A * uInner - rhs; % 残差
    meta.conditionEstimate = condest(A);
end
