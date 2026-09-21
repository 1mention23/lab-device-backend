package com.lab.device.auth

import com.lab.device.common.BizException
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.stereotype.Component
import org.springframework.web.method.HandlerMethod
import org.springframework.web.servlet.HandlerInterceptor

/**
 * 登录校验 + 角色权限拦截器。
 * 拦截 api 下所有请求（login 除外），校验 token，
 * 并按 @RequireRole 注解检查角色是否被允许。
 */
@Component
class AuthInterceptor(private val tokenService: TokenService) : HandlerInterceptor {

    override fun preHandle(request: HttpServletRequest, response: HttpServletResponse, handler: Any): Boolean {
        if (handler !is HandlerMethod) return true

        // 1. 校验 token（所有被拦截的接口都要求登录）
        val token = TokenService.parseToken(request.getHeader("Authorization"))
        val session = token?.let { tokenService.get(it) }
            ?: throw BizException(401, "未登录或登录已过期")

        // 2. 角色校验：方法上的注解优先，其次类上的注解；没有注解则登录即可访问
        val requireRole = handler.getMethodAnnotation(RequireRole::class.java)
            ?: handler.beanType.getAnnotation(RequireRole::class.java)
        if (requireRole != null && session.role !in requireRole.value) {
            throw BizException(403, "当前角色无权访问该接口")
        }

        // 3. 把当前登录人放进 request，Controller 里可以取
        request.setAttribute(TokenService.REQUEST_ATTR, session)
        return true
    }
}
