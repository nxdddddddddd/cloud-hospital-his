package com.ruoyi.his.controller;

import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.ruoyi.common.core.domain.AjaxResult;

/**
 * HIS模块状态接口。
 */
@RestController
@RequestMapping("/his")
public class HisStatusController
{
    @GetMapping("/status")
    public AjaxResult status()
    {
        return AjaxResult.success(Map.of("module", "ruoyi-his", "status", "ready"));
    }
}
