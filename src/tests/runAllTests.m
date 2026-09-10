function runAllTests()
% runAllTests  运行阶段 4 公共工具层的基础测试
%
%   runAllTests()
%   当前阶段验证公共层接口；后续实现第 15、16 题算法后，在本入口中
%   继续加入差分格式、RK4、制造解、稳定性和打靶法测试。
%
%   对应项目阶段: 第 4 阶段
%   作者: 项目成员   日期: 2026-09-08

    testsRoot = fileparts(mfilename('fullpath'));
    projectRoot = fileparts(fileparts(testsRoot));
    addpath(fullfile(projectRoot, 'src', 'common'));
    addpath(fullfile(projectRoot, 'src', 'poisson'));
    addpath(fullfile(projectRoot, 'src', 'ode'));

    temporaryFolder = tempname;
    mkdir(temporaryFolder);

    [maxError, l2Error, rmsError] = errorNorms([1; 3], [0; 4]);
    assert(abs(maxError - 1) < 10 * eps, '最大绝对误差计算错误。');
    assert(abs(l2Error - sqrt(2)) < 10 * eps, '二范数计算错误。');
    assert(abs(rmsError - 1) < 10 * eps, '均方根误差计算错误。');
    fprintf('[通过] errorNorms\n');

    stepSizes = [1; 0.5; 0.25; 0.125];
    errorValues = stepSizes .^ 2;
    [pairwiseOrder, fittedOrder] = computeOrder(stepSizes, errorValues);
    assert(max(abs(pairwiseOrder - 2)) < 10 * eps, '比值法估阶错误。');
    assert(abs(fittedOrder - 2) < 10 * eps, '最小二乘估阶错误。');
    fprintf('[通过] computeOrder\n');

    figHandle = figure('Visible', 'off');
    axHandle = axes('Parent', figHandle);
    plot(axHandle, 0:1, 0:1, 'LineWidth', 1.5);
    applyFigureStyle(axHandle);
    assert(strcmp(get(axHandle, 'FontName'), '宋体'), '中文字体设置错误。');
    fprintf('[通过] applyFigureStyle\n');

    outputStem = fullfile(temporaryFolder, 'common_test');
    exportFigure(figHandle, outputStem);
    assert(exist([outputStem, '.png'], 'file') == 2, 'PNG 文件未生成。');
    assert(exist([outputStem, '.pdf'], 'file') == 2, 'PDF 文件未生成。');
    close(figHandle);
    rmdir(temporaryFolder, 's');
    fprintf('[通过] exportFigure\n');

    [x, uNum, meta] = solvePoissonFD(16);
    assert(numel(x) == 17 && numel(uNum) == 17, '泊松解向量长度错误。');
    assert(issparse(meta.matrix), '差分矩阵未使用稀疏存储。');
    assert(norm(meta.linearResidual, inf) < 1e-10, '线性系统残差过大。');
    h = meta.stepSize;
    differenceResidual = (uNum(1:end-2) - 2 * uNum(2:end-1) + uNum(3:end)) / h^2 ...
        - exp(-x(2:end-1).^2);
    assert(norm(differenceResidual, inf) < 1e-10, '差分方程残差过大。');
    assert(norm([uNum(1); uNum(end)], inf) < 1e-14, '边界残差过大。');
    fprintf('[通过] solvePoissonFD 三种残差\n');

    assert(max(abs(poissonExact([-1; 1]))) < 1e-14, '解析解边界值错误。');
    [mmsExact, mmsSource, mmsBoundary] = poissonMMS();
    [xMms, uMms] = solvePoissonFD(16, mmsSource, mmsBoundary, [-1, 1]);
    % n=16 时该制造解的实际最大误差约为 0.02142，保留适度裕量。
    assert(max(abs(uMms - mmsExact(xMms))) < 0.025, 'MMS 基本误差异常。');
    fprintf('[通过] poissonExact 与 MMS 基本检验\n');

    nList = [8, 16, 32, 64];
    errors = zeros(size(nList));
    steps = zeros(size(nList));
    for k = 1:numel(nList)
        [xGrid, uGrid, gridMeta] = solvePoissonFD(nList(k));
        errors(k) = max(abs(uGrid - poissonExact(xGrid)));
        steps(k) = gridMeta.stepSize;
    end
    [~, exactOrder] = computeOrder(steps, errors);
    assert(exactOrder > 1.7 && exactOrder < 2.3, '第15题精确解观测阶不接近2。');
    fprintf('[通过] 第15题精确解观测阶 = %.4f\n', exactOrder);

    [xRichardson, uRichardson, richardsonMeta] = richardsonExtrapolatePoisson(16);
    assert(numel(xRichardson) == 17 && numel(uRichardson) == 17, ...
        'Richardson 外推解向量长度错误。');
    assert(richardsonMeta.coarseN == 16 && richardsonMeta.fineN == 32, ...
        'Richardson 粗细网格参数错误。');
    assert(max(abs(uRichardson - poissonExact(xRichardson))) < 2e-4, ...
        'Richardson 外推误差异常。');
    fprintf('[通过] Richardson 外推基本检验\n');

    richardsonErrors = zeros(size(nList));
    for k = 1:numel(nList)
        [xGrid, uGrid] = richardsonExtrapolatePoisson(nList(k));
        richardsonErrors(k) = max(abs(uGrid - poissonExact(xGrid)));
    end
    [~, richardsonOrder] = computeOrder(steps, richardsonErrors);
    assert(richardsonOrder > 3.4 && richardsonOrder < 4.6, ...
        'Richardson 外推观测阶不接近4。');
    fprintf('[通过] Richardson 外推观测阶 = %.4f\n', richardsonOrder);

    mmsErrors = zeros(size(nList));
    for k = 1:numel(nList)
        [xGrid, uGrid] = solvePoissonFD(nList(k), mmsSource, mmsBoundary, [-1, 1]);
        mmsErrors(k) = max(abs(uGrid - mmsExact(xGrid)));
    end
    [~, mmsOrder] = computeOrder(steps, mmsErrors);
    assert(mmsOrder > 1.7 && mmsOrder < 2.3, 'MMS 观测阶不接近2。');
    fprintf('[通过] MMS 观测阶 = %.4f\n', mmsOrder);
    [ySym, yExact, symbolicCheck] = ivpExactSymbolic(); %#ok<ASGLU>
    assert(symbolicCheck.passed, '符号解判零失败。');
    rhs = @(t, y) -y + t.^2 + 3;
    [tRk, yRk, rkMeta] = rk4Solve(rhs, [0, 3], 1, 24);
    assert(abs(yRk(1) - 1) < 1e-14 && all(isfinite(yRk(:))), 'RK4 初值或有限性检查失败。');
    assert(abs(yRk(end) - yExact(3)) < 1e-5 && rkMeta.functionEvaluations == 96, 'RK4 结果异常。');
    [~, yVector, ~] = rk4Solve(@(t, y) [y(2); -y(1)], [0, 1], [1; 0], 16);
    assert(size(yVector, 2) == 2 && all(isfinite(yVector(:))), 'RK4 向量状态检查失败。');
    [~, yEuler, eulerMeta] = eulerSolve(rhs, [0, 3], 1, 24);
    [~, yRk2, rk2Meta] = rk2Solve(rhs, [0, 3], 1, 24);
    assert(all(isfinite([yEuler(:); yRk2(:)])), 'Euler/RK2 有限性检查失败。');
    assert(eulerMeta.functionEvaluations == 24 && ...
        rk2Meta.functionEvaluations == 48 && ...
        rkMeta.functionEvaluations == 96, ...
        'Euler/RK2/RK4 右端函数调用次数错误。');

    odeN = [12, 24, 48, 96].';
    odeH = 3 ./ odeN;
    odeSolvers = {@eulerSolve, @rk2Solve, @rk4Solve};
    expectedOrders = [1, 2, 4];
    fittedOrders = zeros(size(expectedOrders));
    for iMethod = 1:numel(odeSolvers)
        maxErrors = zeros(size(odeN));
        for iGrid = 1:numel(odeN)
            [tGrid, yGrid] = odeSolvers{iMethod}(rhs, [0, 3], 1, odeN(iGrid));
            maxErrors(iGrid) = max(abs(yGrid(:, 1) - yExact(tGrid)));
        end
        [~, fittedOrders(iMethod)] = computeOrder(odeH, maxErrors);
    end
    orderTolerances = [0.30, 0.40, 0.50];
    assert(all(abs(fittedOrders - expectedOrders) < orderTolerances), ...
        'Euler/RK2/RK4 拟合阶未落在理论阶附近。');
    fprintf('[通过] Euler/RK2/RK4 函数调用次数与拟合阶检查\n');
    fprintf('        拟合阶：Euler %.4f，RK2 %.4f，RK4 %.4f\n', fittedOrders);
    fprintf('[通过] 第16题 RK4 向量状态、符号解、Euler/RK2 基础检查\n');
    fprintf('阶段 4 至 9 核心测试全部通过。\n');

end
