-- 【给 B 同学】user 表补充"启用/禁用"状态字段
-- 原因：分工要求 A 实现用户状态启用/禁用，但原建表脚本 user 表没有该字段
-- 在 lab_device_manage.sql 执行完之后，再执行本脚本即可（只需执行一次）
USE lab_device_manage;

ALTER TABLE `user`
    ADD COLUMN status TINYINT NOT NULL DEFAULT 0 COMMENT '0正常，1禁用' AFTER phone;
