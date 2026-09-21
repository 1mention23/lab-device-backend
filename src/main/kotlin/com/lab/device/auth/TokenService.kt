package com.lab.device.auth

import org.springframework.stereotype.Service
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

/**
 * 简易 token 登录态管理（内存版）。
 * 登录成功发一个随机 token，前端之后每个请求带 Authorization: Bearer <token>。
 * 注意：服务重启后 token 全部失效，需重新登录（课程项目够用；要持久化可换 Redis）。
 */
@Service
class TokenService {

    /** 登录成功后的会话信息，会放进 request 属性供 Controller 使用 */
    data class Session(val userId: Int, val username: String, val role: Int)

    private val sessions = ConcurrentHashMap<String, Session>()

    fun createSession(userId: Int, username: String, role: Int): String {
        val token = UUID.randomUUID().toString().replace("-", "")
        sessions[token] = Session(userId, username, role)
        return token
    }

    fun get(token: String): Session? = sessions[token]

    fun remove(token: String) {
        sessions.remove(token)
    }

    companion object {
        const val REQUEST_ATTR = "currentSession"

        /** 从请求头解析 token：Authorization: Bearer xxxx */
        fun parseToken(authHeader: String?): String? =
            authHeader?.takeIf { it.startsWith("Bearer ") }
                ?.removePrefix("Bearer ")
                ?.trim()
                ?.takeIf { it.isNotEmpty() }
    }
}
