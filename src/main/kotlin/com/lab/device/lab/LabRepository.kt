package com.lab.device.lab

import org.springframework.data.jpa.repository.JpaRepository

interface LabRepository : JpaRepository<Lab, Int> {
    fun findByLabName(labName: String): Lab?
}
