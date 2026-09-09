function uExact = poissonExact(x)
% poissonExact  第15题 u''=exp(-x^2)、零边界问题的解析解
    validateattributes(x, {'numeric'}, {'real', 'finite'});
    uExact = 0.5 .* exp(-x.^2) + 0.5 .* sqrt(pi) .* x .* erf(x) - 0.5 .* exp(-1) - 0.5 .* sqrt(pi) .* erf(1);
end
