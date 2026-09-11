function [x, uNum, meta] = solvePoissonShooting(nIntervals, sourceFun, boundaryValues, xSpan)
% solvePoissonShooting  用打靶法和固定步长 RK4 求解一维泊松边值问题
%
%   将 u''(x) = sourceFun(x) 改写为 [u; v]' = [v; sourceFun(x)]。
%   先以左端斜率 0 积分，再利用齐次解 x - xSpan(1) 修正初始斜率，
%   因而本线性问题只需一次 RK4 积分，不需要牛顿或割线迭代。
%
%   输入与 solvePoissonFD 相同；输出 uNum 为节点列向量，meta 保存
%   步长、初始斜率、边界残差和 RK4 函数求值次数。

    if nargin < 1 || isempty(nIntervals), nIntervals = 32; end
    if nargin < 2 || isempty(sourceFun), sourceFun = @(x) exp(-x.^2); end
    if nargin < 3 || isempty(boundaryValues), boundaryValues = [0, 0]; end
    if nargin < 4 || isempty(xSpan), xSpan = [-1, 1]; end

    validateattributes(nIntervals, {'numeric'}, {'scalar', 'integer', '>=', 1});
    validateattributes(boundaryValues, {'numeric'}, {'vector', 'numel', 2, 'finite'});
    validateattributes(xSpan, {'numeric'}, {'vector', 'numel', 2, 'finite'});

    leftBoundary = boundaryValues(1);
    rightBoundary = boundaryValues(2);
    odeFun = @(xValue, state) [state(2); checkedSource(sourceFun, xValue)];
    [x, stateZeroSlope, rkMeta] = rk4Solve(odeFun, xSpan, [leftBoundary; 0], nIntervals);

    intervalLength = xSpan(2) - xSpan(1);
    initialSlope = (rightBoundary - stateZeroSlope(end, 1)) / intervalLength;
    uNum = stateZeroSlope(:, 1) + initialSlope .* (x - xSpan(1));
    uNum(1) = leftBoundary;
    uNum(end) = rightBoundary;

    meta = struct();
    meta.stepSize = rkMeta.stepSize;
    meta.nIntervals = nIntervals;
    meta.initialSlope = initialSlope;
    meta.zeroSlopeEndValue = stateZeroSlope(end, 1);
    meta.functionEvaluations = rkMeta.functionEvaluations;
    meta.boundaryResidual = [uNum(1) - leftBoundary; uNum(end) - rightBoundary];
end

function sourceValue = checkedSource(sourceFun, xValue)
    sourceValue = sourceFun(xValue);

    sourceValue = double(sourceValue);
end
