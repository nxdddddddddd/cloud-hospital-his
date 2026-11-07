<script setup lang="ts">
import MedicalTechWorkspace from '@/components/MedicalTechWorkspace.vue'
import type { MedicalTechCategory } from '@/domain/medicalTech'

defineProps<{ category: MedicalTechCategory; mode: 'pending' | 'patient-entry' | 'result-entry' | 'query' }>()
</script>

<template><MedicalTechWorkspace :category="category" :mode="mode" /></template>
