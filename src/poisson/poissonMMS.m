function [mmsExact, mmsSource, mmsBoundary] = poissonMMS()
% poissonMMS  返回用于验证二阶差分格式的制造解及其源项
%   制造解为 (1-x^2)sin(pi*x)，边界值为零。
    mmsExact = @(x) (1 - x.^2) .* sin(pi .* x);
    mmsSource = @(x) -2 .* sin(pi .* x) - 4 .* pi .* x .* cos(pi .* x) - pi^2 .* (1 - x.^2) .* sin(pi .* x);
    mmsBoundary = [0, 0];
end
