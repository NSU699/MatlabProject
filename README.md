# MATLAB 数值计算专题项目

本仓库是课程第七类「数值计算问题」第 15、16 题的独立完成项目：第 15 题用二阶中心有限差分法求解一维泊松边值问题；第 16 题用自编固定步长经典 RK4 求解初值问题，并与符号解析解比较。所有误差、收敛阶、图表和结论都必须来自 MATLAB 实际运行结果，不能用估计值替代。

- 第 15 题：`u''(x) = exp(-x^2)`，`x ∈ [-1,1]`，`u(-1) = u(1) = 0`。
- 第 16 题：`y'(t) = -y(t) + t^2 + 3`，`t ∈ [0,3]`，`y(0) = 1`。

## 目录

```text
.
├── runAll.m                 唯一的一键运行入口，包含两题实验编排
├── README.md                项目说明、进度、索引与统一约定
├── src/                     算法函数、公共工具和测试
│   ├── common/              误差、观测阶、绘图样式与导出
│   ├── poisson/             第 15 题有限差分、解析解与制造解
│   ├── ode/                 第 16 题 ODE 求解器与符号解
│   ├── experiments/         正式实验、分析和图表生成函数
│   └── tests/               公共层及两题核心验收测试
├── results/                 可复核的实验数据（MAT、CSV）
├── figures/                 报告/PPT 使用的图（PNG、PDF）
├── 报告/                    开题方案、推导、报告模板和报告材料
├── ppt/                     汇报 PPT 及讲稿（完成后放入）
├── Reference/               参考教材
├── AGENT.md                 仓库协作与代码约定
├── LICENSE                  版权与使用范围
├── 大作业提交验收规则-2026.pdf  只读课程验收要求
├── Matlab实践项目-Final-2026.pdf  只读题目与考核要求
└── tmp/                     本地临时文件，不纳入 Git
```

## 入口与脚本索引

[`runAll.m`](runAll.m) 是当前唯一总入口（仓库中没有 `runAll.md`）。它先执行 `clear; clc; close all;`，按自身位置定位仓库、配置 `src/` 路径，再依次运行第 15 题和第 16 题基础实验、误差分析、Richardson 外推、打靶法交叉验证、正式收敛实验、Euler/RK2/RK4 正式横向比较和补充图表生成。`runAll.m` 不调用测试函数；测试请单独运行 `src/tests/runAllTests.m`。

第 15 题调用 `src/poisson/solvePoissonFD.m`、`poissonExact.m`，基础网格为 `N = 8,16,32,64,128,256`；第 16 题基础实验调用 `src/ode/ivpExactSymbolic.m` 和 `rk4Solve.m`，步数为 `N = 6,12,24,48`。三方法比较统一使用 `N = 6,12,24,48,96,192,384`。两题均通过公共工具统一样式并导出图片。具体产物见下表。

根目录只保留 `runAll.m` 作为程序入口；基础实验函数和其余实验/分析函数统一位于 `src/experiments/`。`src/` 中现有 `.m` 文件均为函数文件，不是需要顺序手工运行的脚本。所有实验分析函数均已由 `runAll.m` 调用，单独运行仅用于定位问题或复核局部结果。

### `src/` 函数索引

