# 架构

> 版本号见 CLAUDE.md "版本锁定"段。

## 仓库结构

```
ljwx-platform/
├── CLAUDE.md
├── spec.md                          # stub 入口
├── spec/                            # 拆分后的规格文档
├── .claude/                         # Claude Code 扩展（skills / agents）
├── pom.xml                          # Maven parent
├── .mvn/wrapper/                    # Maven Wrapper
├── pnpm-workspace.yaml
├── package.json                     # 前端 root
├── .npmrc
├── .nvmrc                           # 内容：22.22.0
├── docker-compose.yml
├── .env.example
├── .gitignore
├── .editorconfig
│
├── ljwx-platform-core/              # Java: 核心（接口 + 通用类）
│   ├── pom.xml
│   └── src/main/java/com/ljwx/platform/core/
│       ├── result/                  # Result, ErrorCode
│       ├── id/                      # SnowflakeIdGenerator
│       ├── entity/                  # BaseEntity (审计字段)
│       └── context/                 # CurrentUserHolder, CurrentTenantHolder 接口
│
├── ljwx-platform-data/              # Java: 数据层（仅依赖 core）
│   ├── pom.xml
│   └── src/main/java/com/ljwx/platform/data/
│       ├── interceptor/             # AuditFieldInterceptor, TenantLineInterceptor
│       └── config/
│
├── ljwx-platform-security/          # Java: 安全（仅依赖 core）
│   ├── pom.xml
│   └── src/main/java/com/ljwx/platform/security/
│       ├── context/                 # SecurityContextUserHolder, SecurityContextTenantHolder
│       ├── jwt/
│       ├── filter/
│       └── config/
│
├── ljwx-platform-web/               # Java: Web 层（依赖 security + core 传递）
│   ├── pom.xml
│   └── src/main/java/com/ljwx/platform/web/
│       ├── advice/                  # GlobalExceptionHandler
│       └── config/
│
├── ljwx-platform-app/               # Java: 应用层（聚合 web + data）
│   ├── pom.xml
│   └── src/main/java/com/ljwx/platform/app/
│       ├── LjwxPlatformApplication.java
│       ├── controller/
│       ├── facade/
│       ├── appservice/
│       ├── domain/
│       └── infra/
│
├── packages/
│   └── shared/                      # 前端共享 TS 包
│       ├── package.json
│       ├── tsconfig.json
│       └── src/
│           ├── types/
│           ├── constants/
│           └── utils/
│
├── ljwx-platform-admin/             # Vue3 管理后台
│   ├── package.json
│   ├── vite.config.ts
│   ├── tsconfig.json
│   ├── env.d.ts
│   ├── .env.development
│   ├── .env.production
│   ├── index.html
│   └── src/
│       ├── main.ts
│       ├── App.vue
│       ├── router/
│       ├── stores/
│       ├── api/
│       ├── composables/
│       ├── layouts/
│       ├── views/
│       └── styles/
│
├── ljwx-platform-mobile/            # uni-app 移动端
│   ├── package.json
│   ├── manifest.json
│   ├── pages.json
│   └── src/
│
├── ljwx-platform-screen/            # Vue3 数据大屏
│   ├── package.json
│   ├── vite.config.ts
│   └── src/
│
├── docs/
│   ├── adr/                         # Architecture Decision Records + 变更日志
│   └── contracts/                   # OpenAPI JSON
│
└── scripts/
    ├── gates/
    │   ├── gate-all.sh
    │   ├── gate-compile.sh
    │   ├── gate-integration.sh
    │   ├── gate-contract.sh
    │   ├── gate-manifest.sh
    │   └── gate-nfr.sh
    ├── tools/
    │   └── export-openapi.sh
    └── acceptance/
        └── smoke-test.sh
```

## 模块依赖图（DAG — 禁止循环）

```
         ┌──────────────────┐
         │   ljwx-core       │  ← 仅接口 + 通用类
         └────────▲─────────┘
                  │
         ┌────────┴─────────┐
         │                  │
┌────────┴──────┐  ┌───────┴──────────┐
│ ljwx-security │  │ ljwx-data        │
│ (implements   │  │ (interceptors    │
│ holders from  │  │ depend on core   │
│ core)         │  │ interfaces)      │
└────────▲──────┘  └───────▲──────────┘
         │                  │
         └────────┬─────────┘
                  │
         ┌────────┴─────────┐
         │ ljwx-web         │  ← 依赖 security（+ core 传递）
         └────────▲─────────┘
                  │
         ┌────────┴─────────┐
         │ ljwx-app         │  ← 聚合：web + data
         └──────────────────┘
```

**依赖规则：**

| 模块 | 直接依赖 |
|------|---------|
| ljwx-platform-core | 无（仅外部依赖） |
| ljwx-platform-security | core |
| ljwx-platform-data | core |
| ljwx-platform-web | security（core 经传递依赖获得） |
| ljwx-platform-app | web + data（security 和 core 经传递依赖获得） |

**关键：** security 和 data 互不依赖，仅共同依赖 core 的接口契约。data 模块的 AuditFieldInterceptor 和 TenantLineInterceptor 通过 Spring 依赖注入获取 CurrentUserHolder / CurrentTenantHolder 的实现（由 security 模块在运行时提供）。

## Core 模块关键接口

```java
// com.ljwx.platform.core.context.CurrentUserHolder
public interface CurrentUserHolder {
    Long getUserId();
    String getUsername();
}

// com.ljwx.platform.core.context.CurrentTenantHolder
public interface CurrentTenantHolder {
    Long getTenantId();
}
```

## POM 依赖声明

### ljwx-platform-security/pom.xml

```xml
<dependencies>
    <dependency>
        <groupId>com.ljwx.platform</groupId>
        <artifactId>ljwx-platform-core</artifactId>
    </dependency>
    <!-- Spring Security, JWT libs, etc. -->
</dependencies>
```

### ljwx-platform-data/pom.xml

```xml
<dependencies>
    <dependency>
        <groupId>com.ljwx.platform</groupId>
        <artifactId>ljwx-platform-core</artifactId>
    </dependency>
    <!-- MyBatis, PostgreSQL driver, etc. -->
</dependencies>
```

### ljwx-platform-web/pom.xml

```xml
<dependencies>
    <dependency>
        <groupId>com.ljwx.platform</groupId>
        <artifactId>ljwx-platform-security</artifactId>
        <!-- core comes transitively -->
    </dependency>
</dependencies>
```

### ljwx-platform-app/pom.xml

```xml
<dependencies>
    <dependency>
        <groupId>com.ljwx.platform</groupId>
        <artifactId>ljwx-platform-web</artifactId>
        <!-- security + core come transitively -->
    </dependency>
    <dependency>
        <groupId>com.ljwx.platform</groupId>
        <artifactId>ljwx-platform-data</artifactId>
        <!-- core comes transitively -->
    </dependency>
</dependencies>
```
