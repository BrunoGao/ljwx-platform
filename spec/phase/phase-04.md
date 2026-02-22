---
phase: 4
title: "Web Module"
targets:
  backend: true
  frontend: false
depends_on: [2, 3]
bundle_with: [5]
scope:
  - "ljwx-platform-web/**"
---
# Phase 4: Web Module

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/02-architecture.md` — §模块依赖图、§POM 依赖声明（web 部分）
- `spec/03-api.md` — §统一响应、§错误码
- `spec/08-output-rules.md`

## 任务

实现 ljwx-platform-web 模块：GlobalExceptionHandler、ResponseAdvice、WebMvcConfig。

## Phase-Local Manifest

```
ljwx-platform-web/pom.xml
ljwx-platform-web/src/main/java/com/ljwx/platform/web/advice/GlobalExceptionHandler.java
ljwx-platform-web/src/main/java/com/ljwx/platform/web/advice/ResponseAdvice.java
ljwx-platform-web/src/main/java/com/ljwx/platform/web/config/WebMvcConfig.java
```

## 验收条件

1. `pom.xml` 依赖含 `ljwx-platform-security`（core 经传递获得）
2. GlobalExceptionHandler 处理常见异常并返回 Result 格式
3. ErrorCode 中定义的所有错误码均有对应异常处理
4. `./mvnw compile -pl ljwx-platform-web` 通过

## 可 Bundle

可与 Phase 5 一起执行。
