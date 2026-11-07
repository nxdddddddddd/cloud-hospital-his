import type { MedicalTechOrder } from '@/domain/medicalTech'

export const medicalTechOrders: MedicalTechOrder[] = [
  { id: '1', orderNo: 'CHK202611070021', category: 'examination', patientName: '张文杰', outpatientNo: 'MZ20261107018', itemName: '胸部正位片', department: '呼吸内科', doctorName: '李医生', appliedAt: '2026-11-07 08:30', status: 'pending' },
  { id: '2', orderNo: 'CHK202611070024', category: 'examination', patientName: '孙丽', outpatientNo: 'MZ20261107022', itemName: '腹部彩超', department: '消化内科', doctorName: '周医生', appliedAt: '2026-11-07 09:05', status: 'inProgress', executor: '陈技师', executedAt: '2026-11-07 10:12' },
  { id: '3', orderNo: 'CHK202611060091', category: 'examination', patientName: '赵海', outpatientNo: 'MZ20261106072', itemName: '心电图', department: '心内科', doctorName: '吴医生', appliedAt: '2026-11-06 15:20', status: 'completed', executor: '王技师', executedAt: '2026-11-06 15:50', result: '窦性心律，未见明显异常。' },
  { id: '4', orderNo: 'LAB202611070018', category: 'laboratory', patientName: '王晓梅', outpatientNo: 'MZ20261107017', itemName: '血常规', department: '心内科', doctorName: '周医生', appliedAt: '2026-11-07 08:50', status: 'pending' },
  { id: '5', orderNo: 'LAB202611070020', category: 'laboratory', patientName: '刘建国', outpatientNo: 'MZ20261107012', itemName: '肝功能八项', department: '全科门诊', doctorName: '李医生', appliedAt: '2026-11-07 09:18', status: 'inProgress', executor: '林检验师', executedAt: '2026-11-07 09:42' },
  { id: '6', orderNo: 'LAB202611060076', category: 'laboratory', patientName: '郑敏', outpatientNo: 'MZ20261106061', itemName: '尿常规', department: '肾内科', doctorName: '徐医生', appliedAt: '2026-11-06 14:10', status: 'completed', executor: '林检验师', executedAt: '2026-11-06 14:45', result: '各项指标在参考范围内。' },
  { id: '7', orderNo: 'DSP202611070011', category: 'treatment', patientName: '何明', outpatientNo: 'MZ20261107009', itemName: '雾化吸入', department: '呼吸内科', doctorName: '李医生', appliedAt: '2026-11-07 08:40', status: 'pending' },
  { id: '8', orderNo: 'DSP202611070014', category: 'treatment', patientName: '陈洁', outpatientNo: 'MZ20261107013', itemName: '伤口换药', department: '外科门诊', doctorName: '韩医生', appliedAt: '2026-11-07 09:25', status: 'inProgress', executor: '赵护士', executedAt: '2026-11-07 09:55' },
  { id: '9', orderNo: 'DSP202611060052', category: 'treatment', patientName: '赵海', outpatientNo: 'MZ20261106048', itemName: '静脉输液', department: '急诊内科', doctorName: '吴医生', appliedAt: '2026-11-06 13:20', status: 'completed', executor: '赵护士', executedAt: '2026-11-06 15:20', result: '处置顺利完成，患者无不适。' }
]
