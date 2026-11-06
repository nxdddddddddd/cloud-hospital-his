import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'
import Layout from '@/layout/index.vue'

declare module 'vue-router' {
  interface RouteMeta { title?: string; icon?: string; permission?: string; hidden?: boolean; breadcrumb?: string[] }
}

export const constantRoutes: RouteRecordRaw[] = [
  { path: '/login', component: () => import('@/views/login/index.vue'), meta: { title: '登录', hidden: true } },
  { path: '/403', component: () => import('@/views/error/403.vue'), meta: { title: '无权访问', hidden: true } },
  {
    path: '/', component: Layout, redirect: '/dashboard',
    children: [{ path: 'dashboard', name: 'Dashboard', component: () => import('@/views/dashboard/index.vue'), meta: { title: '工作台', icon: 'DataBoard' } }]
  },
  {
    path: '/registration', component: Layout, redirect: '/registration/window', meta: { title: '挂号管理', icon: 'Tickets', permission: 'his:registration:list' },
    children: [{ path: 'window', name: 'Registration', component: () => import('@/views/registration/index.vue'), meta: { title: '窗口挂号', permission: 'his:registration:list' } }]
  },
  {
    path: '/doctor', component: Layout, redirect: '/doctor/workstation', meta: { title: '医生工作站', icon: 'FirstAidKit', permission: 'his:doctor:visits' },
    children: [{ path: 'workstation', name: 'DoctorWorkstation', component: () => import('@/views/doctor/index.vue'), meta: { title: '门诊诊疗', permission: 'his:doctor:visits' } }]
  },
  {
    path: '/charge', component: Layout, redirect: '/charge/window', meta: { title: '收费管理', icon: 'Wallet', permission: 'his:charge:list' },
    children: [{ path: 'window', name: 'Charge', component: () => import('@/views/charge/index.vue'), meta: { title: '收费退费', permission: 'his:charge:list' } }]
  },
  {
    path: '/execution', component: Layout, redirect: '/execution/check', meta: { title: '医技管理', icon: 'Monitor', permission: 'his:execution:list' },
    children: [{ path: 'check', name: 'Execution', component: () => import('@/views/execution/index.vue'), meta: { title: '检查检验处置', permission: 'his:execution:list' } }]
  },
  {
    path: '/pharmacy', component: Layout, redirect: '/pharmacy/dispensing', meta: { title: '药房管理', icon: 'Box', permission: 'his:pharmacy:list' },
    children: [{ path: 'dispensing', name: 'Pharmacy', component: () => import('@/views/pharmacy/index.vue'), meta: { title: '发药退药', permission: 'his:pharmacy:list' } }]
  },
  { path: '/:pathMatch(.*)*', redirect: '/403', meta: { hidden: true } }
]

export default createRouter({ history: createWebHistory(), routes: constantRoutes, scrollBehavior: () => ({ top: 0 }) })
