# 打靶法交叉验证数据分析

## 分析问题

- 原始数据：`poisson_shooting_raw.mat` 及各网格 CSV。
- 比较对象：打靶法 + RK4、二阶中心有限差分、解析解。
- 误差定义：节点上的最大绝对误差、向量二范数和 RMS；方法间差值单独统计。
- 统计单位：每个 N 是一次确定性数值计算，不存在独立重复样本。

## 拟合结果

| 误差序列 | 对数拟合阶 |
|---|---:|
| 打靶法 - 解析解 | 4.00417591 |
| 有限差分 - 解析解 | 2.00250190 |
| 打靶法 - 有限差分 | 2.00312512 |

边界残差的全网格最大值为 `0.000000e+00`。完整数值见 [poisson_shooting_analysis_summary.csv](E:\GitHub_Repository\MatlabProject\results\poisson_shooting_analysis_summary.csv)。

## Claim Candidates

- Claim: 打靶法相对解析解的误差呈现四阶收敛证据。
  - Source evidence: `maxShootingExact` 和 `shootingPairwiseOrder`。
  - Allowed wording: 在本实验网格范围内，观测阶支持四阶误差行为。
  - Forbidden stronger wording: 不得据此声称任意问题、任意步长下都稳定或必然四阶。
  - Uncertainty: 只有单次确定性计算，未估计重复运行不确定度。
  - Next check: 若需扩大结论，应增加独立问题或不同区间验证。
  - Decision: keep

- Claim: 打靶法与普通有限差分的差值主要反映有限差分误差尺度。
  - Source evidence: `maxShootingFiniteDifference` 与二阶参考线。
  - Allowed wording: 两种数值解之差按实验范围呈二阶主导趋势。
  - Forbidden stronger wording: 不得把方法间差值写成打靶法自身的四阶误差。
  - Uncertainty: 当两种误差发生抵消时，局部相邻阶可能波动。
  - Next check: 与 Richardson 外推解比较可进一步隔离高阶误差。
  - Decision: keep