| 路径 | 作用 | 被谁调用 |
|---|---|---|
| `src/poisson/solvePoissonFD.m` | 泊松有限差分、边界修正、稀疏线性系统求解 | `runAll.m`、测试 |
| `src/poisson/solvePoissonShooting.m` | 第 15 题线性打靶法，复用向量 RK4 | `runShootingExperiment.m`、测试 |
| `src/poisson/richardsonExtrapolatePoisson.m` | 组合 N 与 2N 网格解，输出粗网格节点上的四阶 Richardson 外推解 | `runRichardsonExperiment.m`、测试 |
| `src/experiments/runCoreExperiments.m` | 生成两题基础数据和基础图表 | `runAll.m` |
| `src/experiments/runRichardsonFigures.m` | 读取 Richardson 试验 CSV，生成误差收敛、观测阶和点态误差图 | `runAll.m` |
| `src/experiments/runOdeMethodComparison.m` | 三方法精度、阶数、函数调用次数及七次重复计时的正式比较 | `runAll.m` |
| `src/poisson/poissonExact.m` | 第 15 题解析解 | `runAll.m`、测试、打靶交叉验证 |
| `src/poisson/poissonMMS.m` | 制造解、源项和边界值 | 测试 |
| `src/ode/rk4Solve.m` | 向量状态经典四阶 RK4 | `runAll.m`、测试 |
| `src/ode/eulerSolve.m` | 固定步长显式 Euler | `runOdeMethodComparison.m`、测试 |
| `src/ode/rk2Solve.m` | Heun 型二阶 RK | `runOdeMethodComparison.m`、测试 |
| `src/ode/ivpExactSymbolic.m` | `dsolve` 解析解、手推式判零、函数句柄 | `runAll.m`、测试 |
| `src/common/applyFigureStyle.m` | 图窗白底、尺寸、宋体、字号和网格等统一样式 | 两题实验和测试 |
| `src/common/errorNorms.m` | 最大绝对误差、误差二范数、均方根误差 | 测试、正式收敛实验 |
| `src/common/computeOrder.m` | 相邻比值法和对数最小二乘拟合观测阶 | 测试、正式收敛实验 |
| `src/common/exportFigure.m` | 同时导出 300 dpi PNG 与矢量 PDF | 两题实验和测试 |
| `src/tests/runAllTests.m` | 项目基础验收测试，无输出参数 | 手动运行 |

`src/experiments/runShootingExperiment.m` 当前生成打靶法、有限差分和解析解的原始节点数据；`src/experiments/runShootingAnalysis.m` 读取这些原始数据，生成误差汇总、分析附录、对比图和收敛图。两者均由 `runAll.m` 自动调用。

表中“测试”均指 `runAllTests.m`。Euler、RK2、RK4 已完成函数调用次数、拟合阶和正式横向比较；打靶法程序、分析和生图均已接入总入口。ODE 文件内的 `prepareOdeGrid`、`checkedOdeSlope` 等局部函数只供所在文件内部使用，无须另建或单独运行。

### 核心接口与数据约定

以下内容由原 `src/README.md` 迁移，并按当前代码校正：

```matlab
[x, uNum, meta] = solvePoissonFD(nIntervals, sourceFun, boundaryValues, xSpan)
[x, uNum, meta] = solvePoissonShooting(nIntervals, sourceFun, boundaryValues, xSpan)
uExact = poissonExact(x)
[mmsExact, mmsSource, mmsBoundary] = poissonMMS()
[t, yNum, meta] = rk4Solve(odeFun, tSpan, y0, nSteps)
[t, yNum, meta] = eulerSolve(odeFun, tSpan, y0, nSteps)
[t, yNum, meta] = rk2Solve(odeFun, tSpan, y0, nSteps)
[ySym, yExact, verification] = ivpExactSymbolic()

applyFigureStyle(axHandle)
[maxError, l2Error, rmsError] = errorNorms(numericalValues, exactValues)
[pairwiseOrder, fittedOrder] = computeOrder(stepSizes, errorValues)
exportFigure(figHandle, outputStem)
runAllTests()
```

