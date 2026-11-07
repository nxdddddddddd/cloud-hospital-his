<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import PageHeader from '@/components/PageHeader.vue'
import {
  acceptVisit, cancelMedicalOrder, completeVisit, createMedicalOrder, createPrescription,
  getMedicalRecord, getVisitCosts, getVisitResults, listDoctorCatalog, listDoctorVisits,
  saveDiagnosis, saveMedicalRecord, useMockDoctorApi
} from '@/api/doctor'
import { demoCosts, demoMedicalRecord, demoResults, doctorCatalog, doctorVisits } from '@/data/doctor'
import {
  filterDoctorVisits, orderTypeLabel, paymentStateLabel, sumCosts, visitStateLabel,
  type CatalogItem, type CostItem, type DoctorTab, type DoctorVisit, type MedicalRecordForm,
  type MedicalResult, type OrderType, type PrescriptionLine
} from '@/domain/doctor'

const props = withDefaults(defineProps<{ initialTab?: DoctorTab }>(), { initialTab: 'patients' })
const route = useRoute()
const router = useRouter()

const pageConfig: Record<DoctorTab, { title: string }> = {
  patients: { title: '患者查看' }, record: { title: '病历首页' }, check: { title: '检查申请' },
  inspection: { title: '检验申请' }, checkResult: { title: '检查结果' },
  inspectionResult: { title: '检验结果' }, diagnosis: { title: '门诊确诊' },
  prescription: { title: '开设处方' }, disposal: { title: '处置申请' }, costs: { title: '费用查询' }
}
const pathMap: Record<DoctorTab, string> = {
  patients: 'patients', record: 'record', check: 'check', inspection: 'inspection',
  checkResult: 'check-result', inspectionResult: 'inspection-result', diagnosis: 'diagnosis',
  prescription: 'prescription', disposal: 'disposal', costs: 'costs'
}
const orderConfig: Record<OrderType, { label: string; purpose: string }> = {
  check: { label: '检查', purpose: '请输入检查目的及要求' },
  inspection: { label: '检验', purpose: '请输入检验目的及要求' },
  disposal: { label: '处置', purpose: '请输入处置目的及要求' }
}

const currentPage = computed(() => props.initialTab)
const heading = computed(() => pageConfig[currentPage.value])
const queueState = ref<'waiting' | 'completed'>('waiting')
const keyword = ref('')
const visits = ref<DoctorVisit[]>(doctorVisits.map((item) => ({ ...item })))
const selectedId = ref<number>()
const loading = ref(false)
const saving = ref(false)
const results = ref<MedicalResult[]>([])
const selectedResult = ref<MedicalResult>()
const costs = ref<CostItem[]>([])
const costCaseNumber = ref('')
const costPatientName = ref('')
const catalogs = reactive<Record<string, CatalogItem[]>>({ check: [], inspection: [], disposal: [], drug: [], disease: [] })
const record = reactive<MedicalRecordForm>(emptyRecord(0))
const diseaseIds = ref<number[]>([])
const orderForms = reactive<Record<OrderType, { selectedIds: number[]; info: string; position: string; remark: string }>>({
  check: { selectedIds: [], info: '', position: '', remark: '' },
  inspection: { selectedIds: [], info: '', position: '', remark: '' },
  disposal: { selectedIds: [], info: '', position: '', remark: '' }
})
const medicalItemDialogVisible = ref(false)
const medicalItemKeyword = ref('')
const pendingMedicalItemIds = ref<number[]>([])
const prescriptionLines = ref<PrescriptionLine[]>([])
const drugDialogVisible = ref(false)
const drugCodeKeyword = ref('')
const drugNameKeyword = ref('')
const selectedDrugIds = ref<number[]>([])

const currentVisit = computed(() => visits.value.find((item) => item.registrationId === selectedId.value))
const patientRows = computed(() => filterDoctorVisits(visits.value, queueState.value, keyword.value))
const waitingCount = computed(() => visits.value.filter((item) => item.visitState === 1 || item.visitState === 2).length)
const completedCount = computed(() => visits.value.filter((item) => item.visitState === 3).length)
const resultRows = computed(() => results.value.filter((item) => currentPage.value === 'checkResult' ? item.type === 'check' : item.type === 'inspection'))
const activeOrderType = computed<OrderType | undefined>(() => currentPage.value === 'check' || currentPage.value === 'inspection' || currentPage.value === 'disposal' ? currentPage.value : undefined)
const selectedOrderItems = computed(() => activeOrderType.value ? catalogs[activeOrderType.value].filter((item) => orderForms[activeOrderType.value!].selectedIds.includes(item.id)) : [])
const selectedOrderTotal = computed(() => selectedOrderItems.value.reduce((total, item) => total + Number(item.price), 0))
const filteredMedicalItems = computed(() => {
  if (!activeOrderType.value) return []
  const value = medicalItemKeyword.value.trim().toLocaleLowerCase('zh-CN')
  if (!value) return catalogs[activeOrderType.value]
  return catalogs[activeOrderType.value].filter((item) => `${item.code} ${item.name}`.toLocaleLowerCase('zh-CN').includes(value))
})
const costTotal = computed(() => sumCosts(costs.value))
const prescriptionTotal = computed(() => prescriptionLines.value.reduce((total, line) => total + Number(drugOf(line.drugId)?.price ?? 0) * Number(line.quantity || 0), 0))
const filteredDrugs = computed(() => {
  const code = drugCodeKeyword.value.trim().toLocaleLowerCase('zh-CN')
  const name = drugNameKeyword.value.trim().toLocaleLowerCase('zh-CN')
  return catalogs.drug.filter((drug) => {
    const matchesCode = !code || String(drug.code ?? '').toLocaleLowerCase('zh-CN').includes(code)
    const matchesName = !name || String(drug.name ?? '').toLocaleLowerCase('zh-CN').includes(name)
    return matchesCode && matchesName
  })
})

