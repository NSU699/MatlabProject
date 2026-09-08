function exportInfo = exportFigure(figHandle, outputStem, varargin)
% exportFigure  将图窗以 300 dpi PNG 和矢量 PDF 同时导出
%
%   exportInfo = exportFigure(figHandle, outputStem)
%   outputStem 不带扩展名，例如 fullfile(root, 'figures', 'poisson_error')。
%   也可通过名称-值参数指定 'Resolution'，默认值为 300 dpi。
%
%   输出字段:
%       pngPath    - PNG 文件路径
%       pdfPath    - PDF 文件路径
%       resolution - 使用的 PNG 分辨率
%
%   对应项目阶段: 第 4 阶段；供后续全部实验图表调用
%   作者: 项目成员   日期: 2026-09-08

    if ~isgraphics(figHandle, 'figure')
        error('exportFigure:InvalidFigure', 'figHandle 必须是有效的图窗句柄。');
    end
    if isstring(outputStem)
        if ~isscalar(outputStem)
            error('exportFigure:InvalidOutputStem', 'outputStem 必须是单个文件路径。');
        end
        outputStem = char(outputStem);
    end
    validateattributes(outputStem, {'char'}, {'row', 'nonempty'}, mfilename, 'outputStem', 2);

    parser = inputParser;
    parser.FunctionName = mfilename;
    addParameter(parser, 'Resolution', 300, @(value) isnumeric(value) && isscalar(value) && ...
        isfinite(value) && value > 0);
    parse(parser, varargin{:});
    resolution = parser.Results.Resolution;

    [outputFolder, outputName, outputExtension] = fileparts(outputStem);
    if ~isempty(outputExtension) && ~any(strcmpi(outputExtension, {'.png', '.pdf'}))
        error('exportFigure:InvalidExtension', 'outputStem 只能不带扩展名，或使用 .png/.pdf。');
    end
    if isempty(outputFolder)
        outputFolder = pwd;
    end
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end

    outputStem = fullfile(outputFolder, outputName);
    pngPath = [outputStem, '.png'];
    pdfPath = [outputStem, '.pdf'];

    if exist('exportgraphics', 'file') == 2
        exportgraphics(figHandle, pngPath, 'Resolution', resolution);
        exportgraphics(figHandle, pdfPath, 'ContentType', 'vector');
    else
        print(figHandle, pngPath, '-dpng', sprintf('-r%d', round(resolution)));
        print(figHandle, pdfPath, '-dpdf', '-painters');
    end

    exportInfo = struct('pngPath', pngPath, 'pdfPath', pdfPath, 'resolution', resolution);
end
