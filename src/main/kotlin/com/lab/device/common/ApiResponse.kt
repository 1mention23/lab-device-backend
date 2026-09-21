package com.lab.device.common

/**
 * 与前端约定的统一返回格式：{ "code": 0, "msg": "ok", "data": ... }
 * code 非 0 时，前端直接把 msg 弹给用户
 */
data class ApiResponse<T>(
    val code: Int,
    val msg: String,
    val data: T? = null
) {
    companion object {
        fun <T> ok(data: T? = null) = ApiResponse(0, "ok", data)
        fun error(code: Int, msg: String) = ApiResponse<Nothing>(code, msg)
    }
}

/** 业务异常：抛出后由 GlobalExceptionHandler 统一转成 ApiResponse */
class BizException(val code: Int, override val message: String) : RuntimeException(message) {
    constructor(message: String) : this(1, message)
}
