<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getCaptcha, type LoginData } from '@/api/login'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()
const loading = ref(false)
const useMockAuth = import.meta.env.VITE_USE_MOCK_AUTH === 'true'
const captchaEnabled = ref(!useMockAuth)
const captchaImage = ref('')
const form = reactive<LoginData>({ username: 'admin', password: 'admin123', code: '', uuid: '' })

async function loadCaptcha() {
  if (useMockAuth) {
    captchaEnabled.value = false
    return
  }
  try {
    const result = await getCaptcha()
    captchaEnabled.value = result.captchaEnabled
    form.code = ''
    form.uuid = result.uuid ?? ''
    captchaImage.value = result.img ? `data:image/gif;base64,${result.img}` : ''
  } catch {
    captchaImage.value = ''
  }
}

async function submit() {
  loading.value = true
  try {
    await userStore.login(form)
    await userStore.getInfo()
    await router.replace(String(route.query.redirect || '/'))
  } catch {
    if (captchaEnabled.value) await loadCaptcha()
  } finally {
    loading.value = false
  }
}

onMounted(loadCaptcha)
</script>

<template>
  <div class="login-page">
    <section class="login-intro">
      <div class="brand-mark large">H+</div>
      <p class="eyebrow">CLOUD HOSPITAL</p>
      <h1>让门诊协作<br />更清晰、更高效</h1>
      <p>覆盖挂号、接诊、收费、医技执行与药房服务的统一工作平台。</p>
      <div class="feature-list">
        <span><el-icon><CircleCheck /></el-icon>岗位权限隔离</span>
        <span><el-icon><CircleCheck /></el-icon>业务状态贯通</span>
        <span><el-icon><CircleCheck /></el-icon>关键操作留痕</span>
      </div>
    </section>
    <section class="login-panel">
      <div class="login-box">
        <header><span>员工工作台</span><h2>登录云医院 HIS</h2><p>请输入医院员工账号继续</p></header>
        <el-form label-position="top" @submit.prevent="submit">
          <el-form-item label="账号"><el-input v-model="form.username" size="large" prefix-icon="User" /></el-form-item>
          <el-form-item label="密码"><el-input v-model="form.password" size="large" type="password" show-password prefix-icon="Lock" /></el-form-item>
          <el-form-item v-if="captchaEnabled" label="验证码">
            <div class="captcha-row">
              <el-input v-model="form.code" size="large" placeholder="请输入验证码" prefix-icon="Key" />
              <button class="captcha-image" type="button" title="点击刷新验证码" @click="loadCaptcha">
                <img v-if="captchaImage" :src="captchaImage" alt="验证码" />
                <span v-else>点击刷新</span>
              </button>
            </div>
          </el-form-item>
          <div class="login-options"><el-checkbox checked>记住账号</el-checkbox><el-link type="primary">联系管理员</el-link></div>
          <el-button type="primary" size="large" native-type="submit" :loading="loading">进入工作台</el-button>
        </el-form>
        <p v-if="useMockAuth" class="login-hint">当前使用模拟认证，可直接登录</p>
      </div>
    </section>
  </div>
</template>

<style scoped>
.captcha-row {
  display: grid;
  grid-template-columns: 1fr 120px;
  gap: 10px;
  width: 100%;
}

.captcha-image {
  height: 40px;
  padding: 0;
  overflow: hidden;
  color: #7f909f;
  cursor: pointer;
  background: #f6f9fa;
  border: 1px solid var(--border);
  border-radius: 4px;
}

.captcha-image img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}
</style>
