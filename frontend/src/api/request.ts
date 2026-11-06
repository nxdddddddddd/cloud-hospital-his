import axios, { type AxiosError, type InternalAxiosRequestConfig } from 'axios'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getToken, removeToken } from '@/utils/auth'

export interface RuoYiResponse<T = unknown> { code: number; msg: string; data: T; rows?: T[]; total?: number }

const service = axios.create({ baseURL: import.meta.env.VITE_APP_BASE_API, timeout: 15000 })
service.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const token = getToken()
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})
service.interceptors.response.use(
  (response: any): any => {
    const result = response.data as RuoYiResponse
    if (result.code === 200 || result.code === undefined) return result
    ElMessage.error(result.msg || '系统处理失败')
    return Promise.reject(new Error(result.msg))
  },
  async (error: AxiosError) => {
    if (error.response?.status === 401) {
      await ElMessageBox.alert('登录状态已失效，请重新登录。', '提示')
      removeToken()
      location.href = '/login'
    } else ElMessage.error(error.message || '网络连接异常')
    return Promise.reject(error)
  }
)
export default service