onMounted(async () => {
  await Promise.all([loadVisits(), loadCatalogs()])
  const queryId = Number(route.query.registrationId)
  const targetId = queryId || visits.value.find((item) => item.visitState === 2)?.registrationId || visits.value[0]?.registrationId
  if (targetId) await selectVisit(targetId)
})

function emptyRecord(registrationId: number): MedicalRecordForm {
  return { registrationId, readme: '', present: '', presentTreat: '', history: '', allergy: '', physique: '', proposal: '', careful: '', diagnosis: '', cure: '' }
}

async function loadVisits() {
  if (useMockDoctorApi()) return
  loading.value = true
  try { visits.value = await listDoctorVisits({ state: 'all' }) } finally { loading.value = false }
}

async function loadCatalogs() {
  for (const type of Object.keys(catalogs)) {
    catalogs[type] = useMockDoctorApi() ? (doctorCatalog[type] ?? []).map((item) => ({ ...item })) : await listDoctorCatalog(type)
  }
}

async function selectVisit(id: number) {
  selectedId.value = id
  if (useMockDoctorApi()) {
    Object.assign(record, id === 1 ? demoMedicalRecord : emptyRecord(id), { registrationId: id })
    results.value = id === 1 ? demoResults.map((item) => ({ ...item })) : []
    costs.value = id === 1 ? demoCosts.map((item) => ({ ...item })) : []
  } else {
    const [recordData, resultData, costData] = await Promise.all([getMedicalRecord(id), getVisitResults(id), getVisitCosts(id)])
    Object.assign(record, emptyRecord(id), recordData)
    results.value = resultData
    costs.value = costData
  }
  diseaseIds.value = String(record.diseaseIds ?? '').split(',').filter(Boolean).map(Number)
  selectedResult.value = results.value.find((item) => currentPage.value === 'checkResult' ? item.type === 'check' : item.type === 'inspection')
  costCaseNumber.value = currentVisit.value?.caseNumber ?? ''
  costPatientName.value = currentVisit.value?.patientName ?? ''
}

async function queryCostPatient() {
  const target = visits.value.find((item) => (!costCaseNumber.value || item.caseNumber.includes(costCaseNumber.value.trim()))
    && (!costPatientName.value || item.patientName.includes(costPatientName.value.trim())))
  if (!target) return ElMessage.warning('未找到匹配患者')
  await changePatient(target.registrationId)
}

async function changePatient(id: number) {
  await selectVisit(id)
  await router.replace({ query: { ...route.query, registrationId: id } })
}

async function openPatient(patient: DoctorVisit, page: DoctorTab = 'record') {
  if (patient.visitState === 1) {
    if (!useMockDoctorApi()) await acceptVisit(patient.registrationId)
    patient.visitState = 2
    ElMessage.success('接诊成功，已进入病历书写')
  }
  await router.push({ path: `/doctor/${pathMap[page]}`, query: { registrationId: patient.registrationId } })
}

function callPatient(patient: DoctorVisit) { ElMessage.success(`已呼叫 ${patient.patientName} 到诊室就诊`) }
function skipPatient(patient: DoctorVisit) {
  const index = visits.value.findIndex((item) => item.registrationId === patient.registrationId)
  if (index >= 0) visits.value.push(...visits.value.splice(index, 1))
  ElMessage.info('已暂时跳过该患者')
}

async function saveRecord() {
  if (!currentVisit.value || currentVisit.value.visitState !== 2) return ElMessage.warning('仅接诊中的患者可以保存病历')
  if (!record.readme.trim()) return ElMessage.warning('请填写主诉')
  saving.value = true
  try {
    if (!useMockDoctorApi()) await saveMedicalRecord({ ...record, registrationId: currentVisit.value.registrationId })
    ElMessage.success('病历已保存')
  } finally { saving.value = false }
}

