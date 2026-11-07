package com.ruoyi.his.mapper;

import java.util.List;
import java.util.Map;
import org.apache.ibatis.annotations.Param;

public interface MedicalTechMapper
{
    List<Map<String, Object>> selectOrders(@Param("tableName") String tableName,
        @Param("fieldPrefix") String fieldPrefix, @Param("orderPrefix") String orderPrefix,
        @Param("category") String category, @Param("status") String status,
        @Param("keyword") String keyword);

    Long selectEmployeeIdByName(@Param("executor") String executor);

    int startOrder(@Param("tableName") String tableName, @Param("fieldPrefix") String fieldPrefix,
        @Param("id") Long id, @Param("employeeId") Long employeeId);

    int completeOrder(@Param("tableName") String tableName, @Param("fieldPrefix") String fieldPrefix,
        @Param("inputEmployeeField") String inputEmployeeField, @Param("id") Long id,
        @Param("employeeId") Long employeeId, @Param("result") String result,
        @Param("executedAt") String executedAt);
}
