---
phase: 3
title: "Security Module"
targets:
  backend: true
  frontend: false
depends_on: [1]
bundle_with: [2]
scope:
  - "ljwx-platform-security/**"
---
# Phase 3: Security Module

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/01-constraints.md` — §JWT 认证
- `spec/02-architecture.md` — §模块依赖图、§Core 模块关键接口、§POM 依赖声明（security 部分）
- `spec/08-output-rules.md`

## 任务

实现 ljwx-platform-security 模块：JWT 工具类、SecurityContextUserHolder / SecurityContextTenantHolder 实现、Security Filter Config。

## 关键约束

- security 模块**仅依赖 core**，禁止依赖 data
- SecurityContextUserHolder 实现 `CurrentUserHolder` 接口（core 中定义）
- SecurityContextTenantHolder 实现 `CurrentTenantHolder` 接口（core 中定义）
- JWT authorities claim name = `authorities`，不添加 ROLE_ 前缀
- JWT converter：读取 authorities → SimpleGrantedAuthority

## Phase-Local Manifest

```
ljwx-platform-security/pom.xml
ljwx-platform-security/src/main/java/com/ljwx/platform/security/context/SecurityContextUserHolder.java
ljwx-platform-security/src/main/java/com/ljwx/platform/security/context/SecurityContextTenantHolder.java
ljwx-platform-security/src/main/java/com/ljwx/platform/security/jwt/JwtTokenProvider.java
ljwx-platform-security/src/main/java/com/ljwx/platform/security/jwt/JwtProperties.java
ljwx-platform-security/src/main/java/com/ljwx/platform/security/filter/JwtAuthenticationFilter.java
ljwx-platform-security/src/main/java/com/ljwx/platform/security/config/SecurityConfig.java
```

## 验收条件

1. `pom.xml` 依赖仅含 `ljwx-platform-core`，无 `ljwx-platform-data`
2. 全部 import 无 `com.ljwx.platform.data`
3. SecurityContextUserHolder 实现 CurrentUserHolder
4. SecurityContextTenantHolder 实现 CurrentTenantHolder
5. JwtTokenProvider 使用 HS256，支持 access/refresh 两种 type
6. SecurityConfig 中 `/api/auth/login` 和 `/api/auth/refresh` 允许匿名
7. `./mvnw compile -pl ljwx-platform-security` 通过

## 可 Bundle

可与 Phase 2 一起执行。
