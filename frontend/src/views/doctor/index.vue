<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import PageHeader from '@/components/PageHeader.vue'
import {
  acceptVisit, cancelMedicalOrder, completeVisit, createMedicalOrder, createPrescription, getMedicalRecord,
  getVisitCosts, getVisitResults, listDoctorCatalog, listDoctorVisits, saveDiagnosis,
  saveMedicalRecord, useMockDoctorApi
} from '@/api/doctor'
import { demoCosts, demoMedicalRecord, demoResults, doctorCatalog, doctorVisits } from '@/data/doctor'
import {
  filterDoctorVisits, orderTypeLabel, paymentStateLabel, sumCosts, visitStateLabel,
  type CatalogItem, type CostItem, type DoctorTab, type DoctorVisit, type MedicalRecordForm,
  type MedicalResult, type OrderType, type PrescriptionLine
} from '@/domain/doctor'

const props = withDefaults(defineProps<{ initialTab?: DoctorTab }>(), { initialTab: 'patients' })

const tabItems: Array<{ name: DoctorTab; label: string }> = [
  { name: 'patients', label: '患者查看' }, { name: 'record', label: '病历首页' },
  { name: 'check', label: '检查申请' }, { name: 'inspection', label: '检验申请' },
  { name: 'checkResult', label: '检查结果' }, { name: 'inspectionResult', label: '检验结果' },
  { name: 'diagnosis', label: '门诊确诊' }, { name: 'prescription', label: '开设处方' },
  { name: 'disposal', label: '处置申请' }, { name: 'costs', label: '费用查询' }
]
const orderTabs: Array<{ type: OrderType; name: DoctorTab; title: string; purpose: string }> = [
  { type: 'check', name: 'check', title: '检查申请', purpose: '请输入检查目的及要求' },
  { type: 'inspection', name: 'inspection', title: '检验申请', purpose: '请输入检验目的及要求' },
  { type: 'disposal', name: 'disposal', title: '处置申请', purpose: '请输入处置目的及要求' }
]

const activeTab = ref<DoctorTab>(props.initialTab)
const queueState = ref<'waiting' | 'completed'>('waiting')
const keyword = ref('')
const visits = ref<DoctorVisit[]>(doctorVisits.map((item) => ({ ...item })))
const selectedId = ref(visits.value[0]?.registrationId)
const loading = ref(false)
const saving = ref(false)
const results = ref<MedicalResult[]>([])
const costs = ref<CostItem[]>([])
const catalogs = reactive<Record<string, CatalogItem[]>>({ check: [], inspection: [], disposal: [], drug: [], disease: [] })
const record = reactive<MedicalRecordForm>(emptyRecord(selectedId.value ?? 0))
const diseaseIds = ref<number[]>([])
const orderForms = reactive<Record<OrderType, { selectedIds: number[]; info: string; position: string; remark: string }>>({
  check: { selectedIds: [], info: '', position: '', remark: '' },
  inspection: { selectedIds: [], info: '', position: '', remark: '' },
  disposal: { selectedIds: [], info: '', position: '', remark: '' }
})
const prescriptionLines = ref<PrescriptionLine[]>([{ drugId: 0, usage: '', quantity: 1 }])

const currentVisit = computed(() => visits.value.find((item) => item.registrationId === selectedId.value))
const queue = computed(() => filterDoctorVisits(visits.value, queueState.value, keyword.value))
const checkResults = computed(() => results.value.filter((item) => item.type === 'check'))
const inspectionResults = computed(() => results.value.filter((item) => item.type === 'inspection'))
const costTotal = computed(() => sumCosts(costs.value))
const prescriptionTotal = computed(() => prescriptionLines.value.reduce((total, line) => {
  const drug = catalogs.drug.find((item) => item.id === line.drugId)
  return total + Number(drug?.price ?? 0) * Number(line.quantity || 0)
}, 0))

onMounted(async () => {
  await loadVisits()
  await loadCatalogs()
  if (selectedId.value) await selectVisit(selectedId.value)
})

