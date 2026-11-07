# Cloud Hospital HIS

云医院HIS门诊管理系统，面向挂号收费员、门诊医生、医技人员和药房工作人员，覆盖挂号、接诊、收费、检查检验、处置及发退药流程。

## 快速启动

需要 JDK 17、Maven 3.9、Node.js 20+、MySQL 8 和 Redis。

### 1. 初始化数据库

依次执行 `sql/his_cloud.sql`、`sql/ruoyi_system.sql`、`sql/quartz.sql`。后两个脚本需在 `his_cloud_completed` 数据库中执行。

### 2. 启动后端

默认连接本机 MySQL、Redis，MySQL 账号为 `root/password`。配置不同时通过 `HIS_DB_USERNAME`、`HIS_DB_PASSWORD`、`HIS_REDIS_HOST` 等环境变量覆盖。

```bash
cd backend
mvn -pl ruoyi-admin -am clean package -DskipTests
java -jar ruoyi-admin/target/ruoyi-admin.jar
```

后端地址为 `http://localhost:8080`，默认账号为 `admin/admin123`。

### 3. 启动前端

```bash
cd frontend
cp .env.example .env.development
npm install
npm run dev
```

`.env.example` 默认使用模拟认证。与后端联调时，将本地 `.env.development` 中的 `VITE_USE_MOCK_AUTH` 改为 `false`；该本地配置不会提交到 Git。

## 前端效果图

### 登录页

![登录页](docs/前端效果图/01_登录页.png)

### 工作台

![工作台](docs/前端效果图/02_工作台.png)

### 医生工作站

![医生工作站](docs/前端效果图/03_医生工作站.png)