async function submitOrder() {
  const type = activeOrderType.value
  if (!type || !currentVisit.value || currentVisit.value.visitState !== 2) return ElMessage.warning('仅接诊中的患者可以开立申请')
  const form = orderForms[type]
  if (!form.selectedIds.length || !form.info.trim()) return ElMessage.warning('请选择项目并填写目的要求')
  const items = form.selectedIds.map((medicalTechnologyId) => ({ medicalTechnologyId, info: form.info, position: form.position, remark: form.remark }))
  if (!useMockDoctorApi()) await createMedicalOrder(currentVisit.value.registrationId, type, items)
  selectedOrderItems.value.forEach((item, index) => costs.value.unshift({ id: Date.now() + index, type: type === 'check' ? 'CHECK' : type === 'inspection' ? 'INSPECTION' : 'DISPOSAL', itemName: item.name, quantity: 1, unitPrice: Number(item.price), amount: Number(item.price), status: 'UNPAID', createdAt: new Date().toLocaleString('zh-CN') }))
  Object.assign(form, { selectedIds: [], info: '', position: '', remark: '' })
  ElMessage.success(`${orderConfig[type].label}申请已开立`)
}

function openMedicalItemDialog() {
  pendingMedicalItemIds.value = []
  medicalItemKeyword.value = ''
  medicalItemDialogVisible.value = true
}
function handleMedicalItemSelection(rows: CatalogItem[]) { pendingMedicalItemIds.value = rows.map((item) => item.id) }
function addSelectedMedicalItems() {
  const type = activeOrderType.value
  if (!type || !pendingMedicalItemIds.value.length) return ElMessage.warning('请选择需要添加的项目')
  orderForms[type].selectedIds = [...new Set([...orderForms[type].selectedIds, ...pendingMedicalItemIds.value])]
  medicalItemDialogVisible.value = false
}

function drugOf(id: number) { return catalogs.drug.find((item) => item.id === id) }
function removePrescriptionLine(index: number) { prescriptionLines.value.splice(index, 1) }
function openDrugDialog() { selectedDrugIds.value = []; drugCodeKeyword.value = ''; drugNameKeyword.value = ''; drugDialogVisible.value = true }
function handleDrugSelection(rows: CatalogItem[]) { selectedDrugIds.value = rows.map((item) => item.id) }
function addSelectedDrugs() {
  if (!selectedDrugIds.value.length) return ElMessage.warning('请选择需要添加的药品')
  const existing = new Set(prescriptionLines.value.map((item) => item.drugId))
  selectedDrugIds.value.forEach((drugId) => { if (!existing.has(drugId)) prescriptionLines.value.push({ drugId, usage: '', quantity: 1 }) })
  drugDialogVisible.value = false
}

async function submitPrescription() {
  if (!currentVisit.value || currentVisit.value.visitState !== 2) return ElMessage.warning('仅接诊中的患者可以开立处方')
  const validLines = prescriptionLines.value.filter((item) => item.drugId && item.usage.trim() && item.quantity > 0)
  if (!validLines.length || validLines.length !== prescriptionLines.value.length) return ElMessage.warning('请完整填写处方明细')
  if (!useMockDoctorApi()) await createPrescription(currentVisit.value.registrationId, validLines)
  prescriptionLines.value = []
  ElMessage.success('处方已开立')
}

async function saveCurrentDiagnosis() {
  if (!currentVisit.value || currentVisit.value.visitState !== 2) return ElMessage.warning('仅接诊中的患者可以确诊')
  if (!record.diagnosis?.trim()) return ElMessage.warning('请填写诊断结果')
  if (!useMockDoctorApi()) await saveDiagnosis(currentVisit.value.registrationId, diseaseIds.value, record.diagnosis, record.cure ?? '')
  currentVisit.value.diagnosis = record.diagnosis
  ElMessage.success('诊断与处理意见已保存')
}

async function completeCurrentVisit() {
  if (!currentVisit.value || currentVisit.value.visitState !== 2) return ElMessage.warning('当前患者不处于接诊中')
  if (!record.diagnosis?.trim()) return ElMessage.warning('请先完成门诊确诊')
  await ElMessageBox.confirm('完成后不能继续开立项目，确认完成诊疗吗？', '完成诊疗', { type: 'warning' })
  if (!useMockDoctorApi()) await completeVisit(currentVisit.value.registrationId)
  currentVisit.value.visitState = 3
  ElMessage.success('本次诊疗已完成')
}

async function cancelCost(item: CostItem) {
  await ElMessageBox.confirm(`确认作废“${item.itemName}”吗？`, '作废项目', { type: 'warning' })
  const type = ({ CHECK: 'check', INSPECTION: 'inspection', DISPOSAL: 'disposal', PRESCRIPTION: 'prescription' } as const)[item.type]
  if (!useMockDoctorApi()) await cancelMedicalOrder(type, item.id)
  item.status = 'CANCELLED'
  ElMessage.success('项目已作废')
}

