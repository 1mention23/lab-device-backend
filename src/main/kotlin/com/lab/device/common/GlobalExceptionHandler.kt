package com.lab.device.common

import org.springframework.http.converter.HttpMessageNotReadableException
import org.springframework.web.bind.MissingServletRequestParameterException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice

/** 全局异常处理：任何异常都转成统一返回格式，不让前端看到裸报错页面 */
@RestControllerAdvice
class GlobalExceptionHandler {

    @ExceptionHandler(BizException::class)
    fun handleBiz(e: BizException) = ApiResponse.error(e.code, e.message)

    @ExceptionHandler(MissingServletRequestParameterException::class, HttpMessageNotReadableException::class)
    fun handleBadRequest(e: Exception) = ApiResponse.error(400, "请求参数错误：${e.message}")

    @ExceptionHandler(Exception::class)
    fun handleOther(e: Exception): ApiResponse<Nothing> {
        e.printStackTrace()
        return ApiResponse.error(500, "服务器内部错误：${e.message}")
    }
}
