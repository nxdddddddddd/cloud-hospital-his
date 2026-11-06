import pinia from '@/stores'
import { useUserStore } from '@/stores/user'

export function hasPermission(permission?: string) {
  if (!permission) return true
  const permissions = useUserStore(pinia).permissions
  return permissions.includes('*:*:*') || permissions.includes(permission)
}
