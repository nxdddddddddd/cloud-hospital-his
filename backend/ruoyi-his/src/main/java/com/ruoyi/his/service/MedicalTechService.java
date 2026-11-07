package com.ruoyi.his.service;

import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.ruoyi.common.exception.ServiceException;
import com.ruoyi.his.mapper.MedicalTechMapper;

@Service
public class MedicalTechService
{
    private final MedicalTechMapper mapper;

    public MedicalTechService(MedicalTechMapper mapper)
    {
        this.mapper = mapper;
    }

    public List<Map<String, Object>> list(String category, String status, String keyword)
    {
        CategoryConfig config = category(category);
        return mapper.selectOrders(config.tableName(), config.fieldPrefix(), config.orderPrefix(),
            config.category(), databaseStatus(status), keyword == null ? null : keyword.trim());
    }

    @Transactional
    public void start(String category, Long id, String executor)
    {
        CategoryConfig config = category(category);
        Long employeeId = employeeId(executor);
        if (mapper.startOrder(config.tableName(), config.fieldPrefix(), id, employeeId) != 1)
        {
            throw new ServiceException("仅已缴费且未执行的申请可以登记");
        }
    }

    @Transactional
    public void complete(String category, Long id, String executor, String result, String executedAt)
    {
        if (result == null || result.trim().isEmpty())
        {
            throw new ServiceException("结果内容不能为空");
        }
        CategoryConfig config = category(category);
        Long employeeId = employeeId(executor);
        if (mapper.completeOrder(config.tableName(), config.fieldPrefix(), config.inputEmployeeField(),
            id, employeeId, result.trim(), executedAt) != 1)
        {
            throw new ServiceException("申请不存在或当前状态不允许录入结果");
        }
    }

    private Long employeeId(String executor)
    {
        if (executor == null || executor.trim().isEmpty())
        {
            throw new ServiceException("执行人员不能为空");
        }
        Long employeeId = mapper.selectEmployeeIdByName(executor.trim());
        if (employeeId == null)
        {
            throw new ServiceException("未找到有效员工：" + executor.trim());
        }
        return employeeId;
    }

    private String databaseStatus(String status)
    {
        if (status == null || status.isBlank() || "all".equals(status)) return null;
        return switch (status)
        {
            case "pending" -> "PAID";
            case "inProgress" -> "EXECUTING";
            case "completed" -> "COMPLETED";
            default -> throw new ServiceException("不支持的执行状态：" + status);
        };
    }

    private CategoryConfig category(String category)
    {
        return switch (category)
        {
            case "examination" -> new CategoryConfig("check_request", "check", "inputcheck_employee_id", "CHK", "examination");
            case "laboratory" -> new CategoryConfig("inspection_request", "inspection", "inputinspection_employee_id", "LAB", "laboratory");
            case "treatment" -> new CategoryConfig("disposal_request", "disposal", "inputdisposal_employee_id", "DSP", "treatment");
            default -> throw new ServiceException("不支持的医技业务类型：" + category);
        };
    }

    private record CategoryConfig(String tableName, String fieldPrefix, String inputEmployeeField,
        String orderPrefix, String category) { }
}
