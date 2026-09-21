#!/usr/bin/env bash
# A 模块接口 + 功能本地测试脚本
# 用法：先启动后端（gradle bootRun），再执行 bash test/api-test.sh
BASE=http://localhost:8080/api
PASS=0; FAIL=0

check() { # $1=用例名 $2=实际返回 $3=期望包含的字符串
  if echo "$2" | grep -q "$3"; then
    PASS=$((PASS+1)); echo "  ✅ $1"
  else
    FAIL=$((FAIL+1)); echo "  ❌ $1"; echo "     返回: $2"
  fi
}

token_of() { echo "$1" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p'; }

echo "========== 1. 登录模块 =========="
R=$(curl -s -X POST $BASE/login -H 'Content-Type: application/json' -d '{"username":"admin01","password":"123456"}')
check "管理员登录成功返回token" "$R" '"code":0'
ADMIN=$(token_of "$R")

R=$(curl -s -X POST $BASE/login -H 'Content-Type: application/json' -d '{"username":"student01","password":"123456"}')
STUDENT=$(token_of "$R"); check "学生登录成功" "$R" '"code":0'

R=$(curl -s -X POST $BASE/login -H 'Content-Type: application/json' -d '{"username":"repair01","password":"123456"}')
REPAIR=$(token_of "$R"); check "维修人员登录成功" "$R" '"code":0'

R=$(curl -s -X POST $BASE/login -H 'Content-Type: application/json' -d '{"username":"admin01","password":"wrong"}')
check "错误密码被拒绝" "$R" '用户名或密码错误'

R=$(curl -s -X POST $BASE/login -H 'Content-Type: application/json' -d '{"username":"nobody","password":"123456"}')
check "不存在用户被拒绝" "$R" '用户名或密码错误'

R=$(curl -s $BASE/me -H "Authorization: Bearer $ADMIN")
check "me返回当前用户(snake_case字段)" "$R" '"username":"admin01"'

echo "========== 2. 权限拦截 =========="
R=$(curl -s $BASE/users)
check "无token访问被拒(401)" "$R" '"code":401'

R=$(curl -s $BASE/users -H "Authorization: Bearer badtoken123")
check "假token访问被拒(401)" "$R" '"code":401'

R=$(curl -s $BASE/users -H "Authorization: Bearer $STUDENT")
check "学生访问用户管理被拒(403)" "$R" '"code":403'

R=$(curl -s $BASE/labs -H "Authorization: Bearer $STUDENT")
check "学生可查询实验室(登录即可)" "$R" '"code":0'

R=$(curl -s -X POST $BASE/labs/save -H "Authorization: Bearer $STUDENT" -H 'Content-Type: application/json' -d '{"lab_name":"黑客实验室"}')
check "学生新增实验室被拒(403)" "$R" '"code":403'

echo "========== 3. 用户管理 =========="
R=$(curl -s "$BASE/users" -H "Authorization: Bearer $ADMIN")
check "用户列表" "$R" '"username":"student01"'

R=$(curl -s "$BASE/users?role=3" -H "Authorization: Bearer $ADMIN")
check "按角色筛选(role=3只有维修)" "$R" '"username":"repair01"'

R=$(curl -s "$BASE/users?keyword=teacher" -H "Authorization: Bearer $ADMIN")
check "按关键字筛选" "$R" '"username":"teacher01"'

R=$(curl -s -X POST $BASE/users/save -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' -d '{"username":"test_student","role":0,"phone":"13900000000"}')
check "新增用户(默认密码123456)" "$R" '"code":0'
TID=$(echo "$R" | sed -n 's/.*"user_id":\([0-9]*\).*/\1/p')

R=$(curl -s -X POST $BASE/users/save -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' -d '{"username":"test_student","role":1}')
check "重复用户名新增被拒" "$R" '已存在'

R=$(curl -s -X POST $BASE/users/save -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' -d "{\"user_id\":$TID,\"username\":\"test_student\",\"role\":1,\"phone\":\"13711111111\"}")
check "修改用户角色和手机号" "$R" '"role":1'

R=$(curl -s -X POST $BASE/login -H 'Content-Type: application/json' -d '{"username":"test_student","password":"123456"}')
check "新用户默认密码可登录" "$R" '"code":0'

R=$(curl -s -X POST $BASE/users/toggle -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' -d "{\"user_id\":$TID}")
check "禁用用户" "$R" '"status":1'

R=$(curl -s -X POST $BASE/login -H 'Content-Type: application/json' -d '{"username":"test_student","password":"123456"}')
check "禁用后登录被拒" "$R" '已被禁用'

R=$(curl -s -X POST $BASE/users/toggle -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' -d "{\"user_id\":$TID}")
check "重新启用" "$R" '"status":0'

R=$(curl -s $BASE/me -H "Authorization: Bearer $ADMIN")
AID=$(echo "$R" | sed -n 's/.*"user_id":\([0-9]*\).*/\1/p')
R=$(curl -s -X POST $BASE/users/toggle -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' -d "{\"user_id\":$AID}")
check "禁用自己被拒" "$R" '不能禁用'

R=$(curl -s -X POST $BASE/users/delete -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' -d "{\"user_id\":$AID}")
check "删除自己被拒" "$R" '不能删除'

R=$(curl -s -X POST $BASE/users/delete -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' -d "{\"user_id\":$TID}")
check "删除测试用户" "$R" '"code":0'

echo "========== 4. 实验室管理 =========="
R=$(curl -s -X POST $BASE/labs/save -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' -d '{"lab_name":"测试实验室","location":"实验楼C303"}')
check "新增实验室" "$R" '"code":0'
LID=$(echo "$R" | sed -n 's/.*"lab_id":\([0-9]*\).*/\1/p')

R=$(curl -s -X POST $BASE/labs/save -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' -d "{\"lab_id\":$LID,\"lab_name\":\"测试实验室改\",\"location\":\"实验楼C305\"}")
check "修改实验室" "$R" '测试实验室改'

R=$(curl -s -X POST $BASE/labs/delete -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' -d "{\"lab_id\":1}")
check "删除有设备的实验室被拒" "$R" '不能删除'

R=$(curl -s -X POST $BASE/labs/delete -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' -d "{\"lab_id\":$LID}")
check "删除空实验室成功" "$R" '"code":0'

echo "========== 5. 设备类别管理 =========="
R=$(curl -s -X POST $BASE/types/save -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' -d '{"type_name":"测试类别"}')
check "新增类别" "$R" '"code":0'
TYP=$(echo "$R" | sed -n 's/.*"type_id":\([0-9]*\).*/\1/p')

R=$(curl -s -X POST $BASE/types/save -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' -d "{\"type_id\":$TYP,\"type_name\":\"测试类别改\"}")
check "修改类别" "$R" '测试类别改'

R=$(curl -s -X POST $BASE/types/delete -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' -d "{\"type_id\":1}")
check "删除有设备的类别被拒" "$R" '不能删除'

R=$(curl -s -X POST $BASE/types/delete -H "Authorization: Bearer $ADMIN" -H 'Content-Type: application/json' -d "{\"type_id\":$TYP}")
check "删除空类别成功" "$R" '"code":0'

echo "========== 6. 退出登录 =========="
R=$(curl -s -X POST $BASE/logout -H "Authorization: Bearer $REPAIR")
check "退出登录" "$R" '"code":0'
R=$(curl -s $BASE/labs -H "Authorization: Bearer $REPAIR")
check "退出后token失效" "$R" '"code":401'

echo ""
echo "==================================="
echo "  结果：通过 $PASS 项，失败 $FAIL 项"
echo "==================================="
