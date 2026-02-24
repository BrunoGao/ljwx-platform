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
