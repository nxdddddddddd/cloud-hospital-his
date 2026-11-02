<script setup lang="ts">
defineProps<{ title: string; description: string; icon: string; stats: Array<{ label: string; value: string; tone?: string }>; columns: Array<{ label: string; prop: string; width?: number }>; rows: Record<string, string>[] }>()
</script>
<template>
  <section>
    <PageHeader :title="title" :description="description" badge="框架占位页"><el-button><el-icon><Refresh /></el-icon>刷新</el-button><el-button type="primary"><el-icon><Plus /></el-icon>新建业务</el-button></PageHeader>
    <div class="metric-grid"><article v-for="item in stats" :key="item.label" class="metric-card"><div :class="['metric-icon', item.tone]"><el-icon><component :is="icon" /></el-icon></div><div><strong>{{ item.value }}</strong><span>{{ item.label }}</span></div></article></div>
    <el-card shadow="never" class="business-card">
      <div class="filter-bar"><el-input placeholder="输入病历号或患者姓名" clearable><template #prefix><el-icon><Search /></el-icon></template></el-input><el-select placeholder="业务状态" clearable><el-option label="待处理" value="pending" /><el-option label="已完成" value="done" /></el-select><el-date-picker type="daterange" start-placeholder="开始日期" end-placeholder="结束日期" /><el-button type="primary">查询</el-button><el-button>重置</el-button></div>
      <el-table :data="rows" stripe><el-table-column type="index" label="#" width="56" /><el-table-column v-for="column in columns" :key="column.prop" :prop="column.prop" :label="column.label" :width="column.width"><template v-if="column.prop === 'status'" #default="scope"><el-tag :type="scope.row.status.includes('待') ? 'warning' : 'success'" effect="light" round>{{ scope.row.status }}</el-tag></template></el-table-column><el-table-column fixed="right" label="操作" width="150"><template #default><el-button link type="primary">查看</el-button><el-button link type="primary">处理</el-button></template></el-table-column></el-table>
      <div class="table-footer"><span>当前展示示例数据，接口联调后替换</span><el-pagination background layout="prev, pager, next" :total="30" /></div>
    </el-card>
  </section>
</template>
