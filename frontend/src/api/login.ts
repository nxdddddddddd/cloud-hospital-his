import request from './request'
export interface LoginData { username: string; password: string; code?: string; uuid?: string }
export interface LoginResult { code: number; msg: string; token: string }
export interface CaptchaResult { code: number; msg: string; captchaEnabled: boolean; img?: string; uuid?: string }
export const login = (data: LoginData) => request.post<unknown, LoginResult>('/login', data)
export const getCaptcha = () => request.get<unknown, CaptchaResult>('/captchaImage')
export const getInfo = () => request.get('/getInfo')
export const logout = () => request.post('/logout')
