---
phase: 46
title: "导入导出中心 (Import/Export Center)"
targets:
  backend: true
  frontend: true
depends_on: [45]
bundle_with: []
---
# Phase 46 — 导入导出中心

| 项目 | 值 |
|-----|---|
| Phase | 46 |
| 优先级 | 🟡 **P1** |

## 功能概述

实现统一的导入导出中心,支持:
1. Excel 导入/导出
2. 异步任务处理
3. 进度跟踪
4. 错误处理

## 数据库契约

### sys_import_export_task

| 列名 | 类型 | 约束 |
|------|------|------|
| id | BIGINT | PK |
| task_type | VARCHAR(20) | IMPORT/EXPORT |
| business_type | VARCHAR(50) | USER/ROLE/DEPT |
| file_name | VARCHAR(200) | |
| file_url | VARCHAR(500) | |
| status | VARCHAR(20) | PENDING/PROCESSING/SUCCESS/FAILURE |
| total_count | INT | |
| success_count | INT | |
| failure_count | INT | |
| error_message | TEXT | |
| + 7 审计字段 | | |

### Flyway: V046__create_import_export_task.sql

## API 契约

| 方法 | 路径 | 权限 |
|------|------|------|
| POST | /api/v1/import-export/import | system:importExport:import |
| POST | /api/v1/import-export/export | system:importExport:export |
| GET | /api/v1/import-export/tasks/{id} | system:importExport:query |
| GET | /api/v1/import-export/tasks | system:importExport:list |

## 业务规则

- BL-46-01: 导入文件 → 异步处理 → 返回任务 ID
- BL-46-02: 导出请求 → 异步生成文件 → 上传到 MinIO
- BL-46-03: 任务进度 → 实时更新 → 前端轮询查询
- BL-46-04: 导入失败 → 生成错误报告 → 下载查看

## 验收条件

- AC-01: 支持 Excel 导入/导出
- AC-02: 异步任务正常执行
- AC-03: 进度跟踪准确
- AC-04: 错误处理完善
