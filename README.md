# Cloud Hospital HIS

云医院HIS门诊管理系统，面向挂号收费员、门诊医生、医技人员和药房工作人员，覆盖挂号、接诊、收费、检查检验、处置及发退药流程。

## 技术栈

- 前端：Vue 3、Element Plus、Axios、Pinia
- 后端：RuoYi 3.9.2、Spring Boot 4、MyBatis
- 数据库：MySQL 8、Redis

## 目录

```text
backend/   RuoYi后端及HIS业务模块
docs/      项目需求与协作规范
sql/       数据库脚本
```

## 后端启动

环境要求：JDK 17、Maven 3.9、MySQL 8、Redis。

1. 按顺序执行 `sql/his_cloud.sql`、`sql/ruoyi_system.sql`、`sql/quartz.sql`，后两个脚本需在 `his_cloud_completed` 数据库中执行。
2. 按需设置 `HIS_DB_URL`、`HIS_DB_USERNAME`、`HIS_DB_PASSWORD`、`HIS_REDIS_HOST`、`HIS_REDIS_PORT` 等环境变量。
3. 构建并启动：

```bash
cd backend
mvn -pl ruoyi-admin -am clean package -DskipTests
java -jar ruoyi-admin/target/ruoyi-admin.jar
```

默认服务端口为 `8080`。登录后可访问 `GET /his/status` 检查HIS业务模块状态。

