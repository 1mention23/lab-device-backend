package com.lab.device.common

import java.security.MessageDigest

/**
 * SHA-256 十六进制摘要。
 * 与数据库初始化脚本里 MySQL 的 SHA2('123456', 256) 结果一致（小写 64 位十六进制），
 * 这样初始账号 student01/teacher01/admin01/repair01（密码均为 123456）可以直接登录。
 */
fun sha256Hex(text: String): String =
    MessageDigest.getInstance("SHA-256")
        .digest(text.toByteArray(Charsets.UTF_8))
        .joinToString("") { "%02x".format(it) }
