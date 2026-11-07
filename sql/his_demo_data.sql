-- 云医院HIS学生作业：基础数据、角色账号和虚构患者演示数据
-- 前置：已按README依次执行his_cloud.sql、ruoyi_system.sql、quartz.sql。
-- 可重复执行；所有患者、证件号和电话号码均为教学虚构数据。
-- 本脚本只新增不存在的演示记录，不覆盖已修改的账号密码、角色或业务记录。
-- 演示密码与RuoYi默认admin密码相同：admin123，仅限本地作业使用。
-- 医生排班规则固定使用周一至周五上午，演示挂号使用上午号源。

SET NAMES utf8mb4;
SET SESSION sql_mode='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

START TRANSACTION;

-- 基础目录：科室、号别、结算类别、排班。
INSERT INTO department (id, dept_code, dept_name, dept_type) VALUES
  (1, 'NK', '内科', '门诊'),
  (2, 'WK', '外科', '门诊'),
  (3, 'SF', '挂号收费处', '收费'),
  (4, 'JCB', '检查科', '医技'),
  (5, 'JYB', '检验科', '医技'),
  (6, 'CZS', '处置室', '医技'),
  (7, 'YF', '门诊药房', '药房')
ON DUPLICATE KEY UPDATE dept_name = VALUES(dept_name), dept_type = VALUES(dept_type);

INSERT INTO regist_level (id, regist_code, regist_name, regist_fee, regist_quota, sequence_no) VALUES
  (1, 'PT', '普通号', 10.00, 20, 1),
  (2, 'ZJ', '专家号', 30.00, 10, 2)
ON DUPLICATE KEY UPDATE regist_name = VALUES(regist_name), regist_fee = VALUES(regist_fee),
  regist_quota = VALUES(regist_quota), sequence_no = VALUES(sequence_no);

INSERT INTO settle_category (id, settle_code, settle_name, sequence_no) VALUES
  (1, 'ZF', '自费', 1),
  (2, 'YB', '医保', 2)
ON DUPLICATE KEY UPDATE settle_name = VALUES(settle_name), sequence_no = VALUES(sequence_no);

INSERT INTO scheduling (id, rule_name, week_rule) VALUES
  (1, '周一至周五上午', '10101010100000')
ON DUPLICATE KEY UPDATE rule_name = VALUES(rule_name), week_rule = VALUES(week_rule);

-- 作业角色：每个岗位只显示本人负责的页面。
INSERT INTO sys_role (role_id, role_name, role_key, role_sort, data_scope, menu_check_strictly,
  dept_check_strictly, status, del_flag, create_by, create_time, remark) VALUES
  (101, '挂号收费员', 'his_cashier', 101, '1', 1, 1, '0', '0', 'admin', NOW(), '挂号、收费、退费'),
  (102, '门诊医生', 'his_doctor', 102, '1', 1, 1, '0', '0', 'admin', NOW(), '接诊、病历、申请和处方'),
  (103, '检查医生', 'his_examination', 103, '1', 1, 1, '0', '0', 'admin', NOW(), '检查执行与结果'),
  (104, '检验医生', 'his_laboratory', 104, '1', 1, 1, '0', '0', 'admin', NOW(), '检验执行与结果'),
  (105, '处置医生', 'his_treatment', 105, '1', 1, 1, '0', '0', 'admin', NOW(), '处置执行与结果'),
  (106, '药房工作人员', 'his_pharmacist', 106, '1', 1, 1, '0', '0', 'admin', NOW(), '发药、退药与药品查询')
ON DUPLICATE KEY UPDATE role_name = VALUES(role_name), role_key = VALUES(role_key), status = '0', del_flag = '0';

