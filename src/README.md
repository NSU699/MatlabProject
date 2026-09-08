# MATLAB 数值实验程序结构与接口约定

本目录对应项目实施步骤第 3 阶段，固定算法函数、实验脚本和公共工具层之间的边界。算法函数只负责计算，实验脚本负责组织参数、绘图、保存结果，公共层负责复用的误差、阶数、样式和导出逻辑。

## 目录职责

```text
src/
├─ common/   两题共用的样式、误差、收敛阶和图表导出工具
├─ poisson/  第 15 题的有限差分、精确解、制造解和打靶法
├─ ode/      第 16 题的固定步长 ODE 求解器和符号解
└─ tests/    公共层与算法验收测试
```

项目根目录的 `runAll.m` 负责一次性配置路径、运行实验并将数据写入 `results/`、图表写入 `figures/`。`tmp/` 仅用于中间文件，不作为正式结果来源。

## 核心接口

```matlab
[x, uNum, meta] = solvePoissonFD(nIntervals, sourceFun, boundaryValues, xSpan)
[t, yNum, meta] = rk4Solve(odeFun, tSpan, y0, nSteps)
[t, yNum, meta] = eulerSolve(odeFun, tSpan, y0, nSteps)
[t, yNum, meta] = rk2Solve(odeFun, tSpan, y0, nSteps)
```

`sourceFun`、`odeFun` 使用 MATLAB 函数句柄；`y0` 支持标量或列向量；`meta` 保存步长和可供验证使用的诊断信息。第 15 题接口保留默认参数，以支持 `solvePoissonFD(N)` 的基本调用，同时允许制造解和非零边界测试传入一般参数。

公共层接口见 `common/` 内各函数的文件头注释。全项目统一使用 `N` 表示区间等分数、`h` 表示步长、`uNum`/`yNum` 表示数值解、`uExact`/`yExact` 表示精确解。

