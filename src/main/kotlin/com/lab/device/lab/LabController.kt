package com.lab.device.lab

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
 * 实验室信息管理（A 负责）：增删改查。
 * 查询所有登录用户可用（前端下拉框需要）；新增/修改/删除仅管理员。
 */
@Tag(name = "实验室管理（A）")
@RestController
@RequestMapping("/api/labs")
class LabController(
    private val labRepository: LabRepository
) {

    data class SaveLabRequest(
        val labId: Int? = null,
        @field:NotBlank(message = "实验室名称不能为空")
        val labName: String = "",
        val location: String? = null
    )

    data class DeleteRequest(val labId: Int = 0)

    @Operation(summary = "查询实验室列表（所有登录用户可用）")
    @GetMapping
    fun list(): ApiResponse<List<Lab>> = ApiResponse.ok(labRepository.findAll())

    @Operation(summary = "新增或修改实验室（管理员）")
    @RequireRole(2)
    @PostMapping("/save")
    fun save(@RequestBody req: SaveLabRequest): ApiResponse<Lab> {
        val lab = if (req.labId == null) {
            if (labRepository.findByLabName(req.labName) != null) throw BizException("实验室名称已存在")
            Lab(labName = req.labName, location = req.location)
        } else {
            val l = labRepository.findByIdOrNull(req.labId) ?: throw BizException("实验室不存在")
            val other = labRepository.findByLabName(req.labName)
            if (other != null && other.labId != l.labId) throw BizException("实验室名称已存在")
            l.labName = req.labName
            l.location = req.location
            l
        }
        return ApiResponse.ok(labRepository.save(lab))
    }

    @Operation(summary = "删除实验室（管理员；名下有设备时禁止删除）")
    @RequireRole(2)
    @PostMapping("/delete")
    fun delete(@RequestBody req: DeleteRequest): ApiResponse<Any> {
        if (!labRepository.existsById(req.labId)) throw BizException("实验室不存在")
        try {
            labRepository.deleteById(req.labId)
        } catch (e: DataIntegrityViolationException) {
            throw BizException("该实验室下存在设备，不能删除")
        }
        return ApiResponse.ok()
    }
}
