# LJWX Platform

企业级全栈脚手架。Java 21 / Spring Boot 3.5 后端 + Vue 3 三端前端（Admin 管理后台 / Mobile uni-app 移动端 / Screen 数据大屏）。

## 工作流程（IMPORTANT — YOU MUST FOLLOW）

### 首次启动（Preflight）
如果 Current Phase 显示"尚未开始"，必须先执行 preflight 自检：
1. 运行 `/preflight`
2. 等待全部检查通过
3. 通过后将 Current Phase 更新为 `Phase: 0 (Skeleton) — READY`
4. 然后才能执行 `/phase-exec 0`

### 常规 Phase 执行
1. 确认 Current Phase 编号
2. 读取 `spec/phase/phase-{NN}.md` 获取本阶段任务、读取清单、验收条件
3. **仅**按"读取清单"中列出的文件和章节读取 `spec/` 内容
4. 禁止扫描整个 `spec/` 目录（Phase 19 除外）
5. 按 `spec/08-output-rules.md` 格式输出
6. 完成后告知用户更新 Current Phase

## Current Phase

Phase: 19 (Final Gate and Docs) — PASSED, ALL PHASES COMPLETE

## 硬规则（违反任何一篇为 FAIL）

1. **DAG 依赖**: core ← {security, data} ← web ← app。security 和 data 互不依赖。禁止 data import security 的任何类，反之亦然
2. **前端 semver**: 所有 dependencies / devDependencies 仅用 `~`（tilde），禁止 `^`（caret）
3. **审计字段 (audit fields)**: 所有业务表（Quartz 除外）必须含 tenant_id, created_by, created_time, updated_by, updated_time, deleted, version 共 7 列，均 NOT NULL + 有 DEFAULT
4. **TypeScript**: 禁止 `any`，tsconfig 开启 `strict: true`
5. **权限注解**: 每个 Controller 方法必须 `@PreAuthorize`（login / refresh 除外），格式 `hasAuthority('resource:action')`，不使用 ROLE_ 前缀
6. **tenant_id**: DTO 中禁止出现，前端禁止传递，后端由 Interceptor 自动注入
7. **环境变量**: 前端统一 `VITE_APP_BASE_API`，禁止 `VITE_API_BASE_URL`
8. **Vue Router**: 必须按 vue-router @5 API 写，禁止按 v4 经验写。参考 https://router.vuejs.org/guide/migration/v4-to-v5
9. **Flyway**: 禁止 `IF NOT EXISTS`
10. **POM 版本**: 禁止 `${latest.version}`，所有版本必须硬编码数字
11. **输出完整性**: NEW FILES 必须输出完整文件内容，禁止 `// ...省略...` 或 `/* same as before */`
12. **PATCHES 最小化**: 仅修改与当前 Phase 直接相关的文件，禁止顺手重构、重新格式化、批量重写无关文件
13. **日志脱敏**: password → `***`，phone → 中间四位 `*`，idCard → 中间段 `*`
14. **BCrypt**: admin 密码 `Admin@12345` 使用 cost=10 的 BCrypt hash，写在 V006 种子 SQL 中

## 版本锁定（SINGLE SOURCE OF TRUTH — 其他文件禁止重复写版本号，引用本段即可）

### 后端

| 依赖 | 版本 |
|------|------|
| Java JDK | 21 (21.0.10) |
| Spring Boot | 3.5.11 |
| MyBatis Spring Boot Starter | 3.0.5 |
| springdoc-openapi (BOM) | 2.8.15 |
| Testcontainers (BOM) | 1.21.4 |
| PostgreSQL (Docker) | 16.12 (postgres:16.12-alpine) |
| Flyway | 由 Spring Boot BOM 管理 |
| Quartz | 由 spring-boot-starter-quartz 管理 |
| Maven Wrapper | 3.9.9 |

### 前端

