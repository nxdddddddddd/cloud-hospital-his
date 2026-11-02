<script setup lang="ts">
const metrics = [
  { label: '今日挂号', value: '128', delta: '较昨日 +12', icon: 'Tickets', tone: 'blue' },
  { label: '当前待诊', value: '23', delta: '4 个诊室接诊中', icon: 'User', tone: 'cyan' },
  { label: '待执行项目', value: '17', delta: '检查 8 · 检验 9', icon: 'Monitor', tone: 'orange' },
  { label: '待发药处方', value: '11', delta: '最长等待 8 分钟', icon: 'Box', tone: 'green' }
]
const tasks = [
  { title: '检查待执行', count: 8, detail: '胸部正位片、心电图等', type: '检查科', color: '#2878b5' },
  { title: '检验待执行', count: 9, detail: '血常规、肝功能等', type: '检验科', color: '#0f9f8f' },
  { title: '待发药处方', count: 11, detail: '含 2 条库存预警', type: '门诊药房', color: '#d28a18' }
]
const patients = [
  { time: '08:35', name: '张文杰', caseNo: 'MR20261102018', doctor: '李医生', status: '接诊中' },
  { time: '08:28', name: '王晓梅', caseNo: 'MR20261102017', doctor: '李医生', status: '待接诊' },
  { time: '08:16', name: '陈志强', caseNo: 'MR20261102016', doctor: '周医生', status: '已完成' }
]
</script>
<template><section><div class="welcome-banner"><div><p>今日工作概览</p><h2>早上好，演示用户</h2><span>当前门诊运行平稳，共有 4 个诊室正在接诊。</span></div><div class="banner-symbol"><el-icon><FirstAidKit /></el-icon></div></div><div class="metric-grid dashboard-metrics"><article v-for="item in metrics" :key="item.label" class="metric-card"><div :class="['metric-icon', item.tone]"><el-icon><component :is="item.icon" /></el-icon></div><div><strong>{{ item.value }}</strong><span>{{ item.label }}</span><small>{{ item.delta }}</small></div></article></div><div class="dashboard-grid"><el-card shadow="never" class="business-card"><template #header><div class="card-title"><div><strong>待办业务</strong><span>按紧急程度排序</span></div><el-button link type="primary">查看全部</el-button></div></template><div class="task-list"><article v-for="task in tasks" :key="task.title"><i :style="{ background: task.color }" /><div><strong>{{ task.title }}</strong><span>{{ task.detail }}</span></div><b>{{ task.count }}</b><el-tag effect="plain">{{ task.type }}</el-tag><el-icon><ArrowRight /></el-icon></article></div></el-card><el-card shadow="never" class="business-card"><template #header><div class="card-title"><div><strong>门诊进度</strong><span>最近挂号患者</span></div><el-button link type="primary">刷新</el-button></div></template><el-table :data="patients"><el-table-column prop="time" label="时间" width="70" /><el-table-column label="患者"><template #default="scope"><div class="patient-cell"><strong>{{ scope.row.name }}</strong><span>{{ scope.row.caseNo }}</span></div></template></el-table-column><el-table-column prop="doctor" label="医生" /><el-table-column label="状态"><template #default="scope"><el-tag :type="scope.row.status === '已完成' ? 'success' : scope.row.status === '接诊中' ? 'primary' : 'warning'" round>{{ scope.row.status }}</el-tag></template></el-table-column></el-table></el-card></div></section></template>
