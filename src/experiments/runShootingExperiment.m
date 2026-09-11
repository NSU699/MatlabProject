function runShootingExperiment()
% runShootingExperiment  生成打靶法与有限差分/解析解的原始交叉验证数据
%
%   本阶段只计算并保存原始节点数据，不拟合收敛阶、不生成图像。
%   后续分析和生图阶段从 results/poisson_shooting_raw.mat 读取这些数据。

    projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    addpath(genpath(fullfile(projectRoot, 'src')));
    resultsFolder = fullfile(projectRoot, 'results');
    if ~exist(resultsFolder, 'dir'), mkdir(resultsFolder); end

    nIntervalsList = [8, 16, 32, 64, 128, 256, 512].';
    sourceFun = @(x) exp(-x.^2);
    boundaryValues = [0, 0];
    xSpan = [-1, 1];
    rawSolutions = cell(numel(nIntervalsList), 1);

    for iGrid = 1:numel(nIntervalsList)
        nIntervals = nIntervalsList(iGrid);
        [x, uShoot, shootingMeta] = solvePoissonShooting( ...
            nIntervals, sourceFun, boundaryValues, xSpan);
        [xFd, uFd, fdMeta] = solvePoissonFD( ...
            nIntervals, sourceFun, boundaryValues, xSpan);
        uExact = poissonExact(x);
        assert(isequal(x, xFd), '打靶法与有限差分节点不一致。');

        pointTable = table(x, uShoot, uFd, uExact, uShoot - uExact, ...
            uFd - uExact, uShoot - uFd, ...
            'VariableNames', {'x', 'uShooting', 'uFiniteDifference', ...
            'uExact', 'shootingMinusExact', 'finiteDifferenceMinusExact', ...
            'shootingMinusFiniteDifference'});
        csvPath = fullfile(resultsFolder, sprintf( ...
            'poisson_shooting_n%03d_raw.csv', nIntervals));
        writetable(pointTable, csvPath);

        solution = struct();
        solution.nIntervals = nIntervals;
        solution.x = x;
        solution.uShooting = uShoot;
        solution.uFiniteDifference = uFd;
        solution.uExact = uExact;
        solution.shootingMeta = shootingMeta;
        solution.finiteDifferenceMeta = fdMeta;
        solution.csvPath = csvPath;
        rawSolutions{iGrid} = solution;
    end

    save(fullfile(resultsFolder, 'poisson_shooting_raw.mat'), ...
        'nIntervalsList', 'rawSolutions', 'xSpan', 'boundaryValues');
    fprintf('打靶法原始交叉验证数据已保存到 results/。\n');
end
