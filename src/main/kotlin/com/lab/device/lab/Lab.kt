package com.lab.device.lab

import jakarta.persistence.*

/** 实验室基本信息表 lab */
@Entity
@Table(name = "lab")
class Lab(

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "lab_id")
    var labId: Int? = null,

    @Column(name = "lab_name", nullable = false, length = 50)
    var labName: String = "",

    @Column(name = "location", length = 100)
    var location: String? = null
)
