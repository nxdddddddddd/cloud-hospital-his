import test from 'node:test'
import assert from 'node:assert/strict'
import {
  filterMedicalTechOrders,
  summarizeMedicalTechOrders,
  completeMedicalTechOrder,
  mapMedicalTechApiOrder,
  type MedicalTechOrder
} from '../src/domain/medicalTech.ts'

const orders: MedicalTechOrder[] = [
  { id: '1', orderNo: 'CHK001', category: 'examination', patientName: '张文杰', outpatientNo: 'MZ001', itemName: '胸部正位片', department: '呼吸内科', doctorName: '李医生', appliedAt: '2026-11-07 08:30', status: 'pending' },
  { id: '2', orderNo: 'LAB001', category: 'laboratory', patientName: '王晓梅', outpatientNo: 'MZ002', itemName: '血常规', department: '心内科', doctorName: '周医生', appliedAt: '2026-11-07 09:10', status: 'inProgress' },
  { id: '3', orderNo: 'DSP001', category: 'treatment', patientName: '赵海', outpatientNo: 'MZ003', itemName: '雾化吸入', department: '呼吸内科', doctorName: '李医生', appliedAt: '2026-11-07 10:00', status: 'completed', result: '治疗完成' }
]

test('筛选只返回指定业务、状态且命中患者关键字的医技申请', () => {
  const result = filterMedicalTechOrders(orders, {
    category: 'examination',
    status: 'pending',
    keyword: '张文'
  })

  assert.deepEqual(result.map((item) => item.orderNo), ['CHK001'])
})

test('统计分别计算待执行、执行中和已完成数量', () => {
  assert.deepEqual(summarizeMedicalTechOrders(orders), {
    total: 3,
    pending: 1,
    inProgress: 1,
    completed: 1
  })
})

test('录入结果后申请转为已完成并保留执行信息', () => {
  const completed = completeMedicalTechOrder(orders[0], {
    executor: '陈技师',
    result: '未见明显异常',
    executedAt: '2026-11-07 11:20'
  })

  assert.equal(completed.status, 'completed')
  assert.equal(completed.executor, '陈技师')
  assert.equal(completed.result, '未见明显异常')
  assert.equal(completed.executedAt, '2026-11-07 11:20')
})

test('后端医技状态映射为前端统一状态', () => {
  const mapped = mapMedicalTechApiOrder({
    id: 18,
    orderNo: 'LAB18',
    category: 'laboratory',
    patientName: '王晓梅',
    outpatientNo: 'MZ002',
    itemName: '血常规',
    department: '检验科',
    doctorName: '周医生',
    appliedAt: '2026-11-07 09:10:00',
    status: 'EXECUTING',
    executor: '林检验师'
  })

  assert.equal(mapped.id, '18')
  assert.equal(mapped.status, 'inProgress')
  assert.equal(mapped.appliedAt, '2026-11-07 09:10:00')
})
