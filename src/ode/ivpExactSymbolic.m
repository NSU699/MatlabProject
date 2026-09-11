function [ySym, yExact, verification] = ivpExactSymbolic()
% ivpExactSymbolic  求第16题符号解、生成数值句柄并做三项符号判零
%
%   题目固定为 y'=-y+t^2+3，y(0)=1。
%   输出: ySym 为符号表达式，yExact 为 matlabFunction 生成的函数句柄；
%         verification 保存手推差、方程残差、初值残差和代回的初值。
%   依赖 Symbolic Math Toolbox；缺失时明确报错，不冒充符号验证通过。

    syms t y(t)
    equation = diff(y, t) == -y + t^2 + 3;
    ySym = simplify(dsolve(equation, y(0) == 1));
    handDerived = t^2 - 2*t + 5 - 4*exp(-t);
    verification.handDerived = handDerived;
    verification.differenceResidual = simplify(ySym - handDerived);
    verification.equationResidual = simplify(diff(ySym, t) + ySym - t^2 - 3);
    verification.initialValue = simplify(subs(ySym, t, 0));
    verification.initialResidual = simplify(verification.initialValue - 1);
    residuals = [verification.differenceResidual, ...
        verification.equationResidual, verification.initialResidual];
    verification.passed = all(isAlways(residuals == 0, 'Unknown', 'false'));

    yExact = matlabFunction(ySym, 'Vars', t);
    verification.explicitFunction = @(time) time.^2 - 2*time + 5 - 4*exp(-time);
end
