import request from './request'
export interface LoginData { username: string; password: string; code?: string; uuid?: string }
export interface LoginResult { token: string }
export const login = (data: LoginData) => request.post<unknown, { data: LoginResult }>('/login', data)
export const getInfo = () => request.get('/getInfo')
export const logout = () => request.post('/logout')
