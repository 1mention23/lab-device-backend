package com.lab.device.auth

import com.lab.device.common.ApiResponse
import com.lab.device.common.BizException
import com.lab.device.common.sha256Hex
import com.lab.device.user.UserRepository
import com.lab.device.user.toVo
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.servlet.http.HttpServletRequest
import jakarta.validation.constraints.NotBlank
import org.springframework.web.bind.annotation.*

@Tag(name = "登录模块（A）")
@RestController
@RequestMapping("/api")
class AuthController(
    private val userRepository: UserRepository,
    private val tokenService: TokenService
) {

    data class LoginRequest(
        @field:NotBlank(message = "用户名不能为空")
        val username: String = "",
        @field:NotBlank(message = "密码不能为空")
        val password: String = ""
    )

    /**
     * 登录。成功返回 { token, user }，前端把 token 存起来，
     * 之后每个请求带请求头 Authorization: Bearer <token>
     */
    @Operation(summary = "登录，返回 token 与用户信息")
    @PostMapping("/login")
    fun login(@RequestBody req: LoginRequest): ApiResponse<Any> {
        val user = userRepository.findByUsername(req.username)
            ?: throw BizException("用户名或密码错误")
        if (user.password != sha256Hex(req.password)) {
            throw BizException("用户名或密码错误")
        }
        if (user.status != 0) {
            throw BizException("账号已被禁用，请联系管理员")
        }
        val token = tokenService.createSession(user.userId!!, user.username, user.role)
        return ApiResponse.ok(mapOf("token" to token, "user" to user.toVo()))
    }

    @Operation(summary = "退出登录")
    @PostMapping("/logout")
    fun logout(request: HttpServletRequest): ApiResponse<Any> {
        TokenService.parseToken(request.getHeader("Authorization"))?.let { tokenService.remove(it) }
        return ApiResponse.ok()
    }

    @Operation(summary = "获取当前登录用户信息")
    @GetMapping("/me")
    fun me(request: HttpServletRequest): ApiResponse<Any> {
        val session = request.getAttribute(TokenService.REQUEST_ATTR) as TokenService.Session
        val user = userRepository.findById(session.userId).orElseThrow { BizException("用户不存在") }
        return ApiResponse.ok(user.toVo())
    }
}
