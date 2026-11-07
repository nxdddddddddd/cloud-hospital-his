import { defineStore } from 'pinia'
import { login as loginApi, logout as logoutApi, type LoginData } from '@/api/login'
import { getToken, removeToken, setToken } from '@/utils/auth'

export interface UserProfile { name: string; nickName: string; department: string; roles: string[]; permissions: string[] }
const mockProfile: UserProfile = { name: 'demo', nickName: '演示用户', department: '门诊部', roles: ['admin'], permissions: ['*:*:*'] }

export const useUserStore = defineStore('user', {
  state: () => ({ token: getToken() || '', profile: null as UserProfile | null }),
  getters: { roles: (state) => state.profile?.roles ?? [], permissions: (state) => state.profile?.permissions ?? [] },
  actions: {
    async login(form: LoginData) {
      if (import.meta.env.VITE_USE_MOCK_AUTH === 'true') {
        this.token = `mock-${Date.now()}`
      } else {
        const result = await loginApi(form)
        this.token = result.token
      }
      setToken(this.token)
    },
    async getInfo() {
      if (!this.token) throw new Error('未登录')
      if (import.meta.env.VITE_USE_MOCK_AUTH === 'true') this.profile = mockProfile
      else this.profile = mockProfile // 后端联调时在此映射 RuoYi /getInfo 返回值
      return this.profile
    },
    async logout() {
      if (import.meta.env.VITE_USE_MOCK_AUTH !== 'true') await logoutApi()
      this.token = ''
      this.profile = null
      removeToken()
    }
  }
})
