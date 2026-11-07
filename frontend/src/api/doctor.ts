import request, { type RuoYiResponse } from '@/api/request'
import type { CatalogItem, CostItem, DoctorVisit, MedicalOrderLine, MedicalRecordForm, MedicalResult, PrescriptionLine } from '@/domain/doctor'

export const useMockDoctorApi = () => import.meta.env.VITE_USE_MOCK_AUTH === 'true'

export async function listDoctorVisits(params?: { state?: string; keyword?: string }) {
  const response = await request.get<never, RuoYiResponse<DoctorVisit[]>>('/his/doctor/visits', { params })
  return response.data
}

export const acceptVisit = (registrationId: number) => request.post(`/his/visit/${registrationId}/accept`)

export async function getMedicalRecord(registrationId: number) {
  const response = await request.get<never, RuoYiResponse<MedicalRecordForm>>(`/his/medicalRecord/${registrationId}`)
  return response.data
}

export const saveMedicalRecord = (record: MedicalRecordForm) => request.put('/his/medicalRecord', record)

export async function listDoctorCatalog(type: string, keyword?: string) {
  const response = await request.get<never, RuoYiResponse<CatalogItem[]>>(`/his/doctor/catalog/${type}`, { params: { keyword } })
  return response.data
}

export const createMedicalOrder = (registrationId: number, type: string, items: MedicalOrderLine[]) =>
  request.post('/his/medicalOrder', { registrationId, type, items })

export const createPrescription = (registrationId: number, items: PrescriptionLine[]) =>
  request.post('/his/prescription', { registrationId, items })

export const cancelMedicalOrder = (type: string, id: number) => request.post(`/his/medicalOrder/${type}/${id}/cancel`)

export async function getVisitResults(registrationId: number) {
  const response = await request.get<never, RuoYiResponse<MedicalResult[]>>(`/his/visit/${registrationId}/results`)
  return response.data
}

export const saveDiagnosis = (registrationId: number, diseaseIds: number[], diagnosis: string, cure: string) =>
  request.put(`/his/visit/${registrationId}/diagnosis`, { diseaseIds, diagnosis, cure })

export const completeVisit = (registrationId: number) => request.post(`/his/visit/${registrationId}/complete`)

export async function getVisitCosts(registrationId: number) {
  const response = await request.get<never, RuoYiResponse<CostItem[]>>(`/his/visit/${registrationId}/costs`)
  return response.data
}
