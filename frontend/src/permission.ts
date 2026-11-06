import NProgress from 'nprogress'
import 'nprogress/nprogress.css'
import router from './router'
import pinia from './stores'
import { useUserStore } from './stores/user'
import { getToken } from './utils/auth'
import { hasPermission } from './utils/permission'

NProgress.configure({ showSpinner: false })
const whiteList = ['/login']
router.beforeEach(async (to) => {
  NProgress.start()
  document.title = `${to.meta.title ?? '工作台'} - ${import.meta.env.VITE_APP_TITLE}`
  const token = getToken()
  if (!token) return whiteList.includes(to.path) ? true : `/login?redirect=${encodeURIComponent(to.fullPath)}`
  if (to.path === '/login') return '/'
  const userStore = useUserStore(pinia)
  if (!userStore.profile) await userStore.getInfo()
  if (!hasPermission(to.meta.permission)) return '/403'
  return true
})
router.afterEach(() => NProgress.done())
router.onError(() => NProgress.done())