- 算法函数只负责计算；入口负责参数、调用、绘图和保存；公共层负责可复用工具。新增实验继续从 `runAll.m` 接入。
- 数学记号统一用 `N` 表示区间等分数、`h` 表示步长，数值解用 `uNum`/`yNum`，精确解用 `uExact`/`yExact`。代码中泊松等分数为 `nIntervals`，ODE 步数为 `nSteps`，均产生 `N+1` 个节点。
- `solvePoissonFD(N)` 默认解第 15 题；省略全部参数时默认 `N=32`。`sourceFun` 是支持内部节点向量输入的函数句柄；`boundaryValues` 按左、右端排序，`xSpan` 为递增区间。`x`、`uNum` 为列向量，`meta` 含步长、稀疏矩阵、右端项、线性残差和 `condest` 估计等诊断量。可传入一般源项和非零边界；现有测试尚未专门覆盖非零边界情形。
- ODE 求解器接收 `odeFun(t,y)`，内部状态为列向量；`y0` 支持标量或向量，`t` 为时间列向量，`yNum` 每行一个节点、每列一个分量。`meta` 含步长、步数、方法名与右端函数调用次数。RK4 的四个 `k` 是不含步长 `h` 的斜率。
- `ivpExactSymbolic` 用 `dsolve`、`matlabFunction` 求解并检验手推差、方程残差和初值残差；`verification.passed` 为判零结果。缺少符号工具箱时明确报错，不会自动切换为显式公式并声称符号验证通过。
- `errorNorms` 要求两个输入尺寸相同；`l2Error` 是未乘网格权重的向量二范数，不是连续积分意义的 L2 范数。
- `computeOrder` 要求正步长和正误差数据；相邻比值法给出 `pairwiseOrder`，对数拟合给出 `fittedOrder`。进入舍入误差区间后，由实验调用方先选取拟合数据，工具函数不自动筛选。
- `applyFigureStyle` 省略参数时使用当前坐标轴；`exportFigure` 的 `outputStem` 不带扩展名。单个函数参数细节见相应文件头和实现。

### 结果与图表索引

下列产物由表中脚本生成；重新运行会覆盖同名文件。`NNN` 为三位等分数，如 `008`、`016`、`256`。

| 产物 | 生成脚本 | 内容与取数方式 |
|---|---|---|
| `results/poisson_nNNN_points.csv`、`poisson_nNNN.mat` | `runAll.m` | 各网格节点表和包含诊断量的 `solution` 结构体 |
| `results/poisson_all_solutions.mat` | `runAll.m` | `nIntervalsList`、稠密解析解及全部网格解 |
| `figures/poisson_compare_nNNN.*`、`poisson_grid_convergence.*` | `runAll.m` | 单网格及多网格数值解与解析解对比；多网格总览不是误差收敛图 |
| `results/ode_experiment.mat`、`figures/ode_rk4_basic.*` | `runAll.m` | RK4 基础实验、符号解析解检查和逐节点绝对误差 |
| `results/poisson_convergence.csv`、`results/ode_convergence.csv` | `src/experiments/runConvergenceExperiment.m` | 两题长步长序列的最大误差、RMS 误差、相邻阶、拟合阶和 `timeit` 耗时 |
| `results/poisson_richardson_summary.csv`、`results/poisson_richardson_experiment.mat` | `src/experiments/runRichardsonExperiment.m` | 第15题二阶有限差分与 Richardson 外推的误差、观测阶和逐网格完整结果 |
| `results/ode_method_comparison.csv`、`ode_method_timing_raw.csv`、`ode_method_comparison.mat` | `src/experiments/runOdeMethodComparison.m` | 三方法 21 组精度/阶数/工作量汇总、147 个原始计时样本和环境信息 |
| `results/poisson_shooting_nNNN_raw.csv`、`poisson_shooting_raw.mat` | `src/experiments/runShootingExperiment.m` | 打靶法、有限差分、解析解逐节点原始值及两两差值 |
| `results/poisson_shooting_analysis_summary.csv`、`poisson_shooting_analysis.mat` | `src/experiments/runShootingAnalysis.m` | 三组误差范数、相邻观测阶、拟合阶和边界残差 |
| `results/poisson_shooting_analysis_report.md`、`poisson_shooting_stats_appendix.md`、`poisson_shooting_figure_catalog.md` | `src/experiments/runShootingAnalysis.m` | 分析问题、证据边界、统计限制、图表用途和解释检查项 |
| `figures/poisson_convergence_formal.*`、`ode_rk4_convergence_formal.*` | `src/experiments/runConvergenceExperiment.m` | 两题双对数误差图及理论阶参考线 |
| `figures/ode_methods_convergence.*`、`ode_methods_work_precision.*`、`ode_methods_runtime_precision.*`、`ode_methods_timing_variability.*` | `src/experiments/runOdeMethodComparison.m` | 三方法收敛阶、函数调用次数工作量、实测时间—精度和计时波动图 |
| `results/poisson_analysis_summary.csv`、`figures/poisson_solution_panels.png`、`poisson_error_convergence.png`、`poisson_pointwise_error.png`、`poisson_residuals.png` | `src/experiments/runPoissonAnalysis.m` | 第 15 题全局误差、加权离散 L2 误差、代数残差、截断残差、条件数估计及分析图 |
| `figures/poisson_shooting_comparison.*`、`poisson_shooting_convergence.*` | `src/experiments/runShootingAnalysis.m` | 代表网格三方解/点态误差对比，以及三组误差收敛和相邻观测阶 |
| `figures/ode_rk4_solution_comparison.*`、`ode_rk4_signed_error.*`、`ode_rk4_scaled_error.*`、`ode_rk4_convergence.*`、`ode_rk4_observed_order.*`、`ode_rk4_work_precision.*` | `src/experiments/runOdeFigureAnalysis.m` | 第 16 题解对比、有符号误差、四阶归一化误差、收敛阶和函数调用次数工作量分析 |

