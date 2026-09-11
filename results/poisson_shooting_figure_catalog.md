# 打靶法图表目录

数据源：[poisson_shooting_analysis_summary.csv](E:\GitHub_Repository\MatlabProject\results\poisson_shooting_analysis_summary.csv)。图表由 `runShootingAnalysis.m` 生成。

## `figures/poisson_shooting_comparison.png/.pdf`

- 用途：展示代表网格的三条解曲线及三组点态绝对误差。
- 读图重点：解曲线的重合程度，以及打靶法误差和有限差分误差的量级差异。
- 解释限制：对数误差图的零值按 `eps` 显示；不能把图上的机器精度下限当成真实误差。

## `figures/poisson_shooting_convergence.png/.pdf`

- 用途：比较三组最大误差随 h 的变化，并显示相邻观测阶。
- 参考拟合阶：打靶法 4.00417591，有限差分 2.00250190，方法间差值 2.00312512。
- 解释限制：参考线是理论阶的视觉基准，不是额外数据；单次确定性实验不支持显著性结论。