function emptyRecord(registrationId: number): MedicalRecordForm {
  return { registrationId, readme: '', present: '', presentTreat: '', history: '', allergy: '', physique: '', proposal: '', careful: '', diagnosis: '', cure: '' }
}

async function loadVisits() {
  if (useMockDoctorApi()) return
  loading.value = true
  try {
    visits.value = await listDoctorVisits({ state: 'all' })
    selectedId.value = visits.value[0]?.registrationId
  } finally { loading.value = false }
}

async function loadCatalogs() {
  for (const type of Object.keys(catalogs)) {
    catalogs[type] = useMockDoctorApi()
      ? (doctorCatalog[type] ?? []).map((item) => ({ ...item }))
      : await listDoctorCatalog(type)
  }
}

async function selectVisit(id: number) {
  selectedId.value = id
  if (useMockDoctorApi()) {
    Object.assign(record, id === 1 ? { ...demoMedicalRecord } : emptyRecord(id), { registrationId: id })
    results.value = id === 1 ? demoResults.map((item) => ({ ...item })) : []
    costs.value = id === 1 ? demoCosts.map((item) => ({ ...item })) : []
  } else {
    const [recordData, resultData, costData] = await Promise.all([
      getMedicalRecord(id), getVisitResults(id), getVisitCosts(id)
    ])
    Object.assign(record, emptyRecord(id), recordData)
    results.value = resultData
    costs.value = costData
  }
  diseaseIds.value = String(record.diseaseIds ?? '').split(',').filter(Boolean).map(Number)
}

async function acceptCurrentVisit() {
  const visit = currentVisit.value
  if (!visit || visit.visitState !== 1) return
  if (!useMockDoctorApi()) await acceptVisit(visit.registrationId)
  visit.visitState = 2
  activeTab.value = 'record'
  ElMessage.success('接诊成功，请填写病历首页')
}

async function saveRecord() {
  if (!currentVisit.value || currentVisit.value.visitState !== 2) return ElMessage.warning('请先接诊患者')
  if (!record.readme.trim()) return ElMessage.warning('请填写主诉')
  saving.value = true
  try {
    if (!useMockDoctorApi()) await saveMedicalRecord({ ...record, registrationId: currentVisit.value.registrationId })
    ElMessage.success('病历已保存')
  } finally { saving.value = false }
}

async function submitOrder(type: OrderType) {
  const form = orderForms[type]
  if (!currentVisit.value || currentVisit.value.visitState !== 2) return ElMessage.warning('请先接诊患者')
  if (!form.selectedIds.length || !form.info.trim()) return ElMessage.warning('请选择项目并填写目的要求')
  const items = form.selectedIds.map((medicalTechnologyId) => ({ medicalTechnologyId, info: form.info, position: form.position, remark: form.remark }))
  if (!useMockDoctorApi()) await createMedicalOrder(currentVisit.value.registrationId, type, items)
  catalogs[type].filter((item) => form.selectedIds.includes(item.id)).forEach((item, index) => costs.value.unshift({ id: Date.now() + index, type: type === 'check' ? 'CHECK' : type === 'inspection' ? 'INSPECTION' : 'DISPOSAL', itemName: item.name, quantity: 1, unitPrice: Number(item.price), amount: Number(item.price), status: 'UNPAID', createdAt: new Date().toLocaleString('zh-CN') }))
  Object.assign(form, { selectedIds: [], info: '', position: '', remark: '' })
  ElMessage.success('申请已开立，等待收费')
}

function addPrescriptionLine() { prescriptionLines.value.push({ drugId: 0, usage: '', quantity: 1 }) }
function removePrescriptionLine(index: number) {
  if (prescriptionLines.value.length === 1) return ElMessage.warning('处方至少保留一条明细')
  prescriptionLines.value.splice(index, 1)
}
function drugOf(id: number) { return catalogs.drug.find((item) => item.id === id) }