-- 角色与已有前端权限标识一致。
INSERT INTO sys_menu (menu_id, menu_name, parent_id, order_num, path, component, query, route_name,
  is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark) VALUES
  (2001, 'HIS挂号', 0, 201, 'his-registration', NULL, '', '', 1, 0, 'F', '0', '0', 'his:registration:list', '#', 'admin', NOW(), '挂号查询与退号'),
  (2002, 'HIS收费', 0, 202, 'his-charge', NULL, '', '', 1, 0, 'F', '0', '0', 'his:charge:list', '#', 'admin', NOW(), '收费、退费与费用记录'),
  (2003, 'HIS门诊医生', 0, 203, 'his-doctor', NULL, '', '', 1, 0, 'F', '0', '0', 'his:doctor:visits', '#', 'admin', NOW(), '门诊医生工作站'),
  (2004, 'HIS检查查询', 0, 204, 'his-examination-list', NULL, '', '', 1, 0, 'F', '0', '0', 'his:examination:list', '#', 'admin', NOW(), '检查列表'),
  (2005, 'HIS检查执行', 0, 205, 'his-examination-edit', NULL, '', '', 1, 0, 'F', '0', '0', 'his:examination:edit', '#', 'admin', NOW(), '检查登记与结果'),
  (2006, 'HIS检验查询', 0, 206, 'his-laboratory-list', NULL, '', '', 1, 0, 'F', '0', '0', 'his:laboratory:list', '#', 'admin', NOW(), '检验列表'),
  (2007, 'HIS检验执行', 0, 207, 'his-laboratory-edit', NULL, '', '', 1, 0, 'F', '0', '0', 'his:laboratory:edit', '#', 'admin', NOW(), '检验登记与结果'),
  (2008, 'HIS处置查询', 0, 208, 'his-treatment-list', NULL, '', '', 1, 0, 'F', '0', '0', 'his:treatment:list', '#', 'admin', NOW(), '处置列表'),
  (2009, 'HIS处置执行', 0, 209, 'his-treatment-edit', NULL, '', '', 1, 0, 'F', '0', '0', 'his:treatment:edit', '#', 'admin', NOW(), '处置登记与结果'),
  (2010, 'HIS药房', 0, 210, 'his-pharmacy', NULL, '', '', 1, 0, 'F', '0', '0', 'his:pharmacy:list', '#', 'admin', NOW(), '药房业务')
ON DUPLICATE KEY UPDATE menu_name = VALUES(menu_name), perms = VALUES(perms), status = '0';

INSERT INTO sys_role_menu (role_id, menu_id)
SELECT r.role_id, m.menu_id FROM sys_role r JOIN sys_menu m ON m.menu_id IN (2001, 2002)
WHERE r.role_id = 101
ON DUPLICATE KEY UPDATE role_id = VALUES(role_id);
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 102, 2003 WHERE EXISTS (SELECT 1 FROM sys_role WHERE role_id = 102)
ON DUPLICATE KEY UPDATE role_id = VALUES(role_id);
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT r.role_id, m.menu_id FROM sys_role r JOIN sys_menu m ON m.menu_id IN (2004, 2005)
WHERE r.role_id = 103
ON DUPLICATE KEY UPDATE role_id = VALUES(role_id);
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT r.role_id, m.menu_id FROM sys_role r JOIN sys_menu m ON m.menu_id IN (2006, 2007)
WHERE r.role_id = 104
ON DUPLICATE KEY UPDATE role_id = VALUES(role_id);
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT r.role_id, m.menu_id FROM sys_role r JOIN sys_menu m ON m.menu_id IN (2008, 2009)
WHERE r.role_id = 105
ON DUPLICATE KEY UPDATE role_id = VALUES(role_id);
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 106, 2010 WHERE EXISTS (SELECT 1 FROM sys_role WHERE role_id = 106)
ON DUPLICATE KEY UPDATE role_id = VALUES(role_id);

-- 各岗位演示账号；业务表只通过sys_user_id关联，不再保存第二份密码。
INSERT INTO sys_user (user_id, dept_id, user_name, nick_name, user_type, password, status, del_flag,
  create_by, create_time, remark) VALUES
  (101, 103, 'cashier', '王收费', '00', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '0', '0', 'admin', NOW(), 'HIS演示挂号收费员'),
  (102, 103, 'doctor', '李医生', '00', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '0', '0', 'admin', NOW(), 'HIS演示门诊医生'),
  (103, 103, 'examiner', '赵检查', '00', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '0', '0', 'admin', NOW(), 'HIS演示检查医生'),
  (104, 103, 'lab', '钱检验', '00', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '0', '0', 'admin', NOW(), 'HIS演示检验医生'),
  (105, 103, 'treatment', '孙处置', '00', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '0', '0', 'admin', NOW(), 'HIS演示处置医生'),
  (106, 103, 'pharmacy', '周药师', '00', '$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2', '0', '0', 'admin', NOW(), 'HIS演示药房工作人员')
ON DUPLICATE KEY UPDATE nick_name = VALUES(nick_name), status = '0', del_flag = '0';

INSERT INTO sys_user_role (user_id, role_id) VALUES
  (101, 101), (102, 102), (103, 103), (104, 104), (105, 105), (106, 106)
ON DUPLICATE KEY UPDATE user_id = VALUES(user_id);

