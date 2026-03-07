# Phase 编号映射（实现编号 → 逻辑编号）

本仓库的实现阶段存在历史编号（`spec/phase/phase-XX.md`）与权威路线图编号（`docs/reference/list.md` Phase 1-35）并存的情况。  
为保证验收与报表口径统一，使用映射文件：

- `spec/phase/logical-phase-map.json`

## 规则

1. 若实现编号在 `01..35`，默认逻辑编号与实现编号一致。  
2. 若实现编号命中 `physical_to_logical` 映射，按映射覆盖。  
3. 未命中规则的编号在逻辑视图中记为 `null`（仅出现在实现视图）。

## 当前关键映射

- `50/51/52 -> 28`（消息中台）
- `39/47/48/49 -> 29`（脱敏 + 开放平台 + Webhook）
- `46/55 -> 30`（导入导出 + 报表）
- `54 -> 31`（自定义表单）
- `53 -> 32`（流程引擎）
- `56 -> 33`（AI 运维助手）
- `57 -> 34`（移动端 + i18n）
- `58 -> 35`（运营仪表盘 + 计量计费 + 帮助中心）

## 报表输出

`scripts/gates/gate-summary.sh` 与 `scripts/gen-rtm.sh` 会同时输出：

- 实现视图（physical phase）
- 逻辑视图（logical phase，1-35）

逻辑视图用于最终 UAT/验收汇报口径，避免“phase 54+”与“phase 1-35”口径冲突。
