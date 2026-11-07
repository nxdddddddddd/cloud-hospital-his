# Cloud Hospital HIS

云医院HIS门诊管理系统，面向挂号收费员、门诊医生、医技人员和药房工作人员，覆盖挂号、接诊、收费、检查检验、处置及发退药流程。

## 本地开发

需要 JDK 17、Maven 3.9、Node.js 20+、MySQL 8 和 Redis。

### 首次初始化（只需一次）

1. 依次执行 `sql/his_cloud.sql`、`sql/ruoyi_system.sql`、`sql/quartz.sql`。后两个脚本需在 `his_cloud_completed` 数据库中执行。
2. 在 `frontend` 目录复制 `.env.example` 为 `.env.development`，然后执行 `npm install`。
3. 启动 MySQL 和 Redis。数据库账号不是默认的 `root/password` 时，设置 `HIS_DB_USERNAME`、`HIS_DB_PASSWORD` 等环境变量。

数据库脚本不需要每天重复执行，只有新建或重置数据库时才需要重新导入。

### 日常启动

- 后端：在 IDEA 中运行 `backend/ruoyi-admin` 下的 `RuoYiApplication`。
- 前端：在 `frontend` 目录执行：

```text
npm run dev
```

后端地址为 `http://localhost:8080`，默认账号为 `admin/admin123`。与后端联调时，将 `.env.development` 中的 `VITE_USE_MOCK_AUTH` 改为 `false`。

### 命令行启动后端（可选）

不使用 IDEA 时，首次在 `backend` 目录执行一次 `mvn install -DskipTests`，以后进入 `backend/ruoyi-admin` 执行 `mvn spring-boot:run` 即可。

## 前端效果图

### 登录页

![登录页](docs/前端效果图/01_登录页.png)

### 工作台

![工作台](docs/前端效果图/02_工作台.png)

### 医生工作站

![医生工作站](docs/前端效果图/03_医生工作站.png)

