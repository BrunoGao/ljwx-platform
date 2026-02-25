---
phase: 18
title: "Screen Components"
targets:
  backend: false
  frontend: true
depends_on: [17]
bundle_with: [17]
scope:
  - "ljwx-platform-screen/src/components/**"
  - "ljwx-platform-screen/src/views/home/index.vue"
---
# Phase 18: Screen Components

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/03-api.md` — §Screen 路由
- `spec/08-output-rules.md`

## 任务

ECharts 图表组件（≥13 个）、大屏完整布局、数据对接 screen API。

## Phase-Local Manifest

```
ljwx-platform-screen/src/components/charts/BarChart.vue
ljwx-platform-screen/src/components/charts/LineChart.vue
ljwx-platform-screen/src/components/charts/PieChart.vue
ljwx-platform-screen/src/components/charts/RadarChart.vue
ljwx-platform-screen/src/components/charts/GaugeChart.vue
ljwx-platform-screen/src/components/charts/ScatterChart.vue
ljwx-platform-screen/src/components/charts/MapChart.vue
ljwx-platform-screen/src/components/charts/FunnelChart.vue
ljwx-platform-screen/src/components/charts/HeatmapChart.vue
ljwx-platform-screen/src/components/charts/TreemapChart.vue
ljwx-platform-screen/src/components/charts/SankeyChart.vue
ljwx-platform-screen/src/components/charts/WaterBallChart.vue
ljwx-platform-screen/src/components/charts/RingChart.vue
ljwx-platform-screen/src/components/widgets/NumberFlip.vue
ljwx-platform-screen/src/components/widgets/ScrollTable.vue
ljwx-platform-screen/src/views/home/index.vue
```

## 验收条件

1. ≥ 13 个图表组件
2. 每个组件接收 typed props，无 `any`
3. 大屏首页布局完整，使用 DataV 边框装饰
4. 数据对接 `/api/screen/*` 接口
5. build 通过

## 可 Bundle

可与 Phase 17 一起执行。

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-18-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-18-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-18-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-18-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-18-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-18-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-18-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-18-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-18-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-18-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
