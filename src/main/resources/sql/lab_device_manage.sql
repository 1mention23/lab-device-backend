CREATE DATABASE IF NOT EXISTS lab_device_manage
DEFAULT CHARACTER SET utf8mb4
DEFAULT COLLATE utf8mb4_general_ci;

USE lab_device_manage;

SET NAMES utf8mb4;

-- 先关闭外键检查，按依赖倒序删表，保证脚本可重复执行
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS operation_log;
DROP TABLE IF EXISTS scrap_record;
DROP TABLE IF EXISTS maintain_record;
DROP TABLE IF EXISTS repair_record;
DROP TABLE IF EXISTS fault_record;
DROP TABLE IF EXISTS return_record;
DROP TABLE IF EXISTS borrow_detail;
DROP TABLE IF EXISTS borrow_apply;
DROP TABLE IF EXISTS device;
DROP TABLE IF EXISTS device_type;
DROP TABLE IF EXISTS lab;
DROP TABLE IF EXISTS `user`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. 用户基本信息表 user
CREATE TABLE `user` (
    user_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '用户主键',
    username VARCHAR(30) NOT NULL COMMENT '用户名',
    password VARCHAR(100) NOT NULL COMMENT '密码(加密存储)',
    role TINYINT NOT NULL COMMENT '0学生，1教师，2实验室管理员，3维修人员',
    phone VARCHAR(20) DEFAULT NULL COMMENT '手机号',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    UNIQUE KEY uk_user_username (username),
    CONSTRAINT chk_user_role CHECK (role IN (0,1,2,3))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户基本信息表';

-- 2. 实验室基本信息表 lab
CREATE TABLE lab (
    lab_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '实验室主键',
    lab_name VARCHAR(50) NOT NULL COMMENT '实验室名称',
    location VARCHAR(100) DEFAULT NULL COMMENT '实验室位置',
    UNIQUE KEY uk_lab_name (lab_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='实验室基本信息表';

-- 3. 设备类别表 device_type
CREATE TABLE device_type (
    type_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '类别主键',
    type_name VARCHAR(50) NOT NULL COMMENT '设备类别名称',
    UNIQUE KEY uk_device_type_name (type_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备类别表';

-- 4. 设备基本信息表 device
CREATE TABLE device (
    device_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '设备主键',
    type_id INT NOT NULL COMMENT '设备类别外键',
    lab_id INT NOT NULL COMMENT '所属实验室外键',
    device_name VARCHAR(80) NOT NULL COMMENT '设备名称',
    total_num INT NOT NULL DEFAULT 0 COMMENT '设备总数量',
    available_num INT NOT NULL DEFAULT 0 COMMENT '设备可借数量',
    status TINYINT NOT NULL DEFAULT 0 COMMENT '0正常，1维修中，2报废',
    buy_date DATE DEFAULT NULL COMMENT '采购日期',
    CONSTRAINT chk_device_status CHECK (status IN (0,1,2)),
    CONSTRAINT chk_device_total_num CHECK (total_num >= 0),
    CONSTRAINT chk_device_available_num CHECK (available_num >= 0),
    CONSTRAINT chk_device_available_le_total CHECK (available_num <= total_num),
    CONSTRAINT fk_device_type FOREIGN KEY (type_id) REFERENCES device_type(type_id),
    CONSTRAINT fk_device_lab FOREIGN KEY (lab_id) REFERENCES lab(lab_id),
    INDEX idx_device_type (type_id),
    INDEX idx_device_lab (lab_id),
    INDEX idx_device_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备基本信息表';

-- 5. 设备借用申请表 borrow_apply
CREATE TABLE borrow_apply (
    apply_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '申请主键',
    user_id INT NOT NULL COMMENT '申请人外键',
    apply_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '申请提交时间',
    borrow_start DATETIME NOT NULL COMMENT '借用开始时间',
    borrow_end DATETIME NOT NULL COMMENT '借用截止时间',
    apply_status TINYINT NOT NULL DEFAULT 0 COMMENT '0待审核，1审核通过，2审核驳回，3已归还，4已取消',
    audit_user INT DEFAULT NULL COMMENT '审核管理员外键',
    audit_time DATETIME DEFAULT NULL COMMENT '审核时间',
    borrow_purpose VARCHAR(200) DEFAULT NULL COMMENT '借用用途',
    CONSTRAINT chk_borrow_apply_status CHECK (apply_status IN (0,1,2,3,4)),
    CONSTRAINT chk_borrow_time CHECK (borrow_end > borrow_start),
    CONSTRAINT fk_borrow_apply_user FOREIGN KEY (user_id) REFERENCES `user`(user_id),
    CONSTRAINT fk_borrow_apply_audit_user FOREIGN KEY (audit_user) REFERENCES `user`(user_id),
    INDEX idx_borrow_apply_user (user_id),
    INDEX idx_borrow_apply_status (apply_status),
    INDEX idx_borrow_apply_audit_user (audit_user)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备借用申请表';

-- 6. 借用明细表 borrow_detail
CREATE TABLE borrow_detail (
    detail_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '明细主键',
    apply_id INT NOT NULL COMMENT '借用申请外键',
    device_id INT NOT NULL COMMENT '设备外键',
    borrow_num INT NOT NULL COMMENT '借用数量',
    CONSTRAINT chk_borrow_detail_num CHECK (borrow_num > 0),
    CONSTRAINT fk_borrow_detail_apply FOREIGN KEY (apply_id) REFERENCES borrow_apply(apply_id) ON DELETE CASCADE,
    CONSTRAINT fk_borrow_detail_device FOREIGN KEY (device_id) REFERENCES device(device_id),
    UNIQUE KEY uk_borrow_detail_apply_device (apply_id, device_id),
    INDEX idx_borrow_detail_device (device_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='借用明细表';

-- 7. 设备归还记录表 return_record
CREATE TABLE return_record (
    return_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '归还记录主键',
    apply_id INT NOT NULL COMMENT '借用申请外键',
    return_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '归还时间',
    device_state VARCHAR(100) DEFAULT NULL COMMENT '归还时设备状态',
    remark VARCHAR(200) DEFAULT NULL COMMENT '备注',
    overdue_flag TINYINT NOT NULL DEFAULT 0 COMMENT '0未超期，1超期',
    check_admin INT DEFAULT NULL COMMENT '归还核验管理员外键',
    check_time DATETIME DEFAULT NULL COMMENT '核验时间',
    CONSTRAINT chk_return_overdue CHECK (overdue_flag IN (0,1)),
    CONSTRAINT fk_return_apply FOREIGN KEY (apply_id) REFERENCES borrow_apply(apply_id),
    CONSTRAINT fk_return_check_admin FOREIGN KEY (check_admin) REFERENCES `user`(user_id),
    UNIQUE KEY uk_return_apply (apply_id),
    INDEX idx_return_check_admin (check_admin)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备归还记录表';

-- 8. 设备故障记录表 fault_record
CREATE TABLE fault_record (
    fault_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '故障工单主键',
    device_id INT NOT NULL COMMENT '故障设备外键',
    report_user INT NOT NULL COMMENT '上报人外键',
    report_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '上报时间',
    work_order_status TINYINT NOT NULL DEFAULT 0 COMMENT '0待派工，1维修中，2已完成',
    fault_desc TEXT COMMENT '故障描述',
    assign_admin INT DEFAULT NULL COMMENT '派工管理员外键',
    assign_time DATETIME DEFAULT NULL COMMENT '派工时间',
    repair_man INT DEFAULT NULL COMMENT '指派维修人员外键',
    CONSTRAINT chk_fault_work_order_status CHECK (work_order_status IN (0,1,2)),
    CONSTRAINT fk_fault_device FOREIGN KEY (device_id) REFERENCES device(device_id),
    CONSTRAINT fk_fault_report_user FOREIGN KEY (report_user) REFERENCES `user`(user_id),
    CONSTRAINT fk_fault_assign_admin FOREIGN KEY (assign_admin) REFERENCES `user`(user_id),
    CONSTRAINT fk_fault_repair_man FOREIGN KEY (repair_man) REFERENCES `user`(user_id),
    INDEX idx_fault_device (device_id),
    INDEX idx_fault_report_user (report_user),
    INDEX idx_fault_status (work_order_status),
    INDEX idx_fault_repair_man (repair_man)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备故障记录表';

-- 9. 设备维修记录表 repair_record
CREATE TABLE repair_record (
    repair_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '维修记录主键',
    fault_id INT NOT NULL COMMENT '故障工单外键',
    repair_man INT NOT NULL COMMENT '维修人员外键',
    repair_time DATETIME DEFAULT NULL COMMENT '维修完成时间',
    repair_result VARCHAR(200) DEFAULT NULL COMMENT '维修结果',
    repair_cost DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '维修费用',
    CONSTRAINT chk_repair_cost CHECK (repair_cost >= 0),
    CONSTRAINT fk_repair_fault FOREIGN KEY (fault_id) REFERENCES fault_record(fault_id),
    CONSTRAINT fk_repair_man FOREIGN KEY (repair_man) REFERENCES `user`(user_id),
    INDEX idx_repair_fault (fault_id),
    INDEX idx_repair_man (repair_man)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备维修记录表';

-- 10. 设备保养记录表 maintain_record
CREATE TABLE maintain_record (
    maintain_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '保养主键',
    device_id INT NOT NULL COMMENT '设备外键',
    maintain_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '保养时间',
    operator INT NOT NULL COMMENT '操作管理员外键',
    maintain_content VARCHAR(500) DEFAULT NULL COMMENT '保养内容',
    CONSTRAINT fk_maintain_device FOREIGN KEY (device_id) REFERENCES device(device_id),
    CONSTRAINT fk_maintain_operator FOREIGN KEY (operator) REFERENCES `user`(user_id),
    INDEX idx_maintain_device (device_id),
    INDEX idx_maintain_operator (operator)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备保养记录表';

-- 11. 设备报废记录表 scrap_record
CREATE TABLE scrap_record (
    scrap_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '报废主键',
    device_id INT NOT NULL COMMENT '报废设备外键',
    apply_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '报废申请时间',
    approve_time DATETIME DEFAULT NULL COMMENT '审批时间',
    scrap_reason VARCHAR(200) DEFAULT NULL COMMENT '报废原因',
    approve_admin INT DEFAULT NULL COMMENT '审批管理员外键',
    scrap_status TINYINT NOT NULL DEFAULT 0 COMMENT '0待审批，1审批通过，2审批驳回',
    CONSTRAINT chk_scrap_status CHECK (scrap_status IN (0,1,2)),
    CONSTRAINT fk_scrap_device FOREIGN KEY (device_id) REFERENCES device(device_id),
    CONSTRAINT fk_scrap_approve_admin FOREIGN KEY (approve_admin) REFERENCES `user`(user_id),
    INDEX idx_scrap_device (device_id),
    INDEX idx_scrap_status (scrap_status),
    INDEX idx_scrap_approve_admin (approve_admin)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备报废记录表';

-- 12. 关键业务操作日志表 operation_log
CREATE TABLE operation_log (
    log_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '日志主键',
    user_id INT DEFAULT NULL COMMENT '操作用户外键',
    operation VARCHAR(100) NOT NULL COMMENT '操作类型',
    table_name VARCHAR(50) DEFAULT NULL COMMENT '涉及表',
    record_id VARCHAR(50) DEFAULT NULL COMMENT '涉及记录主键',
    operation_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
    detail VARCHAR(500) DEFAULT NULL COMMENT '操作详情',
    CONSTRAINT fk_log_user FOREIGN KEY (user_id) REFERENCES `user`(user_id),
    INDEX idx_log_user (user_id),
    INDEX idx_log_time (operation_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='关键业务操作日志表';

INSERT INTO `user` (username, password, role, phone) VALUES
('student01', SHA2('123456', 256), 0, '13800000001'),
('teacher01', SHA2('123456', 256), 1, '13800000002'),
('admin01',   SHA2('123456', 256), 2, '13800000003'),
('repair01',  SHA2('123456', 256), 3, '13800000004');

INSERT INTO lab (lab_name, location) VALUES
('电子实验室', '实验楼A101'),
('计算机实验室', '实验楼B202');

INSERT INTO device_type (type_name) VALUES
('示波器'),
('万用表'),
('计算机');

INSERT INTO device (type_id, lab_id, device_name, total_num, available_num, status, buy_date) VALUES
(1, 1, '数字示波器', 10, 10, 0, '2023-01-01'),
(2, 1, '数字万用表', 20, 20, 0, '2023-01-01'),
(3, 2, '台式计算机', 30, 30, 0, '2022-09-01');

-- 触发器：借用审核通过后自动扣减可借数量；归还后恢复可借数量
DROP TRIGGER IF EXISTS trg_borrow_apply_before_update;
DROP TRIGGER IF EXISTS trg_borrow_apply_after_update;

DELIMITER $$

-- 审核通过前检查设备状态和可借数量
CREATE TRIGGER trg_borrow_apply_before_update
BEFORE UPDATE ON borrow_apply
FOR EACH ROW
BEGIN
    IF NEW.apply_status = 1 AND OLD.apply_status <> 1 THEN
        IF EXISTS (
            SELECT 1
            FROM borrow_detail bd
            JOIN device d ON bd.device_id = d.device_id
            WHERE bd.apply_id = NEW.apply_id
              AND (d.status <> 0 OR bd.borrow_num > d.available_num)
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '设备状态不可借或可借数量不足';
        END IF;
    END IF;
END$$

-- 审核通过后扣减；归还后恢复
CREATE TRIGGER trg_borrow_apply_after_update
AFTER UPDATE ON borrow_apply
FOR EACH ROW
BEGIN
    IF NEW.apply_status = 1 AND OLD.apply_status <> 1 THEN
        UPDATE device d
        JOIN borrow_detail bd ON d.device_id = bd.device_id
        SET d.available_num = d.available_num - bd.borrow_num
        WHERE bd.apply_id = NEW.apply_id;
    END IF;

    IF NEW.apply_status = 3 AND OLD.apply_status <> 3 THEN
        UPDATE device d
        JOIN borrow_detail bd ON d.device_id = bd.device_id
        SET d.available_num = d.available_num + bd.borrow_num
        WHERE bd.apply_id = NEW.apply_id;
    END IF;
END$$

DELIMITER ;

-- 触发器：派工后设备状态变为维修中；维修完成后设备恢复为正常
DROP TRIGGER IF EXISTS trg_fault_after_update;
DROP TRIGGER IF EXISTS trg_repair_after_insert;

DELIMITER $$

CREATE TRIGGER trg_fault_after_update
AFTER UPDATE ON fault_record
FOR EACH ROW
BEGIN
    IF NEW.work_order_status = 1 AND OLD.work_order_status <> 1 THEN
        UPDATE device SET status = 1 WHERE device_id = NEW.device_id;
    END IF;
END$$

CREATE TRIGGER trg_repair_after_insert
AFTER INSERT ON repair_record
FOR EACH ROW
BEGIN
    UPDATE fault_record
    SET work_order_status = 2
    WHERE fault_id = NEW.fault_id;

    UPDATE device d
    JOIN fault_record f ON d.device_id = f.device_id
    SET d.status = 0
    WHERE f.fault_id = NEW.fault_id;
END$$

DELIMITER ;

-- 触发器：报废审批通过后设备状态改为报废，不再可借
DROP TRIGGER IF EXISTS trg_scrap_after_update;

DELIMITER $$

CREATE TRIGGER trg_scrap_after_update
AFTER UPDATE ON scrap_record
FOR EACH ROW
BEGIN
    IF NEW.scrap_status = 1 AND OLD.scrap_status <> 1 THEN
        UPDATE device
        SET status = 2, available_num = 0
        WHERE device_id = NEW.device_id;
    END IF;
END$$

DELIMITER ;

-- 存储过程：审核借用申请
DROP PROCEDURE IF EXISTS sp_audit_borrow_apply;

DELIMITER $$

CREATE PROCEDURE sp_audit_borrow_apply(
    IN p_apply_id INT,
    IN p_audit_user INT,
    IN p_approved TINYINT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF p_approved = 1 THEN
        UPDATE borrow_apply
        SET apply_status = 1,
            audit_user = p_audit_user,
            audit_time = NOW()
        WHERE apply_id = p_apply_id
          AND apply_status = 0;
    ELSE
        UPDATE borrow_apply
        SET apply_status = 2,
            audit_user = p_audit_user,
            audit_time = NOW()
        WHERE apply_id = p_apply_id
          AND apply_status = 0;
    END IF;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '申请不存在或状态不是待审核';
    END IF;

    COMMIT;
END$$

DELIMITER ;

-- 存储过程：归还设备
DROP PROCEDURE IF EXISTS sp_return_device;

DELIMITER $$

CREATE PROCEDURE sp_return_device(
    IN p_apply_id INT,
    IN p_device_state VARCHAR(100),
    IN p_remark VARCHAR(200),
    IN p_check_admin INT
)
BEGIN
    DECLARE v_overdue TINYINT DEFAULT 0;
    DECLARE v_borrow_end DATETIME;
    DECLARE v_status TINYINT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT borrow_end, apply_status
    INTO v_borrow_end, v_status
    FROM borrow_apply
    WHERE apply_id = p_apply_id
    FOR UPDATE;

    IF v_status <> 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '只有审核通过的借用申请才能归还';
    END IF;

    IF NOW() > v_borrow_end THEN
        SET v_overdue = 1;
    END IF;

    INSERT INTO return_record (
        apply_id, return_time, device_state, remark,
        overdue_flag, check_admin, check_time
    ) VALUES (
        p_apply_id, NOW(), p_device_state, p_remark,
        v_overdue, p_check_admin, NOW()
    );

    UPDATE borrow_apply
    SET apply_status = 3
    WHERE apply_id = p_apply_id;

    COMMIT;
END$$

DELIMITER ;

-- 存储过程：派工
DROP PROCEDURE IF EXISTS sp_assign_fault;

DELIMITER $$

CREATE PROCEDURE sp_assign_fault(
    IN p_fault_id INT,
    IN p_admin_id INT,
    IN p_repair_man INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    UPDATE fault_record
    SET assign_admin = p_admin_id,
        assign_time = NOW(),
        repair_man = p_repair_man,
        work_order_status = 1
    WHERE fault_id = p_fault_id
      AND work_order_status = 0;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '故障工单不存在或已派工';
    END IF;

    COMMIT;
END$$

DELIMITER ;

-- 存储过程：维修完成登记
DROP PROCEDURE IF EXISTS sp_finish_repair;

DELIMITER $$

CREATE PROCEDURE sp_finish_repair(
    IN p_fault_id INT,
    IN p_repair_man INT,
    IN p_repair_result VARCHAR(200),
    IN p_repair_cost DECIMAL(10,2)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT INTO repair_record (
        fault_id, repair_man, repair_time, repair_result, repair_cost
    ) VALUES (
        p_fault_id, p_repair_man, NOW(), p_repair_result, p_repair_cost
    );

    COMMIT;
END$$

DELIMITER ;

-- 存储过程：报废审批
DROP PROCEDURE IF EXISTS sp_approve_scrap;

DELIMITER $$

CREATE PROCEDURE sp_approve_scrap(
    IN p_scrap_id INT,
    IN p_admin_id INT,
    IN p_approved TINYINT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF p_approved = 1 THEN
        UPDATE scrap_record
        SET scrap_status = 1,
            approve_admin = p_admin_id,
            approve_time = NOW()
        WHERE scrap_id = p_scrap_id
          AND scrap_status = 0;
    ELSE
        UPDATE scrap_record
        SET scrap_status = 2,
            approve_admin = p_admin_id,
            approve_time = NOW()
        WHERE scrap_id = p_scrap_id
          AND scrap_status = 0;
    END IF;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '报废申请不存在或状态不是待审批';
    END IF;

    COMMIT;
END$$

DELIMITER ;