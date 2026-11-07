import type { CatalogItem, CostItem, DoctorVisit, MedicalRecordForm, MedicalResult } from '@/domain/doctor'

export const doctorVisits: DoctorVisit[] = [
  { registrationId: 1, caseNumber: 'DEMO0001', patientName: '陈演示', gender: '男', age: 36, ageType: '年', cardNumber: '110101199001010011', homeAddress: '教学演示地址', visitState: 2, visitDate: '2026-11-07', noon: '上午', departmentName: '内科', settlementName: '自费', allergy: '否认药物过敏。' },
  { registrationId: 2, caseNumber: 'MZ20261107002', patientName: '王晓梅', gender: '女', age: 45, ageType: '年', visitState: 1, visitDate: '2026-11-07', noon: '上午', departmentName: '内科', settlementName: '医保' },
  { registrationId: 3, caseNumber: 'MZ20261107003', patientName: '刘建国', gender: '男', age: 62, ageType: '年', visitState: 3, visitDate: '2026-11-07', noon: '上午', departmentName: '内科', settlementName: '自费', diagnosis: '原发性高血压' }
]

export const doctorCatalog: Record<string, CatalogItem[]> = {
  check: [
    { id: 1, code: 'JC001', name: '胸部X线检查', format: '正位', price: 80, category: '检查费', department: '检查科' },
    { id: 2, code: 'JC002', name: '心电图检查', format: '十二导联', price: 30, category: '检查费', department: '检查科' }
  ],
  inspection: [
    { id: 3, code: 'JY001', name: '血常规', format: '五分类', price: 25, category: '检验费', department: '检验科' },
    { id: 4, code: 'JY002', name: '尿常规', format: '干化学法', price: 20, category: '检验费', department: '检验科' }
  ],
  disposal: [
    { id: 5, code: 'CZ001', name: '普通换药', format: '小换药', price: 15, category: '处置费', department: '处置科' },
    { id: 6, code: 'CZ002', name: '静脉输液', format: '一次', price: 10, category: '处置费', department: '处置科' }
  ],
  drug: [
    { id: 1, code: 'YP001', name: '阿莫西林胶囊', format: '0.25g×24粒/盒', unit: '盒', price: 18.5, stock: 100, manufacturer: '演示制药一厂' },
    { id: 2, code: 'YP002', name: '布洛芬缓释胶囊', format: '0.3g×20粒/盒', unit: '盒', price: 16, stock: 100, manufacturer: '演示制药二厂' },
    { id: 3, code: 'YP003', name: '感冒灵颗粒', format: '10g×9袋/盒', unit: '盒', price: 12.8, stock: 100, manufacturer: '演示制药三厂' }
  ],
  disease: [
    { id: 1, code: 'GR', name: '急性上呼吸道感染', format: 'J06.900', category: '呼吸系统' },
    { id: 2, code: 'GY', name: '原发性高血压', format: 'I10.x00', category: '循环系统' },
    { id: 3, code: 'WG', name: '急性胃肠炎', format: 'A09.901', category: '消化系统' }
  ]
}

export const demoMedicalRecord: MedicalRecordForm = {
  registrationId: 1, readme: '咳嗽、咽痛两天', present: '两天前受凉后出现咳嗽、咽痛，无胸痛。', presentTreat: '',
  history: '既往体健。', allergy: '否认药物过敏。', physique: '咽部充血，双肺呼吸音清。', proposal: '', careful: '',
  diagnosis: '急性上呼吸道感染', cure: '完善检查，口服药物治疗，三日后复诊。', diseaseIds: '1'
}

export const demoResults: MedicalResult[] = [
  { id: 1, type: 'check', itemCode: 'JC001', itemName: '胸部X线检查', status: 'COMPLETED', result: '两肺纹理清晰，未见明显异常。', executor: '赵检查', executedAt: '2026-11-07 10:20:00' },
  { id: 1, type: 'inspection', itemCode: 'JY001', itemName: '血常规', status: 'COMPLETED', result: '白细胞计数轻度升高，其余指标未见明显异常。', executor: '钱检验', executedAt: '2026-11-07 10:35:00' }
]

export const demoCosts: CostItem[] = [
  { id: 1, type: 'CHECK', itemName: '胸部X线检查', quantity: 1, unitPrice: 80, amount: 80, status: 'PAID', createdAt: '2026-11-07 09:10:00' },
  { id: 1, type: 'INSPECTION', itemName: '血常规', quantity: 1, unitPrice: 25, amount: 25, status: 'PAID', createdAt: '2026-11-07 09:12:00' },
  { id: 1, type: 'DISPOSAL', itemName: '静脉输液', quantity: 1, unitPrice: 10, amount: 10, status: 'PAID', createdAt: '2026-11-07 09:15:00' },
  { id: 1, type: 'PRESCRIPTION', itemName: '感冒灵颗粒', quantity: 1, unitPrice: 12.8, amount: 12.8, status: 'PAID', createdAt: '2026-11-07 09:18:00' }
]
