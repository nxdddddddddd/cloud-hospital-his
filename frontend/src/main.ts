import { createApp } from 'vue'
import ElementPlus from 'element-plus'
import zhCn from 'element-plus/es/locale/lang/zh-cn'
import * as ElementPlusIconsVue from '@element-plus/icons-vue'
import 'element-plus/dist/index.css'
import '@/styles/index.scss'
import App from './App.vue'
import router from './router'
import pinia from './stores'
import './permission'

const app = createApp(App)
Object.entries(ElementPlusIconsVue).forEach(([key, component]) => app.component(key, component))
app.use(pinia).use(router).use(ElementPlus, { locale: zhCn }).mount('#app')
