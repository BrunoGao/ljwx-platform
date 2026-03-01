---
phase: 46
title: "导入导出中心 (Import/Export Center)"
targets:
  backend: true
  frontend: true
depends_on: [45]
bundle_with: []
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V046__create_import_export_task.sql"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/domain/ImportExportTask.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/ImportExportController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/service/ImportExportService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/ImportExportTaskMapper.java"
  - "ljwx-platform-app/src/main/resources/mapper/ImportExportTaskMapper.xml"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/dto/ImportExportTaskDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/vo/ImportExportTaskVO.java"
  - "ljwx-platform-admin/src/views/system/import-export/index.vue"
  - "ljwx-platform-admin/src/api/system/import-export.ts"
---
# Phase 46 — 导入导出中心

| 项目 | 值 |
|-----|---|
| Phase | 46 |
| 模块 | ljwx-platform-app (后端) + ljwx-platform-web (前端) |
| Feature | L0-D06-F01 |
| 前置依赖 | Phase 45 (数据范围权限) |
| 测试契约 | `spec/tests/phase-46-import-export.tests.yml` |
| 优先级 | 🟡 **P1** |

## 读取清单

> 仅读取以下文件（禁止扫描整个 spec/）

- `CLAUDE.md`（自动加载）
- `spec/04-database.md` — §导入导出任务表
- `spec/01-constraints.md` — §审计字段
- `spec/08-output-rules.md`

## 功能概述

实现统一的导入导出中心,支持:
1. Excel 导入/导出
2. 异步任务处理
3. 进度跟踪
4. 错误处理

## 数据库契约

### 表结构：sys_import_export_task

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| task_type | VARCHAR(20) | NOT NULL, INDEX | IMPORT / EXPORT |
| business_type | VARCHAR(50) | NOT NULL | USER / ROLE / DEPT / MENU |
| file_name | VARCHAR(200) | NOT NULL | 文件名 |
| file_url | VARCHAR(500) | | 文件 URL (MinIO) |
| status | VARCHAR(20) | NOT NULL, INDEX | PENDING / PROCESSING / SUCCESS / FAILURE |
| total_count | INT | NOT NULL, DEFAULT 0 | 总记录数 |
| success_count | INT | NOT NULL, DEFAULT 0 | 成功记录数 |
| failure_count | INT | NOT NULL, DEFAULT 0 | 失败记录数 |
| error_message | TEXT | | 错误信息 |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**:
- `idx_status` (status)
- `idx_tenant_id` (tenant_id)
- `idx_created_time` (created_time)

> 审计字段（最后 7 列）由 BaseEntity 自动管理,禁止在 DTO 中声明。

### Flyway 文件

| 文件 | 内容 |
|------|------|
| `V046__create_import_export_task.sql` | 建表 + 索引 |

禁止：`IF NOT EXISTS`、在建表文件中写 DML。

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

## 核心组件契约

### ImportExportTask 实体

```java
@Data
@TableName("sys_import_export_task")
public class ImportExportTask extends BaseEntity {
    private String taskType;      // IMPORT / EXPORT
    private String businessType;  // USER / ROLE / DEPT / MENU
    private String fileName;
    private String fileUrl;
    private String status;        // PENDING / PROCESSING / SUCCESS / FAILURE
    private Integer totalCount;
    private Integer successCount;
    private Integer failureCount;
    private String errorMessage;
}
```

### ImportExportTaskDTO

```java
@Data
public class ImportExportTaskDTO {
    @NotBlank(message = "任务类型不能为空")
    private String taskType;      // IMPORT / EXPORT

    @NotBlank(message = "业务类型不能为空")
    private String businessType;  // USER / ROLE / DEPT / MENU

    @NotBlank(message = "文件名不能为空")
    private String fileName;

    private MultipartFile file;   // 导入文件
}
```

### ImportExportTaskVO

```java
@Data
public class ImportExportTaskVO {
    private Long id;
    private String taskType;
    private String businessType;
    private String fileName;
    private String fileUrl;
    private String status;
    private Integer totalCount;
    private Integer successCount;
    private Integer failureCount;
    private String errorMessage;
    private LocalDateTime createdTime;
}
```

### ImportExportController

```java
@RestController
@RequestMapping("/api/v1/import-export")
@RequiredArgsConstructor
public class ImportExportController {

    @PostMapping("/import")
    @PreAuthorize("@ss.hasPermission('system:importExport:import')")
    public R<Long> importData(@Valid ImportExportTaskDTO dto) {
        // 返回任务 ID
    }

    @PostMapping("/export")
    @PreAuthorize("@ss.hasPermission('system:importExport:export')")
    public R<Long> exportData(@Valid ImportExportTaskDTO dto) {
        // 返回任务 ID
    }

    @GetMapping("/tasks/{id}")
    @PreAuthorize("@ss.hasPermission('system:importExport:query')")
    public R<ImportExportTaskVO> getTask(@PathVariable Long id) {
        // 查询任务详情
    }

    @GetMapping("/tasks")
    @PreAuthorize("@ss.hasPermission('system:importExport:list')")
    public R<PageResult<ImportExportTaskVO>> listTasks(ImportExportTaskQueryDTO query) {
        // 分页查询任务列表
    }
}
```

## 前端文件路径

| 文件 | 说明 |
|------|------|
| `ljwx-platform-web/src/views/system/import-export/index.vue` | 导入导出中心页面 |
| `ljwx-platform-web/src/api/system/import-export.ts` | API 调用封装 |

## 验收条件

- AC-01: 支持 Excel 导入/导出
- AC-02: 异步任务正常执行
- AC-03: 进度跟踪准确
- AC-04: 错误处理完善