| 依赖 | 版本 | 策略 |
|------|------|------|
| Node.js | 22.22.0 (.nvmrc) | ≥20.19 \| ≥22.12 |
| pnpm | 10.30.1 | packageManager 字段锁定 |
| Vue | ~3.5.28 | ~ patch only |
| Vite | ~7.3.1 | ~ patch only |
| TypeScript | ~5.9.3 | ~ patch only |
| Vue Router | ~5.0.2 | ~ patch only |
| Pinia | ~3.0.4 | ~ patch only |
| Element Plus | ~2.13.2 | ~ patch only |
| @element-plus/icons-vue | ~2.3.2 | ~ patch only |
| ECharts | ~6.0.0 | ~ patch only |
| Axios | ~1.13.5 | ~ patch only |
| @vueuse/core | ~14.2.1 | ~ patch only |
| unplugin-auto-import | ~21.0.0 | ~ devDep |
| unplugin-vue-components | ~31.0.0 | ~ devDep |
| vue-tsc | ~3.2.4 | ~ devDep |
| sass | ~1.97.3 | ~ devDep |
| nprogress | ~0.2.0 | ~ |
| dayjs | ~1.11.19 | ~ |
| @kjgl77/datav-vue3 | ~1.7.4 | ~ Screen 专用 |
| tsup | ~8.5.0 | ~ shared 包构建 |

### Maven 坐标

```xml
<groupId>com.ljwx.platform</groupId>
<artifactId>ljwx-platform-{module}</artifactId>
<version>1.0.0-SNAPSHOT</version>
```

## 代码风格参考（少样本）

### Controller（后端）

```java
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {
    private final UserAppService userAppService;

    @GetMapping
    @PreAuthorize("hasAuthority('user:read')")
    public Result<PageResult<UserVO>> list(UserQueryDTO query) {
        return Result.ok(userAppService.listUsers(query));
    }

    @PostMapping
    @PreAuthorize("hasAuthority('user:write')")
    public Result<Long> create(@RequestBody @Valid UserCreateDTO dto) {
        return Result.ok(userAppService.createUser(dto));
    }
}
```

### Service（后端）

```java
@Service
@RequiredArgsConstructor
public class UserAppService {
    private final UserMapper userMapper;

    public PageResult<UserVO> listUsers(UserQueryDTO query) {
        // 不传 tenantId，TenantLineInterceptor 自动注入
        List<UserVO> list = userMapper.selectUserList(query);
        long total = userMapper.countUsers(query);
        return new PageResult<>(list, total);
    }
}
```

### Vue 组件（前端）

```vue
<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { getUsers } from '@/api/user'
import type { UserVO } from '@ljwx/shared'

const loading = ref(false)
const users = ref<UserVO[]>([])

onMounted(async () => {
  loading.value = true
  try {
    users.value = await getUsers()
  } finally {
    loading.value = false
  }
})
</script>
```

### API 调用（前端）

```typescript
import request from '@/api/request'
import type { Result, PageResult, UserVO, UserQueryDTO } from '@ljwx/shared'

export function getUsers(params?: UserQueryDTO): Promise<PageResult<UserVO>> {
  return request.get('/users', { params })
}
```

## 反模式（IMPORTANT — 禁止）

- ❌ data 模块 import com.ljwx.platform.security.* → 违反 DAG
- ❌ security 模块 import com.ljwx.platform.data.* → 违反 DAG
- ❌ DTO 中 private Long tenantId → 违反多租户规则
- ❌ @PreAuthorize("hasRole('ADMIN')") → 不使用 ROLE_ 前缀
- ❌ "axios": "^1.13.5" → 禁止 caret
- ❌ const data: any = response → 禁止 any
- ❌ CREATE TABLE IF NOT EXISTS 在 Flyway SQL 中 → 禁止
- ❌ VITE_API_BASE_URL → 已废弃变量名
- ❌ 按 vue-router v4 经验写 createRouter → 必须用 v5 API
- ❌ 修改非本 Phase 职责范围内的文件 → PATCHES 最小化
- ❌ // ... 省略 ... 或 /* rest same as before */ → 必须输出完整内容

## Compact 指令

When compacting, always preserve: 当前 Phase 编号及进度、已完成的文件清单、硬规则全文、版本锁定表全文、反模式清单。
