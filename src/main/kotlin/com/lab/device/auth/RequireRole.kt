package com.lab.device.auth

/**
 * 角色权限注解。标在 Controller 类或方法上，限定可访问的角色。
 * 角色值与数据字典一致：0学生，1教师，2系统管理员，3维修人员
 *
 * 用法：
 *   @RequireRole(2)                // 仅管理员
 *   @RequireRole(0, 1)             // 学生或教师
 *   不写注解                        // 登录即可访问
 */
@Target(AnnotationTarget.FUNCTION, AnnotationTarget.CLASS)
@Retention(AnnotationRetention.RUNTIME)
annotation class RequireRole(vararg val value: Int)