`src/experiments/runPoissonAnalysis.m` 当前只导出 PNG；其余表中带 `.*` 的图均有 PNG/PDF。第 16 题基础节点结果保存在 MAT 中，正式收敛汇总另有 CSV。

### 文档索引

- [开题方案定稿（HTML）](报告/第七类-第15-16题-开题方案(定稿).html)：原 18 阶段实施表和理论/实验规划；另有同目录定稿 PDF。历史方案保留，不当作当前实现清单。
- [开题方案修订版（Markdown）](报告/第七类-第15-16题-开题方案-修订版.md)：可检索的方案文字；其中旧 `CLAUDE.md` 引用不代表当前协作入口。
- [手工推导与程序讲解](报告/第七类-第15-16题-手工推导.md)：两题公式、手算例子与代码思路；另有同名 PDF。
- 根目录两份课程 PDF 是题目、验收要求的只读来源；`报告/` 中的 DOCX 模板是后续正式报告基础。本次未改动或重新审阅这些 PDF/DOCX。
- `Reference/` 保存参考教材，`ppt/` 尚无正式汇报材料；参考资料、历史方案和临时文件都不能代替脚本结果。

## 当前进度（截至 2026-09-11）

### 今日工作总结

- 完成仓库脚手架整理，并建立本地 `.vscode/settings.json`；该目录受 `.gitignore` 管理，不进入版本库。
- 完成第 15 题有限差分求解、解析解、制造解和结果分析；已生成多网格解、误差/残差汇总及相关图表。
- 完成第 16 题固定步长 Euler、RK2、经典 RK4 和符号解析解函数；已生成 RK4 基础结果及六类补充分析图。
- 扩充公共误差、观测阶、绘图和导出工具及验收测试，并把两题基础实验与正式收敛实验接入 `runAll.m`。
- 完成两题正式收敛 CSV 与双对数图。当前 CSV 记录的最大误差拟合阶分别为 `2.002502`（有限差分）和 `4.036671`（RK4），与理论二阶、四阶一致。
- 完成 Euler/RK2/RK4 正式横向比较。最大误差拟合阶为 `1.018057`、`2.046956`、`4.036671`；每个方法和步数组合进行了 7 次独立 `timeit`，原始值与汇总统计均已保存。
- 整理手工推导 MD/PDF、参考教材、统一约定和项目索引；原 `src/README.md` 的有效内容已迁入本文。
- 完成第 15 题线性打靶法程序与原始交叉验证数据导出；本轮按“两步执行”约定暂不做打靶法数据分析和生图。

