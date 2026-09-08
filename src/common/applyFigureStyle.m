function [figHandle, axHandle] = applyFigureStyle(figHandle, axHandle, options)
% applyFigureStyle  应用项目统一的 MATLAB 图形样式
%
%   [figHandle, axHandle] = applyFigureStyle(figHandle, axHandle, options)
%   对指定图窗和坐标轴设置中文字体、字号、线宽、网格和配色。
%
%   输入:
%       figHandle - 图窗句柄；省略时使用当前图窗
%       axHandle  - 坐标轴句柄；省略时使用图窗当前坐标轴
%       options   - 可选结构体，字段包括 FontName、FontSize、
%                   LineWidth、ColorOrder、GridAlpha 和 FigureColor
%   输出:
%       figHandle - 实际使用的图窗句柄
%       axHandle  - 实际使用的坐标轴句柄
%
%   对应项目阶段: 第 3、4 阶段；供后续全部实验脚本调用
%   作者: 项目成员   日期: 2026-09-08

    if nargin < 1 || isempty(figHandle)
        figHandle = gcf;
    end
    if ~isgraphics(figHandle, 'figure')
        error('applyFigureStyle:InvalidFigure', 'figHandle 必须是有效的图窗句柄。');
    end

    if nargin < 2 || isempty(axHandle)
        axHandle = get(figHandle, 'CurrentAxes');
    end
    if isempty(axHandle) || ~isgraphics(axHandle, 'axes')
        error('applyFigureStyle:InvalidAxes', 'axHandle 必须是有效的坐标轴句柄。');
    end

    if nargin < 3 || isempty(options)
        options = struct();
    end
    if ~isstruct(options) || ~isscalar(options)
        error('applyFigureStyle:InvalidOptions', 'options 必须是标量结构体。');
    end

    defaults = struct( ...
        'FontName', '宋体', ...
        'FontSize', 11, ...
        'LineWidth', 1.5, ...
        'ColorOrder', [0.0000 0.4470 0.7410; ...
                       0.8500 0.3250 0.0980; ...
                       0.9290 0.6940 0.1250; ...
                       0.4940 0.1840 0.5560], ...
        'GridAlpha', 0.20, ...
        'FigureColor', 'w');

    optionNames = fieldnames(defaults);
    for nameIndex = 1:numel(optionNames)
        optionName = optionNames{nameIndex};
        if ~isfield(options, optionName) || isempty(options.(optionName))
            options.(optionName) = defaults.(optionName);
        end
    end

    validFontName = (ischar(options.FontName) && isrow(options.FontName) && ~isempty(options.FontName)) || ...
        (isstring(options.FontName) && isscalar(options.FontName) && strlength(options.FontName) > 0);
    if ~validFontName
        error('applyFigureStyle:InvalidFontName', 'options.FontName 必须是非空文本。');
    end
    validateattributes(options.FontSize, {'numeric'}, {'scalar', 'real', 'finite', 'positive'}, ...
        mfilename, 'options.FontSize');
    validateattributes(options.LineWidth, {'numeric'}, {'scalar', 'real', 'finite', 'positive'}, ...
        mfilename, 'options.LineWidth');
    validateattributes(options.GridAlpha, {'numeric'}, {'scalar', 'real', 'finite', '>=', 0, '<=', 1}, ...
        mfilename, 'options.GridAlpha');
    validateattributes(options.ColorOrder, {'numeric'}, {'2d', 'ncols', 3, 'real', 'finite', '>=', 0, '<=', 1}, ...
        mfilename, 'options.ColorOrder');

    set(figHandle, 'Color', options.FigureColor);
    set(axHandle, ...
        'FontName', char(options.FontName), ...
        'FontSize', options.FontSize, ...
        'LineWidth', options.LineWidth, ...
        'Box', 'on', ...
        'Layer', 'top', ...
        'ColorOrder', options.ColorOrder, ...
        'GridAlpha', options.GridAlpha);
    grid(axHandle, 'on');
end
