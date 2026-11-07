package com.ruoyi.his.service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.ruoyi.common.exception.ServiceException;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.his.domain.DoctorDtos.DiagnosisRequest;
import com.ruoyi.his.domain.DoctorDtos.MedicalOrderItem;
import com.ruoyi.his.domain.DoctorDtos.MedicalOrderRequest;
import com.ruoyi.his.domain.DoctorDtos.MedicalRecordRequest;
import com.ruoyi.his.domain.DoctorDtos.PrescriptionItem;
import com.ruoyi.his.domain.DoctorDtos.PrescriptionRequest;
import com.ruoyi.his.mapper.DoctorMapper;

@Service
public class DoctorService
{
    private final DoctorMapper mapper;

    public DoctorService(DoctorMapper mapper)
    {
        this.mapper = mapper;
    }

    public List<Map<String, Object>> visits(String state, String keyword)
    {
        if (state != null && !state.isBlank() && !List.of("waiting", "completed", "all").contains(state))
        {
            throw new ServiceException("不支持的患者状态：" + state);
        }
        return mapper.selectVisits(currentEmployeeId(), state,
            keyword == null ? null : keyword.trim());
    }

    @Transactional
    public void accept(Long registrationId)
    {
        if (mapper.acceptRegistration(registrationId, currentEmployeeId()) != 1)
        {
            throw new ServiceException("患者不存在、并非当前医生患者或已接诊");
        }
    }

    public Map<String, Object> medicalRecord(Long registrationId)
    {
        ensureOwned(registrationId);
        Map<String, Object> record = mapper.selectMedicalRecord(registrationId);
        return record == null ? Map.of("registrationId", registrationId) : record;
    }

    @Transactional
    public void saveMedicalRecord(MedicalRecordRequest request)
    {
        if (request == null || request.registrationId() == null)
        {
            throw new ServiceException("挂号ID不能为空");
        }
        ensureActive(request.registrationId());
        if (blank(request.readme()))
        {
            throw new ServiceException("主诉不能为空");
        }
        mapper.upsertMedicalRecord(request.registrationId(), request.readme().trim(), request.present(),
            request.presentTreat(), request.history(), request.allergy(), request.physique(),
            request.proposal(), request.careful());
    }

    public List<Map<String, Object>> catalog(String type, String keyword)
    {
        String databaseType = switch (type)
        {
            case "check" -> "CHECK";
            case "inspection" -> "INSPECTION";
            case "disposal" -> "DISPOSAL";
            case "drug" -> "DRUG";
            case "disease" -> "DISEASE";
            default -> throw new ServiceException("不支持的目录类型：" + type);
        };
        return mapper.selectCatalog(databaseType, keyword == null ? null : keyword.trim());
    }

    @Transactional
    public void createMedicalOrder(MedicalOrderRequest request)
    {
        if (request == null || request.registrationId() == null || request.items() == null
            || request.items().isEmpty())
        {
            throw new ServiceException("申请项目不能为空");
        }
        Long employeeId = currentEmployeeId();
        ensureActive(request.registrationId(), employeeId);
        OrderConfig config = orderConfig(request.type());
        String requestKey = UUID.randomUUID().toString();
        String requestHash = sha256(requestKey + request.registrationId() + request.type());
        int lineNo = 1;
        for (MedicalOrderItem item : request.items())
        {
            if (item == null || item.medicalTechnologyId() == null || blank(item.info()))
            {
                throw new ServiceException("申请项目和目的要求不能为空");
            }
            int inserted = mapper.insertMedicalOrder(config.tableName(), config.fieldPrefix(),
                config.techType(), request.registrationId(), item.medicalTechnologyId(),
                item.info().trim(), item.position(), item.remark(), employeeId, requestKey,
                requestHash, lineNo++);
            if (inserted != 1)
            {
                throw new ServiceException("项目不存在或项目类型不匹配");
            }
        }
    }

    @Transactional
    public void createPrescription(PrescriptionRequest request)
    {
        if (request == null || request.registrationId() == null || request.items() == null
            || request.items().isEmpty())
        {
            throw new ServiceException("处方明细不能为空");
        }
        Long employeeId = currentEmployeeId();
        ensureActive(request.registrationId(), employeeId);
        String requestKey = UUID.randomUUID().toString();
        String requestHash = sha256(requestKey + request.registrationId() + "prescription");
        int lineNo = 1;
        for (PrescriptionItem item : request.items())
        {
            if (item == null || item.drugId() == null || blank(item.usage())
                || item.quantity() == null || item.quantity().signum() <= 0)
            {
                throw new ServiceException("药品、用法和数量必须完整");
            }
            if (mapper.insertPrescription(request.registrationId(), item.drugId(), item.usage().trim(),
                item.quantity(), employeeId, requestKey, requestHash, lineNo++) != 1)
            {
                throw new ServiceException("药品不存在");
            }
        }
    }