INSERT INTO employee (id, sys_user_id, deptment_id, regist_level_id, scheduling_id, realname) VALUES
  (1, 101, 3, NULL, NULL, '王收费'),
  (2, 102, 1, 1, 1, '李医生'),
  (3, NULL, 1, 2, 1, '吴专家'),
  (4, 103, 4, NULL, NULL, '赵检查'),
  (5, 104, 5, NULL, NULL, '钱检验'),
  (6, 105, 6, NULL, NULL, '孙处置'),
  (7, 106, 7, NULL, NULL, '周药师')
ON DUPLICATE KEY UPDATE deptment_id = VALUES(deptment_id), regist_level_id = VALUES(regist_level_id),
  scheduling_id = VALUES(scheduling_id), realname = VALUES(realname);

-- 疾病、医技项目和药品目录。
INSERT INTO disease (id, disease_code, disease_name, diseaseICD, disease_category) VALUES
  (1, 'GR', '急性上呼吸道感染', 'J06.900', '呼吸系统'),
  (2, 'GY', '原发性高血压', 'I10.x00', '循环系统'),
  (3, 'WG', '急性胃肠炎', 'A09.901', '消化系统')
ON DUPLICATE KEY UPDATE disease_name = VALUES(disease_name), diseaseICD = VALUES(diseaseICD),
  disease_category = VALUES(disease_category);

INSERT INTO medical_technology (id, tech_code, tech_name, tech_format, tech_price, tech_type, price_type, deptment_id) VALUES
  (1, 'JC001', '胸部X线检查', '正位', 80.00, 'CHECK', '检查费', 4),
  (2, 'JC002', '心电图检查', '十二导联', 30.00, 'CHECK', '检查费', 4),
  (3, 'JY001', '血常规', '五分类', 25.00, 'INSPECTION', '检验费', 5),
  (4, 'JY002', '尿常规', '干化学法', 20.00, 'INSPECTION', '检验费', 5),
  (5, 'CZ001', '普通换药', '小换药', 15.00, 'DISPOSAL', '处置费', 6),
  (6, 'CZ002', '静脉输液', '一次', 10.00, 'DISPOSAL', '处置费', 6)
ON DUPLICATE KEY UPDATE tech_name = VALUES(tech_name), tech_format = VALUES(tech_format),
  tech_price = VALUES(tech_price), tech_type = VALUES(tech_type), price_type = VALUES(price_type), deptment_id = VALUES(deptment_id);

INSERT INTO drug_info (id, drug_code, drug_name, drug_format, drug_unit, manufacturer, drug_dosage,
  drug_type, drug_price, mnemonic_code, creation_date) VALUES
  (1, 'YP001', '阿莫西林胶囊', '0.25g×24粒/盒', '盒', '演示制药一厂', '胶囊剂', '西药', 18.50, 'AMXLJN', '2026-01-01'),
  (2, 'YP002', '布洛芬缓释胶囊', '0.3g×20粒/盒', '盒', '演示制药二厂', '胶囊剂', '西药', 16.00, 'BLFHSJN', '2026-01-01'),
  (3, 'YP003', '感冒灵颗粒', '10g×9袋/盒', '盒', '演示制药三厂', '颗粒剂', '中成药', 12.80, 'GMLKL', '2026-01-01'),
  (4, 'YP004', '氯化钠注射液', '0.9% 250ml/袋', '袋', '演示制药四厂', '注射剂', '西药', 3.50, 'LHNZSY', '2026-01-01')
ON DUPLICATE KEY UPDATE drug_name = VALUES(drug_name), drug_format = VALUES(drug_format), drug_unit = VALUES(drug_unit),
  drug_price = VALUES(drug_price), mnemonic_code = VALUES(mnemonic_code);

INSERT INTO drug_stock (drug_id, on_hand) VALUES (1, 100), (2, 100), (3, 100), (4, 200)
ON DUPLICATE KEY UPDATE drug_id = VALUES(drug_id);

-- 一名虚构患者的已缴费挂号和病历，可继续演示医技执行、发药和费用查询。
INSERT INTO register (id, case_number, real_name, gender, birthdate, age, age_type, home_address,
  visit_date, noon, deptment_id, employee_id, regist_level_id, settle_category_id, is_book,
  regist_method, regist_money, visit_state, request_key, request_hash) VALUES
  (1, 'DEMO0001', '陈演示', '男', '1990-01-01', 36, '年', '教学演示地址', CURRENT_DATE, '上午', 1, 2, 1, 1, '否',
   '现金', 10.00, 1, 'DEMO-REGISTER-0001', REPEAT('0', 64))
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO charge_order (id, order_no, register_id, total_amount, refunded_amount, status,
  request_key, request_hash, operator_id) VALUES
  (1, 'DEMO-CHARGE-0001', 1, 10.00, 0.00, 'PAID', 'DEMO-CHARGE-REQUEST-0001', REPEAT('0', 64), 1)
