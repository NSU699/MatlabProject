function testSummary = runAllTests()
% runAllTests  运行阶段 4 公共工具层的基础测试
%
%   testSummary = runAllTests()
%   当前阶段验证公共层接口；后续实现第 15、16 题算法后，在本入口中
%   继续加入差分格式、RK4、制造解、稳定性和打靶法测试。
%
%   对应项目阶段: 第 4 阶段
%   作者: 项目成员   日期: 2026-09-08

    testsRoot = fileparts(mfilename('fullpath'));
    projectRoot = fileparts(fileparts(testsRoot));
    addpath(fullfile(projectRoot, 'src', 'common'));

    testNames = {'errorNorms', 'computeOrder', 'applyFigureStyle', 'exportFigure'};
    testSummary = struct('passed', false, 'tests', {testNames}, 'message', '');
    temporaryFolder = tempname;
    mkdir(temporaryFolder);
    cleanupObject = onCleanup(@() cleanupTemporaryFolder(temporaryFolder)); %#ok<NASGU>

    try
        metrics = errorNorms([1; 3], [0; 4]);
        assert(abs(metrics.maxAbs - 1) < 10 * eps, '最大绝对误差计算错误。');
        assert(abs(metrics.l2 - sqrt(2)) < 10 * eps, '二范数计算错误。');
        assert(abs(metrics.rms - 1) < 10 * eps, '均方根误差计算错误。');
        assert(abs(metrics.relativeInf - 0.25) < 10 * eps, '相对无穷范数计算错误。');
        assertThrows(@() errorNorms([1; 2], 1), 'errorNorms 尺寸校验未生效。');
        fprintf('[通过] errorNorms\n');

        stepSizes = [1; 0.5; 0.25; 0.125];
        errors = stepSizes .^ 2;
        orderInfo = computeOrder(stepSizes, errors);
        assert(max(abs(orderInfo.pairwiseOrder - 2)) < 10 * eps, '比值法估阶错误。');
        assert(abs(orderInfo.fitOrder - 2) < 10 * eps, '最小二乘估阶错误。');
        assertThrows(@() computeOrder(stepSizes, [1; 0; 0.1; 0.01]), 'computeOrder 正数校验未生效。');
        fprintf('[通过] computeOrder\n');

        figHandle = figure('Visible', 'off');
        axHandle = axes('Parent', figHandle);
        plot(axHandle, 0:1, 0:1, 'LineWidth', 1.5);
        applyFigureStyle(figHandle, axHandle);
        assert(strcmp(get(axHandle, 'FontName'), '宋体'), '中文字体设置错误。');
        assert(abs(get(axHandle, 'LineWidth') - 1.5) < 10 * eps, '线宽设置错误。');
        close(figHandle);
        fprintf('[通过] applyFigureStyle\n');

        figHandle = figure('Visible', 'off');
        axes('Parent', figHandle);
        exportInfo = exportFigure(figHandle, fullfile(temporaryFolder, 'common_test'));
        assert(exist(exportInfo.pngPath, 'file') == 2, 'PNG 文件未生成。');
        assert(exist(exportInfo.pdfPath, 'file') == 2, 'PDF 文件未生成。');
        close(figHandle);
        fprintf('[通过] exportFigure\n');

        testSummary.passed = true;
        testSummary.message = '阶段 4 公共层测试全部通过。';
        fprintf('%s\n', testSummary.message);
    catch testError
        testSummary.message = testError.message;
        fprintf(2, '[失败] %s\n', testError.message);
        rethrow(testError);
    end
end

function cleanupTemporaryFolder(temporaryFolder)
    if exist(temporaryFolder, 'dir')
        rmdir(temporaryFolder, 's');
    end
end

function assertThrows(functionHandle, failureMessage)
    didThrow = false;
    try
        functionHandle();
    catch
        didThrow = true;
    end
    assert(didThrow, failureMessage);
end