    @Transactional
    public void cancel(String type, Long id)
    {
        CancelConfig config = cancelConfig(type);
        if (mapper.cancelOrder(config.tableName(), config.stateField(), id, currentEmployeeId()) != 1)
        {
            throw new ServiceException("仅当前医生开立且未缴费的项目可以作废");
        }
    }

    public List<Map<String, Object>> results(Long registrationId)
    {
        ensureOwned(registrationId);
        return mapper.selectResults(registrationId);
    }

    @Transactional
    public void saveDiagnosis(Long registrationId, DiagnosisRequest request)
    {
        ensureActive(registrationId);
        if (request == null || blank(request.diagnosis()))
        {
            throw new ServiceException("诊断结果不能为空");
        }
        if (mapper.updateDiagnosis(registrationId, request.diagnosis().trim(), request.cure()) != 1)
        {
            throw new ServiceException("请先保存病历首页");
        }
        Long recordId = mapper.selectMedicalRecordId(registrationId);
        mapper.deleteRecordDiseases(recordId);
        if (request.diseaseIds() != null)
        {
            request.diseaseIds().stream().filter(id -> id != null).distinct()
                .forEach(id -> mapper.insertRecordDisease(recordId, id));
        }
    }

    @Transactional
    public void complete(Long registrationId)
    {
        if (mapper.completeRegistration(registrationId, currentEmployeeId()) != 1)
        {
            throw new ServiceException("请先接诊并填写诊断结果，再完成诊疗");
        }
    }

    public List<Map<String, Object>> costs(Long registrationId)
    {
        ensureOwned(registrationId);
        return mapper.selectCosts(registrationId);
    }

    private Long currentEmployeeId()
    {
        Long employeeId = mapper.selectEmployeeIdByUserId(SecurityUtils.getUserId());
        if (employeeId == null)
        {
            throw new ServiceException("当前账号未关联有效医院员工");
        }
        return employeeId;
    }

    private void ensureOwned(Long registrationId)
    {
        if (mapper.countOwnedRegistration(registrationId, currentEmployeeId()) != 1)
        {
            throw new ServiceException("患者不存在或并非当前医生患者");
        }
    }

    private void ensureActive(Long registrationId)
    {
        ensureActive(registrationId, currentEmployeeId());
    }

    private void ensureActive(Long registrationId, Long employeeId)
    {
        if (mapper.countActiveRegistration(registrationId, employeeId) != 1)
        {
            throw new ServiceException("患者尚未接诊、已完成诊疗或不属于当前医生");
        }
    }

    private OrderConfig orderConfig(String type)
    {
        return switch (type)
        {
            case "check" -> new OrderConfig("check_request", "check", "CHECK");
            case "inspection" -> new OrderConfig("inspection_request", "inspection", "INSPECTION");
            case "disposal" -> new OrderConfig("disposal_request", "disposal", "DISPOSAL");
            default -> throw new ServiceException("不支持的申请类型：" + type);
        };
    }

    private CancelConfig cancelConfig(String type)
    {
        return switch (type)
        {
            case "check" -> new CancelConfig("check_request", "check_state");
            case "inspection" -> new CancelConfig("inspection_request", "inspection_state");
            case "disposal" -> new CancelConfig("disposal_request", "disposal_state");
            case "prescription" -> new CancelConfig("prescription", "drug_state");
            default -> throw new ServiceException("不支持的作废类型：" + type);
        };
    }

    private boolean blank(String value)
    {
        return value == null || value.isBlank();
    }

    private String sha256(String value)
    {
        try
        {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                .digest(value.getBytes(StandardCharsets.UTF_8)));
        }
        catch (NoSuchAlgorithmException exception)
        {
            throw new IllegalStateException("JVM不支持SHA-256", exception);
        }
    }

    private record OrderConfig(String tableName, String fieldPrefix, String techType) { }
    private record CancelConfig(String tableName, String stateField) { }
}
