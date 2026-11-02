# Cloud Hospital HIS

云医院HIS门诊管理系统，面向挂号收费员、门诊医生、医技人员和药房工作人员，覆盖挂号、接诊、收费、检查检验、处置及发退药流程。

## 技术栈

- 前端：Vue 3、Element Plus、Axios、Pinia
- 后端：RuoYi、Spring Boot、MyBatis
- 数据库：MySQL 8

## 目录

```text
docs/    项目需求与协作规范
frontend/ Vue 3 前端工程
sql/     数据库脚本
```

## 前端启动

```bash
cd frontend
npm install
npm run dev
```

开发环境默认启用模拟登录，可直接使用页面预填账号进入工作台。连接RuoYi后端时，将 `.env.development` 中的 `VITE_USE_MOCK_AUTH` 改为 `false`，并配置后端代理地址。

