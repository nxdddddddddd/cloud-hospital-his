package com.ruoyi.his.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.his.service.MedicalTechService;

@RestController
@RequestMapping("/his/medical-tech")
public class MedicalTechController
{
    private final MedicalTechService service;

    public MedicalTechController(MedicalTechService service)
    {
        this.service = service;
    }

    @GetMapping("/{category}")
    public AjaxResult list(@PathVariable String category,
        @RequestParam(required = false) String status,
        @RequestParam(required = false) String keyword)
    {
        return AjaxResult.success(service.list(category, status, keyword));
    }

    @PutMapping("/{category}/{id}/start")
    public AjaxResult start(@PathVariable String category, @PathVariable Long id,
        @RequestBody ExecutorRequest request)
    {
        service.start(category, id, request.executor());
        return AjaxResult.success();
    }

    @PutMapping("/{category}/{id}/complete")
    public AjaxResult complete(@PathVariable String category, @PathVariable Long id,
        @RequestBody CompletionRequest request)
    {
        service.complete(category, id, request.executor(), request.result(), request.executedAt());
        return AjaxResult.success();
    }

    public record ExecutorRequest(String executor) { }
    public record CompletionRequest(String executor, String result, String executedAt) { }
}
