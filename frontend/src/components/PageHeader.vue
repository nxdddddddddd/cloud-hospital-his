<script setup lang="ts">
defineProps<{ title: string; description: string; badge?: string }>()
</script>
<template><div class="page-heading"><div><div class="heading-line"><h2>{{ title }}</h2><el-tag v-if="badge" effect="plain" round>{{ badge }}</el-tag></div><p>{{ description }}</p></div><div class="page-actions"><slot /></div></div></template>
