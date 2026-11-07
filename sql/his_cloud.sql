-- 东软HIS医院数据库设计_补全版
-- 原15张表 + 新增7张表 = 22张表；与work中的时序图设计配套。
-- 新建空库脚本，不是旧数据库迁移脚本；不要使用 --force 忽略错误。
-- 使用MySQL 8.0.16+语法（CHECK需实际执行），验证版本见配套Markdown。
-- 不包含DROP、样例患者、初始账号、默认密码或触发器。
-- 若his_cloud_completed已存在，CREATE DATABASE报错；请改用未使用的库名。
-- 跨表金额、来源归属、状态迁移、幂等摘要由Service事务保证，详见Markdown。

SET NAMES utf8mb4;
SET SESSION sql_mode='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
CREATE DATABASE `his_cloud_completed` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `his_cloud_completed`;

-- 科室表：维护挂号科室和医技执行科室。
CREATE TABLE `department` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `dept_code` VARCHAR(64) NOT NULL COMMENT '科室编码',
  `dept_name` VARCHAR(64) NOT NULL COMMENT '科室名称',
  `dept_type` VARCHAR(64) NOT NULL COMMENT '科室类型，如门诊、医技、药房',
  `delmark` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '生效标记：1有效、0停用',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_department_1` (`dept_code`),
  CONSTRAINT `ck_department_1` CHECK (delmark IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='科室表';

-- 挂号级别表：维护号别、收费与每医生每午别的号额上限。
CREATE TABLE `regist_level` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `regist_code` VARCHAR(64) NOT NULL COMMENT '号别编码',
  `regist_name` VARCHAR(64) NOT NULL COMMENT '号别名称',
  `regist_fee` DECIMAL(12,2) NOT NULL COMMENT '挂号费；当前流程要求正金额',
  `regist_quota` INT UNSIGNED NOT NULL COMMENT '医生每就诊日每午别的挂号限额',
  `sequence_no` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '显示顺序',
  `delmark` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '生效标记：1有效、0停用',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_regist_level_1` (`regist_code`),
  CONSTRAINT `ck_regist_level_1` CHECK (regist_fee > 0),
  CONSTRAINT `ck_regist_level_2` CHECK (regist_quota > 0),
  CONSTRAINT `ck_regist_level_3` CHECK (delmark IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='挂号级别表';

-- 结算类别表：维护自费、医保等类别标签，不实现医保审核接口。
CREATE TABLE `settle_category` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `settle_code` VARCHAR(64) NOT NULL COMMENT '类别编码',
  `settle_name` VARCHAR(64) NOT NULL COMMENT '类别名称',
  `sequence_no` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '显示顺序',
  `delmark` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '生效标记：1有效、0停用',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_settle_category_1` (`settle_code`),
  CONSTRAINT `ck_settle_category_1` CHECK (delmark IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='结算类别表';

-- 排班表：保存每周出诊规则。
CREATE TABLE `scheduling` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `rule_name` VARCHAR(64) NOT NULL COMMENT '排班规则名称',
  `week_rule` VARCHAR(14) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '14位0/1字符串：周一上午、下午至周日上午、下午；1出诊、0停诊',
  `delmark` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '生效标记：1有效、0停用',
  PRIMARY KEY (`id`),
  CONSTRAINT `ck_scheduling_1` CHECK (CHAR_LENGTH(week_rule)=14 AND REPLACE(REPLACE(week_rule,'0',''),'1','')=''),
  CONSTRAINT `ck_scheduling_2` CHECK (delmark IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='排班表';

-- 医院员工表：保存业务岗位资料，登录密码和角色统一由RuoYi sys_user/sys_role维护。
-- sys_user在本脚本之后创建，因此其物理外键由ruoyi_system.sql末尾补充。
CREATE TABLE `employee` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `sys_user_id` BIGINT NULL DEFAULT NULL COMMENT 'RuoYi登录用户ID；与sys_user.user_id类型一致，未开通账号的内部员工可空',
  `deptment_id` BIGINT UNSIGNED NOT NULL COMMENT '所属科室ID',
  `regist_level_id` BIGINT UNSIGNED NULL DEFAULT NULL COMMENT '挂号级别ID；非坐诊员工可空',
  `scheduling_id` BIGINT UNSIGNED NULL DEFAULT NULL COMMENT '排班规则ID；非坐诊员工可空',
  `realname` VARCHAR(64) NOT NULL COMMENT '员工真实姓名',
  `delmark` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '生效标记：1有效、0停用',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_employee_1` (`sys_user_id`),
  KEY `idx_employee_1` (`deptment_id`, `delmark`),
  CONSTRAINT `fk_employee_1` FOREIGN KEY (`deptment_id`) REFERENCES `department` (`id`),
  CONSTRAINT `fk_employee_2` FOREIGN KEY (`regist_level_id`) REFERENCES `regist_level` (`id`),
  CONSTRAINT `fk_employee_3` FOREIGN KEY (`scheduling_id`) REFERENCES `scheduling` (`id`),
  CONSTRAINT `ck_employee_1` CHECK (delmark IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='医院员工表';

-- 疾病表：维护诊断疾病字典。
CREATE TABLE `disease` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `disease_code` VARCHAR(64) NOT NULL COMMENT '疾病助记编码',
  `disease_name` VARCHAR(255) NOT NULL COMMENT '疾病名称',
  `diseaseICD` VARCHAR(64) NOT NULL COMMENT '国际ICD编码，保留原字段大小写',
  `disease_category` VARCHAR(64) NOT NULL COMMENT '疾病所属分类',
  PRIMARY KEY (`id`),
  KEY `idx_disease_1` (`disease_code`),
  KEY `idx_disease_2` (`diseaseICD`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='疾病表';

-- 医技项目表：维护检查、检验与处置项目目录。
CREATE TABLE `medical_technology` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `tech_code` VARCHAR(64) NOT NULL COMMENT '项目编码',
  `tech_name` VARCHAR(64) NOT NULL COMMENT '项目名称',
  `tech_format` VARCHAR(64) NULL DEFAULT NULL COMMENT '项目规格',
  `tech_price` DECIMAL(12,2) NOT NULL COMMENT '当前目录单价',
  `tech_type` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT 'CHECK检查、INSPECTION检验、DISPOSAL处置',
  `price_type` VARCHAR(64) NOT NULL COMMENT '费用分类',
  `deptment_id` BIGINT UNSIGNED NOT NULL COMMENT '执行科室ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_medical_technology_1` (`tech_code`),
  KEY `idx_medical_technology_1` (`tech_type`, `deptment_id`),
  CONSTRAINT `fk_medical_technology_1` FOREIGN KEY (`deptment_id`) REFERENCES `department` (`id`),
  CONSTRAINT `ck_medical_technology_1` CHECK (tech_price > 0),
  CONSTRAINT `ck_medical_technology_2` CHECK (`tech_type` IN ('CHECK', 'INSPECTION', 'DISPOSAL'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='医技项目表';

-- 药品信息表：维护药品目录与当前价格，不直接保存库存。
CREATE TABLE `drug_info` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `drug_code` VARCHAR(255) NOT NULL COMMENT '药品编码',
  `drug_name` VARCHAR(255) NOT NULL COMMENT '药品名称',
  `drug_format` VARCHAR(255) NOT NULL COMMENT '药品规格',
  `drug_unit` VARCHAR(16) NOT NULL COMMENT '本系统计价和库存的统一单位',
  `manufacturer` VARCHAR(255) NOT NULL COMMENT '生产厂家',
  `drug_dosage` VARCHAR(64) NOT NULL COMMENT '药剂类型',
  `drug_type` VARCHAR(64) NOT NULL COMMENT '药品类型',
  `drug_price` DECIMAL(12,2) NOT NULL COMMENT '当前药品单价',
  `mnemonic_code` VARCHAR(255) NULL DEFAULT NULL COMMENT '拼音助记码',
  `creation_date` DATE NOT NULL COMMENT '目录创建日期，由服务端填写',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_drug_info_1` (`drug_code`),
  KEY `idx_drug_info_1` (`mnemonic_code`),
  CONSTRAINT `ck_drug_info_1` CHECK (drug_price > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='药品信息表';

-- 患者历次挂号信息表：一次门诊挂号一行，保留患者信息快照。
CREATE TABLE `register` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `case_number` VARCHAR(64) NOT NULL COMMENT '患者病历号，可用于多次挂号',
  `real_name` VARCHAR(64) NOT NULL COMMENT '本次登记的患者姓名',
  `gender` VARCHAR(6) NULL DEFAULT NULL COMMENT '性别：男/女；未取得时可空',
  `card_number` VARCHAR(18) NULL DEFAULT NULL COMMENT '身份证号；未取得时可空',
  `birthdate` DATE NULL DEFAULT NULL COMMENT '出生日期',
  `age` INT UNSIGNED NULL DEFAULT NULL COMMENT '本次挂号时年龄快照',
  `age_type` VARCHAR(6) NULL DEFAULT NULL COMMENT '年龄单位：年/天，与age同时有值或同时为空',
  `home_address` VARCHAR(64) NULL DEFAULT NULL COMMENT '家庭住址快照',
  `visit_date` DATETIME NOT NULL COMMENT '就诊日期；本版统一存当日00:00:00',
  `noon` VARCHAR(6) NOT NULL COMMENT '午别：上午/下午',
  `deptment_id` BIGINT UNSIGNED NOT NULL COMMENT '挂号科室ID',
  `employee_id` BIGINT UNSIGNED NOT NULL COMMENT '挂号医生ID',
  `regist_level_id` BIGINT UNSIGNED NOT NULL COMMENT '本次挂号级别ID',
  `settle_category_id` BIGINT UNSIGNED NOT NULL COMMENT '结算类别ID',
  `is_book` CHAR(2) NOT NULL DEFAULT '否' COMMENT '是否需要病历本',
  `regist_method` VARCHAR(10) NOT NULL COMMENT '挂号费收款方式',
  `regist_money` DECIMAL(12,2) NOT NULL COMMENT '本次挂号实收金额快照',
  `visit_state` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '1已挂号、2医生接诊、3看诊结束、4已退号',
  `request_key` VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '幂等请求键，区分大小写',
  `request_hash` CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '规范化完整请求的SHA-256十六进制摘要',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_register_1` (`request_key`),
  KEY `idx_register_1` (`employee_id`, `visit_date`, `noon`, `visit_state`),
  KEY `idx_register_2` (`case_number`),
  KEY `idx_register_3` (`card_number`),
  CONSTRAINT `fk_register_1` FOREIGN KEY (`deptment_id`) REFERENCES `department` (`id`),
  CONSTRAINT `fk_register_2` FOREIGN KEY (`employee_id`) REFERENCES `employee` (`id`),
  CONSTRAINT `fk_register_3` FOREIGN KEY (`regist_level_id`) REFERENCES `regist_level` (`id`),
  CONSTRAINT `fk_register_4` FOREIGN KEY (`settle_category_id`) REFERENCES `settle_category` (`id`),
  CONSTRAINT `ck_register_1` CHECK (visit_state IN (1,2,3,4)),
  CONSTRAINT `ck_register_2` CHECK (regist_money > 0),
  CONSTRAINT `ck_register_3` CHECK (`gender` IN ('男', '女')),
  CONSTRAINT `ck_register_4` CHECK (`noon` IN ('上午', '下午')),
  CONSTRAINT `ck_register_5` CHECK (`is_book` IN ('是', '否')),
  CONSTRAINT `ck_register_6` CHECK ((age IS NULL AND age_type IS NULL) OR (age IS NOT NULL AND age_type IS NOT NULL AND age_type IN ('年','天'))),
  CONSTRAINT `ck_register_7` CHECK (TIME(visit_date)='00:00:00')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='患者历次挂号信息表';

-- 患者病历表：一次挂号最多保存一份病历，支持接诊草稿至最终诊断。
CREATE TABLE `medical_record` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `register_id` BIGINT UNSIGNED NOT NULL COMMENT '挂号ID',
  `readme` VARCHAR(512) NOT NULL COMMENT '主诉',
  `present` VARCHAR(512) NULL DEFAULT NULL COMMENT '现病史',
  `present_treat` VARCHAR(512) NULL DEFAULT NULL COMMENT '现病治疗情况',
  `history` VARCHAR(512) NULL DEFAULT NULL COMMENT '既往史',
  `allergy` VARCHAR(512) NULL DEFAULT NULL COMMENT '过敏史',
  `physique` VARCHAR(512) NULL DEFAULT NULL COMMENT '体格检查',
  `proposal` VARCHAR(512) NULL DEFAULT NULL COMMENT '检查/检验建议',
  `careful` VARCHAR(512) NULL DEFAULT NULL COMMENT '注意事项',
  `diagnosis` VARCHAR(512) NULL DEFAULT NULL COMMENT '诊断结果',
  `cure` VARCHAR(512) NULL DEFAULT NULL COMMENT '处理意见',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_medical_record_1` (`register_id`),
  CONSTRAINT `fk_medical_record_1` FOREIGN KEY (`register_id`) REFERENCES `register` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='患者病历表';

-- 病历首页疾病关联表：实现病历与疾病的多对多关联，防止重复关联。
CREATE TABLE `medical_record_disease` (
  `medical_record_id` BIGINT UNSIGNED NOT NULL COMMENT '病历ID',
  `disease_id` BIGINT UNSIGNED NOT NULL COMMENT '疾病ID',
  PRIMARY KEY (`medical_record_id`, `disease_id`),
  KEY `idx_medical_record_disease_1` (`disease_id`),
  CONSTRAINT `fk_medical_record_disease_1` FOREIGN KEY (`medical_record_id`) REFERENCES `medical_record` (`id`),
  CONSTRAINT `fk_medical_record_disease_2` FOREIGN KEY (`disease_id`) REFERENCES `disease` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='病历首页疾病关联表';

-- 检查申请表：保存检查申请、执行登记及结果，一行一个项目。
CREATE TABLE `check_request` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `register_id` BIGINT UNSIGNED NOT NULL COMMENT '挂号ID',
  `medical_technology_id` BIGINT UNSIGNED NOT NULL COMMENT '医技项目ID',
  `check_info` VARCHAR(512) NOT NULL COMMENT '目的要求',
  `check_position` VARCHAR(255) NULL DEFAULT NULL COMMENT '检查部位',
  `creation_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开立时间',
  `check_employee_id` BIGINT UNSIGNED NULL DEFAULT NULL COMMENT '检查执行人员ID；执行前为空',
  `inputcheck_employee_id` BIGINT UNSIGNED NULL DEFAULT NULL COMMENT '结果录入人员ID；完成前为空',
  `check_time` DATETIME NULL DEFAULT NULL COMMENT '检查执行登记时间',
  `check_result` VARCHAR(512) NULL DEFAULT NULL COMMENT '检查结果',
  `check_state` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'UNPAID' COMMENT 'UNPAID/PAID/EXECUTING/COMPLETED/CANCELLED/REFUNDED',
  `check_remark` VARCHAR(512) NULL DEFAULT NULL COMMENT '备注',
  `created_by` BIGINT UNSIGNED NOT NULL COMMENT '开立医生ID',
  `unit_price` DECIMAL(12,2) NOT NULL COMMENT '开立时项目单价快照',
  `request_key` VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '幂等请求键，区分大小写',
  `request_hash` CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '规范化完整请求的SHA-256十六进制摘要',
  `line_no` INT UNSIGNED NOT NULL COMMENT '批量请求内的行号，从1开始',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_check_request_1` (`request_key`, `line_no`),
  KEY `idx_check_request_1` (`register_id`, `check_state`),
  KEY `idx_check_request_2` (`medical_technology_id`, `check_state`),
  CONSTRAINT `fk_check_request_1` FOREIGN KEY (`register_id`) REFERENCES `register` (`id`),
  CONSTRAINT `fk_check_request_2` FOREIGN KEY (`medical_technology_id`) REFERENCES `medical_technology` (`id`),
  CONSTRAINT `fk_check_request_3` FOREIGN KEY (`check_employee_id`) REFERENCES `employee` (`id`),
  CONSTRAINT `fk_check_request_4` FOREIGN KEY (`inputcheck_employee_id`) REFERENCES `employee` (`id`),
  CONSTRAINT `fk_check_request_5` FOREIGN KEY (`created_by`) REFERENCES `employee` (`id`),
  CONSTRAINT `ck_check_request_1` CHECK (`check_state` IN ('UNPAID', 'PAID', 'EXECUTING', 'COMPLETED', 'CANCELLED', 'REFUNDED')),
  CONSTRAINT `ck_check_request_2` CHECK (unit_price > 0),
  CONSTRAINT `ck_check_request_3` CHECK (line_no > 0),
  CONSTRAINT `ck_check_request_4` CHECK (check_state NOT IN ('EXECUTING','COMPLETED') OR (check_employee_id IS NOT NULL AND check_time IS NOT NULL)),
  CONSTRAINT `ck_check_request_5` CHECK (check_state <> 'COMPLETED' OR (inputcheck_employee_id IS NOT NULL AND check_result IS NOT NULL AND CHAR_LENGTH(TRIM(check_result))>0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='检查申请表';

-- 检验申请表：保存检验申请、执行登记及结果，一行一个项目。
CREATE TABLE `inspection_request` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `register_id` BIGINT UNSIGNED NOT NULL COMMENT '挂号ID',
  `medical_technology_id` BIGINT UNSIGNED NOT NULL COMMENT '医技项目ID',
  `inspection_info` VARCHAR(512) NOT NULL COMMENT '目的要求',
  `inspection_position` VARCHAR(255) NULL DEFAULT NULL COMMENT '检验部位',
  `creation_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开立时间',
  `inspection_employee_id` BIGINT UNSIGNED NULL DEFAULT NULL COMMENT '检验执行人员ID；执行前为空',
  `inputinspection_employee_id` BIGINT UNSIGNED NULL DEFAULT NULL COMMENT '结果录入人员ID；完成前为空',
  `inspection_time` DATETIME NULL DEFAULT NULL COMMENT '检验执行登记时间',
  `inspection_result` VARCHAR(512) NULL DEFAULT NULL COMMENT '检验结果',
  `inspection_state` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'UNPAID' COMMENT 'UNPAID/PAID/EXECUTING/COMPLETED/CANCELLED/REFUNDED',
  `inspection_remark` VARCHAR(512) NULL DEFAULT NULL COMMENT '备注',
  `created_by` BIGINT UNSIGNED NOT NULL COMMENT '开立医生ID',
  `unit_price` DECIMAL(12,2) NOT NULL COMMENT '开立时项目单价快照',
  `request_key` VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '幂等请求键，区分大小写',
  `request_hash` CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '规范化完整请求的SHA-256十六进制摘要',
  `line_no` INT UNSIGNED NOT NULL COMMENT '批量请求内的行号，从1开始',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_inspection_request_1` (`request_key`, `line_no`),
  KEY `idx_inspection_request_1` (`register_id`, `inspection_state`),
  KEY `idx_inspection_request_2` (`medical_technology_id`, `inspection_state`),
  CONSTRAINT `fk_inspection_request_1` FOREIGN KEY (`register_id`) REFERENCES `register` (`id`),
  CONSTRAINT `fk_inspection_request_2` FOREIGN KEY (`medical_technology_id`) REFERENCES `medical_technology` (`id`),
  CONSTRAINT `fk_inspection_request_3` FOREIGN KEY (`inspection_employee_id`) REFERENCES `employee` (`id`),
  CONSTRAINT `fk_inspection_request_4` FOREIGN KEY (`inputinspection_employee_id`) REFERENCES `employee` (`id`),
  CONSTRAINT `fk_inspection_request_5` FOREIGN KEY (`created_by`) REFERENCES `employee` (`id`),
  CONSTRAINT `ck_inspection_request_1` CHECK (`inspection_state` IN ('UNPAID', 'PAID', 'EXECUTING', 'COMPLETED', 'CANCELLED', 'REFUNDED')),
  CONSTRAINT `ck_inspection_request_2` CHECK (unit_price > 0),
  CONSTRAINT `ck_inspection_request_3` CHECK (line_no > 0),
  CONSTRAINT `ck_inspection_request_4` CHECK (inspection_state NOT IN ('EXECUTING','COMPLETED') OR (inspection_employee_id IS NOT NULL AND inspection_time IS NOT NULL)),
  CONSTRAINT `ck_inspection_request_5` CHECK (inspection_state <> 'COMPLETED' OR (inputinspection_employee_id IS NOT NULL AND inspection_result IS NOT NULL AND CHAR_LENGTH(TRIM(inspection_result))>0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='检验申请表';

-- 处置申请表：保存处置申请、执行登记及结果，一行一个项目。
CREATE TABLE `disposal_request` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `register_id` BIGINT UNSIGNED NOT NULL COMMENT '挂号ID',
  `medical_technology_id` BIGINT UNSIGNED NOT NULL COMMENT '医技项目ID',
  `disposal_info` VARCHAR(512) NOT NULL COMMENT '目的要求',
  `disposal_position` VARCHAR(255) NULL DEFAULT NULL COMMENT '处置部位',
  `creation_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开立时间',
  `disposal_employee_id` BIGINT UNSIGNED NULL DEFAULT NULL COMMENT '处置执行人员ID；执行前为空',
  `inputdisposal_employee_id` BIGINT UNSIGNED NULL DEFAULT NULL COMMENT '结果录入人员ID；完成前为空',
  `disposal_time` DATETIME NULL DEFAULT NULL COMMENT '处置执行登记时间',
  `disposal_result` VARCHAR(512) NULL DEFAULT NULL COMMENT '处置结果',
  `disposal_state` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'UNPAID' COMMENT 'UNPAID/PAID/EXECUTING/COMPLETED/CANCELLED/REFUNDED',
  `disposal_remark` VARCHAR(512) NULL DEFAULT NULL COMMENT '备注',
  `created_by` BIGINT UNSIGNED NOT NULL COMMENT '开立医生ID',
  `unit_price` DECIMAL(12,2) NOT NULL COMMENT '开立时项目单价快照',
  `request_key` VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '幂等请求键，区分大小写',
  `request_hash` CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '规范化完整请求的SHA-256十六进制摘要',
  `line_no` INT UNSIGNED NOT NULL COMMENT '批量请求内的行号，从1开始',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_disposal_request_1` (`request_key`, `line_no`),
  KEY `idx_disposal_request_1` (`register_id`, `disposal_state`),
  KEY `idx_disposal_request_2` (`medical_technology_id`, `disposal_state`),
  CONSTRAINT `fk_disposal_request_1` FOREIGN KEY (`register_id`) REFERENCES `register` (`id`),
  CONSTRAINT `fk_disposal_request_2` FOREIGN KEY (`medical_technology_id`) REFERENCES `medical_technology` (`id`),
  CONSTRAINT `fk_disposal_request_3` FOREIGN KEY (`disposal_employee_id`) REFERENCES `employee` (`id`),
  CONSTRAINT `fk_disposal_request_4` FOREIGN KEY (`inputdisposal_employee_id`) REFERENCES `employee` (`id`),
  CONSTRAINT `fk_disposal_request_5` FOREIGN KEY (`created_by`) REFERENCES `employee` (`id`),
  CONSTRAINT `ck_disposal_request_1` CHECK (`disposal_state` IN ('UNPAID', 'PAID', 'EXECUTING', 'COMPLETED', 'CANCELLED', 'REFUNDED')),
  CONSTRAINT `ck_disposal_request_2` CHECK (unit_price > 0),
  CONSTRAINT `ck_disposal_request_3` CHECK (line_no > 0),
  CONSTRAINT `ck_disposal_request_4` CHECK (disposal_state NOT IN ('EXECUTING','COMPLETED') OR (disposal_employee_id IS NOT NULL AND disposal_time IS NOT NULL)),
  CONSTRAINT `ck_disposal_request_5` CHECK (disposal_state <> 'COMPLETED' OR (inputdisposal_employee_id IS NOT NULL AND disposal_result IS NOT NULL AND CHAR_LENGTH(TRIM(disposal_result))>0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='处置申请表';

-- 处方表（药品条目）：每行是一种药品的处方条目，批量提交用请求键和行号分组。
CREATE TABLE `prescription` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `register_id` BIGINT UNSIGNED NOT NULL COMMENT '挂号ID，修正原PDF中文“病历id”的歧义',
  `drug_id` BIGINT UNSIGNED NOT NULL COMMENT '药品ID',
  `drug_usage` VARCHAR(255) NOT NULL COMMENT '用法、用量与频次',
  `drug_number` DECIMAL(12,3) NOT NULL COMMENT '药品数量，修正原VARCHAR类型',
  `creation_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开立时间',
  `drug_state` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'UNPAID' COMMENT 'UNPAID/PAID/DISPENSED/RETURNED/REFUNDED/CANCELLED',
  `created_by` BIGINT UNSIGNED NOT NULL COMMENT '开立医生ID',
  `unit_price` DECIMAL(12,2) NOT NULL COMMENT '开立时药品单价快照',
  `request_key` VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '幂等请求键，区分大小写',
  `request_hash` CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '规范化完整请求的SHA-256十六进制摘要',
  `line_no` INT UNSIGNED NOT NULL COMMENT '批量请求内的行号，从1开始',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_prescription_1` (`request_key`, `line_no`),
  KEY `idx_prescription_1` (`register_id`, `drug_state`),
  CONSTRAINT `fk_prescription_1` FOREIGN KEY (`register_id`) REFERENCES `register` (`id`),
  CONSTRAINT `fk_prescription_2` FOREIGN KEY (`drug_id`) REFERENCES `drug_info` (`id`),
  CONSTRAINT `fk_prescription_3` FOREIGN KEY (`created_by`) REFERENCES `employee` (`id`),
  CONSTRAINT `ck_prescription_1` CHECK (drug_number > 0),
  CONSTRAINT `ck_prescription_2` CHECK (unit_price > 0),
  CONSTRAINT `ck_prescription_3` CHECK (ROUND(drug_number*unit_price,2)>0),
  CONSTRAINT `ck_prescription_4` CHECK (line_no > 0),
  CONSTRAINT `ck_prescription_5` CHECK (`drug_state` IN ('UNPAID', 'PAID', 'DISPENSED', 'RETURNED', 'REFUNDED', 'CANCELLED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='处方表（药品条目）';

-- 收费单：记录一次窗口收费，归属于同一次挂号。
CREATE TABLE `charge_order` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `order_no` VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '收费单业务编号',
  `register_id` BIGINT UNSIGNED NOT NULL COMMENT '挂号ID',
  `total_amount` DECIMAL(12,2) NOT NULL COMMENT '原收费总额',
  `refunded_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '累计退款额',
  `status` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'PAID' COMMENT 'PAID/PARTIAL_REFUNDED/REFUNDED',
  `request_key` VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '幂等请求键，区分大小写',
  `request_hash` CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '规范化完整请求的SHA-256十六进制摘要',
  `operator_id` BIGINT UNSIGNED NOT NULL COMMENT '收费操作员工ID',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_charge_order_1` (`order_no`),
  UNIQUE KEY `uq_charge_order_2` (`request_key`),
  KEY `idx_charge_order_1` (`register_id`, `created_at`),
  CONSTRAINT `fk_charge_order_1` FOREIGN KEY (`register_id`) REFERENCES `register` (`id`),
  CONSTRAINT `fk_charge_order_2` FOREIGN KEY (`operator_id`) REFERENCES `employee` (`id`),
  CONSTRAINT `ck_charge_order_1` CHECK (total_amount > 0),
  CONSTRAINT `ck_charge_order_2` CHECK (refunded_amount >= 0 AND refunded_amount <= total_amount),
  CONSTRAINT `ck_charge_order_3` CHECK ((status='PAID' AND refunded_amount=0) OR (status='PARTIAL_REFUNDED' AND refunded_amount>0 AND refunded_amount<total_amount) OR (status='REFUNDED' AND refunded_amount=total_amount))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='收费单';

-- 收费明细：保存源业务条目及收费金额快照。
CREATE TABLE `charge_item` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `order_id` BIGINT UNSIGNED NOT NULL COMMENT '收费单ID',
  `source_type` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT 'REGISTER/CHECK/INSPECTION/DISPOSAL/PRESCRIPTION',
  `source_id` BIGINT UNSIGNED NOT NULL COMMENT '对应业务表主键；多态逻辑引用，不是单一物理外键',
  `item_name` VARCHAR(255) NOT NULL COMMENT '收费时项目/药品名称快照',
  `quantity` DECIMAL(12,3) NOT NULL COMMENT '收费数量',
  `unit_price` DECIMAL(12,2) NOT NULL COMMENT '收费单价快照',
  `amount` DECIMAL(12,2) NOT NULL COMMENT '逐行舍入后的收费金额',
  `status` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'PAID' COMMENT 'PAID/REFUNDED',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_charge_item_1` (`source_type`, `source_id`),
  KEY `idx_charge_item_1` (`order_id`, `status`),
  CONSTRAINT `fk_charge_item_1` FOREIGN KEY (`order_id`) REFERENCES `charge_order` (`id`),
  CONSTRAINT `ck_charge_item_1` CHECK (`source_type` IN ('REGISTER', 'CHECK', 'INSPECTION', 'DISPOSAL', 'PRESCRIPTION')),
  CONSTRAINT `ck_charge_item_2` CHECK (source_id > 0),
  CONSTRAINT `ck_charge_item_3` CHECK (quantity > 0),
  CONSTRAINT `ck_charge_item_4` CHECK (unit_price > 0),
  CONSTRAINT `ck_charge_item_5` CHECK (amount > 0 AND amount=ROUND(quantity*unit_price,2)),
  CONSTRAINT `ck_charge_item_6` CHECK (source_type='PRESCRIPTION' OR quantity=1),
  CONSTRAINT `ck_charge_item_7` CHECK (`status` IN ('PAID', 'REFUNDED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='收费明细';

-- 支付记录：记录窗口已核实收款凭据，一张收费单对应一次全额支付。
CREATE TABLE `payment_record` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `order_id` BIGINT UNSIGNED NOT NULL COMMENT '收费单ID',
  `payment_no` VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '系统支付流水号',
  `receipt_ref` VARCHAR(128) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '渠道+外部凭据号，现金用唯一窗口收款凭据',
  `amount` DECIMAL(12,2) NOT NULL COMMENT '原实付金额',
  `method` VARCHAR(10) NOT NULL COMMENT '支付方式：现金、银行卡、医保卡、微信、支付宝',
  `status` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'SUCCESS' COMMENT '本版仅SUCCESS',
  `operator_id` BIGINT UNSIGNED NOT NULL COMMENT '收费操作员工ID',
  `paid_at` DATETIME NOT NULL COMMENT '实际确认收款时间，由服务端填写',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_payment_record_1` (`order_id`),
  UNIQUE KEY `uq_payment_record_2` (`payment_no`),
  UNIQUE KEY `uq_payment_record_3` (`receipt_ref`),
  CONSTRAINT `fk_payment_record_1` FOREIGN KEY (`order_id`) REFERENCES `charge_order` (`id`),
  CONSTRAINT `fk_payment_record_2` FOREIGN KEY (`operator_id`) REFERENCES `employee` (`id`),
  CONSTRAINT `ck_payment_record_1` CHECK (amount > 0),
  CONSTRAINT `ck_payment_record_2` CHECK (status='SUCCESS')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='支付记录';

-- 退款记录：记录一笔原支付的退款；支持选择部分整行收费明细。
CREATE TABLE `refund_record` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `payment_id` BIGINT UNSIGNED NOT NULL COMMENT '原支付记录ID',
  `refund_no` VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '系统退款流水号',
  `refund_ref` VARCHAR(128) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '渠道+唯一线下退款凭据号',
  `request_key` VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '幂等请求键，区分大小写',
  `request_hash` CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '规范化完整请求的SHA-256十六进制摘要',
  `amount` DECIMAL(12,2) NOT NULL COMMENT '本次退款金额',
  `status` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'SUCCESS' COMMENT '本版仅SUCCESS',
  `reason` VARCHAR(512) NOT NULL COMMENT '退款原因',
  `operator_id` BIGINT UNSIGNED NOT NULL COMMENT '退款操作员工ID',
  `refunded_at` DATETIME NOT NULL COMMENT '实际确认退款时间，由服务端填写',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_refund_record_1` (`refund_no`),
  UNIQUE KEY `uq_refund_record_2` (`refund_ref`),
  UNIQUE KEY `uq_refund_record_3` (`request_key`),
  KEY `idx_refund_record_1` (`payment_id`),
  CONSTRAINT `fk_refund_record_1` FOREIGN KEY (`payment_id`) REFERENCES `payment_record` (`id`),
  CONSTRAINT `fk_refund_record_2` FOREIGN KEY (`operator_id`) REFERENCES `employee` (`id`),
  CONSTRAINT `ck_refund_record_1` CHECK (amount > 0),
  CONSTRAINT `ck_refund_record_2` CHECK (status='SUCCESS')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='退款记录';

-- 退款明细：把退款流水关联到原收费明细。
CREATE TABLE `refund_item` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `refund_id` BIGINT UNSIGNED NOT NULL COMMENT '退款记录ID',
  `charge_item_id` BIGINT UNSIGNED NOT NULL COMMENT '原收费明细ID',
  `amount` DECIMAL(12,2) NOT NULL COMMENT '该收费明细的全额退款金额',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_refund_item_1` (`charge_item_id`),
  CONSTRAINT `fk_refund_item_1` FOREIGN KEY (`refund_id`) REFERENCES `refund_record` (`id`),
  CONSTRAINT `fk_refund_item_2` FOREIGN KEY (`charge_item_id`) REFERENCES `charge_item` (`id`),
  CONSTRAINT `ck_refund_item_1` CHECK (amount > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='退款明细';

-- 药品库存：单药房每药品一行，数量与目录单位一致。
CREATE TABLE `drug_stock` (
  `drug_id` BIGINT UNSIGNED NOT NULL COMMENT '药品ID，同时为主键',
  `on_hand` DECIMAL(12,3) NOT NULL DEFAULT 0.000 COMMENT '当前可用库存数量',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后变更时间',
  PRIMARY KEY (`drug_id`),
  CONSTRAINT `fk_drug_stock_1` FOREIGN KEY (`drug_id`) REFERENCES `drug_info` (`id`),
  CONSTRAINT `ck_drug_stock_1` CHECK (on_hand >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='药品库存';

-- 出入库流水：记录入库、发药、验收退药及每次变动后余额。
CREATE TABLE `stock_movement` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `drug_id` BIGINT UNSIGNED NOT NULL COMMENT '药品ID',
  `movement_type` VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT 'RECEIPT入库、DISPENSE发药、RETURN退药',
  `business_key` VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '入库请求键；发药/退药时为处方行ID字符串',
  `prescription_id` BIGINT UNSIGNED NULL DEFAULT NULL COMMENT '处方行ID；普通入库为空',
  `quantity_delta` DECIMAL(12,3) NOT NULL COMMENT '库存变化量，入库/退药为正，发药为负',
  `balance_after` DECIMAL(12,3) NOT NULL COMMENT '本条流水写入后的库存余额',
  `receipt_ref` VARCHAR(128) CHARACTER SET ascii COLLATE ascii_bin NULL DEFAULT NULL COMMENT '入库来源凭据，可多行共用',
  `operator_id` BIGINT UNSIGNED NOT NULL COMMENT '操作员工ID',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '流水创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_stock_movement_1` (`movement_type`, `business_key`),
  UNIQUE KEY `uq_stock_movement_2` (`movement_type`, `prescription_id`),
  KEY `idx_stock_movement_1` (`drug_id`, `created_at`),
  CONSTRAINT `fk_stock_movement_1` FOREIGN KEY (`drug_id`) REFERENCES `drug_info` (`id`),
  CONSTRAINT `fk_stock_movement_2` FOREIGN KEY (`prescription_id`) REFERENCES `prescription` (`id`),
  CONSTRAINT `fk_stock_movement_3` FOREIGN KEY (`operator_id`) REFERENCES `employee` (`id`),
  CONSTRAINT `ck_stock_movement_1` CHECK (balance_after >= 0),
  CONSTRAINT `ck_stock_movement_2` CHECK ((movement_type='RECEIPT' AND quantity_delta>0 AND prescription_id IS NULL) OR (movement_type='DISPENSE' AND quantity_delta<0 AND prescription_id IS NOT NULL) OR (movement_type='RETURN' AND quantity_delta>0 AND prescription_id IS NOT NULL)),
  CONSTRAINT `ck_stock_movement_3` CHECK (`movement_type` IN ('RECEIPT', 'DISPENSE', 'RETURN'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='出入库流水';
