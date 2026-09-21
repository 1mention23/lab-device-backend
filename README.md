# 实验室设备借用与维护管理系统 — 后端

Kotlin + Spring Boot 3.3 + Spring Data JPA + MySQL 8 + springdoc-openapi（Swagger）

## 技术栈与分工对应

| 模块 | 负责人 | 包路径 |
|---|---|---|
| 登录、用户管理、角色权限、实验室、设备类别 | **A** | `auth` / `user` / `lab` / `devicetype` / `common` / `config` |
| 设备、借用归还、故障维修、保养、报废、统计、备份 | B | 待 B 在 `com.lab.device` 下新建包开发 |
| 数据库建表 | B | 桌面 `lab_device_manage.sql` |

## 运行步骤

1. 安装 JDK 17+（本机已装 JDK 21）
2. B 先执行 `lab_device_manage.sql` 建库建表，**再执行** `src/main/resources/sql/user_add_status.sql`（给 user 表补 status 启用/禁用字段）
3. 修改 `src/main/resources/application.yml` 里的数据库密码
4. 用 IDEA 打开本目录（Open → 选 `build.gradle.kts`），等待 Gradle 同步完成
5. 运行 `LabDeviceApplication.kt`，或命令行 `gradle bootRun`
6. 验证：
   - 接口文档（Swagger）：http://localhost:8080/swagger-ui.html
   - 初始账号（密码都是 `123456`）：`admin01`(管理员) / `student01` / `teacher01` / `repair01`

## 前后端约定（与前端 C 已确认，来自《前后端对接总原则》）

- 前缀 `/api`，REST 风格
- 统一返回 `{ "code": 0, "msg": "ok", "data": ... }`，code 非 0 时 msg 直接弹给用户
- 字段 snake_case，与数据字典一致（已在 application.yml 全局配置，写 Kotlin 用驼峰即可，自动转下划线）
- 登录后前端带请求头 `Authorization: Bearer <token>`
- 已开启 CORS（允许 localhost 任意端口）

## A 已完成接口清单

| 方法 | 路径 | 说明 | 权限 |
|---|---|---|---|
| POST | /api/login | 登录，body: `{username, password}` → `{token, user}` | 公开 |
| POST | /api/logout | 退出登录 | 登录 |
| GET | /api/me | 当前登录用户信息 | 登录 |
| GET | /api/users | 用户列表，可选参数 `role`、`keyword` | 管理员 |
| POST | /api/users/save | 新增/修改用户（传 `user_id` 为修改；新增密码不填默认 123456） | 管理员 |
| POST | /api/users/toggle | 启用/禁用，body: `{user_id, status?}`，status 不传则取反 | 管理员 |
| POST | /api/users/delete | 删除用户，body: `{user_id}` | 管理员 |
| GET | /api/labs | 实验室列表 | 登录 |
| POST | /api/labs/save | 新增/修改实验室，body: `{lab_id?, lab_name, location?}` | 管理员 |
| POST | /api/labs/delete | 删除实验室，body: `{lab_id}` | 管理员 |
| GET | /api/types | 设备类别列表 | 登录 |
| POST | /api/types/save | 新增/修改类别，body: `{type_id?, type_name}` | 管理员 |
| POST | /api/types/delete | 删除类别，body: `{type_id}` | 管理员 |

角色值：0学生，1教师，2系统管理员，3维修人员

## B 开发指引（后端基础框架已就绪，直接用）

1. **实体/仓库/控制器**：仿照 `lab` 包，一个模块一个包（建议 `device`、`borrow`、`fault`、`maintain`、`scrap`、`stats`），实体类字段对应数据字典，写驼峰即可，返回给前端自动转 snake_case。
2. **权限控制**：在 Controller 类或方法上加 `@RequireRole(2)` 即可限定角色；不加则登录即可访问。拦截器、token、统一返回、异常处理都已全局生效，**不用重复写**。
3. **拿当前登录人**：`request.getAttribute("currentSession") as TokenService.Session`（含 userId/username/role），参考 `UserController.toggle`。
4. **报错**：业务错误直接 `throw BizException("提示语")`，会自动按约定格式返回给前端。
5. **密码**：用 `sha256Hex(...)`（common 包里），与数据库初始数据一致。
6. **表结构**：`ddl-auto: none`，JPA 不会动表；改表结构必须先改 SQL 脚本并通知全员。

## 已知事项

- token 存内存，服务重启需重新登录（课程项目够用）
- user 表 status 字段是 A 补充的，B 建库后需执行 `sql/user_add_status.sql`
- 设备借用数量扣减/恢复已由 B 的 SQL 触发器保证，B 写业务代码时注意不要在 Java 里重复扣减
