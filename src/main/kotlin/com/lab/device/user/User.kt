package com.lab.device.user

import jakarta.persistence.*
import java.time.LocalDateTime

/** 用户基本信息表 user。角色：0学生，1教师，2系统管理员，3维修人员 */
@Entity
@Table(name = "user")
class User(

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_id")
    var userId: Int? = null,

    @Column(name = "username", nullable = false, length = 30)
    var username: String = "",

    @Column(name = "password", nullable = false, length = 100)
    var password: String = "",

    @Column(name = "role", nullable = false)
    var role: Int = 0,

    @Column(name = "phone", length = 20)
    var phone: String? = null,

    /** 0禁用，1启用（与前端契约一致）。该字段需 B 执行 sql/user_add_status.sql 补充 */
    @Column(name = "status", nullable = false)
    var status: Int = 1,

    @Column(name = "create_time", insertable = false, updatable = false)
    var createTime: LocalDateTime? = null
)

/** 返回给前端的用户视图：不带密码。序列化后字段为 snake_case（user_id、create_time 等） */
data class UserVo(
    val userId: Int?,
    val username: String,
    val role: Int,
    val phone: String?,
    val status: Int,
    val createTime: LocalDateTime?
)

fun User.toVo() = UserVo(userId, username, role, phone, status, createTime)
