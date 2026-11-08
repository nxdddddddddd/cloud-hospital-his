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
    public AjaxResult start(@PathVariable String category, @PathVariable Long id)
    {
        service.start(category, id);
        return AjaxResult.success();
    }

    @PutMapping("/{category}/{id}/complete")
    public AjaxResult complete(@PathVariable String category, @PathVariable Long id,
        @RequestBody CompletionRequest request)
    {
        service.complete(category, id, request.result(), request.executedAt());
        return AjaxResult.success();
    }

    /** 执行人员由后端从当前登录用户推导，请求体只包含结果和执行时间。 */
    public record CompletionRequest(String result, String executedAt) { }
}