function statusType(status: string) { return status === 'UNPAID' ? 'warning' : status === 'CANCELLED' || status === 'REFUNDED' ? 'info' : 'success' }
</script>

<template>
  <section class="doctor-module">
    <PageHeader :title="heading.title" description="">
      <el-button v-if="currentPage !== 'patients'" @click="router.push('/doctor/patients')">返回患者列表</el-button>
      <el-button v-if="currentPage !== 'patients' && currentVisit?.visitState === 2" type="primary" @click="completeCurrentVisit">完成诊疗</el-button>
      <el-button v-if="currentPage === 'patients'" @click="loadVisits"><el-icon><Refresh /></el-icon>刷新</el-button>
    </PageHeader>

    <template v-if="currentPage === 'patients'">
      <div class="patient-overview">
        <article><el-icon><User /></el-icon><div><strong>{{ completedCount }}</strong><span>今日已看诊</span></div></article>
        <article><el-icon><Clock /></el-icon><div><strong>{{ waitingCount }}</strong><span>当前排队</span></div></article>
      </div>
      <el-card shadow="never" class="business-card patient-list-card">
        <div class="patient-filter">
          <el-input v-model="keyword" placeholder="输入病历号、身份证号或姓名搜索" clearable><template #prefix><el-icon><Search /></el-icon></template></el-input>
          <el-radio-group v-model="queueState"><el-radio-button value="waiting">待诊患者</el-radio-button><el-radio-button value="completed">已诊患者</el-radio-button></el-radio-group>
          <el-button type="primary">搜索</el-button>
        </div>
        <el-table v-loading="loading" :data="patientRows" stripe>
          <el-table-column type="index" label="编号" width="80" /><el-table-column prop="patientName" label="患者姓名" width="140" /><el-table-column prop="caseNumber" label="病历号" min-width="180" />
          <el-table-column label="性别/年龄" width="120"><template #default="scope">{{ scope.row.gender || '-' }} / {{ scope.row.age ?? '-' }}{{ scope.row.ageType }}</template></el-table-column><el-table-column prop="departmentName" label="挂号科室" width="130" />
          <el-table-column label="状态" width="110"><template #default="scope"><el-tag :type="scope.row.visitState === 3 ? 'success' : 'primary'">{{ visitStateLabel(scope.row.visitState) }}</el-tag></template></el-table-column>
          <el-table-column label="操作" min-width="250" fixed="right"><template #default="scope"><el-button link type="primary" @click="openPatient(scope.row)">{{ scope.row.visitState === 1 ? '创建病案' : scope.row.visitState === 2 ? '继续诊疗' : '查看病历' }}</el-button><el-button v-if="scope.row.visitState === 1" link @click="skipPatient(scope.row)">跳过</el-button><el-button v-if="scope.row.visitState !== 3" link @click="callPatient(scope.row)">叫号</el-button></template></el-table-column>
          <template #empty><el-empty description="暂无患者" /></template>
        </el-table>
        <div class="table-footer"><span>共 {{ patientRows.length }} 条记录</span><el-pagination background layout="prev, pager, next" :total="patientRows.length" /></div>
      </el-card>
    </template>

    <template v-else>
      <el-card v-if="currentVisit" shadow="never" class="patient-info-card">
        <div class="patient-info-label">患者信息</div>
        <div class="patient-chip"><span>姓名</span><strong>{{ currentVisit.patientName }}</strong></div><div class="patient-chip"><span>病历号</span><strong>{{ currentVisit.caseNumber }}</strong></div><div class="patient-chip"><span>年龄</span><strong>{{ currentVisit.age }}{{ currentVisit.ageType }}</strong></div><div class="patient-chip"><span>性别</span><strong>{{ currentVisit.gender }}</strong></div><div class="patient-chip"><span>结算类别</span><strong>{{ currentVisit.settlementName }}</strong></div>
        <el-select :model-value="currentVisit.registrationId" filterable class="patient-switch" @change="changePatient"><el-option v-for="item in visits" :key="item.registrationId" :label="`${item.patientName} · ${item.caseNumber}`" :value="item.registrationId" /></el-select>
      </el-card>
      <el-empty v-else description="暂无可用患者，请先返回患者查看接诊" />

      <el-card v-if="currentVisit && currentPage === 'record'" shadow="never" class="business-card page-card">
        <div class="medical-order record-order"><el-form label-width="120px" class="clinical-form">
          <el-form-item label="主诉"><el-input v-model="record.readme" type="textarea" :rows="2" placeholder="请输入主诉" /></el-form-item>
          <el-form-item label="现病史"><el-input v-model="record.present" type="textarea" :rows="2" placeholder="请输入现病史" /></el-form-item>
          <el-form-item label="现病治疗情况"><el-input v-model="record.presentTreat" type="textarea" :rows="2" placeholder="请输入现病治疗情况" /></el-form-item>
          <el-form-item label="既往史"><el-input v-model="record.history" type="textarea" :rows="2" placeholder="请输入既往史" /></el-form-item>
          <el-form-item label="过敏史"><el-input v-model="record.allergy" type="textarea" :rows="2" placeholder="请输入过敏史" /></el-form-item>
          <el-form-item label="体格检查"><el-input v-model="record.physique" type="textarea" :rows="2" placeholder="请输入体格检查" /></el-form-item>
          <el-form-item label="诊断"><div class="record-disease"><el-select v-model="diseaseIds" multiple filterable placeholder="按 ICD 编码或疾病名称添加诊断"><el-option v-for="item in catalogs.disease" :key="item.id" :label="`${item.format} · ${item.name}`" :value="item.id" /></el-select><el-table :data="catalogs.disease.filter(item => diseaseIds.includes(item.id))" size="small"><el-table-column prop="code" label="疾病编码" width="150" /><el-table-column prop="name" label="疾病名称" min-width="180" /><el-table-column prop="format" label="国际 ICD 编码" width="170" /><el-table-column prop="category" label="疾病类型" width="140" /><template #empty><el-empty :image-size="45" description="暂无诊断" /></template></el-table></div></el-form-item>
          <el-form-item label="检查/检验建议"><el-input v-model="record.proposal" type="textarea" :rows="2" placeholder="请输入检查/检验建议" /></el-form-item>
          <el-form-item label="注意事项"><el-input v-model="record.careful" type="textarea" :rows="2" placeholder="请输入注意事项" /></el-form-item>
        </el-form><div class="form-actions"><el-button type="primary" :loading="saving" @click="saveRecord">保存</el-button><el-button @click="Object.assign(record, emptyRecord(currentVisit.registrationId)); diseaseIds = []">清空</el-button></div></div>
      </el-card>

      <el-card v-if="currentVisit && activeOrderType" shadow="never" class="business-card page-card">
        <div class="detail-toolbar"><div class="amount-badge">项目金额：¥{{ selectedOrderTotal.toFixed(2) }}</div><el-button type="primary" @click="openMedicalItemDialog"><el-icon><Plus /></el-icon>添加{{ orderConfig[activeOrderType].label }}项目</el-button></div>
        <el-table :data="selectedOrderItems" stripe><el-table-column prop="code" :label="`${orderConfig[activeOrderType].label}编码`" width="150" /><el-table-column prop="name" :label="`${orderConfig[activeOrderType].label}名称`" min-width="180" /><el-table-column prop="format" label="规格" width="140" /><el-table-column prop="price" label="单价" width="110"><template #default="scope">¥{{ Number(scope.row.price).toFixed(2) }}</template></el-table-column><el-table-column prop="category" label="费用分类" width="130" /><el-table-column label="操作" width="90"><template #default="scope"><el-button link type="danger" @click="orderForms[activeOrderType!].selectedIds = orderForms[activeOrderType!].selectedIds.filter(id => id !== scope.row.id)">删除</el-button></template></el-table-column><template #empty><el-empty :description="`暂未添加${orderConfig[activeOrderType].label}项目`" /></template></el-table>
      </el-card>
      <h3 v-if="currentVisit && activeOrderType" class="content-section-title">医嘱</h3>
      <el-card v-if="currentVisit && activeOrderType" shadow="never" class="business-card page-card">
        <div class="medical-order standalone-order"><el-form label-width="90px"><el-form-item label="目的要求"><el-input v-model="orderForms[activeOrderType].info" type="textarea" :rows="3" :placeholder="orderConfig[activeOrderType].purpose" /></el-form-item><el-form-item :label="`${orderConfig[activeOrderType].label}部位`"><el-input v-model="orderForms[activeOrderType].position" type="textarea" :rows="2" /></el-form-item><el-form-item label="备注"><el-input v-model="orderForms[activeOrderType].remark" type="textarea" :rows="2" /></el-form-item></el-form><div class="form-actions"><el-button type="primary" @click="submitOrder">保存申请</el-button><el-button @click="Object.assign(orderForms[activeOrderType!], { selectedIds: [], info: '', position: '', remark: '' })">清空</el-button></div></div>
      </el-card>

      <el-card v-if="currentVisit && (currentPage === 'checkResult' || currentPage === 'inspectionResult')" shadow="never" class="business-card page-card">
        <el-table :data="resultRows" stripe highlight-current-row @row-click="selectedResult = $event"><el-table-column prop="itemCode" label="项目编码" width="140" /><el-table-column prop="itemName" label="项目名称" min-width="180" /><el-table-column label="状态" width="110"><template #default="scope"><el-tag :type="scope.row.status === 'COMPLETED' ? 'success' : 'warning'">{{ paymentStateLabel(scope.row.status) }}</el-tag></template></el-table-column><el-table-column prop="executor" label="执行人员" width="120" /><el-table-column prop="executedAt" label="执行时间" width="180" /><el-table-column label="操作" width="100"><template #default="scope"><el-button link type="primary" @click.stop="selectedResult = scope.row">查看详情</el-button></template></el-table-column><template #empty><el-empty :description="`暂无${heading.title}`" /></template></el-table>
      </el-card>
      <h3 v-if="currentVisit && (currentPage === 'checkResult' || currentPage === 'inspectionResult')" class="content-section-title">{{ heading.title }}详情</h3>
      <el-card v-if="currentVisit && (currentPage === 'checkResult' || currentPage === 'inspectionResult')" shadow="never" class="business-card page-card">
        <div class="result-detail standalone-result"><el-descriptions v-if="selectedResult" :column="1" border><el-descriptions-item label="项目名称">{{ selectedResult.itemName }}</el-descriptions-item><el-descriptions-item label="项目编码">{{ selectedResult.itemCode }}</el-descriptions-item><el-descriptions-item label="执行人员">{{ selectedResult.executor || '-' }}</el-descriptions-item><el-descriptions-item label="执行时间">{{ selectedResult.executedAt || '-' }}</el-descriptions-item><el-descriptions-item label="执行状态"><el-tag :type="selectedResult.status === 'COMPLETED' ? 'success' : 'warning'">{{ paymentStateLabel(selectedResult.status) }}</el-tag></el-descriptions-item><el-descriptions-item label="结果内容">{{ selectedResult.result || '尚未录入结果' }}</el-descriptions-item></el-descriptions><el-empty v-else :image-size="55" description="请选择一条结果查看详情" /></div>
      </el-card>

      <el-card v-if="currentVisit && currentPage === 'diagnosis'" shadow="never" class="business-card page-card">
        <el-form label-width="110px" label-position="left" class="clinical-form diagnosis-form"><el-form-item label="疾病目录"><el-select v-model="diseaseIds" multiple filterable placeholder="按 ICD 编码或疾病名称选择"><el-option v-for="item in catalogs.disease" :key="item.id" :label="`${item.format} · ${item.name}`" :value="item.id" /></el-select></el-form-item><el-form-item label="诊断结果"><el-input v-model="record.diagnosis" type="textarea" :rows="4" placeholder="请输入诊断结果" /></el-form-item><el-form-item label="处理意见"><el-input v-model="record.cure" type="textarea" :rows="4" placeholder="请输入治疗、用药和复诊意见" /></el-form-item><div class="form-actions"><el-button type="primary" @click="saveCurrentDiagnosis">确诊提交</el-button><el-button @click="record.diagnosis = ''; record.cure = ''; diseaseIds = []">重置录入</el-button></div></el-form>
      </el-card>

      <el-card v-if="currentVisit && currentPage === 'prescription'" shadow="never" class="business-card page-card">
        <div class="prescription-toolbar"><div class="amount-badge">处方金额：¥{{ prescriptionTotal.toFixed(2) }}</div><el-button type="primary" @click="openDrugDialog"><el-icon><Plus /></el-icon>添加药品</el-button></div>
        <el-table :data="prescriptionLines" stripe><el-table-column label="药品名称" min-width="190"><template #default="scope"><div class="drug-name"><strong>{{ drugOf(scope.row.drugId)?.name }}</strong><span>{{ drugOf(scope.row.drugId)?.code }}</span></div></template></el-table-column><el-table-column label="规格" min-width="150"><template #default="scope">{{ drugOf(scope.row.drugId)?.format || '-' }}</template></el-table-column><el-table-column label="单价" width="100"><template #default="scope">¥{{ Number(drugOf(scope.row.drugId)?.price || 0).toFixed(2) }}</template></el-table-column><el-table-column label="用法用量" min-width="250"><template #default="scope"><el-input v-model="scope.row.usage" placeholder="请输入用法、用量和频次" /></template></el-table-column><el-table-column label="数量" width="150"><template #default="scope"><el-input-number v-model="scope.row.quantity" :min="0.001" :precision="3" /></template></el-table-column><el-table-column label="金额" width="110"><template #default="scope">¥{{ (Number(drugOf(scope.row.drugId)?.price || 0) * scope.row.quantity).toFixed(2) }}</template></el-table-column><el-table-column label="操作" width="80"><template #default="scope"><el-button link type="danger" @click="removePrescriptionLine(scope.$index)">删除</el-button></template></el-table-column><template #empty><el-empty description="请通过添加药品选择处方药品" /></template></el-table>
        <div class="form-actions"><el-button type="primary" @click="submitPrescription">开立处方</el-button><el-button @click="prescriptionLines = []">重置处方</el-button></div>
      </el-card>

      <el-card v-if="currentVisit && currentPage === 'costs'" shadow="never" class="business-card page-card">
        <div class="cost-query"><h4>患者信息查询</h4><el-form inline><el-form-item label="病历号"><el-input v-model="costCaseNumber" placeholder="请输入病历号" clearable /></el-form-item><el-form-item label="患者姓名"><el-input v-model="costPatientName" placeholder="请输入患者姓名" clearable /></el-form-item><el-form-item><el-button type="primary" @click="queryCostPatient">搜索</el-button></el-form-item></el-form></div>
        <h4 class="cost-confirm-title">患者信息确认</h4>
        <div class="cost-patient-confirm"><div><span>患者姓名</span><strong>{{ currentVisit.patientName }}</strong></div><div><span>病历号</span><strong>{{ currentVisit.caseNumber }}</strong></div><div><span>年龄</span><strong>{{ currentVisit.age }}{{ currentVisit.ageType }}</strong></div><div><span>性别</span><strong>{{ currentVisit.gender }}</strong></div></div>
        <div class="detail-toolbar cost-toolbar"><div class="amount-badge">合计金额：¥{{ costTotal.toFixed(2) }}</div></div>
        <el-table :data="costs" stripe><el-table-column prop="itemName" label="项目名称" min-width="190" /><el-table-column label="单价" width="100"><template #default="scope">¥{{ Number(scope.row.unitPrice).toFixed(2) }}</template></el-table-column><el-table-column label="类型" width="100"><template #default="scope"><el-tag effect="plain">{{ orderTypeLabel(scope.row.type) }}</el-tag></template></el-table-column><el-table-column prop="quantity" label="数量" width="90" /><el-table-column label="金额" width="110"><template #default="scope">¥{{ Number(scope.row.amount).toFixed(2) }}</template></el-table-column><el-table-column label="状态" width="110"><template #default="scope"><el-tag :type="statusType(scope.row.status)">{{ paymentStateLabel(scope.row.status) }}</el-tag></template></el-table-column><el-table-column label="操作" width="90"><template #default="scope"><el-button v-if="scope.row.status === 'UNPAID'" link type="danger" @click="cancelCost(scope.row)">作废</el-button><span v-else>-</span></template></el-table-column><template #empty><el-empty description="暂无费用项目" /></template></el-table>
      </el-card>
    </template>

    <el-dialog v-model="medicalItemDialogVisible" :title="`添加${activeOrderType ? orderConfig[activeOrderType].label : ''}项目`" width="720px">
      <div class="item-search"><el-input v-model="medicalItemKeyword" placeholder="请输入项目编码或名称" clearable><template #prefix><el-icon><Search /></el-icon></template></el-input><el-button type="primary">搜索</el-button></div>
      <el-table :data="filteredMedicalItems" row-key="id" max-height="420" @selection-change="handleMedicalItemSelection"><el-table-column type="selection" width="48" /><el-table-column prop="code" label="项目编码" width="130" /><el-table-column prop="name" label="项目名称" min-width="170" /><el-table-column prop="format" label="规格" width="130" /><el-table-column prop="price" label="单价" width="100"><template #default="scope">¥{{ Number(scope.row.price).toFixed(2) }}</template></el-table-column><el-table-column prop="category" label="费用分类" width="120" /></el-table>
      <template #footer><el-button @click="medicalItemDialogVisible = false">关闭</el-button><el-button type="primary" @click="addSelectedMedicalItems">添加</el-button></template>
    </el-dialog>

    <el-dialog v-model="drugDialogVisible" title="添加药品" width="760px">
      <div class="drug-search"><div class="drug-search-fields"><el-input v-model="drugCodeKeyword" placeholder="请输入药品编码" clearable><template #prefix><el-icon><Search /></el-icon></template></el-input><el-input v-model="drugNameKeyword" placeholder="请输入药品名称" clearable><template #prefix><el-icon><Search /></el-icon></template></el-input></div><el-button type="primary">搜索</el-button></div>
      <el-table :data="filteredDrugs" row-key="id" max-height="420" @selection-change="handleDrugSelection"><el-table-column type="selection" width="48" /><el-table-column prop="code" label="药品编码" width="120" /><el-table-column prop="name" label="药品名称" min-width="150" /><el-table-column prop="format" label="药品规格" width="150" /><el-table-column prop="price" label="药品单价" width="100"><template #default="scope">¥{{ Number(scope.row.price).toFixed(2) }}</template></el-table-column><el-table-column prop="unit" label="单位" width="70" /><el-table-column prop="stock" label="库存" width="80" /></el-table>
      <template #footer><el-button @click="drugDialogVisible = false">关闭</el-button><el-button type="primary" @click="addSelectedDrugs">添加</el-button></template>
    </el-dialog>
  </section>
