function exportFigure(figHandle, outputStem)
% exportFigure  将图窗以 300 dpi PNG 和矢量 PDF 同时导出
%
%   exportFigure(figHandle, outputStem)
%   outputStem 不带扩展名，例如 fullfile(root, 'figures', 'poisson_error')。

    outputStem = char(outputStem);

    [outputFolder, outputName, ~] = fileparts(outputStem);

    if isempty(outputFolder)
        outputFolder = pwd;
    end
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end

    outputStem = fullfile(outputFolder, outputName);
    exportgraphics(figHandle, [outputStem, '.png'], 'Resolution', 300);
    exportgraphics(figHandle, [outputStem, '.pdf'], 'ContentType', 'vector');
end
