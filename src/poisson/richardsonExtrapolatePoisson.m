function [x, uRichardson, meta] = richardsonExtrapolatePoisson(nIntervals, sourceFun, boundaryValues, xSpan)
% richardsonExtrapolatePoisson  对二阶有限差分解进行 Richardson 外推
%
%   分别在 N 和 2N 个子区间上调用 solvePoissonFD，并在粗网格节点上计算
%   uRichardson = (4 * uFine - uCoarse) / 3，从而得到四阶近似。

    if nargin < 1 || isempty(nIntervals), nIntervals = 32; end
    if nargin < 2 || isempty(sourceFun), sourceFun = @(x) exp(-x.^2); end
    if nargin < 3 || isempty(boundaryValues), boundaryValues = [0, 0]; end
    if nargin < 4 || isempty(xSpan), xSpan = [-1, 1]; end

    validateattributes(nIntervals, {'numeric'}, {'scalar', 'integer', '>=', 2});

    [x, uCoarse, coarseMeta] = solvePoissonFD( ...
        nIntervals, sourceFun, boundaryValues, xSpan);
    [~, uFine, fineMeta] = solvePoissonFD( ...
        2 * nIntervals, sourceFun, boundaryValues, xSpan);

    % 细网格的第 1、3、5、... 个元素与粗网格节点位于相同位置。
    uFineAtCoarse = uFine(1:2:end);

    uRichardson = (4 * uFineAtCoarse - uCoarse) / 3;

    meta.coarseN = nIntervals;
    meta.fineN = 2 * nIntervals;
    meta.stepSize = coarseMeta.stepSize;
    meta.coarseSolution = uCoarse;
    meta.fineSolutionAtCoarseNodes = uFineAtCoarse;
    meta.coarseSolver = coarseMeta;
    meta.fineSolver = fineMeta;
end
