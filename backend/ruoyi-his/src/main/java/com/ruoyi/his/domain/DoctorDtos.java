package com.ruoyi.his.domain;

import java.math.BigDecimal;
import java.util.List;

public final class DoctorDtos
{
    private DoctorDtos() { }

    public record MedicalRecordRequest(Long registrationId, String readme, String present,
        String presentTreat, String history, String allergy, String physique, String proposal,
        String careful) { }

    public record DiagnosisRequest(List<Long> diseaseIds, String diagnosis, String cure) { }

    public record MedicalOrderItem(Long medicalTechnologyId, String info, String position,
        String remark) { }

    public record MedicalOrderRequest(Long registrationId, String type,
        List<MedicalOrderItem> items) { }

    public record PrescriptionItem(Long drugId, String usage, BigDecimal quantity) { }

    public record PrescriptionRequest(Long registrationId, List<PrescriptionItem> items) { }
}