async function submitPrescription() {
  if (!currentVisit.value || currentVisit.value.visitState !== 2) return ElMessage.warning('请先接诊患者')
  const validLines = prescriptionLines.value.filter((item) => item.drugId && item.usage.trim() && item.quantity > 0)
  if (!validLines.length || validLines.length !== prescriptionLines.value.length) return ElMessage.warning('请完整填写处方明细')
  if (!useMockDoctorApi()) await createPrescription(currentVisit.value.registrationId, validLines)
  validLines.forEach((line, index) => {
    const drug = drugOf(line.drugId)!
    costs.value.unshift({ id: Date.now() + index, type: 'PRESCRIPTION', itemName: drug.name, quantity: line.quantity, unitPrice: Number(drug.price), amount: Number((Number(drug.price) * line.quantity).toFixed(2)), status: 'UNPAID', createdAt: new Date().toLocaleString('zh-CN') })
  })
  prescriptionLines.value = [{ drugId: 0, usage: '', quantity: 1 }]
  ElMessage.success('处方已开立，等待收费')
}

async function saveCurrentDiagnosis() {
  if (!currentVisit.value || currentVisit.value.visitState !== 2) return ElMessage.warning('请先接诊患者')
  if (!record.diagnosis?.trim()) return ElMessage.warning('请填写诊断结果')
  if (!useMockDoctorApi()) await saveDiagnosis(currentVisit.value.registrationId, diseaseIds.value, record.diagnosis, record.cure ?? '')
  currentVisit.value.diagnosis = record.diagnosis
  ElMessage.success('诊断与处理意见已保存')
}

async function completeCurrentVisit() {
  const visit = currentVisit.value
  if (!visit || visit.visitState !== 2) return ElMessage.warning('当前患者不处于接诊中')
  if (!record.diagnosis?.trim()) return ElMessage.warning('请先完成门诊确诊')
  await ElMessageBox.confirm('完成后本次诊疗将不能继续开立项目，确认完成吗？', '完成诊疗', { type: 'warning' })
  if (!useMockDoctorApi()) await completeVisit(visit.registrationId)
  visit.visitState = 3
  queueState.value = 'completed'
  ElMessage.success('本次诊疗已完成')
}

function resultStatus(status: string) { return status === 'COMPLETED' ? '已出结果' : paymentStateLabel(status) }
function costStatusType(status: string) { return status === 'UNPAID' ? 'warning' : status === 'CANCELLED' || status === 'REFUNDED' ? 'info' : 'success' }
async function cancelCost(item: CostItem) {
  await ElMessageBox.confirm(`确认作废“${item.itemName}”吗？`, '作废项目', { type: 'warning' })
  const type = ({ CHECK: 'check', INSPECTION: 'inspection', DISPOSAL: 'disposal', PRESCRIPTION: 'prescription' } as const)[item.type]
  if (!useMockDoctorApi()) await cancelMedicalOrder(type, item.id)
  item.status = 'CANCELLED'
  ElMessage.success('项目已作废')
}
</script>

