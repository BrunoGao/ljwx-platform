---
phase: 8
title: "Dict and Config"
targets:
  backend: true
  frontend: false
depends_on: [7]
bundle_with: [7]
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V012__create_sys_dict_type.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V013__create_sys_dict_data.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V014__create_sys_config.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V019__seed_dict_data.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V020__seed_config_data.sql"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/DictController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/ConfigController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/DictAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/ConfigAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysDictType.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysDictData.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysConfig.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysDictTypeMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysDictDataMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysConfigMapper.java"
  - "ljwx-platform-app/src/main/resources/mapper/SysDictTypeMapper.xml"
  - "ljwx-platform-app/src/main/resources/mapper/SysDictDataMapper.xml"
  - "ljwx-platform-app/src/main/resources/mapper/SysConfigMapper.xml"
---
# Phase 8: Dict & Config

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/01-constraints.md` — §缓存策略、§审计字段
- `spec/03-api.md` — §Dicts 路由、§Configs 路由
- `spec/04-database.md` — V012 ~ V014、V019 ~ V020
- `spec/08-output-rules.md`

## 任务

字典和系统配置 CRUD + Caffeine 缓存：V012-V014（表结构）、V019-V020（种子数据）、Controller / Service / Mapper。

## 关键约束

- Caffeine 缓存，TTL = 10 min，由 Spring Boot 管理
- 不使用 Redis / MQ / JPA
- 所有 CREATE TABLE 含 7 列审计字段

## Phase-Local Manifest

```
ljwx-platform-app/src/main/resources/db/migration/V012__create_sys_dict_type.sql
ljwx-platform-app/src/main/resources/db/migration/V013__create_sys_dict_data.sql
ljwx-platform-app/src/main/resources/db/migration/V014__create_sys_config.sql
ljwx-platform-app/src/main/resources/db/migration/V019__seed_dict_data.sql
ljwx-platform-app/src/main/resources/db/migration/V020__seed_config_data.sql
ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/DictController.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/ConfigController.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/DictAppService.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/ConfigAppService.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysDictType.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysDictData.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysConfig.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysDictTypeMapper.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysDictDataMapper.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysConfigMapper.java
ljwx-platform-app/src/main/resources/mapper/SysDictTypeMapper.xml
ljwx-platform-app/src/main/resources/mapper/SysDictDataMapper.xml
ljwx-platform-app/src/main/resources/mapper/SysConfigMapper.xml
```

## 验收条件

1. V012-V014 含 7 列审计字段，无 IF NOT EXISTS
2. DictAppService / ConfigAppService 使用 `@Cacheable` / `@CacheEvict`
3. Controller 方法均有 @PreAuthorize
4. 编译通过

## 可 Bundle

可与 Phase 7 一起执行。
