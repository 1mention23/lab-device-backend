package com.lab.device.devicetype

import com.lab.device.auth.RequireRole
import com.lab.device.common.ApiResponse
import com.lab.device.common.BizException
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.constraints.NotBlank
import org.springframework.dao.DataIntegrityViolationException
import org.springframework.data.repository.findByIdOrNull
import org.springframework.web.bind.annotation.*

/**
 * 设备类别管理（A 负责）：增删改查。
 * 查询所有登录用户可用（前端下拉框需要）；新增/修改/删除仅管理员。
 */
@Tag(name = "设备类别管理（A）")
@RestController
@RequestMapping("/api/types")
class DeviceTypeController(
    private val deviceTypeRepository: DeviceTypeRepository
) {

    data class SaveTypeRequest(
        val typeId: Int? = null,
        @field:NotBlank(message = "类别名称不能为空")
        val typeName: String = ""
    )

    data class DeleteRequest(val typeId: Int = 0)

    @Operation(summary = "查询设备类别列表（所有登录用户可用）")
    @GetMapping
    fun list(): ApiResponse<List<DeviceType>> = ApiResponse.ok(deviceTypeRepository.findAll())

    @Operation(summary = "新增或修改设备类别（管理员）")
    @RequireRole(2)
    @PostMapping("/save")
    fun save(@RequestBody req: SaveTypeRequest): ApiResponse<DeviceType> {
        val type = if (req.typeId == null) {
            if (deviceTypeRepository.findByTypeName(req.typeName) != null) throw BizException("类别名称已存在")
            DeviceType(typeName = req.typeName)
        } else {
            val t = deviceTypeRepository.findByIdOrNull(req.typeId) ?: throw BizException("类别不存在")
            val other = deviceTypeRepository.findByTypeName(req.typeName)
            if (other != null && other.typeId != t.typeId) throw BizException("类别名称已存在")
            t.typeName = req.typeName
            t
        }
        return ApiResponse.ok(deviceTypeRepository.save(type))
    }

    @Operation(summary = "删除设备类别（管理员；类别下有设备时禁止删除）")
    @RequireRole(2)
    @PostMapping("/delete")
    fun delete(@RequestBody req: DeleteRequest): ApiResponse<Boolean> {
        if (!deviceTypeRepository.existsById(req.typeId)) throw BizException("类别不存在")
        try {
            deviceTypeRepository.deleteById(req.typeId)
        } catch (e: DataIntegrityViolationException) {
            throw BizException("该类别下存在设备，不能删除")
        }
        return ApiResponse.ok(true)
    }
}