<template>
  <section class="doctor-page">
    <PageHeader title="门诊医生工作站" description="完成患者接诊、病历、申请、处方、确诊及费用查询。" badge="需求 8.2">
      <el-button @click="queueState = queueState === 'waiting' ? 'completed' : 'waiting'">{{ queueState === 'waiting' ? '查看已诊' : '返回待诊' }}</el-button>
      <el-button type="primary" :disabled="currentVisit?.visitState !== 2" @click="completeCurrentVisit">完成诊疗</el-button>
    </PageHeader>

    <div class="doctor-workstation">
      <el-card shadow="never" class="patient-queue">
        <template #header><div class="card-title"><div><strong>患者队列</strong><span>待诊 {{ visits.filter(v => v.visitState !== 3).length }} · 已诊 {{ visits.filter(v => v.visitState === 3).length }}</span></div><el-button circle @click="loadVisits"><el-icon><Refresh /></el-icon></el-button></div></template>
        <el-input v-model="keyword" placeholder="姓名、病历号或身份证" clearable><template #prefix><el-icon><Search /></el-icon></template></el-input>
        <div class="queue-tabs"><button :class="{ active: queueState === 'waiting' }" @click="queueState = 'waiting'">待诊</button><button :class="{ active: queueState === 'completed' }" @click="queueState = 'completed'">已诊</button></div>
        <div v-loading="loading" class="queue-list">
          <article v-for="patient in queue" :key="patient.registrationId" :class="{ active: selectedId === patient.registrationId }" @click="selectVisit(patient.registrationId)">
            <el-avatar>{{ patient.patientName[0] }}</el-avatar>
            <div><strong>{{ patient.patientName }} <small>{{ patient.gender }} · {{ patient.age }}{{ patient.ageType }}</small></strong><span>{{ patient.caseNumber }}</span><em>{{ patient.departmentName }} · {{ patient.settlementName }}</em></div>
            <el-tag :type="patient.visitState === 2 ? 'primary' : patient.visitState === 1 ? 'warning' : 'success'" size="small" round>{{ visitStateLabel(patient.visitState) }}</el-tag>
          </article>
          <el-empty v-if="!queue.length" :image-size="72" description="暂无患者" />
        </div>
      </el-card>

      <el-card shadow="never" class="clinical-panel">
        <template #header>
          <div v-if="currentVisit" class="patient-summary">
            <div><el-avatar :size="44">{{ currentVisit.patientName[0] }}</el-avatar><div><strong>{{ currentVisit.patientName }} <span>{{ currentVisit.gender }} · {{ currentVisit.age }}{{ currentVisit.ageType }}</span></strong><p>{{ currentVisit.caseNumber }} · {{ currentVisit.settlementName }} · {{ currentVisit.departmentName }}</p></div></div>
            <div class="vital"><span>过敏史</span><b>{{ currentVisit.allergy || record.allergy || '未记录' }}</b></div>
            <div class="vital"><span>就诊状态</span><b class="state-value">{{ visitStateLabel(currentVisit.visitState) }}</b></div>
            <el-button v-if="currentVisit.visitState === 1" type="primary" @click="acceptCurrentVisit">接诊患者</el-button>
          </div>
          <el-empty v-else :image-size="40" description="请先选择患者" />
        </template>

        <el-tabs v-if="currentVisit" v-model="activeTab" class="doctor-tabs">
          <el-tab-pane v-for="tab in tabItems" :key="tab.name" :label="tab.label" :name="tab.name">
            <template v-if="tab.name === 'patients'">
              <div class="section-heading"><div><h3>患者查看</h3><p>查看当前医生的待诊和已诊患者。</p></div></div>
              <el-descriptions :column="4" border>
                <el-descriptions-item label="姓名">{{ currentVisit.patientName }}</el-descriptions-item><el-descriptions-item label="病历号">{{ currentVisit.caseNumber }}</el-descriptions-item>
                <el-descriptions-item label="性别年龄">{{ currentVisit.gender }} / {{ currentVisit.age }}{{ currentVisit.ageType }}</el-descriptions-item><el-descriptions-item label="午别">{{ currentVisit.noon }}</el-descriptions-item>
                <el-descriptions-item label="身份证号">{{ currentVisit.cardNumber || '未登记' }}</el-descriptions-item><el-descriptions-item label="结算类别">{{ currentVisit.settlementName }}</el-descriptions-item>
                <el-descriptions-item label="挂号科室">{{ currentVisit.departmentName }}</el-descriptions-item><el-descriptions-item label="就诊日期">{{ currentVisit.visitDate }}</el-descriptions-item>
                <el-descriptions-item label="家庭住址" :span="4">{{ currentVisit.homeAddress || '未登记' }}</el-descriptions-item>
              </el-descriptions>
              <div class="form-actions"><el-button v-if="currentVisit.visitState === 1" type="primary" @click="acceptCurrentVisit">接诊并创建病历</el-button><el-button v-else @click="activeTab = 'record'">进入病历首页</el-button></div>
            </template>

            <template v-else-if="tab.name === 'record'">
              <div class="section-heading"><div><h3>病历首页</h3><p>记录主诉、病史、查体和诊疗建议。</p></div><el-tag effect="plain">自动关联本次挂号</el-tag></div>
              <el-form label-position="top" class="record-form">
                <el-row :gutter="16"><el-col :span="12"><el-form-item label="主诉（必填）"><el-input v-model="record.readme" type="textarea" :rows="3" placeholder="请输入患者主诉" /></el-form-item></el-col><el-col :span="12"><el-form-item label="现病史"><el-input v-model="record.present" type="textarea" :rows="3" placeholder="请输入现病史" /></el-form-item></el-col>
                <el-col :span="12"><el-form-item label="现病治疗情况"><el-input v-model="record.presentTreat" type="textarea" :rows="3" /></el-form-item></el-col><el-col :span="12"><el-form-item label="既往史"><el-input v-model="record.history" type="textarea" :rows="3" /></el-form-item></el-col>
                <el-col :span="12"><el-form-item label="过敏史"><el-input v-model="record.allergy" type="textarea" :rows="3" /></el-form-item></el-col><el-col :span="12"><el-form-item label="体格检查"><el-input v-model="record.physique" type="textarea" :rows="3" /></el-form-item></el-col>
                <el-col :span="12"><el-form-item label="检查/检验建议"><el-input v-model="record.proposal" type="textarea" :rows="3" /></el-form-item></el-col><el-col :span="12"><el-form-item label="注意事项"><el-input v-model="record.careful" type="textarea" :rows="3" /></el-form-item></el-col></el-row>
                <div class="form-actions"><el-button type="primary" :loading="saving" @click="saveRecord">保存病历</el-button></div>
              </el-form>
            </template>

            <template v-else-if="orderTabs.some(item => item.name === tab.name)">
              <template v-for="order in orderTabs.filter(item => item.name === tab.name)" :key="order.type">
                <div class="section-heading"><div><h3>{{ order.title }}</h3><p>选择目录项目并填写医嘱，提交后进入待收费状态。</p></div><el-tag type="warning" effect="plain">未缴费可作废</el-tag></div>
                <el-form label-position="top" class="record-form order-form">
                  <el-form-item :label="`${order.title.replace('申请', '')}项目（可多选）`"><el-select v-model="orderForms[order.type].selectedIds" multiple filterable collapse-tags placeholder="请选择项目"><el-option v-for="item in catalogs[order.type]" :key="item.id" :label="`${item.code} · ${item.name} · ¥${item.price}`" :value="item.id" /></el-select></el-form-item>
                  <el-row :gutter="16"><el-col :span="12"><el-form-item label="目的要求"><el-input v-model="orderForms[order.type].info" type="textarea" :rows="4" :placeholder="order.purpose" /></el-form-item></el-col><el-col :span="12"><el-form-item label="部位"><el-input v-model="orderForms[order.type].position" type="textarea" :rows="4" placeholder="请输入部位，可留空" /></el-form-item></el-col></el-row>
                  <el-form-item label="备注"><el-input v-model="orderForms[order.type].remark" type="textarea" :rows="3" placeholder="请输入备注，可留空" /></el-form-item>
                  <div class="selected-strip"><span>已选 {{ orderForms[order.type].selectedIds.length }} 项</span><strong>合计 ¥{{ catalogs[order.type].filter(i => orderForms[order.type].selectedIds.includes(i.id)).reduce((sum, i) => sum + Number(i.price), 0).toFixed(2) }}</strong></div>
                  <div class="form-actions"><el-button @click="Object.assign(orderForms[order.type], { selectedIds: [], info: '', position: '', remark: '' })">清空</el-button><el-button type="primary" @click="submitOrder(order.type)">开立申请</el-button></div>
                </el-form>
              </template>
            </template>

            <template v-else-if="tab.name === 'checkResult' || tab.name === 'inspectionResult'">
              <div class="section-heading"><div><h3>{{ tab.label }}</h3><p>查看医技科室已经录入的执行结果。</p></div><el-button @click="selectVisit(currentVisit.registrationId)"><el-icon><Refresh /></el-icon>刷新</el-button></div>
              <el-table :data="tab.name === 'checkResult' ? checkResults : inspectionResults" stripe>
                <el-table-column prop="itemCode" label="项目编码" width="130" /><el-table-column prop="itemName" label="项目名称" min-width="160" /><el-table-column label="状态" width="110"><template #default="scope"><el-tag :type="scope.row.status === 'COMPLETED' ? 'success' : 'warning'">{{ resultStatus(scope.row.status) }}</el-tag></template></el-table-column>
                <el-table-column prop="executor" label="执行人员" width="110" /><el-table-column prop="executedAt" label="执行时间" width="170" /><el-table-column prop="result" label="结果" min-width="260" show-overflow-tooltip />
                <template #empty><el-empty :description="`暂无${tab.label}`" /></template>
              </el-table>
            </template>

            <template v-else-if="tab.name === 'diagnosis'">
              <div class="section-heading"><div><h3>门诊确诊</h3><p>关联疾病目录，填写最终诊断和处理意见。</p></div></div>
              <el-form label-position="top" class="record-form diagnosis-form">
                <el-form-item label="疾病诊断"><el-select v-model="diseaseIds" multiple filterable placeholder="请选择疾病"><el-option v-for="item in catalogs.disease" :key="item.id" :label="`${item.format} · ${item.name}`" :value="item.id" /></el-select></el-form-item>
                <el-form-item label="诊断结果（必填）"><el-input v-model="record.diagnosis" type="textarea" :rows="5" placeholder="请输入诊断结果" /></el-form-item>
                <el-form-item label="处理意见"><el-input v-model="record.cure" type="textarea" :rows="5" placeholder="请输入用药、复诊等处理意见" /></el-form-item>
                <div class="form-actions"><el-button type="primary" @click="saveCurrentDiagnosis">保存确诊</el-button></div>
              </el-form>
            </template>

            <template v-else-if="tab.name === 'prescription'">
              <div class="section-heading"><div><h3>开设处方</h3><p>逐行选择药品，填写用法用量和数量。</p></div><el-button type="primary" plain @click="addPrescriptionLine"><el-icon><Plus /></el-icon>添加明细</el-button></div>
              <el-table :data="prescriptionLines" stripe class="prescription-table">
                <el-table-column label="药品" min-width="230"><template #default="scope"><el-select v-model="scope.row.drugId" filterable placeholder="编码、名称或助记码"><el-option v-for="drug in catalogs.drug" :key="drug.id" :label="`${drug.code} · ${drug.name}`" :value="drug.id" /></el-select></template></el-table-column>
                <el-table-column label="规格" min-width="150"><template #default="scope">{{ drugOf(scope.row.drugId)?.format || '-' }}</template></el-table-column><el-table-column label="单价" width="100"><template #default="scope">¥{{ Number(drugOf(scope.row.drugId)?.price || 0).toFixed(2) }}</template></el-table-column>
                <el-table-column label="用法用量" min-width="230"><template #default="scope"><el-input v-model="scope.row.usage" placeholder="如：口服，一日3次，一次1粒" /></template></el-table-column><el-table-column label="数量" width="150"><template #default="scope"><el-input-number v-model="scope.row.quantity" :min="0.001" :precision="3" :step="1" /></template></el-table-column>
                <el-table-column label="金额" width="110"><template #default="scope"><strong>¥{{ (Number(drugOf(scope.row.drugId)?.price || 0) * scope.row.quantity).toFixed(2) }}</strong></template></el-table-column><el-table-column label="操作" width="80"><template #default="scope"><el-button link type="danger" @click="removePrescriptionLine(scope.$index)">删除</el-button></template></el-table-column>
              </el-table>
              <div class="prescription-summary"><span>共 {{ prescriptionLines.length }} 条处方明细</span><strong>处方合计 ¥{{ prescriptionTotal.toFixed(2) }}</strong></div>
              <div class="form-actions"><el-button @click="prescriptionLines = [{ drugId: 0, usage: '', quantity: 1 }]">重置处方</el-button><el-button type="primary" @click="submitPrescription">开立处方</el-button></div>
            </template>

            <template v-else-if="tab.name === 'costs'">
              <div class="section-heading"><div><h3>费用查询</h3><p>查看本次诊疗的项目费用、缴费及执行状态。</p></div><div class="cost-total"><span>有效费用合计</span><strong>¥{{ costTotal.toFixed(2) }}</strong></div></div>
              <el-table :data="costs" stripe>
                <el-table-column label="类型" width="100"><template #default="scope"><el-tag effect="plain">{{ orderTypeLabel(scope.row.type) }}</el-tag></template></el-table-column><el-table-column prop="itemName" label="项目名称" min-width="180" /><el-table-column prop="unitPrice" label="单价" width="100"><template #default="scope">¥{{ Number(scope.row.unitPrice).toFixed(2) }}</template></el-table-column>
                <el-table-column prop="quantity" label="数量" width="90" /><el-table-column prop="amount" label="金额" width="110"><template #default="scope"><strong>¥{{ Number(scope.row.amount).toFixed(2) }}</strong></template></el-table-column><el-table-column prop="createdAt" label="开立时间" width="170" />
                <el-table-column label="状态" width="110"><template #default="scope"><el-tag :type="costStatusType(scope.row.status)">{{ paymentStateLabel(scope.row.status) }}</el-tag></template></el-table-column><el-table-column label="操作" width="90"><template #default="scope"><el-button v-if="scope.row.status === 'UNPAID'" link type="danger" @click="cancelCost(scope.row)">作废</el-button><span v-else>-</span></template></el-table-column>
                <template #empty><el-empty description="暂无费用项目" /></template>
              </el-table>
            </template>
          </el-tab-pane>
        </el-tabs>
      </el-card>
    </div>
  </section>
