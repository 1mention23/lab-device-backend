package com.lab.device.devicetype

import org.springframework.data.jpa.repository.JpaRepository

interface DeviceTypeRepository : JpaRepository<DeviceType, Int> {
    fun findByTypeName(typeName: String): DeviceType?
}
