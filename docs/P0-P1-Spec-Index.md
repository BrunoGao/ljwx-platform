# P0 + P1 功能 Spec 索引

本文档汇总所有 P0 和 P1 功能的 Phase 规划。

---

## P0 功能 (Phase 33-39) - 生产就绪必需

### Phase 33: 多级缓存管理器 ✅
- **文件**: `spec/phase/phase-33.md`
- **功能**: Caffeine L1 + Redis L2 + Pub/Sub 广播
- **Flyway**: V033
- **优先级**: 🔴 P0
- **预计工期**: 1 周
- **依赖**: Phase 32

### Phase 34: Outbox 事件表 ✅
- **文件**: `spec/phase/phase-34.md`
- **功能**: 事件最终一致性,PostgreSQL LISTEN/NOTIFY
- **Flyway**: V034
- **优先级**: 🔴 P0
- **预计工期**: 1 周
- **依赖**: Phase 33

### Phase 35: 结构化日志与 Loki 集成 ✅
- **文件**: `spec/phase/phase-35.md`
- **功能**: Logback JSON + MDC + Fluent Bit + Loki
- **Flyway**: —
- **优先级**: 🔴 P0
- **预计工期**: 1 周
- **依赖**: Phase 34

### Phase 36: Prometheus 指标监控 ✅
- **文件**: `spec/phase/phase-36.md`
- **功能**: Micrometer + Prometheus + 三层指标策略
- **Flyway**: —
- **优先级**: 🔴 P0
- **预计工期**: 1 周
- **依赖**: Phase 35

### Phase 37: Grafana 仪表盘与告警 ✅
- **文件**: `spec/phase/phase-37.md`
- **功能**: 全局总览 + JVM + 租户视图 + 告警规则
- **Flyway**: —
- **优先级**: 🔴 P0
- **预计工期**: 3 天
- **依赖**: Phase 36

### Phase 38: 租户品牌配置 ✅
- **文件**: `spec/phase/phase-38.md`
- **功能**: 6 大分类品牌配置,租户级 UI 定制
- **Flyway**: V038 (sys_tenant_brand)
- **优先级**: 🔴 P0
- **预计工期**: 1 周
- **依赖**: Phase 37
- **修复**: ✅ 删除重复 tenant_id 列,Flyway 版本号改为 V038,权限改为 list/edit

### Phase 39: 数据脱敏 ✅
- **文件**: `spec/phase/phase-39.md`
- **功能**: @DataMask 注解,Jackson 序列化脱敏
- **Flyway**: —
- **优先级**: 🔴 P0
- **预计工期**: 1 周
- **依赖**: Phase 38

**P0 合计**: 7 个功能,约 6 周

---

## P1 功能 (Phase 40-53) - 核心功能增强

### Phase 40: 岗位管理 ✅
- **文件**: `spec/phase/phase-40.md`
- **功能**: sys_post + sys_user_post,岗位 CRUD
- **Flyway**: V035-V036
- **优先级**: 🟡 P1
- **预计工期**: 3 天
- **依赖**: Phase 39

### Phase 41: 租户生命周期管理 📝
- **文件**: `spec/phase/phase-41.md` (待生成)
- **功能**: TenantInitializer + 冻结/注销机制
- **Flyway**: V037
- **优先级**: 🟡 P1
- **预计工期**: 3 天
- **依赖**: Phase 40

### Phase 42: 超级管理员机制 📝
- **文件**: `spec/phase/phase-42.md` (待生成)
- **功能**: tenant_id=0 跳过租户过滤
- **Flyway**: —
- **优先级**: 🟡 P1
- **预计工期**: 2 天
- **依赖**: Phase 41

### Phase 43: 租户域名识别 📝
- **文件**: `spec/phase/phase-43.md` (待生成)
- **功能**: TenantResolverFilter + 多策略识别
- **Flyway**: —
- **优先级**: 🟡 P1
- **预计工期**: 3 天
- **依赖**: Phase 42

### Phase 44: 角色-自定义数据范围 📝
- **文件**: `spec/phase/phase-44.md` (待生成)
- **功能**: sys_role_dept,自定义数据范围
- **Flyway**: V038
- **优先级**: 🟡 P1
- **预计工期**: 2 天
- **依赖**: Phase 43

### Phase 45: 任务执行日志 📝
- **文件**: `spec/phase/phase-45.md` (待生成)
- **功能**: sys_job_log,任务执行历史
- **Flyway**: V039
- **优先级**: 🟡 P1
- **预计工期**: 2 天
- **依赖**: Phase 44

### Phase 46: 导入导出中心 📝
- **文件**: `spec/phase/phase-46.md` (待生成)
- **功能**: sys_import_export_task + EasyExcel
- **Flyway**: V040
- **优先级**: 🟡 P1
- **预计工期**: 1 周
- **依赖**: Phase 45

### Phase 47-48: 开放 API 管理 📝
- **文件**: `spec/phase/phase-47.md`, `spec/phase/phase-48.md` (待生成)
- **功能**: sys_open_app + HMAC + 三级限流
- **Flyway**: V041-V042
- **优先级**: 🟡 P1
- **预计工期**: 2 周
- **依赖**: Phase 46

### Phase 49: Webhook 事件推送 📝
- **文件**: `spec/phase/phase-49.md` (待生成)
- **功能**: sys_webhook + Outbox 投递
- **Flyway**: V043
- **优先级**: 🟡 P1
- **预计工期**: 1 周
- **依赖**: Phase 48

