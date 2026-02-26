---
phase: 9
title: "Logs Notice and File"
targets:
  backend: true
  frontend: false
depends_on: [8]
bundle_with: [10]
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V015__create_sys_operation_log.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V016__create_sys_login_log.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V017__create_sys_file.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V018__create_sys_notice.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V019__seed_dict_data.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V020__seed_config_data.sql"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/OperationLogController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/LoginLogController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/FileController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/NoticeController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/OperationLogAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/FileAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/NoticeAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysOperationLog.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysLoginLog.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysFile.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysNotice.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysOperationLogMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysLoginLogMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysFileMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysNoticeMapper.java"
  - "ljwx-platform-app/src/main/resources/mapper/SysOperationLogMapper.xml"
  - "ljwx-platform-app/src/main/resources/mapper/SysLoginLogMapper.xml"
  - "ljwx-platform-app/src/main/resources/mapper/SysFileMapper.xml"
  - "ljwx-platform-app/src/main/resources/mapper/SysNoticeMapper.xml"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/config/LogAsyncConfig.java"
---
# Phase 9 — 日志通知文件 (Logs Notice and File)

| 项目 | 值 |
|-----|---|
| Phase | 9 |
| 模块 | ljwx-platform-app |
| Feature | F-009 (日志通知文件管理) |
| 前置依赖 | Phase 8 (Dict and Config) |
| 测试契约 | `spec/tests/phase-09-logs.tests.yml` |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/01-constraints.md` — §操作日志、§文件管理、§审计字段、§日志脱敏
- `spec/03-api.md` — §Logs、§Files、§Notices 路由
- `spec/04-database.md` — V015 ~ V020
- `spec/08-output-rules.md`

---

## 数据库契约

### V015__create_sys_operation_log.sql（操作日志表）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK | 雪花 ID |
| module | VARCHAR(50) | NOT NULL | 模块名称 |
| business_type | SMALLINT | NOT NULL | 业务类型（0=其他, 1=新增, 2=修改, 3=删除） |
| method | VARCHAR(200) | NOT NULL | 方法名 |
| request_method | VARCHAR(10) | NOT NULL | 请求方式（GET/POST/PUT/DELETE） |
| operator_type | SMALLINT | NOT NULL | 操作类别（0=其他, 1=后台用户, 2=手机端用户） |
| operator_name | VARCHAR(50) | NULL | 操作人员 |
| request_url | VARCHAR(500) | NULL | 请求 URL |
| request_ip | VARCHAR(50) | NULL | 请求 IP |
| request_param | TEXT | NULL | 请求参数（脱敏后，截断 4096） |
| response_result | TEXT | NULL | 响应结果（截断 4096） |
| status | SMALLINT | NOT NULL | 状态（0=失败, 1=成功） |
| error_msg | TEXT | NULL | 错误消息 |
| cost_time | BIGINT | NULL | 耗时（毫秒） |
| **审计字段** | | | **7 列** |

### V016__create_sys_login_log.sql（登录日志表）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK | 雪花 ID |
| username | VARCHAR(50) | NOT NULL | 用户名 |
| login_ip | VARCHAR(50) | NULL | 登录 IP |
| login_location | VARCHAR(255) | NULL | 登录地点 |
| browser | VARCHAR(50) | NULL | 浏览器 |
| os | VARCHAR(50) | NULL | 操作系统 |
| status | SMALLINT | NOT NULL | 状态（0=失败, 1=成功） |
| msg | VARCHAR(255) | NULL | 提示消息 |
| login_time | TIMESTAMP | NOT NULL | 登录时间 |
| **审计字段** | | | **7 列** |

### V017__create_sys_file.sql（文件表）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK | 雪花 ID |
| file_name | VARCHAR(255) | NOT NULL | 文件名 |
| file_path | VARCHAR(500) | NOT NULL | 文件路径（含 tenant_id） |
| file_size | BIGINT | NOT NULL | 文件大小（字节） |
| file_type | VARCHAR(50) | NULL | 文件类型（MIME） |
| file_ext | VARCHAR(10) | NULL | 文件扩展名 |
| **审计字段** | | | **7 列** |

### V018__create_sys_notice.sql（通知表）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK | 雪花 ID |
| notice_title | VARCHAR(100) | NOT NULL | 通知标题 |
| notice_type | SMALLINT | NOT NULL | 通知类型（1=通知, 2=公告） |
| notice_content | TEXT | NULL | 通知内容 |
| status | SMALLINT | NOT NULL | 状态（0=关闭, 1=正常） |
| **审计字段** | | | **7 列** |

---

## API 契约

### OperationLogController

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/v1/logs/operation | system:log:list | 查询操作日志列表 |
| GET | /api/v1/logs/operation/{id} | system:log:detail | 查询操作日志详情 |
| DELETE | /api/v1/logs/operation/{id} | system:log:delete | 删除操作日志 |
| DELETE | /api/v1/logs/operation/clean | system:log:clean | 清空操作日志 |

### FileController

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| POST | /api/v1/files/upload | system:file:upload | 上传文件 |
| GET | /api/v1/files/{id}/download | system:file:download | 下载文件 |
| GET | /api/v1/files | system:file:list | 查询文件列表 |
| DELETE | /api/v1/files/{id} | system:file:delete | 删除文件 |

---

## 业务规则

- **BL-09-01**：操作日志使用异步线程池（core=2, max=4, queue=1024）
- **BL-09-02**：日志体 > 4096 字节自动截断
- **BL-09-03**：日志脱敏规则：password → `***`，phone → 中间四位 `*`，idCard → 中间段 `*`
- **BL-09-04**：文件使用雪花 ID 命名，路径格式：`/uploads/{tenantId}/{yyyyMM}/{snowflakeId}.{ext}`
- **BL-09-05**：文件大小限制 50MB
- **BL-09-06**：文件扩展名白名单：jpg, jpeg, png, gif, pdf, doc, docx, xls, xlsx, zip
- **BL-09-07**：操作日志和登录日志只读，不允许修改

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-09-logs.tests.yml`**。

P0 强制覆盖：

| ID | 场景 | P |
|----|------|---|
| TC-09-01 | 无 Token → 401 | P0 |
| TC-09-02 | 无权限 → 403 | P0 |
| TC-09-03 | 查询操作日志成功 | P0 |
| TC-09-04 | 上传文件成功 | P0 |
| TC-09-05 | 文件大小超限 → 400 | P0 |
| TC-09-06 | 非法扩展名 → 400 | P0 |
| TC-09-07 | 日志脱敏验证 | P0 |
| TC-09-08 | 租户隔离验证 | P0 |

---

## 验收条件

- **AC-01**：V015-V018 包含 7 列审计字段
- **AC-02**：操作日志使用异步线程池（LogAsyncConfig）
- **AC-03**：日志脱敏逻辑已实现
- **AC-04**：文件上传有后缀白名单校验和 50MB 限制
- **AC-05**：文件路径包含 tenant_id
- **AC-06**：Controller 所有方法有 @PreAuthorize
- **AC-07**：`./mvnw compile -pl ljwx-platform-app` 通过

---

## 关键约束

- 禁止：日志允许修改 · 文件路径不含 tenant_id · 无扩展名白名单
- 异步线程池：core=2, max=4, queue=1024
- 日志体截断：4096 字节
- 文件大小限制：50MB

## 可 Bundle

可与 Phase 10 一起执行。
