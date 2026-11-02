const { chromium } = require('C:/Users/19468/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright')
const path = require('node:path')
const fs = require('node:fs')

async function main() {
  const browser = await chromium.launch({
    headless: true,
    executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe'
  })
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 1 })
  const output = path.resolve(__dirname, '../../docs/前端效果图')
  fs.mkdirSync(output, { recursive: true })

  await page.goto('http://127.0.0.1:5173/login', { waitUntil: 'networkidle' })
  await page.screenshot({ path: path.join(output, '01_登录页.png'), fullPage: true })

  await page.evaluate(() => localStorage.setItem('Cloud-Hospital-Token', 'preview-token'))
  await page.goto('http://127.0.0.1:5173/dashboard', { waitUntil: 'networkidle' })
  await page.screenshot({ path: path.join(output, '02_工作台.png'), fullPage: true })

  await page.goto('http://127.0.0.1:5173/doctor/workstation', { waitUntil: 'networkidle' })
  await page.screenshot({ path: path.join(output, '03_医生工作站.png'), fullPage: true })
  await browser.close()
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
