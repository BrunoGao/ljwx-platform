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
---
# Phase 9: Logs, Notice & File

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/01-constraints.md` — §操作日志、§文件管理、§审计字段
- `spec/03-api.md` — §Logs、§Files、§Notices 路由
- `spec/04-database.md` — V015 ~ V018
- `spec/08-output-rules.md`

## 任务

操作日志（异步 + 脱敏）、登录日志、通知、文件管理：V015-V018 + 全部 Controller / Service / Mapper。

## 关键约束

- 操作日志异步线程池：core=2, max=4, queue=1024
- 日志体 > 4096 字节截断
- 脱敏：password → `***`，phone → 中间四位 `*`，idCard → 中间段 `*`
- 文件：Snowflake ID 命名，50MB 限制，白名单后缀，路径含 tenant_id

## Phase-Local Manifest

```
ljwx-platform-app/src/main/resources/db/migration/V015__create_sys_operation_log.sql
ljwx-platform-app/src/main/resources/db/migration/V016__create_sys_login_log.sql
ljwx-platform-app/src/main/resources/db/migration/V017__create_sys_file.sql
ljwx-platform-app/src/main/resources/db/migration/V018__create_sys_notice.sql
ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/OperationLogController.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/LoginLogController.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/FileController.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/NoticeController.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/OperationLogAppService.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/FileAppService.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/NoticeAppService.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysOperationLog.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysLoginLog.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysFile.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysNotice.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysOperationLogMapper.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysLoginLogMapper.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysFileMapper.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysNoticeMapper.java
ljwx-platform-app/src/main/resources/mapper/SysOperationLogMapper.xml
ljwx-platform-app/src/main/resources/mapper/SysLoginLogMapper.xml
ljwx-platform-app/src/main/resources/mapper/SysFileMapper.xml
ljwx-platform-app/src/main/resources/mapper/SysNoticeMapper.xml
```

## 验收条件

1. V015-V018 含 7 列审计字段（日志表也需要 tenant_id 和 created_time 等）
2. 操作日志使用异步线程池
3. 脱敏逻辑已实现
4. 文件上传有后缀白名单校验和 50MB 限制
5. Controller 方法均有 @PreAuthorize
6. 编译通过

## 可 Bundle

可与 Phase 10 一起执行。

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-09-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-09-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-09-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-09-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-09-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-09-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-09-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-09-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-09-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-09-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
