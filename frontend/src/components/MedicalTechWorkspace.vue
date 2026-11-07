<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { ElMessage } from 'element-plus'
import PageHeader from '@/components/PageHeader.vue'
import { medicalTechOrders } from '@/data/medicalTech'
import { completeMedicalTechOrder, filterMedicalTechOrders, summarizeMedicalTechOrders, type MedicalTechCategory, type MedicalTechOrder, type MedicalTechStatus } from '@/domain/medicalTech'

type WorkspaceMode = 'pending' | 'patient-entry' | 'result-entry' | 'query'
const props = defineProps<{ category: MedicalTechCategory; mode: WorkspaceMode }>()

const categoryConfig = {
  examination: { title: '检查管理', noun: '检查', icon: 'Monitor' },
  laboratory: { title: '检验管理', noun: '检验', icon: 'DataAnalysis' },
  treatment: { title: '处置管理', noun: '处置', icon: 'FirstAidKit' }
} as const
const modeConfig = {
  pending: { title: '待执行患者', description: '查看已缴费申请，确认患者后进入执行流程。' },
  'patient-entry': { title: '患者录入', description: '登记到检患者和执行人员，确保申请与患者身份一致。' },
  'result-entry': { title: '结果录入', description: '记录执行结果并完成本次医技申请。' },
  query: { title: '业务查询', description: '按患者、申请单和执行状态检索历史记录。' }
} as const

const orders = ref<MedicalTechOrder[]>(medicalTechOrders.map((item) => ({ ...item })))
const keyword = ref('')
const status = ref<MedicalTechStatus | 'all'>(props.mode === 'pending' ? 'pending' : 'all')
const selected = ref<MedicalTechOrder>()
const dialogVisible = ref(false)
const resultForm = reactive({ executor: '', executedAt: '2026-11-07 11:20', result: '' })
const patientForm = reactive({ patientName: '', outpatientNo: '', itemName: '', doctorName: '', department: '' })

const currentCategory = computed(() => categoryConfig[props.category])
const currentMode = computed(() => modeConfig[props.mode])
const categoryOrders = computed(() => orders.value.filter((item) => item.category === props.category))
const summary = computed(() => summarizeMedicalTechOrders(categoryOrders.value))
const displayedOrders = computed(() => filterMedicalTechOrders(orders.value, {
  category: props.category,
  status: props.mode === 'pending' ? 'pending' : status.value,
  keyword: keyword.value
}))

watch(() => props.mode, (mode) => { status.value = mode === 'pending' ? 'pending' : 'all' })

function statusLabel(value: MedicalTechStatus) {
  return { pending: '待执行', inProgress: '执行中', completed: '已完成' }[value]
}

function statusType(value: MedicalTechStatus) {
  return value === 'pending' ? 'warning' : value === 'inProgress' ? 'primary' : 'success'
}

function openAction(order: MedicalTechOrder) {
  selected.value = order
  resultForm.executor = order.executor ?? ''
  resultForm.executedAt = order.executedAt ?? '2026-11-07 11:20'
  resultForm.result = order.result ?? ''
  dialogVisible.value = true
}

function saveResult() {
  if (!selected.value || !resultForm.executor.trim() || !resultForm.result.trim()) {
    ElMessage.warning('请填写执行人员和结果内容')
    return
  }
  const index = orders.value.findIndex((item) => item.id === selected.value?.id)
  orders.value[index] = completeMedicalTechOrder(orders.value[index], { ...resultForm })
  dialogVisible.value = false
  ElMessage.success(`${currentCategory.value.noun}结果已保存`)
}

function registerPatient() {
  if (!patientForm.patientName || !patientForm.outpatientNo || !patientForm.itemName) {
    ElMessage.warning('请填写患者、门诊号和执行项目')
    return
  }
  orders.value.unshift({
    id: `${props.category}-${Date.now()}`,
    orderNo: `${props.category === 'examination' ? 'CHK' : props.category === 'laboratory' ? 'LAB' : 'DSP'}${Date.now()}`,
    category: props.category,
    status: 'inProgress',
    appliedAt: '2026-11-07 11:20',
    ...patientForm
  })
  Object.assign(patientForm, { patientName: '', outpatientNo: '', itemName: '', doctorName: '', department: '' })
  ElMessage.success('患者已登记并进入执行中')
}
</script>

