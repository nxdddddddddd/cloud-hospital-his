# Clinical Liquid Glass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将现有云医院 HIS 的视觉层改造为高可读性的纯白 Liquid Glass，同时保持业务布局和功能不变。

**Architecture:** 新增独立的 `liquid-glass.scss` 作为材质层，覆盖既有布局和 Element Plus 外观；现有 `index.scss` 保留结构尺寸，`motion.scss` 保留交互节奏。登录页、应用骨架和业务内容共享同一组玻璃 token，并通过浏览器验证可读性和响应式表现。

**Tech Stack:** Vue 3、TypeScript、Element Plus、SCSS、Vite

**Spec:** `docs/superpowers/specs/2026-11-05-clinical-liquid-glass-design.md`

## Global Constraints

- 不改变现有菜单、路由、字段和业务流程。
- 不增加运行时依赖，不使用全屏 SVG 置换滤镜或 Canvas。
- 动效限制为 120–240ms，并保留 `prefers-reduced-motion`。
- 患者身份、金额、生命体征和表格正文保持高对比度。

## Review Focus

- `backdrop-filter` 不可用时，玻璃表面仍呈白色且文字可读。
- 1280px 宽度下侧栏、筛选栏和医生工作站不遮挡关键操作。
- 表格行、输入框和弹出层不会因透明背景丢失边界。
- 减弱动态效果模式不出现位移动画。
- 登录页与业务页使用同一设计语言但保持表单聚焦清晰。

---

### Task 1: Liquid Glass 材质层

**Files:**
- Create: `frontend/src/styles/liquid-glass.scss`
- Modify: `frontend/src/main.ts`
- Test: `frontend/scripts/verify-liquid-glass.cjs`

**Interfaces:**
- Consumes: 既有 `.app-shell`、`.sidebar`、`.topbar`、`.business-card`、Element Plus 类名
- Produces: `--glass-*` CSS tokens 和全局材质覆盖

- [ ] **Step 1: 编写静态验证脚本并确认失败**

验证入口导入、玻璃 token、降级规则、减弱动态效果和关键正文不透明规则。

- [ ] **Step 2: 运行 `node scripts/verify-liquid-glass.cjs`**

Expected: FAIL，提示缺少 `liquid-glass.scss` 或入口导入。

- [ ] **Step 3: 实现纯白玻璃 token、环境背景、侧栏、顶栏、卡片、表格和表单覆盖**

- [ ] **Step 4: 运行静态验证脚本**

Expected: PASS。

### Task 2: 页面适配与视觉验证

**Files:**
- Modify: `frontend/src/styles/liquid-glass.scss`
- Modify: `frontend/scripts/capture-screenshots.cjs`（仅在验证需要时）
- Update: `docs/前端效果图/*.png`

**Interfaces:**
- Consumes: Task 1 的 `--glass-*` tokens
- Produces: 登录、工作台、医生工作站的可验证视觉结果

- [ ] **Step 1: 运行生产构建**

Run: `npm run build`

Expected: PASS，无 TypeScript 或 SCSS 错误。

- [ ] **Step 2: 在浏览器检查登录、工作台和医生工作站**

检查玻璃层级、表格对比度、焦点状态和 1280/1366/1440 布局。

- [ ] **Step 3: 修正视觉问题并重新构建**

- [ ] **Step 4: 更新三张效果图并确认无控制台错误**

### Task 3: 文档与交付

**Files:**
- Modify: `README.md`（仅当效果图链接或说明需要更新）
- Modify: `docs/superpowers/plans/2026-11-05-clinical-liquid-glass.md`

**Interfaces:**
- Consumes: 已验证的页面和截图
- Produces: 可审查提交

- [ ] **Step 1: 运行 `git diff --check` 与 `npm run build`**

- [ ] **Step 2: 提交并推送 `feature/nx-frontend-framework`**

Commit: `feat: 升级纯白液态玻璃界面`
