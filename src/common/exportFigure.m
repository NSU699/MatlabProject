function exportFigure(figHandle, outputStem)
% exportFigure  将图窗以 300 dpi PNG 和矢量 PDF 同时导出
%
%   exportFigure(figHandle, outputStem)
%   outputStem 不带扩展名，例如 fullfile(root, 'figures', 'poisson_error')。
%
%   对应项目阶段: 第 4 阶段；供后续全部实验图表调用
%   作者: 项目成员   日期: 2026-09-08

    if ~isgraphics(figHandle, 'figure')
        error('exportFigure:InvalidFigure', 'figHandle 必须是有效的图窗句柄。');
    end
    outputStem = char(outputStem);
    if isempty(outputStem)
        error('exportFigure:InvalidPath', '输出文件路径不能为空。');
    end

    [outputFolder, outputName, outputExtension] = fileparts(outputStem);
    if ~isempty(outputExtension)
        error('exportFigure:InvalidExtension', 'outputStem 不应包含文件扩展名。');
    end
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
