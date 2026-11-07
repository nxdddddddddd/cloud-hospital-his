import test from 'node:test'
import assert from 'node:assert/strict'
import { filterDoctorVisits, paymentStateLabel, sumCosts, type CostItem, type DoctorVisit } from '../src/domain/doctor.ts'

const visits: DoctorVisit[] = [
  { registrationId: 1, caseNumber: 'MZ001', patientName: '陈演示', visitState: 1 },
  { registrationId: 2, caseNumber: 'MZ002', patientName: '王晓梅', visitState: 2 },
  { registrationId: 3, caseNumber: 'MZ003', patientName: '刘建国', visitState: 3 }
]

test('待诊队列包含未接诊和接诊中患者', () => {
  assert.deepEqual(filterDoctorVisits(visits, 'waiting').map((item) => item.registrationId), [1, 2])
})

test('患者搜索支持姓名和病历号', () => {
  assert.equal(filterDoctorVisits(visits, 'waiting', 'MZ002')[0]?.patientName, '王晓梅')
  assert.equal(filterDoctorVisits(visits, 'completed', '刘建')[0]?.registrationId, 3)
})

test('费用合计排除作废和已退费项目', () => {
  const items = [
    { amount: 80, status: 'PAID' }, { amount: 25, status: 'UNPAID' },
    { amount: 10, status: 'CANCELLED' }, { amount: 16, status: 'REFUNDED' }
  ] as CostItem[]
  assert.equal(sumCosts(items), 105)
})

test('后端状态转换为医生可读文本', () => {
  assert.equal(paymentStateLabel('UNPAID'), '待缴费')
  assert.equal(paymentStateLabel('COMPLETED'), '已完成')
})