<template>
  <section class="medical-tech-workspace">
    <PageHeader :title="`${currentCategory.title} · ${currentMode.title}`" :description="currentMode.description" :badge="`8.${category === 'examination' ? '3' : category === 'laboratory' ? '4' : '6'}`">
      <el-button @click="keyword = ''; status = mode === 'pending' ? 'pending' : 'all'"><el-icon><Refresh /></el-icon>重置</el-button>
      <el-button v-if="mode !== 'query'" type="primary"><el-icon><Plus /></el-icon>新建{{ currentCategory.noun }}</el-button>
    </PageHeader>

    <div class="metric-grid medical-metrics">
      <article class="metric-card"><div class="metric-icon"><el-icon><component :is="currentCategory.icon" /></el-icon></div><div><strong>{{ summary.pending }}</strong><span>待执行</span><small>等待患者到检</small></div></article>
      <article class="metric-card"><div class="metric-icon"><el-icon><Timer /></el-icon></div><div><strong>{{ summary.inProgress }}</strong><span>执行中</span><small>已登记执行人员</small></div></article>
      <article class="metric-card"><div class="metric-icon"><el-icon><CircleCheck /></el-icon></div><div><strong>{{ summary.completed }}</strong><span>已完成</span><small>结果已归档</small></div></article>
      <article class="metric-card"><div class="metric-icon"><el-icon><Document /></el-icon></div><div><strong>{{ summary.total }}</strong><span>全部申请</span><small>当前业务样例数据</small></div></article>
    </div>

    <el-card v-if="mode === 'patient-entry'" shadow="never" class="business-card patient-entry-card">
      <template #header><div class="card-title"><div><strong>到检患者登记</strong><span>核验身份后登记执行项目</span></div><el-tag effect="plain" round>执行中</el-tag></div></template>
      <el-form label-position="top" class="medical-entry-form">
        <el-row :gutter="16">
          <el-col :span="6"><el-form-item label="患者姓名"><el-input v-model="patientForm.patientName" placeholder="请输入患者姓名" /></el-form-item></el-col>
          <el-col :span="6"><el-form-item label="门诊号"><el-input v-model="patientForm.outpatientNo" placeholder="请输入门诊号" /></el-form-item></el-col>
          <el-col :span="6"><el-form-item :label="`${currentCategory.noun}项目`"><el-input v-model="patientForm.itemName" placeholder="请输入执行项目" /></el-form-item></el-col>
          <el-col :span="6"><el-form-item label="申请科室"><el-input v-model="patientForm.department" placeholder="请输入申请科室" /></el-form-item></el-col>
          <el-col :span="6"><el-form-item label="申请医生"><el-input v-model="patientForm.doctorName" placeholder="请输入申请医生" /></el-form-item></el-col>
          <el-col :span="18" class="entry-actions"><el-button>读取就诊卡</el-button><el-button type="primary" @click="registerPatient">确认登记</el-button></el-col>
        </el-row>
      </el-form>
    </el-card>

    <el-card shadow="never" class="business-card medical-list-card">
      <div class="filter-bar medical-filter">
        <el-input v-model="keyword" placeholder="申请单号、门诊号或患者姓名" clearable><template #prefix><el-icon><Search /></el-icon></template></el-input>
        <el-select v-model="status" :disabled="mode === 'pending'" placeholder="执行状态"><el-option label="全部状态" value="all" /><el-option label="待执行" value="pending" /><el-option label="执行中" value="inProgress" /><el-option label="已完成" value="completed" /></el-select>
        <el-date-picker type="daterange" start-placeholder="开始日期" end-placeholder="结束日期" />
        <el-button type="primary">查询</el-button>
      </div>
      <el-table :data="displayedOrders" stripe>
        <el-table-column prop="orderNo" label="申请单号" width="180" />
        <el-table-column label="患者" width="150"><template #default="scope"><div class="patient-cell"><strong>{{ scope.row.patientName }}</strong><span>{{ scope.row.outpatientNo }}</span></div></template></el-table-column>
        <el-table-column prop="itemName" :label="`${currentCategory.noun}项目`" min-width="160" />
        <el-table-column prop="department" label="申请科室" width="120" />
        <el-table-column prop="doctorName" label="申请医生" width="100" />
        <el-table-column prop="appliedAt" label="申请时间" width="155" />
        <el-table-column label="状态" width="100"><template #default="scope"><el-tag :type="statusType(scope.row.status)" effect="light" round>{{ statusLabel(scope.row.status) }}</el-tag></template></el-table-column>
        <el-table-column fixed="right" label="操作" width="150"><template #default="scope"><el-button link type="primary" @click="openAction(scope.row)">{{ mode === 'result-entry' ? '录入结果' : scope.row.status === 'completed' ? '查看结果' : '处理' }}</el-button></template></el-table-column>
      </el-table>
      <div class="table-footer"><span>共 {{ displayedOrders.length }} 条{{ currentCategory.noun }}申请</span><el-pagination background layout="prev, pager, next" :total="displayedOrders.length" /></div>
    </el-card>

    <el-dialog v-model="dialogVisible" :title="`${currentCategory.noun}执行结果`" width="640px">
      <div v-if="selected" class="result-patient-strip"><div><span>患者</span><strong>{{ selected.patientName }}</strong></div><div><span>门诊号</span><strong>{{ selected.outpatientNo }}</strong></div><div><span>项目</span><strong>{{ selected.itemName }}</strong></div></div>
      <el-form label-position="top" class="record-form">
        <el-row :gutter="16"><el-col :span="12"><el-form-item label="执行人员"><el-input v-model="resultForm.executor" /></el-form-item></el-col><el-col :span="12"><el-form-item label="执行时间"><el-input v-model="resultForm.executedAt" /></el-form-item></el-col></el-row>
        <el-form-item label="结果内容"><el-input v-model="resultForm.result" type="textarea" :rows="6" placeholder="请输入客观、完整的执行结果" /></el-form-item>
      </el-form>
      <template #footer><el-button @click="dialogVisible = false">取消</el-button><el-button type="primary" @click="saveResult">保存结果</el-button></template>
    </el-dialog>
  </section>
</template>
