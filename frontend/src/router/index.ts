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
    path: '/doctor', component: Layout, redirect: '/doctor/patients', meta: { title: '医生工作站', icon: 'FirstAidKit', permission: 'his:doctor:visits' },
    children: [
      { path: 'patients', name: 'DoctorPatients', component: () => import('@/views/doctor/index.vue'), props: { initialTab: 'patients' }, meta: { title: '患者查看', permission: 'his:doctor:visits' } },
      { path: 'record', name: 'DoctorRecord', component: () => import('@/views/doctor/index.vue'), props: { initialTab: 'record' }, meta: { title: '病历首页', permission: 'his:doctor:visits' } },
      { path: 'check', name: 'DoctorCheck', component: () => import('@/views/doctor/index.vue'), props: { initialTab: 'check' }, meta: { title: '检查申请', permission: 'his:doctor:visits' } },
      { path: 'inspection', name: 'DoctorInspection', component: () => import('@/views/doctor/index.vue'), props: { initialTab: 'inspection' }, meta: { title: '检验申请', permission: 'his:doctor:visits' } },
      { path: 'check-result', name: 'DoctorCheckResult', component: () => import('@/views/doctor/index.vue'), props: { initialTab: 'checkResult' }, meta: { title: '检查结果', permission: 'his:doctor:visits' } },
      { path: 'inspection-result', name: 'DoctorInspectionResult', component: () => import('@/views/doctor/index.vue'), props: { initialTab: 'inspectionResult' }, meta: { title: '检验结果', permission: 'his:doctor:visits' } },
      { path: 'diagnosis', name: 'DoctorDiagnosis', component: () => import('@/views/doctor/index.vue'), props: { initialTab: 'diagnosis' }, meta: { title: '门诊确诊', permission: 'his:doctor:visits' } },
      { path: 'prescription', name: 'DoctorPrescription', component: () => import('@/views/doctor/index.vue'), props: { initialTab: 'prescription' }, meta: { title: '开设处方', permission: 'his:doctor:visits' } },
      { path: 'disposal', name: 'DoctorDisposal', component: () => import('@/views/doctor/index.vue'), props: { initialTab: 'disposal' }, meta: { title: '处置申请', permission: 'his:doctor:visits' } },
      { path: 'costs', name: 'DoctorCosts', component: () => import('@/views/doctor/index.vue'), props: { initialTab: 'costs' }, meta: { title: '费用查询', permission: 'his:doctor:visits' } }
    ]
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