</template>

<style scoped>
.doctor-page{max-width:1700px;margin:0 auto}.doctor-workstation{height:calc(100vh - 158px);min-height:680px}.patient-queue,.clinical-panel{min-height:0}.patient-queue :deep(.el-card__body){height:calc(100% - 73px);display:flex;flex-direction:column}.queue-list{overflow:auto;min-height:180px}.clinical-panel :deep(.el-card__body){height:calc(100% - 76px);padding:0 18px 18px}.doctor-tabs{height:100%}.doctor-tabs :deep(.el-tabs__header){margin:0}.doctor-tabs :deep(.el-tabs__nav-wrap){padding:0 4px}.doctor-tabs :deep(.el-tabs__item){padding:0 13px;font-size:13px}.doctor-tabs :deep(.el-tabs__content){height:calc(100% - 40px);overflow:auto;padding:18px 4px 4px}.section-heading{display:flex;align-items:center;justify-content:space-between;margin-bottom:18px;padding-bottom:14px;border-bottom:1px solid var(--border)}.section-heading h3{margin:0;font-size:18px}.section-heading p{margin:6px 0 0;color:#80919d;font-size:12px}.record-form{max-width:1120px;margin:0 auto}.order-form .el-select,.diagnosis-form .el-select,.prescription-table .el-select{width:100%}.selected-strip,.prescription-summary{display:flex;justify-content:space-between;align-items:center;margin:4px 0 18px;padding:13px 16px;border-radius:10px;background:#f2f7f8;color:#637785}.selected-strip strong,.prescription-summary strong{color:var(--primary);font-size:16px}.form-actions{margin-top:16px}.prescription-table :deep(.el-input-number){width:125px}.cost-total{text-align:right}.cost-total span,.cost-total strong{display:block}.cost-total span{font-size:11px;color:#84949f}.cost-total strong{margin-top:3px;color:var(--primary);font-size:22px}.state-value{color:var(--primary)!important}@media(max-width:1366px){.doctor-workstation{grid-template-columns:270px 1fr}.doctor-tabs :deep(.el-tabs__item){padding:0 9px;font-size:12px}.vital{padding:0 10px!important}}
</style>
