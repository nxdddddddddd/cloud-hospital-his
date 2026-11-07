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
    path: '/examination', component: Layout, redirect: '/examination/pending', meta: { title: '检查管理', icon: 'Monitor', permission: 'his:examination:list' },
    children: [
      { path: 'pending', name: 'ExaminationPending', component: () => import('@/views/execution/index.vue'), props: { category: 'examination', mode: 'pending' }, meta: { title: '待执行患者', permission: 'his:examination:list' } },
      { path: 'patient-entry', name: 'ExaminationPatientEntry', component: () => import('@/views/execution/index.vue'), props: { category: 'examination', mode: 'patient-entry' }, meta: { title: '患者录入', permission: 'his:examination:edit' } },
      { path: 'result-entry', name: 'ExaminationResultEntry', component: () => import('@/views/execution/index.vue'), props: { category: 'examination', mode: 'result-entry' }, meta: { title: '结果录入', permission: 'his:examination:edit' } },
      { path: 'query', name: 'ExaminationQuery', component: () => import('@/views/execution/index.vue'), props: { category: 'examination', mode: 'query' }, meta: { title: '检查查询', permission: 'his:examination:list' } }
    ]
  },
  {
    path: '/laboratory', component: Layout, redirect: '/laboratory/pending', meta: { title: '检验管理', icon: 'DataAnalysis', permission: 'his:laboratory:list' },
    children: [
      { path: 'pending', name: 'LaboratoryPending', component: () => import('@/views/execution/index.vue'), props: { category: 'laboratory', mode: 'pending' }, meta: { title: '待执行患者', permission: 'his:laboratory:list' } },
      { path: 'patient-entry', name: 'LaboratoryPatientEntry', component: () => import('@/views/execution/index.vue'), props: { category: 'laboratory', mode: 'patient-entry' }, meta: { title: '患者录入', permission: 'his:laboratory:edit' } },
      { path: 'result-entry', name: 'LaboratoryResultEntry', component: () => import('@/views/execution/index.vue'), props: { category: 'laboratory', mode: 'result-entry' }, meta: { title: '结果录入', permission: 'his:laboratory:edit' } },
      { path: 'query', name: 'LaboratoryQuery', component: () => import('@/views/execution/index.vue'), props: { category: 'laboratory', mode: 'query' }, meta: { title: '检验查询', permission: 'his:laboratory:list' } }
    ]
  },
  {
    path: '/treatment', component: Layout, redirect: '/treatment/pending', meta: { title: '处置管理', icon: 'FirstAidKit', permission: 'his:treatment:list' },
    children: [
      { path: 'pending', name: 'TreatmentPending', component: () => import('@/views/execution/index.vue'), props: { category: 'treatment', mode: 'pending' }, meta: { title: '待执行患者', permission: 'his:treatment:list' } },
      { path: 'patient-entry', name: 'TreatmentPatientEntry', component: () => import('@/views/execution/index.vue'), props: { category: 'treatment', mode: 'patient-entry' }, meta: { title: '患者录入', permission: 'his:treatment:edit' } },
      { path: 'result-entry', name: 'TreatmentResultEntry', component: () => import('@/views/execution/index.vue'), props: { category: 'treatment', mode: 'result-entry' }, meta: { title: '结果录入', permission: 'his:treatment:edit' } },
      { path: 'query', name: 'TreatmentQuery', component: () => import('@/views/execution/index.vue'), props: { category: 'treatment', mode: 'query' }, meta: { title: '处置查询', permission: 'his:treatment:list' } }
    ]
  },
  {
    path: '/pharmacy', component: Layout, redirect: '/pharmacy/dispensing', meta: { title: '药房管理', icon: 'Box', permission: 'his:pharmacy:list' },
    children: [{ path: 'dispensing', name: 'Pharmacy', component: () => import('@/views/pharmacy/index.vue'), meta: { title: '发药退药', permission: 'his:pharmacy:list' } }]
  },
  { path: '/:pathMatch(.*)*', redirect: '/403', meta: { hidden: true } }
]

export default createRouter({ history: createWebHistory(), routes: constantRoutes, scrollBehavior: () => ({ top: 0 }) })
