<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { hasPermission } from '@/utils/permission'
import LiquidGlassDefs from '@/components/LiquidGlassDefs.vue'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()
const collapsed = ref(false)
const menuRoutes = computed(() => router.options.routes.filter((item) => !item.meta?.hidden && hasPermission(item.meta?.permission)))
const pageTitle = computed(() => route.meta.title ?? '工作台')
const today = new Intl.DateTimeFormat('zh-CN', { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' }).format(new Date())

async function handleCommand(command: string) {
  if (command === 'logout') {
    await userStore.logout()
    await router.replace('/login')
  }
}
</script>

<template>
  <LiquidGlassDefs />
  <div class="app-shell" :class="{ collapsed }">
    <aside class="sidebar">
      <div class="brand">
        <div class="brand-mark">H+</div>
        <div v-show="!collapsed" class="brand-copy"><strong>云医院 HIS</strong><span>门诊管理系统</span></div>
      </div>
      <el-scrollbar class="menu-scroll">
        <el-menu :default-active="route.path" router :collapse="collapsed" :collapse-transition="false">
          <template v-for="item in menuRoutes" :key="item.path">
            <el-menu-item v-if="item.children?.length === 1" :index="`${item.path}/${item.children[0].path}`.replace('//', '/')">
              <el-icon><component :is="item.meta?.icon || item.children[0].meta?.icon || 'Menu'" /></el-icon>
              <template #title>{{ item.meta?.title || item.children[0].meta?.title }}</template>
            </el-menu-item>
          </template>
        </el-menu>
      </el-scrollbar>
      <div class="sidebar-foot"><span v-show="!collapsed">系统运行正常</span><i class="status-dot" /></div>
    </aside>
    <section class="workspace">
      <header class="topbar">
        <div class="topbar-left">
          <el-button text circle @click="collapsed = !collapsed"><el-icon size="20"><Fold v-if="!collapsed" /><Expand v-else /></el-icon></el-button>
          <div><h1>{{ pageTitle }}</h1><p>{{ today }}</p></div>
        </div>
        <div class="topbar-right">
          <el-tooltip content="消息中心"><el-badge :value="3"><el-button circle><el-icon><Bell /></el-icon></el-button></el-badge></el-tooltip>
          <div class="department"><span>当前科室</span><strong>{{ userStore.profile?.department }}</strong></div>
          <el-dropdown @command="handleCommand">
            <div class="user-card"><el-avatar :size="36">{{ userStore.profile?.nickName?.slice(0, 1) }}</el-avatar><div><strong>{{ userStore.profile?.nickName }}</strong><span>在岗</span></div><el-icon><ArrowDown /></el-icon></div>
            <template #dropdown><el-dropdown-menu><el-dropdown-item command="logout"><el-icon><SwitchButton /></el-icon>退出登录</el-dropdown-item></el-dropdown-menu></template>
          </el-dropdown>
        </div>
      </header>
      <main class="page-container">
        <router-view v-slot="{ Component, route: currentRoute }">
          <transition name="page" mode="out-in">
            <component :is="Component" :key="currentRoute.path" />
          </transition>
        </router-view>
      </main>
    </section>
  </div>
</template>
