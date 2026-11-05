const fs = require('node:fs')
const path = require('node:path')

const root = path.resolve(__dirname, '..')
const main = fs.readFileSync(path.join(root, 'src/main.ts'), 'utf8')
const stylePath = path.join(root, 'src/styles/liquid-glass.scss')
const layoutPath = path.join(root, 'src/layout/index.vue')
const defsPath = path.join(root, 'src/components/LiquidGlassDefs.vue')

if (!fs.existsSync(stylePath)) throw new Error('liquid-glass.scss is missing')

const css = fs.readFileSync(stylePath, 'utf8')
const layout = fs.readFileSync(layoutPath, 'utf8')
const checks = [
  [main.includes("@/styles/liquid-glass.scss"), 'main.ts must import liquid-glass.scss'],
  [css.includes('--glass-surface:'), 'glass surface token is missing'],
  [css.includes('backdrop-filter:'), 'backdrop filter is missing'],
  [css.includes('@supports not ((backdrop-filter:'), 'backdrop-filter fallback is missing'],
  [css.includes('@media (prefers-reduced-motion: reduce)'), 'reduced motion rule is missing'],
  [css.includes('.el-table__body'), 'opaque table body rule is missing'],
  [css.includes('.login-page'), 'login page glass treatment is missing'],
  [css.includes('background: var(--el-button-bg-color);'), 'primary button background must remain visible'],
  [css.includes('--glass-surface: rgba(255, 255, 255, .48);'), 'glass surface must use the approved high transparency'],
  [css.includes('--glass-ambient: rgba(214, 221, 225, .34);'), 'ambient light must stay neutral'],
  [fs.existsSync(defsPath), 'shared liquid glass SVG filter is missing'],
  [layout.includes('<LiquidGlassDefs />'), 'layout must mount the shared liquid glass filter'],
  [css.includes('url(#his-liquid-edge)'), 'small glass controls must use edge refraction'],
]

for (const [passed, message] of checks) {
  if (!passed) throw new Error(message)
}

console.log('Liquid Glass contract: PASS')
