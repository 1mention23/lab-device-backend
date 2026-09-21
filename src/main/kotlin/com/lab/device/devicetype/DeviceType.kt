package com.lab.device.devicetype

import jakarta.persistence.*

/** 设备类别表 device_type */
@Entity
@Table(name = "device_type")
class DeviceType(

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "type_id")
    var typeId: Int? = null,

    @Column(name = "type_name", nullable = false, length = 50)
    var typeName: String = ""
)
