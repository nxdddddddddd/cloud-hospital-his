#!/usr/bin/env python3
"""离线检查HIS建表脚本的结构、引用和演示脚本关键约定。仅使用Python标准库。"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCHEMA_PATH = ROOT / "sql" / "his_cloud.sql"
SYSTEM_PATH = ROOT / "sql" / "ruoyi_system.sql"
DEMO_PATH = ROOT / "sql" / "his_demo_data.sql"

EXPECTED_TABLES = {
    "department", "regist_level", "settle_category", "scheduling", "employee", "disease",
    "medical_technology", "drug_info", "register", "medical_record", "medical_record_disease",
    "check_request", "inspection_request", "disposal_request", "prescription", "charge_order",
    "charge_item", "payment_record", "refund_record", "refund_item", "drug_stock", "stock_movement",
}


def strip_comments(sql: str) -> str:
    return re.sub(r"/\*.*?\*/|--[^\r\n]*", "", sql, flags=re.S)


def unquote_identifier(identifier: str) -> str:
    return identifier.strip().strip("`")


def extract_create_tables(sql: str) -> dict[str, str]:
    tables: dict[str, str] = {}
    matches = list(re.finditer(r"\bCREATE\s+TABLE\s+`([^`]+)`\s*\(", sql, re.I))
    for match in matches:
        depth = 1
        index = match.end()
        while index < len(sql) and depth:
            if sql[index] == "(":
                depth += 1
            elif sql[index] == ")":
                depth -= 1
            index += 1
        if depth:
            raise AssertionError(f"表 {match.group(1)} 的括号未闭合")
        tables[match.group(1)] = sql[match.end():index - 1]
    return tables


def split_items(body: str) -> list[str]:
    items, start, depth = [], 0, 0
    for index, char in enumerate(body):
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
        elif char == "," and depth == 0:
            items.append(body[start:index].strip())
            start = index + 1
    items.append(body[start:].strip())
    return [item for item in items if item]


def columns_and_types(body: str) -> dict[str, str]:
    columns: dict[str, str] = {}
    for item in split_items(body):
        match = re.match(r"`([^`]+)`\s+((?:BIGINT|INT|TINYINT|DECIMAL)\s*(?:\([^)]*\))?\s*(?:UNSIGNED)?)", item, re.I)
        if match:
            columns[match.group(1)] = re.sub(r"\s+", "", match.group(2)).upper()
    return columns


def references(body: str) -> list[tuple[str, str, str, str]]:
    pattern = re.compile(
        r"FOREIGN\s+KEY\s*\(\s*`?([^`,)]+)`?\s*\)\s*"
        r"REFERENCES\s*`?([^`,\s(]+)`?\s*\(\s*`?([^`,)]+)`?\s*\)", re.I)
    return [(unquote_identifier(c), unquote_identifier(t), unquote_identifier(tc), m.group(0))
            for m in pattern.finditer(body)
            for c, t, tc in [(m.group(1), m.group(2), m.group(3))]]


def main() -> int:
    failures: list[str] = []

    def check(condition: bool, message: str) -> None:
        if not condition:
            failures.append(message)

    schema = strip_comments(SCHEMA_PATH.read_text(encoding="utf-8"))
    system = strip_comments(SYSTEM_PATH.read_text(encoding="utf-8"))
    demo = strip_comments(DEMO_PATH.read_text(encoding="utf-8"))
    tables = extract_create_tables(schema)
    system_tables = extract_create_tables(system)
    all_tables = tables | system_tables

    check(set(tables) == EXPECTED_TABLES,
          f"业务表应为22张：缺少{sorted(EXPECTED_TABLES - set(tables))}，多出{sorted(set(tables) - EXPECTED_TABLES)}")
    check("ENGINE=INNODB" in schema.upper(), "未使用InnoDB")
    check(schema.upper().count("ENGINE=INNODB") == 22, "不是全部22张业务表都显式使用InnoDB")
    check("utf8mb4_0900_ai_ci" in schema, "业务表未统一使用utf8mb4排序规则")
    check("employee" in tables and "sys_user_id" in tables["employee"], "员工表缺少RuoYi账号关联列")
    check("password" not in tables.get("employee", "").lower(), "员工表不应重复保存登录密码")
    check(re.search(r"fk_employee_sys_user\s+foreign\s+key", system, re.I) is not None,
          "RuoYi脚本末尾缺少员工账号物理外键")

    types = {name: columns_and_types(body) for name, body in all_tables.items()}
    for table_name, body in all_tables.items():
        for local_column, target_table, target_column, description in references(body):
            check(target_table in all_tables, f"{table_name}外键引用不存在的表：{description}")
            if target_table not in all_tables:
                continue
            check(local_column in types[table_name], f"{table_name}外键列不存在：{local_column}")
            check(target_column in types[target_table], f"{target_table}被引用列不存在：{target_column}")
            if local_column in types[table_name] and target_column in types[target_table]:
                check(types[table_name][local_column] == types[target_table][target_column],
                      f"外键类型不一致：{table_name}.{local_column}={types[table_name][local_column]}，"
                      f"{target_table}.{target_column}={types[target_table][target_column]}")

    expected_unique = {
        "register": "request_key",
        "check_request": "request_key`, `line_no",
        "inspection_request": "request_key`, `line_no",
        "disposal_request": "request_key`, `line_no",
        "prescription": "request_key`, `line_no",
        "charge_order": "request_key",
        "charge_item": "source_type`, `source_id",
        "refund_record": "request_key",
        "refund_item": "charge_item_id",
    }
    for table, columns in expected_unique.items():
        check(re.search(rf"UNIQUE\s+KEY\s+`[^`]+`\s*\(\s*`{columns}`?\s*\)", tables.get(table, ""), re.I) is not None,
              f"{table}缺少幂等/防重复唯一键：{columns}")

    for table, state in (("check_request", "check_state"), ("inspection_request", "inspection_state"),
                         ("disposal_request", "disposal_state"), ("prescription", "drug_state")):
        check(state in tables.get(table, ""), f"{table}缺少状态字段{state}")
        check("UNPAID" in tables[table] and "PAID" in tables[table], f"{table}缺少缴费状态约束")

    check("ck_stock_movement_3" in tables.get("stock_movement", ""), "库存流水缺少类型CHECK")
    check("fk_employee_sys_user" in system, "员工登录外键未在RuoYi脚本中添加")
    check(system.rfind("fk_employee_sys_user") > system.rfind("CREATE TABLE `sys_notice_read`"),
          "员工登录外键必须放在RuoYi建表之后")

    for required in ("department", "regist_level", "employee", "disease", "medical_technology",
                     "drug_info", "drug_stock", "register", "check_request", "inspection_request",
                     "disposal_request", "prescription", "charge_order", "charge_item", "payment_record"):
        check(re.search(rf"INSERT\s+INTO\s+{re.escape(required)}\b", demo, re.I) is not None,
              f"演示脚本缺少{required}数据")
    check("START TRANSACTION" in demo.upper() and "COMMIT" in demo.upper(), "演示脚本缺少事务边界")
    check("'DEMO-REGISTER-0001'" in demo and "陈演示" in demo, "缺少虚构患者演示记录")
    for account in ("cashier", "doctor", "examiner", "lab", "treatment", "pharmacy"):
        check(f"'{account}'" in demo, f"缺少演示账号{account}")
    for permission in ("his:registration:list", "his:charge:list", "his:doctor:visits",
                       "his:examination:list", "his:laboratory:list", "his:treatment:list", "his:pharmacy:list"):
        check(permission in demo, f"缺少前端权限标识{permission}")
    for statement in re.findall(r"PREPARE\s+\w+\s+FROM\s+(@\w+)", demo, re.I):
        check(demo.count(statement) >= 3, f"动态自增语句变量使用异常：{statement}")

    if failures:
        print(f"FAIL：数据库静态检查未通过，共{len(failures)}项：")
        for failure in failures:
            print(f" - {failure}")
        return 1
    print(f"PASS：{len(tables)}张HIS业务表结构完整，全部为InnoDB。")
    print("PASS：业务外键和员工-RuoYi账号外键的引用、类型检查通过。")
    print("PASS：幂等唯一键、状态约束、演示数据和岗位权限检查通过。")
    print("注意：此检查不替代MySQL实际导入与业务事务测试。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
