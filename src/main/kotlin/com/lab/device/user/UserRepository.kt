package com.lab.device.user

import org.springframework.data.jpa.repository.JpaRepository

interface UserRepository : JpaRepository<User, Int> {
    fun findByUsername(username: String): User?
    fun findByRole(role: Int): List<User>
    fun findByUsernameContaining(keyword: String): List<User>
}
