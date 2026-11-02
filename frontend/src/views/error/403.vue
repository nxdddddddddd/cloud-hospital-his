<script setup lang="ts">
import { useRouter } from 'vue-router'

const router = useRouter()
</script>
<template><div class="error-page"><strong>403</strong><h2>无权访问当前页面</h2><p>请联系系统管理员为当前岗位配置菜单或按钮权限。</p><el-button type="primary" @click="router.replace('/')">返回工作台</el-button></div></template>