ON DUPLICATE KEY UPDATE id = id;
INSERT INTO charge_item (id, order_id, source_type, source_id, item_name, quantity, unit_price, amount) VALUES
  (1, 1, 'REGISTER', 1, '普通号', 1, 10.00, 10.00)
ON DUPLICATE KEY UPDATE id = id;
INSERT INTO payment_record (id, order_id, payment_no, receipt_ref, amount, method, operator_id, paid_at) VALUES
  (1, 1, 'DEMO-PAY-0001', 'CASH-DEMO-0001', 10.00, '现金', 1, NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO medical_record (id, register_id, readme, present, history, allergy, physique) VALUES
  (1, 1, '咳嗽、咽痛两天', '两天前受凉后出现咳嗽、咽痛，无胸痛。', '既往体健。', '否认药物过敏。', '咽部充血，双肺呼吸音清。')
ON DUPLICATE KEY UPDATE id = id;
UPDATE register SET visit_state = 2 WHERE id = 1 AND visit_state = 1;
INSERT INTO medical_record_disease (medical_record_id, disease_id) VALUES (1, 1)
ON DUPLICATE KEY UPDATE medical_record_id = VALUES(medical_record_id);

-- 已缴费医技项目：可以直接在检查、检验和处置页面演示执行。
INSERT INTO check_request (id, register_id, medical_technology_id, check_info, check_position,
  created_by, unit_price, request_key, request_hash, line_no) VALUES
  (1, 1, 1, '排查肺部感染', '胸部', 2, 80.00, 'DEMO-CHECK-REQUEST-0001', REPEAT('0', 64), 1)
ON DUPLICATE KEY UPDATE id = id;
INSERT INTO inspection_request (id, register_id, medical_technology_id, inspection_info,
  created_by, unit_price, request_key, request_hash, line_no) VALUES
  (1, 1, 3, '辅助判断感染情况', 2, 25.00, 'DEMO-INSPECTION-REQUEST-0001', REPEAT('0', 64), 1)
ON DUPLICATE KEY UPDATE id = id;
INSERT INTO disposal_request (id, register_id, medical_technology_id, disposal_info,
  created_by, unit_price, request_key, request_hash, line_no) VALUES
  (1, 1, 6, '按医嘱静脉输液', 2, 10.00, 'DEMO-DISPOSAL-REQUEST-0001', REPEAT('0', 64), 1)
ON DUPLICATE KEY UPDATE id = id;

-- 处方条目与待发药记录。
INSERT INTO prescription (id, register_id, drug_id, drug_usage, drug_number, created_by, unit_price,
  request_key, request_hash, line_no) VALUES
  (1, 1, 3, '口服，一次1袋，一日3次', 1, 2, 12.80, 'DEMO-PRESCRIPTION-REQUEST-0001', REPEAT('0', 64), 1),
  (2, 1, 4, '静脉滴注，一次1袋', 1, 2, 3.50, 'DEMO-PRESCRIPTION-REQUEST-0001', REPEAT('0', 64), 2)
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO charge_order (id, order_no, register_id, total_amount, refunded_amount, status,
  request_key, request_hash, operator_id) VALUES
  (2, 'DEMO-CHARGE-0002', 1, 131.30, 0.00, 'PAID', 'DEMO-CHARGE-REQUEST-0002', REPEAT('0', 64), 1)
ON DUPLICATE KEY UPDATE id = id;
INSERT INTO charge_item (id, order_id, source_type, source_id, item_name, quantity, unit_price, amount) VALUES
  (2, 2, 'CHECK', 1, '胸部X线检查', 1, 80.00, 80.00),
  (3, 2, 'INSPECTION', 1, '血常规', 1, 25.00, 25.00),
  (4, 2, 'DISPOSAL', 1, '静脉输液', 1, 10.00, 10.00),
  (5, 2, 'PRESCRIPTION', 1, '感冒灵颗粒', 1, 12.80, 12.80),
  (6, 2, 'PRESCRIPTION', 2, '氯化钠注射液', 1, 3.50, 3.50)
ON DUPLICATE KEY UPDATE id = id;
INSERT INTO payment_record (id, order_id, payment_no, receipt_ref, amount, method, operator_id, paid_at) VALUES
  (2, 2, 'DEMO-PAY-0002', 'CASH-DEMO-0002', 131.30, '现金', 1, NOW())
ON DUPLICATE KEY UPDATE id = id;

UPDATE check_request SET check_state = 'PAID' WHERE id = 1 AND check_state = 'UNPAID';
UPDATE inspection_request SET inspection_state = 'PAID' WHERE id = 1 AND inspection_state = 'UNPAID';
UPDATE disposal_request SET disposal_state = 'PAID' WHERE id = 1 AND disposal_state = 'UNPAID';
UPDATE prescription SET drug_state = 'PAID' WHERE id IN (1, 2) AND drug_state = 'UNPAID';

-- 固定演示ID允许安全重复导入，同时不影响后续自增主键。
SET @next_employee_id = (SELECT GREATEST(COALESCE(MAX(id), 0) + 1, 8) FROM employee);
SET @next_register_id = (SELECT GREATEST(COALESCE(MAX(id), 0) + 1, 2) FROM register);
SET @next_medical_record_id = (SELECT GREATEST(COALESCE(MAX(id), 0) + 1, 2) FROM medical_record);
SET @next_charge_order_id = (SELECT GREATEST(COALESCE(MAX(id), 0) + 1, 3) FROM charge_order);
SET @next_check_request_id = (SELECT GREATEST(COALESCE(MAX(id), 0) + 1, 2) FROM check_request);
SET @next_inspection_request_id = (SELECT GREATEST(COALESCE(MAX(id), 0) + 1, 2) FROM inspection_request);
SET @next_disposal_request_id = (SELECT GREATEST(COALESCE(MAX(id), 0) + 1, 2) FROM disposal_request);
SET @next_prescription_id = (SELECT GREATEST(COALESCE(MAX(id), 0) + 1, 3) FROM prescription);
-- MySQL PREPARE一次只能执行一条语句，因此分别调整各表自增起点。
SET @reset_auto_increment = CONCAT('ALTER TABLE employee AUTO_INCREMENT=', @next_employee_id);
PREPARE reset_auto_increment FROM @reset_auto_increment;
EXECUTE reset_auto_increment;
DEALLOCATE PREPARE reset_auto_increment;
SET @reset_auto_increment = CONCAT('ALTER TABLE register AUTO_INCREMENT=', @next_register_id);
PREPARE reset_auto_increment FROM @reset_auto_increment;
EXECUTE reset_auto_increment;
DEALLOCATE PREPARE reset_auto_increment;
SET @reset_auto_increment = CONCAT('ALTER TABLE medical_record AUTO_INCREMENT=', @next_medical_record_id);
PREPARE reset_auto_increment FROM @reset_auto_increment;
EXECUTE reset_auto_increment;
DEALLOCATE PREPARE reset_auto_increment;
SET @reset_auto_increment = CONCAT('ALTER TABLE charge_order AUTO_INCREMENT=', @next_charge_order_id);
PREPARE reset_auto_increment FROM @reset_auto_increment;
EXECUTE reset_auto_increment;
DEALLOCATE PREPARE reset_auto_increment;
SET @reset_auto_increment = CONCAT('ALTER TABLE check_request AUTO_INCREMENT=', @next_check_request_id);
PREPARE reset_auto_increment FROM @reset_auto_increment;
EXECUTE reset_auto_increment;
DEALLOCATE PREPARE reset_auto_increment;
SET @reset_auto_increment = CONCAT('ALTER TABLE inspection_request AUTO_INCREMENT=', @next_inspection_request_id);
PREPARE reset_auto_increment FROM @reset_auto_increment;
EXECUTE reset_auto_increment;
DEALLOCATE PREPARE reset_auto_increment;
SET @reset_auto_increment = CONCAT('ALTER TABLE disposal_request AUTO_INCREMENT=', @next_disposal_request_id);
PREPARE reset_auto_increment FROM @reset_auto_increment;
EXECUTE reset_auto_increment;
DEALLOCATE PREPARE reset_auto_increment;
SET @reset_auto_increment = CONCAT('ALTER TABLE prescription AUTO_INCREMENT=', @next_prescription_id);
PREPARE reset_auto_increment FROM @reset_auto_increment;
EXECUTE reset_auto_increment;
DEALLOCATE PREPARE reset_auto_increment;

COMMIT;
