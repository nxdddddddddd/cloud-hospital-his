<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'

const router = useRouter(), route = useRoute(), userStore = useUserStore()
const loading = ref(false)
const form = reactive({ username: 'admin', password: 'admin123' })
async function submit() { loading.value = true; try { await userStore.login(form); await userStore.getInfo(); await router.replace(String(route.query.redirect || '/')) } finally { loading.value = false } }
</script>
<template><div class="login-page"><section class="login-intro"><div class="brand-mark large">H+</div><p class="eyebrow">CLOUD HOSPITAL</p><h1>让门诊协作<br />更清晰、更高效</h1><p>覆盖挂号、接诊、收费、医技执行与药房服务的统一工作平台。</p><div class="feature-list"><span><el-icon><CircleCheck /></el-icon>岗位权限隔离</span><span><el-icon><CircleCheck /></el-icon>业务状态贯通</span><span><el-icon><CircleCheck /></el-icon>关键操作留痕</span></div></section><section class="login-panel"><div class="login-box"><header><span>员工工作台</span><h2>登录云医院 HIS</h2><p>请输入医院员工账号继续</p></header><el-form label-position="top" @submit.prevent="submit"><el-form-item label="账号"><el-input v-model="form.username" size="large" prefix-icon="User" /></el-form-item><el-form-item label="密码"><el-input v-model="form.password" size="large" type="password" show-password prefix-icon="Lock" /></el-form-item><div class="login-options"><el-checkbox checked>记住账号</el-checkbox><el-link type="primary">联系管理员</el-link></div><el-button type="primary" size="large" native-type="submit" :loading="loading">进入工作台</el-button></el-form><p class="login-hint">开发环境已启用模拟认证，可直接登录</p></div></section></div></template>