总体判断：两题核心算法、基础验证、单次实验、正式收敛实验、Euler/RK2/RK4 横向比较，以及打靶法程序与原始数据已形成可复核基础；打靶法分析/生图、报告、PPT、视频和最终提交验收仍未完成。阶段编号沿用开题方案，按当前文件与结果逐项记录如下。

| 阶段 | 当前状态 | 对应依据或待补项 |
|---|---|---|
| 1. 冻结需求 | 已整理 | 题目、区间、初边值及提交要求已记载；本次未重做原题 PDF 逐字/截图验收 |
| 2. 手工推导 | 基础推导已整理 | 手工推导 MD/PDF 已有两题解析解、差分与 RK4、手算例子；条件数闭式、稳定域边界的详细推导验收仍待补齐 |
| 3. 设计接口 | 已完成并更新索引 | 本文接口与调用关系；`runAll.m` 统一编排，算法独立成函数 |
| 4. 公共层 | 已实现，现有测试通过 | 四个 `src/common/` 工具 |
| 5. 第 15 题核心 | 已实现并验证 | 稀疏中心差分、边界修正与求解已测；`runPoissonAnalysis.m` 已独立计算解析解代入差分算子的截断残差及其观测阶 |
| 6. 第 15 题验证 | 现有验证通过 | `poissonExact`、`poissonMMS`；测试包含两类最大误差的二阶拟合检查 |
| 7. 第 16 题核心 | 已实现并通过当前验收 | 自编 RK4/Euler/RK2；函数调用次数和拟合阶已测；未用 `ode45` 替代 |
| 8. 第 16 题符号解 | 已实现，符号检验通过 | `ivpExactSymbolic` 三项判零 |
| 9. 单次实验 | 已完成，视觉验收待补 | 两题基础产物、泊松点态误差图和 RK4 多类误差分析图均已存在；尚未逐张完成视觉检查 |
| 10. 收敛实验 | 已完成 | 两题各 7 级步长序列、误差 CSV、比值法/拟合法双估阶、`timeit` 耗时及带理论参考线的 `loglog` 图均已生成 |
| 11. U 形曲线 | 暂缓 | 舍入平台问题先搁置，待与指导老师商议；若后续保留，考虑放在论文偏后部分作为补充分析。已有 `meta.conditionEstimate`，相关实验目前不纳入近期实施范围 |
| 12. 稳定域实验 | 暂缓 | 稳定域问题先搁置，待与指导老师商议后再决定是否开展；在本人明确说明前，不纳入论文内容 |
| 13. 阶数与效率 | 已完成 | 三方法统一使用 7 级步数，拟合阶分别为 `1.018057`、`2.046956`、`4.036671`；保存函数调用次数、7 次重复 `timeit` 原始值/汇总表及四组 PNG/PDF 图 |
| 14. 打靶法 | 程序、原始数据、分析和生图已完成 | `solvePoissonShooting.m`、`runShootingExperiment.m`、`runShootingAnalysis.m`；三方误差与收敛证据已保存 |
| 15. 结果解释 | 分析附录已完成，报告正文待写 | `results/poisson_shooting_analysis_report.md` 已记录允许表述、限制和下一步检查 |
| 16. 整理成果 | 部分基础已有 | 总入口与基础图/数据导出已有；全部扩展实验的可复现打包仍待完成 |
| 17. 报告与 PPT | 待完成 | 已有模板/方案/推导，不等于正式结题报告与汇报 PPT |
| 18. 视频与验收 | 待完成 | 视频、彩排、提交包和最终验收 |

验证记录：2026-09-10 在 MATLAB `26.1 (R2026a)`、`PCWIN64` 上实际运行完整 `runAll.m`，公共工具、泊松/MMS/Richardson、ODE 符号解、三方法调用次数和拟合阶断言均通过，随后成功生成横向比较的 MAT、CSV、PNG/PDF。四张 `ode_methods_*` PNG 已逐张检查白底黑字、图例、端点留白和数据可辨识性。短步数算例为微秒级任务，最终结果中最高计时变异系数约为 `15.5%`；因此函数调用次数是更稳定的工作量指标，运行时间只代表本机本次会话。测试输出不直接抄入报告；正式实验数值须先保存到 `results/`。

