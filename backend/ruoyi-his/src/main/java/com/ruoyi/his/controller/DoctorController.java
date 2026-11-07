package com.ruoyi.his.controller;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.his.domain.DoctorDtos.DiagnosisRequest;
import com.ruoyi.his.domain.DoctorDtos.MedicalOrderRequest;
import com.ruoyi.his.domain.DoctorDtos.MedicalRecordRequest;
import com.ruoyi.his.domain.DoctorDtos.PrescriptionRequest;
import com.ruoyi.his.service.DoctorService;

@RestController
@RequestMapping("/his")
@PreAuthorize("@ss.hasPermi('his:doctor:visits')")
public class DoctorController
{
    private final DoctorService service;

    public DoctorController(DoctorService service)
    {
        this.service = service;
    }

    @GetMapping("/doctor/visits")
    public AjaxResult visits(@RequestParam(required = false) String state,
        @RequestParam(required = false) String keyword)
    {
        return AjaxResult.success(service.visits(state, keyword));
    }

    @PostMapping("/visit/{registrationId}/accept")
    public AjaxResult accept(@PathVariable Long registrationId)
    {
        service.accept(registrationId);
        return AjaxResult.success();
    }

    @GetMapping("/medicalRecord/{registrationId}")
    public AjaxResult medicalRecord(@PathVariable Long registrationId)
    {
        return AjaxResult.success(service.medicalRecord(registrationId));
    }

    @PutMapping("/medicalRecord")
    public AjaxResult saveMedicalRecord(@RequestBody MedicalRecordRequest request)
    {
        service.saveMedicalRecord(request);
        return AjaxResult.success();
    }

    @GetMapping("/doctor/catalog/{type}")
    public AjaxResult catalog(@PathVariable String type,
        @RequestParam(required = false) String keyword)
    {
        return AjaxResult.success(service.catalog(type, keyword));
    }

    @PostMapping("/medicalOrder")
    public AjaxResult createMedicalOrder(@RequestBody MedicalOrderRequest request)
    {
        service.createMedicalOrder(request);
        return AjaxResult.success();
    }

    @PostMapping("/prescription")
    public AjaxResult createPrescription(@RequestBody PrescriptionRequest request)
    {
        service.createPrescription(request);
        return AjaxResult.success();
    }

    @PostMapping("/medicalOrder/{type}/{id}/cancel")
    public AjaxResult cancel(@PathVariable String type, @PathVariable Long id)
    {
        service.cancel(type, id);
        return AjaxResult.success();
    }

    @GetMapping("/visit/{registrationId}/results")
    public AjaxResult results(@PathVariable Long registrationId)
    {
        return AjaxResult.success(service.results(registrationId));
    }

    @PutMapping("/visit/{registrationId}/diagnosis")
    public AjaxResult diagnosis(@PathVariable Long registrationId,
        @RequestBody DiagnosisRequest request)
    {
        service.saveDiagnosis(registrationId, request);
        return AjaxResult.success();
    }

    @PostMapping("/visit/{registrationId}/complete")
    public AjaxResult complete(@PathVariable Long registrationId)
    {
        service.complete(registrationId);
        return AjaxResult.success();
    }

    @GetMapping("/visit/{registrationId}/costs")
    public AjaxResult costs(@PathVariable Long registrationId)
    {
        return AjaxResult.success(service.costs(registrationId));
    }
}