</template>

<style scoped>
.doctor-module{--el-color-primary:var(--glass-accent);max-width:1600px;margin:0 auto}.doctor-module :deep(.page-heading p){display:none}.patient-overview{display:flex;gap:16px;margin-bottom:18px}.patient-overview article{width:220px;padding:16px 20px;display:flex;align-items:center;gap:15px;border:1px solid var(--glass-edge);border-radius:16px;background:rgba(255,255,255,.62);box-shadow:var(--glass-shadow-soft)}.patient-overview .el-icon{width:38px;height:38px;border-radius:10px;color:var(--glass-accent);background:rgba(8,127,145,.1);font-size:20px}.patient-overview strong,.patient-overview span{display:block}.patient-overview strong{font-size:23px}.patient-overview span{margin-top:3px;color:var(--glass-muted);font-size:12px}.patient-list-card :deep(.el-card__body),.page-card :deep(.el-card__body){padding:20px}.patient-filter{display:grid;grid-template-columns:minmax(320px,1fr) auto 90px;gap:12px;margin-bottom:18px}.doctor-module :deep(.el-radio-button__inner:hover){color:var(--glass-accent)}.patient-info-card{margin-bottom:18px;border:1px solid var(--glass-edge)!important;background:rgba(255,255,255,.58)!important}.patient-info-card :deep(.el-card__body){display:flex;align-items:center;gap:24px;padding:14px 20px}.patient-info-label{padding-right:20px;border-right:1px solid var(--glass-line);font-weight:700}.patient-chip span,.patient-chip strong{display:block}.patient-chip span{color:var(--glass-muted);font-size:10px}.patient-chip strong{margin-top:4px;font-size:13px}.patient-switch{width:230px;margin-left:auto}.section-title{display:flex;align-items:center;width:100%}.section-title strong{font-size:17px}.amount-badge{padding:8px 13px;border-radius:8px;color:#fff;background:var(--glass-accent);font-size:12px;white-space:nowrap}.clinical-form{max-width:1120px;margin:0 auto}.detail-toolbar,.prescription-toolbar{display:flex;align-items:center;justify-content:space-between;gap:14px;margin-bottom:15px}.cost-toolbar{justify-content:flex-start}.medical-order{margin-top:20px;padding-top:16px;border-top:1px solid var(--glass-line)}.medical-order h4{margin:0 0 16px}.record-order{margin-top:0;padding-top:0;border-top:0}.record-disease{width:100%}.record-disease>.el-select{width:100%;margin-bottom:10px}.form-actions{display:flex;justify-content:flex-end;gap:10px;margin-top:18px}.diagnosis-form .el-select{width:100%}.result-detail{margin-top:22px;padding-top:18px;border-top:1px solid var(--glass-line)}.result-detail h4{margin:0 0 14px}.result-detail :deep(.el-descriptions__label){width:150px}.add-item-button,.add-drug-button{color:#fff!important;background:var(--glass-accent)!important;border-color:var(--glass-accent)!important}.drug-name strong,.drug-name span{display:block}.drug-name span{margin-top:3px;color:var(--glass-muted);font-size:10px}.item-search{display:grid;grid-template-columns:1fr 80px;gap:10px;margin-bottom:16px}.drug-search{display:grid;grid-template-columns:140px 1fr 80px;gap:10px;margin-bottom:16px}.cost-patient-confirm{display:grid;grid-template-columns:repeat(4,1fr);gap:1px;margin-bottom:18px;overflow:hidden;border:1px solid var(--glass-line);border-radius:10px;background:var(--glass-line)}.cost-patient-confirm div{padding:12px 16px;background:rgba(255,255,255,.7)}.cost-patient-confirm span,.cost-patient-confirm strong{display:block}.cost-patient-confirm span{color:var(--glass-muted);font-size:10px}.cost-patient-confirm strong{margin-top:5px;font-size:13px}.cost-query{padding:4px 0 16px;border-bottom:1px solid var(--glass-line)}.cost-query h4,.cost-confirm-title{margin:0 0 14px}.cost-query :deep(.el-form-item){margin-bottom:0}.cost-query :deep(.el-input){width:260px}.cost-confirm-title{margin-top:18px}@media(max-width:1280px){.patient-info-card :deep(.el-card__body){gap:14px}.patient-chip:nth-of-type(5){display:none}}
.doctor-module .business-card:hover{border-color:var(--glass-edge)!important;box-shadow:var(--glass-shadow-soft)}
.content-section-title{margin:18px 4px 10px;font-size:15px}
.standalone-order{margin:0;padding:0;border-top:0}
.standalone-result{margin:0;padding:0;border-top:0}
.drug-search{grid-template-columns:1fr 80px;align-items:end}
.drug-search-fields{display:grid;gap:10px}
</style>
