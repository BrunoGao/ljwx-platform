import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'
import { setupRouterGuards } from './guards'

// Augment vue-router RouteMeta for type-safe route metadata
declare module 'vue-router' {
  interface RouteMeta {
    requiresAuth?: boolean
    title?: string
    icon?: string
    hidden?: boolean
    /** RBAC authority string required to access this route, e.g. 'user:read' */
    authority?: string
  }
}

const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/login/index.vue'),
    meta: {
      title: '登录',
      requiresAuth: false,
    },
  },
  {
    path: '/',
    component: () => import('@/layouts/DefaultLayout.vue'),
    meta: { requiresAuth: true },
    children: [
      {
        path: '',
        redirect: '/dashboard',
      },
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: () => import('@/views/dashboard/index.vue'),
        meta: {
          title: '仪表盘',
          icon: 'Odometer',
          requiresAuth: true,
        },
      },
      {
        path: 'ops/dashboard',
        name: 'OpsDashboard',
        component: () => import('@/views/ops/dashboard/index.vue'),
        meta: {
          title: '运营看板',
          icon: 'DataAnalysis',
          requiresAuth: true,
          authority: 'system:ops:dashboard',
        },
      },
      {
        path: 'billing/usage',
        name: 'BillingUsage',
        component: () => import('@/views/billing/usage/index.vue'),
        meta: {
          title: '用量计费',
          icon: 'Coin',
          requiresAuth: true,
          authority: 'system:billing:list',
        },
      },
      {
        path: 'system/user',
        name: 'SystemUser',
        component: () => import('@/views/system/user/index.vue'),
        meta: {
          title: '用户管理',
          icon: 'User',
          requiresAuth: true,
        },
      },
      {
        path: 'system/role',
        name: 'SystemRole',
        component: () => import('@/views/system/role/index.vue'),
        meta: {
          title: '角色管理',
          icon: 'UserFilled',
          requiresAuth: true,
        },
      },
      {
        path: 'system/tenant',
        name: 'SystemTenant',
        component: () => import('@/views/system/tenant/index.vue'),
        meta: {
          title: '租户管理',
          icon: 'OfficeBuilding',
          requiresAuth: true,
        },
      },
      {
        path: 'system/tenant/lifecycle',
        name: 'SystemTenantLifecycle',
        component: () => import('@/views/system/tenant/lifecycle.vue'),
        meta: {
          title: '租户生命周期',
          icon: 'Clock',
          requiresAuth: true,
        },
      },
      {
        path: 'system/tenant-package',
        name: 'SystemTenantPackage',
        component: () => import('@/views/system/tenantPackage/index.vue'),
        meta: {
          title: '租户套餐',
          icon: 'Box',
          requiresAuth: true,
        },
      },
      {
        path: 'system/dict',
        name: 'SystemDict',
        component: () => import('@/views/system/dict/index.vue'),
        meta: {
          title: '字典管理',
          icon: 'Collection',
          requiresAuth: true,
        },
      },
      {
        path: 'system/config',
        name: 'SystemConfig',
        component: () => import('@/views/system/config/index.vue'),
        meta: {
          title: '系统配置',
          icon: 'Setting',
          requiresAuth: true,
        },
      },
      {
        path: 'system/ai-config',
        name: 'SystemAiConfig',
        component: () => import('@/views/system/ai-config/index.vue'),
        meta: {
          title: 'AI 配置',
          icon: 'MagicStick',
          requiresAuth: true,
        },
      },
      {
        path: 'system/custom-field',
        name: 'SystemCustomField',
        component: () => import('@/views/system/custom-field/index.vue'),
        meta: {
          title: '自定义字段',
          icon: 'EditPen',
          requiresAuth: true,
        },
      },
      {
        path: 'system/help',
        name: 'SystemHelp',
        component: () => import('@/views/system/help/index.vue'),
        meta: {
          title: '帮助文档',
          icon: 'QuestionFilled',
          requiresAuth: true,
          authority: 'system:help:list',
        },
      },
      {
        path: 'system/import-export',
        name: 'SystemImportExport',
        component: () => import('@/views/system/import-export/index.vue'),
        meta: {
          title: '导入导出',
          icon: 'UploadFilled',
          requiresAuth: true,
        },
      },
      {
        path: 'system/job',
        name: 'SystemJob',
        component: () => import('@/views/system/job/index.vue'),
        meta: {
          title: '定时任务',
          icon: 'Timer',
          requiresAuth: true,
        },
      },
      {
        path: 'system/file',
        name: 'SystemFile',
        component: () => import('@/views/system/file/index.vue'),
        meta: {
          title: '文件管理',
          icon: 'FolderOpened',
          requiresAuth: true,
        },
      },
      {
        path: 'system/notice',
        name: 'SystemNotice',
        component: () => import('@/views/system/notice/index.vue'),
        meta: {
          title: '通知公告',
          icon: 'Bell',
          requiresAuth: true,
        },
      },
      {
        path: 'system/post',
        name: 'SystemPost',
        component: () => import('@/views/system/post/index.vue'),
        meta: {
          title: '岗位管理',
          icon: 'Suitcase',
          requiresAuth: true,
        },
      },
      {
        path: 'monitor/operlog',
        name: 'MonitorOperlog',
        component: () => import('@/views/monitor/operlog/index.vue'),
        meta: {
          title: '操作日志',
          icon: 'Document',
          requiresAuth: true,
        },
      },
      {
        path: 'monitor/loginlog',
        name: 'MonitorLoginlog',
        component: () => import('@/views/monitor/loginlog/index.vue'),
        meta: {
          title: '登录日志',
          icon: 'Key',
          requiresAuth: true,
        },
      },
      {
        path: 'monitor/server',
        name: 'MonitorServer',
        component: () => import('@/views/monitor/server/index.vue'),
        meta: {
          title: '服务监控',
          icon: 'Cpu',
          requiresAuth: true,
          authority: 'system:monitor:server',
        },
      },
      {
        path: 'monitor/ai-assistant',
        name: 'MonitorAiAssistant',
        component: () => import('@/views/monitor/ai-assistant/index.vue'),
        meta: {
          title: 'AI 助手',
          icon: 'ChatDotRound',
          requiresAuth: true,
        },
      },
      {
        path: 'system/dept',
        name: 'SystemDept',
        component: () => import('@/views/system/dept/index.vue'),
        meta: {
          title: '部门管理',
          icon: 'OfficeBuilding',
          requiresAuth: true,
        },
      },
      {
        path: 'system/menu',
        name: 'SystemMenu',
        component: () => import('@/views/system/menu/index.vue'),
        meta: {
          title: '菜单管理',
          icon: 'Menu',
          requiresAuth: true,
        },
      },
      {
        path: 'system/open-api/app',
        name: 'SystemOpenApiApp',
        component: () => import('@/views/system/open-api/app/index.vue'),
        meta: {
          title: '开放应用',
          icon: 'Link',
          requiresAuth: true,
        },
      },
      {
        path: 'system/open-api/secret',
        name: 'SystemOpenApiSecret',
        component: () => import('@/views/system/open-api/secret/index.vue'),
        meta: {
          title: '应用密钥',
          icon: 'Key',
          requiresAuth: true,
        },
      },
      {
        path: 'system/profile',
        name: 'SystemProfile',
        component: () => import('@/views/system/profile/index.vue'),
        meta: {
          title: '个人中心',
          icon: 'UserFilled',
          requiresAuth: true,
        },
      },
      {
        path: 'system/webhook',
        name: 'SystemWebhook',
        component: () => import('@/views/system/webhook/index.vue'),
        meta: {
          title: 'Webhook',
          icon: 'Connection',
          requiresAuth: true,
        },
      },
      {
        path: 'system/task-log',
        name: 'SystemTaskLog',
        component: () => import('@/views/system/task-log/index.vue'),
        meta: {
          title: '任务执行日志',
          icon: 'List',
          requiresAuth: true,
        },
      },
      {
        path: 'system/message/inbox',
        name: 'SystemMessageInbox',
        component: () => import('@/views/system/message/inbox.vue'),
        meta: {
          title: '站内信收件箱',
          icon: 'MessageBox',
          requiresAuth: true,
        },
      },
      {
        path: 'system/message/records',
        name: 'SystemMessageRecords',
        component: () => import('@/views/system/message/records.vue'),
        meta: {
          title: '消息发送记录',
          icon: 'Tickets',
          requiresAuth: true,
        },
      },
      {
        path: 'monitor/online-user',
        name: 'MonitorOnlineUser',
        component: () => import('@/views/monitor/onlineUser/index.vue'),
        meta: {
          title: '在线用户',
          icon: 'Monitor',
          requiresAuth: true,
        },
      },
      {
        path: 'monitor/data-change-log',
        name: 'DataChangeLog',
        component: () => import('@/views/monitor/dataChangeLog/index.vue'),
        meta: {
          title: '数据变更日志',
          icon: 'Document',
          requiresAuth: true,
          authority: 'system:audit:list',
        },
      },
      {
        path: 'form/designer',
        name: 'FormDesigner',
        component: () => import('@/views/form/designer/index.vue'),
        meta: {
          title: '表单设计器',
          icon: 'EditPen',
          requiresAuth: true,
        },
      },
      {
        path: 'form/data',
        name: 'FormData',
        component: () => import('@/views/form/data/index.vue'),
        meta: {
          title: '表单数据',
          icon: 'Document',
          requiresAuth: true,
        },
      },
      {
        path: 'message/template',
        name: 'MessageTemplate',
        component: () => import('@/views/message/template/index.vue'),
        meta: {
          title: '消息模板',
          icon: 'ChatLineSquare',
          requiresAuth: true,
        },
      },
      {
        path: 'message/subscription',
        name: 'MessageSubscription',
        component: () => import('@/views/message/subscription/index.vue'),
        meta: {
          title: '消息订阅',
          icon: 'BellFilled',
          requiresAuth: true,
        },
      },
      {
        path: 'workflow/definition',
        name: 'WorkflowDefinition',
        component: () => import('@/views/workflow/definition/index.vue'),
        meta: {
          title: '流程定义',
          icon: 'Connection',
          requiresAuth: true,
        },
      },
      {
        path: 'workflow/instance',
        name: 'WorkflowInstance',
        component: () => import('@/views/workflow/instance/index.vue'),
        meta: {
          title: '流程实例',
          icon: 'Files',
          requiresAuth: true,
        },
      },
      {
        path: 'workflow/task',
        name: 'WorkflowTask',
        component: () => import('@/views/workflow/task/index.vue'),
        meta: {
          title: '流程任务',
          icon: 'Checked',
          requiresAuth: true,
        },
      },
      {
        path: 'report/designer',
        name: 'ReportDesigner',
        component: () => import('@/views/report/designer/index.vue'),
        meta: {
          title: '报表设计',
          icon: 'Histogram',
          requiresAuth: true,
        },
      },
      {
        path: 'report/preview',
        name: 'ReportPreview',
        component: () => import('@/views/report/preview/index.vue'),
        meta: {
          title: '报表预览',
          icon: 'View',
          requiresAuth: true,
        },
      },
      {
        path: 'tenant/brand',
        name: 'TenantBrand',
        component: () => import('@/views/tenant/brand/index.vue'),
        meta: {
          title: '租户品牌',
          icon: 'Brush',
          requiresAuth: true,
        },
      },
    ],
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/dashboard',
  },
]

export const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
  scrollBehavior: () => ({ left: 0, top: 0 }),
})

setupRouterGuards(router)

export default router