注意：测试输出中的“第 15 题三种残差”是线性系统残差、数值解的差分方程残差和边界残差；独立的局部截断残差与全局误差分析见 `runPoissonAnalysis.m` 及其 CSV。三方法横向比较把“相同步长精度”“相同函数调用次数”和“本机实测时间”分开呈现，不能把单次或最粗网格计时解释为普遍性能结论。

稳定域问题备注：相关分析暂时搁置，待本人和指导老师商议后再决定后续安排。未经本人明确说明，论文中不得出现稳定域相关内容。

## 环境与运行

本次测试环境为 MATLAB R2026a Update 5，其他版本本次未验证。完整入口和现有测试都需要 MATLAB 图形功能及 Symbolic Math Toolbox；虽然数值求解器本身不依赖符号工具箱，但 `runAllTests` 也会调用符号验证。在 MATLAB 当前目录切换到仓库根目录后运行：

```matlab
runAll
```

单独运行测试：

```matlab
addpath(genpath(fullfile(pwd, 'src')));
runAllTests();
```

正式数据写入 `results/`，正式图表写入 `figures/`，临时文件写入 `tmp/`。每次应从清空工作区的 MATLAB 会话运行入口，以保持可复现性。

`runAllTests` 是无返回值函数，正常返回即通过，断言失败会报错；不要使用旧写法 `summary = runAllTests()`。其绘图导出测试使用系统临时目录，不覆盖正式图表。入口和测试中个别“仅公共层”的旧注释/提示尚未更新，实际覆盖范围以本索引和函数实现为准。

## 统一约定

根目录 `README.md` 是项目说明、进度、索引、接口及今后各种约定的统一维护位置。原 `src/README.md` 中仍有效的内容已迁入本文，旧文件删除，不再在子目录维护同类规范副本。新增或变更约定、文件职责、调用关系时，在同一次任务中同步更新本文。

`AGENT.md` 保留现有协作约束，并明确本统一维护规则；后续新增的一般项目约定写到本文，避免在多个文件重复维护。函数文件头继续记录自身输入输出和实现细节，报告继续记录推导与结果，不承担另立项目规则的作用。

- 中文注释、说明、输出与图表标签；英文代码标识符采用小驼峰。入口组织实验，核心算法独立成函数，保持本人可以逐行解释的复杂度。
- 参数集中、输入校验、入口自行配置路径；使用随机数时固定 `rng(42)`。新增脚本、算法结构变化、关键数值方法设计或大幅报告改写仍须先给具体方案并等本人确认。
- 使用统一绘图样式，图表导出 PNG/PDF；报告图注、表注记录生成脚本与运行日期。未来收敛图使用 `loglog` 并标出理论参考斜率。
- 每个正式结果必须先保存再引用；未经计算的结果标记 `TODO`。保留原始资料，不虚构成员、实验数字、引用或验收结论。完整项目交付仍遵守课程原始要求。

## 提交前检查

1. 在干净 MATLAB 会话中运行 `runAll`，确认测试和实验均通过。
2. 确认 `results/` 与 `figures/` 能由脚本重建，报告中的数值均有实际来源。
3. 检查报告、PPT、视频和压缩包符合课程验收规则。
4. 不提交 `tmp/`、崩溃转储、编辑器配置或个人凭据。
5. 作者、学号和团队信息由本人填写，不虚构成员或分工。

## 版权与使用范围

本仓库不是开源项目。仓库可见性仅用于课程提交、教师评阅、查重和归档，不代表作者向公众授予开源许可。除课程评阅所需的有限使用外，复制、修改、再分发、公开镜像和商业使用均需获得作者书面许可。具体条款见根目录 `LICENSE`。