### Phase 50-51: 消息中台 📝
- **文件**: `spec/phase/phase-50.md`, `spec/phase/phase-51.md` (待生成)
- **功能**: msg_template + 多渠道适配器
- **Flyway**: V044
- **优先级**: 🟡 P1
- **预计工期**: 2 周
- **依赖**: Phase 49

### Phase 52: 敏感数据加密 📝
- **文件**: `spec/phase/phase-52.md` (待生成)
- **功能**: AES 加密 + MyBatis TypeHandler
- **Flyway**: V052
- **优先级**: 🟡 P1
- **预计工期**: 1 周
- **依赖**: Phase 51

### Phase 53: 流程引擎 (简化版) 📝
- **文件**: `spec/phase/phase-53.md` (待生成)
- **功能**: wf_process_def + wf_process_instance + wf_task
- **Flyway**: V045-V048
- **优先级**: 🟡 P1
- **预计工期**: 3 周
- **依赖**: Phase 52

**P1 合计**: 14 个功能,约 14 周

---

## P2 功能 (Phase 54+) - 扩展功能

### Phase 54: 自定义表单 📝
- **功能**: sys_form_def + sys_form_data
- **Flyway**: V049-V051
- **优先级**: 🟢 P2
- **预计工期**: 3 周

### Phase 55: 链路追踪 📝
- **功能**: Micrometer Tracing + OpenTelemetry + Tempo
- **优先级**: 🟢 P2
- **预计工期**: 3 天

### Phase 56: K8s 事件采集 📝
- **功能**: kubernetes-event-exporter + Nginx Ingress 日志
- **优先级**: 🟢 P2
- **预计工期**: 2 天

### Phase 57: 移动端完整功能 📝
- **功能**: 高频场景完整实现 + 扫码登录
- **优先级**: 🟢 P2
- **预计工期**: 2 周

### Phase 58: 国际化 📝
- **功能**: 后端错误码多语言 + 字典/菜单 JSONB
- **Flyway**: V053
- **优先级**: 🟢 P2
- **预计工期**: 2 周

### Phase 59: 计量计费 📝
- **功能**: bill_usage_record + Quartz 统计
- **Flyway**: V054
- **优先级**: 🟢 P2
- **预计工期**: 1 周

### Phase 60: 运营看板 📝
- **功能**: DAU/MAU + 存储用量 + API 调用量
- **优先级**: 🟢 P2
- **预计工期**: 1 周

### Phase 61: 帮助中心 📝
- **功能**: sys_help_doc + Driver.js
- **Flyway**: V055
- **优先级**: 🟢 P2
- **预计工期**: 3 天

### Phase 62-63: 代码生成器 📝
- **功能**: sys_gen_table + 代码生成引擎
- **Flyway**: V056-V057
- **优先级**: 🟢 P2
- **预计工期**: 1 周

### Phase 64-65: 报表引擎 📝
- **功能**: rpt_report_def + SQL 模板引擎
- **Flyway**: V058
- **优先级**: 🟢 P2
- **预计工期**: 2 周

### Phase 66-67: AI 智能助手 📝
- **功能**: Spring AI + MCP + 只读 Tool
- **Flyway**: V059-V060
- **优先级**: 🟢 P2
- **预计工期**: 2 周

**P2 合计**: 14 个功能,约 11 周

---

## Final Gate

### Phase 68: Final Gate v4 📝
- **功能**: 全量校验 + FULL_MANIFEST 更新 + ADR 补充
- **优先级**: 🔴 必需
- **预计工期**: 1 天

---

## 总体规划

| 阶段 | Phase 范围 | 功能数 | 预计工期 | 状态 |
|------|-----------|--------|----------|------|
| **已完成** | Phase 0-32 | 32 | — | ✅ PASSED |
| **P0 生产就绪** | Phase 33-39 | 7 | 6 周 | ✅ Spec 已生成 |
| **P1 核心增强** | Phase 40-53 | 14 | 14 周 | 🔄 部分 Spec 已生成 |
| **P2 扩展功能** | Phase 54-67 | 14 | 11 周 | 📝 待生成 |
| **Final Gate** | Phase 68 | 1 | 1 天 | 📝 待生成 |
| **总计** | Phase 0-68 | 68 | 31 周 | — |

---

## 实施建议

### 阶段一：P0 生产就绪 (6 周)
1. Week 1-2: 缓存与事件一致性 (Phase 33-34)
2. Week 3-4: 可观测体系 (Phase 35-37)
3. Week 5: 租户品牌配置 (Phase 38)
4. Week 6: 数据脱敏 (Phase 39)

### 阶段二：P1 核心增强 (14 周)
1. Week 7-9: 租户管理增强 + 岗位管理 (Phase 40-43)
2. Week 10-12: 权限增强 + 任务日志 + 导入导出 (Phase 44-46)
3. Week 13-14: 消息中台 (Phase 50-51)
4. Week 15-16: 开放 API 管理 (Phase 47-48)
5. Week 17-18: Webhook + 敏感数据加密 (Phase 49, 52)
6. Week 19-21: 流程引擎 (Phase 53)

### 阶段三：P2 扩展功能 (11 周)
根据业务需求决定实施顺序

---

## 下一步行动

1. ✅ 已完成 P0 功能 Spec (Phase 33-39)
2. ✅ 已完成 Phase 40 (岗位管理) Spec
3. 📝 待生成 Phase 41-53 Spec (P1 剩余功能)
4. 📝 待生成 Phase 54-67 Spec (P2 功能)
5. 📝 待生成 Phase 68 Spec (Final Gate v4)

---

**文档版本**: v1.0
**生成时间**: 2026-03-01
**状态**: P0 + Phase 40 Spec 已完成,P1 剩余 Spec 待生成
