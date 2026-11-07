package com.ruoyi.his.mapper;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import org.apache.ibatis.annotations.Param;

public interface DoctorMapper
{
    Long selectEmployeeIdByUserId(@Param("userId") Long userId);

    List<Map<String, Object>> selectVisits(@Param("employeeId") Long employeeId,
        @Param("state") String state, @Param("keyword") String keyword);

    int countOwnedRegistration(@Param("registrationId") Long registrationId,
        @Param("employeeId") Long employeeId);

    int countActiveRegistration(@Param("registrationId") Long registrationId,
        @Param("employeeId") Long employeeId);

    int acceptRegistration(@Param("registrationId") Long registrationId,
        @Param("employeeId") Long employeeId);

    Map<String, Object> selectMedicalRecord(@Param("registrationId") Long registrationId);

    int upsertMedicalRecord(@Param("registrationId") Long registrationId,
        @Param("readme") String readme, @Param("present") String present,
        @Param("presentTreat") String presentTreat, @Param("history") String history,
        @Param("allergy") String allergy, @Param("physique") String physique,
        @Param("proposal") String proposal, @Param("careful") String careful);

    Long selectMedicalRecordId(@Param("registrationId") Long registrationId);

    List<Map<String, Object>> selectCatalog(@Param("type") String type,
        @Param("keyword") String keyword);

    int insertMedicalOrder(@Param("tableName") String tableName,
        @Param("fieldPrefix") String fieldPrefix, @Param("techType") String techType,
        @Param("registrationId") Long registrationId, @Param("medicalTechnologyId") Long medicalTechnologyId,
        @Param("info") String info, @Param("position") String position,
        @Param("remark") String remark, @Param("employeeId") Long employeeId,
        @Param("requestKey") String requestKey, @Param("requestHash") String requestHash,
        @Param("lineNo") int lineNo);

    int insertPrescription(@Param("registrationId") Long registrationId,
        @Param("drugId") Long drugId, @Param("usage") String usage,
        @Param("quantity") BigDecimal quantity, @Param("employeeId") Long employeeId,
        @Param("requestKey") String requestKey, @Param("requestHash") String requestHash,
        @Param("lineNo") int lineNo);

    int cancelOrder(@Param("tableName") String tableName,
        @Param("stateField") String stateField, @Param("id") Long id,
        @Param("employeeId") Long employeeId);

    List<Map<String, Object>> selectResults(@Param("registrationId") Long registrationId);

    int updateDiagnosis(@Param("registrationId") Long registrationId,
        @Param("diagnosis") String diagnosis, @Param("cure") String cure);

    int deleteRecordDiseases(@Param("medicalRecordId") Long medicalRecordId);

    int insertRecordDisease(@Param("medicalRecordId") Long medicalRecordId,
        @Param("diseaseId") Long diseaseId);

    int completeRegistration(@Param("registrationId") Long registrationId,
        @Param("employeeId") Long employeeId);

    List<Map<String, Object>> selectCosts(@Param("registrationId") Long registrationId);
}
