function [x, uRichardson, meta] = richardsonExtrapolatePoisson(nIntervals, sourceFun, boundaryValues, xSpan)
% richardsonExtrapolatePoisson  对二阶有限差分解进行 Richardson 外推
%
%   分别在 N 和 2N 个子区间上调用 solvePoissonFD，并在粗网格节点上计算
%   uRichardson = (4 * uFine - uCoarse) / 3，从而得到四阶近似。
%
%   输入:
%       nIntervals   - 粗网格区间等分数
%       sourceFun    - 方程 u''(x) = sourceFun(x) 的源项函数
%       boundaryValues - 左、右端点的 Dirichlet 边界值
%       xSpan        - 求解区间 [xLeft, xRight]
%   输出:
%       x             - 粗网格节点列向量
%       uRichardson   - 粗网格节点上的 Richardson 外推解
%       meta          - 粗细网格参数及外推前的两组节点值
%
%   对应报告: 第15题 Richardson 外推算法延伸
%   作者: 项目成员   日期: 2026-09-10

    if nargin < 1 || isempty(nIntervals), nIntervals = 32; end
    if nargin < 2 || isempty(sourceFun), sourceFun = @(x) exp(-x.^2); end
    if nargin < 3 || isempty(boundaryValues), boundaryValues = [0, 0]; end
    if nargin < 4 || isempty(xSpan), xSpan = [-1, 1]; end

    validateattributes(nIntervals, {'numeric'}, {'scalar', 'integer', '>=', 2});

    [x, uCoarse, coarseMeta] = solvePoissonFD( ...
        nIntervals, sourceFun, boundaryValues, xSpan);
    [xFine, uFine, fineMeta] = solvePoissonFD( ...
        2 * nIntervals, sourceFun, boundaryValues, xSpan);

    % 细网格的第 1、3、5、... 个元素与粗网格节点位于相同位置。
    uFineAtCoarse = uFine(1:2:end);
    xFineAtCoarse = xFine(1:2:end);
    if max(abs(xFineAtCoarse - x)) > 10 * eps(max(1, max(abs(x))))
        error('richardsonExtrapolatePoisson:GridMismatch', ...
            '粗网格节点与细网格重合节点不一致。');
    end

    uRichardson = (4 * uFineAtCoarse - uCoarse) / 3;

    meta.coarseN = nIntervals;
    meta.fineN = 2 * nIntervals;
    meta.stepSize = coarseMeta.stepSize;
    meta.coarseSolution = uCoarse;
    meta.fineSolutionAtCoarseNodes = uFineAtCoarse;
    meta.coarseSolver = coarseMeta;
    meta.fineSolver = fineMeta;
end
