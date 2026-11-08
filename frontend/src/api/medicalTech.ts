import request, { type RuoYiResponse } from '@/api/request'
import { mapMedicalTechApiOrder, type CompletionInput, type MedicalTechApiOrder, type MedicalTechCategory } from '@/domain/medicalTech'

export async function listMedicalTechOrders(category: MedicalTechCategory, params?: { status?: string; keyword?: string }) {
  const response = await request.get<never, RuoYiResponse<MedicalTechApiOrder[]>>(`/his/medical-tech/${category}`, { params })
  return response.data.map(mapMedicalTechApiOrder)
}

export async function startMedicalTechOrder(category: MedicalTechCategory, id: string) {
  await request.put(`/his/medical-tech/${category}/${id}/start`)
}

export async function saveMedicalTechResult(category: MedicalTechCategory, id: string, input: CompletionInput) {
  await request.put(`/his/medical-tech/${category}/${id}/complete`, input)
}

export function useMockMedicalTechApi() {
  return import.meta.env.VITE_USE_MOCK_AUTH === 'true'
}
