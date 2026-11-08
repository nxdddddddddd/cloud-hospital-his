export type MedicalTechCategory = 'examination' | 'laboratory' | 'treatment'
export type MedicalTechStatus = 'pending' | 'inProgress' | 'completed'

export interface MedicalTechOrder {
  id: string
  orderNo: string
  category: MedicalTechCategory
  patientName: string
  outpatientNo: string
  itemName: string
  department: string
  doctorName: string
  appliedAt: string
  status: MedicalTechStatus
  executor?: string
  executedAt?: string
  result?: string
}

export interface MedicalTechFilter {
  category?: MedicalTechCategory
  status?: MedicalTechStatus | 'all'
  keyword?: string
}

export interface CompletionInput {
  executedAt: string
  result: string
}

export interface MedicalTechApiOrder extends Omit<MedicalTechOrder, 'id' | 'status'> {
  id: number
  status: 'PAID' | 'EXECUTING' | 'COMPLETED'
}

export function mapMedicalTechApiOrder(order: MedicalTechApiOrder): MedicalTechOrder {
  const statusMap: Record<MedicalTechApiOrder['status'], MedicalTechStatus> = {
    PAID: 'pending',
    EXECUTING: 'inProgress',
    COMPLETED: 'completed'
  }
  return { ...order, id: String(order.id), status: statusMap[order.status] }
}

export function filterMedicalTechOrders(orders: MedicalTechOrder[], filter: MedicalTechFilter) {
  const keyword = filter.keyword?.trim().toLocaleLowerCase('zh-CN') ?? ''

  return orders.filter((order) => {
    const matchesCategory = !filter.category || order.category === filter.category
    const matchesStatus = !filter.status || filter.status === 'all' || order.status === filter.status
    const searchable = [order.orderNo, order.patientName, order.outpatientNo, order.itemName]
      .join(' ')
      .toLocaleLowerCase('zh-CN')
    return matchesCategory && matchesStatus && (!keyword || searchable.includes(keyword))
  })
}

export function summarizeMedicalTechOrders(orders: MedicalTechOrder[]) {
  return orders.reduce((summary, order) => {
    summary.total += 1
    summary[order.status] += 1
    return summary
  }, { total: 0, pending: 0, inProgress: 0, completed: 0 })
}

export function completeMedicalTechOrder(order: MedicalTechOrder, input: CompletionInput): MedicalTechOrder {
  return { ...order, ...input, status: 'completed' }
}
