export type VisitState = 1 | 2 | 3
export type DoctorTab = 'patients' | 'record' | 'check' | 'inspection' | 'checkResult' | 'inspectionResult' | 'diagnosis' | 'prescription' | 'disposal' | 'costs'
export type OrderType = 'check' | 'inspection' | 'disposal'

export interface DoctorVisit {
  registrationId: number
  caseNumber: string
  patientName: string
  gender?: string
  age?: number
  ageType?: string
  cardNumber?: string
  homeAddress?: string
  noon?: string
  visitState: VisitState
  visitDate?: string
  departmentName?: string
  settlementName?: string
  allergy?: string
  diagnosis?: string
}

export interface MedicalRecordForm {
  registrationId: number
  readme: string
  present: string
  presentTreat: string
  history: string
  allergy: string
  physique: string
  proposal: string
  careful: string
  diagnosis?: string
  cure?: string
  diseaseIds?: string
}

export interface CatalogItem {
  id: number
  code: string
  name: string
  format?: string
  unit?: string
  price?: number
  category?: string
  department?: string
  manufacturer?: string
  stock?: number
}

export interface MedicalResult {
  id: number
  type: 'check' | 'inspection'
  itemCode: string
  itemName: string
  status: string
  result?: string
  executor?: string
  executedAt?: string
}

export interface CostItem {
  id: number
  type: 'CHECK' | 'INSPECTION' | 'DISPOSAL' | 'PRESCRIPTION'
  itemName: string
  quantity: number
  unitPrice: number
  amount: number
  status: string
  createdAt: string
}

export interface MedicalOrderLine { medicalTechnologyId: number; info: string; position: string; remark: string }
export interface PrescriptionLine { drugId: number; usage: string; quantity: number }

export function filterDoctorVisits(visits: DoctorVisit[], state: 'waiting' | 'completed', keyword = '') {
  const normalized = keyword.trim().toLocaleLowerCase('zh-CN')
  return visits.filter((visit) => {
    const stateMatch = state === 'waiting' ? visit.visitState === 1 || visit.visitState === 2 : visit.visitState === 3
    const text = `${visit.patientName} ${visit.caseNumber} ${visit.cardNumber ?? ''}`.toLocaleLowerCase('zh-CN')
    return stateMatch && (!normalized || text.includes(normalized))
  })
}

export function visitStateLabel(state: VisitState) {
  return ({ 1: '待接诊', 2: '接诊中', 3: '已诊' } as const)[state]
}

export function sumCosts(items: CostItem[]) {
  return Number(items.filter((item) => item.status !== 'CANCELLED' && item.status !== 'REFUNDED')
    .reduce((total, item) => total + Number(item.amount), 0).toFixed(2))
}

export function orderTypeLabel(type: CostItem['type']) {
  return { CHECK: '检查', INSPECTION: '检验', DISPOSAL: '处置', PRESCRIPTION: '药品' }[type]
}

export function paymentStateLabel(status: string) {
  return ({ UNPAID: '待缴费', PAID: '已缴费', EXECUTING: '执行中', COMPLETED: '已完成',
    DISPENSED: '已发药', RETURNED: '已退药', REFUNDED: '已退费', CANCELLED: '已作废' } as Record<string, string>)[status] ?? status
}
