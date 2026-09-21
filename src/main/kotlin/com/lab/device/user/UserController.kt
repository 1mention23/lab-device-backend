package com.lab.device.user

import com.lab.device.auth.RequireRole
import com.lab.device.auth.TokenService
import com.lab.device.common.ApiResponse
import com.lab.device.common.BizException
import com.lab.device.common.sha256Hex
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.servlet.http.HttpServletRequest
import jakarta.validation.constraints.NotBlank
import org.springframework.data.repository.findByIdOrNull
import org.springframework.web.bind.annotation.*

/**
 * 用户管理模块（A 负责）：用户新增、查询、修改、启用/禁用、删除。
 * 仅系统管理员（role=2）可操作。
 */
@Tag(name = "用户管理（A）")
@RequireRole(2)
@RestController
@RequestMapping("/api/users")
class UserController(
    private val userRepository: UserRepository
) {

    data class SaveUserRequest(
        val userId: Int? = null,          // 传了 userId = 修改，不传 = 新增
        @field:NotBlank(message = "用户名不能为空")
        val username: String = "",
        val password: String? = null,     // 新增时不填默认 123456；修改时不填表示不改密码
        val role: Int = 0,
        val phone: String? = null
    )

    data class ToggleRequest(val userId: Int = 0, val status: Int? = null)
    data class DeleteRequest(val userId: Int = 0)

    @Operation(summary = "查询用户列表，可按角色/用户名关键字筛选")
    @GetMapping
    fun list(
        @RequestParam(required = false) role: Int?,
        @RequestParam(required = false) keyword: String?
    ): ApiResponse<List<UserVo>> {
        val users = when {
            role != null -> userRepository.findByRole(role)
            !keyword.isNullOrBlank() -> userRepository.findByUsernameContaining(keyword)
            else -> userRepository.findAll()
        }
        return ApiResponse.ok(users.map { it.toVo() })
    }

    @Operation(summary = "新增或修改用户（传 user_id 为修改）")
    @PostMapping("/save")
    fun save(@RequestBody req: SaveUserRequest): ApiResponse<UserVo> {
        if (req.role !in 0..3) throw BizException("角色取值必须为 0~3")

        val user = if (req.userId == null) {
            // 新增：用户名不能重复，密码默认 123456
            if (userRepository.findByUsername(req.username) != null) {
                throw BizException("用户名已存在")
            }
            User(
                username = req.username,
                password = sha256Hex(req.password.takeUnless { it.isNullOrBlank() } ?: "123456"),
                role = req.role,
                phone = req.phone
            )
        } else {
            // 修改：用户名、角色、手机号可改；密码传了才改
            val u = userRepository.findByIdOrNull(req.userId) ?: throw BizException("用户不存在")
            val other = userRepository.findByUsername(req.username)
            if (other != null && other.userId != u.userId) throw BizException("用户名已存在")
            u.username = req.username
            u.role = req.role
            u.phone = req.phone
            if (!req.password.isNullOrBlank()) u.password = sha256Hex(req.password)
            u
        }
        return ApiResponse.ok(userRepository.save(user).toVo())
    }

    @Operation(summary = "启用/禁用用户（status 不传则取反；不能禁用自己）")
    @PostMapping("/toggle")
    fun toggle(@RequestBody req: ToggleRequest, request: HttpServletRequest): ApiResponse<UserVo> {
        val session = request.getAttribute(TokenService.REQUEST_ATTR) as TokenService.Session
        if (req.userId == session.userId) throw BizException("不能禁用当前登录账号")
        val user = userRepository.findByIdOrNull(req.userId) ?: throw BizException("用户不存在")
        user.status = req.status ?: if (user.status == 0) 1 else 0
        return ApiResponse.ok(userRepository.save(user).toVo())
    }

    @Operation(summary = "删除用户（不能删除自己）")
    @PostMapping("/delete")
    fun delete(@RequestBody req: DeleteRequest, request: HttpServletRequest): ApiResponse<Any> {
        val session = request.getAttribute(TokenService.REQUEST_ATTR) as TokenService.Session
        if (req.userId == session.userId) throw BizException("不能删除当前登录账号")
        if (!userRepository.existsById(req.userId)) throw BizException("用户不存在")
        userRepository.deleteById(req.userId)
        return ApiResponse.ok()
    }
}
