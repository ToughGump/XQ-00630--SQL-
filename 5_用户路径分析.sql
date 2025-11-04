--2025年5月新注册玩家及注册日期
WITH may_new_users AS (
    SELECT 
        roleid,
        logymd AS register_date 
    FROM register
    WHERE logymd BETWEEN '2025-05-01' AND '2025-05-31'
    GROUP BY roleid, logymd
),

--计算5月新注册玩家注册后“首次登录时间”
user_first_login AS (
    SELECT 
        may_new_users.roleid,
        MIN(login.time) AS first_login_time  --首次登录时间为最早的登录时间
    FROM may_new_users
    LEFT JOIN login
        ON may_new_users.roleid = login.roleid
        AND login.time >= may_new_users.register_date --首次登录时间须晚于注册时间
    GROUP BY may_new_users.roleid
),

--5月新注册玩家“首次付费时间”
user_first_payment AS (
    SELECT 
        may_new_users.roleid,
        MIN(payment.time) AS first_pay_time
    FROM may_new_users
    LEFT JOIN payment 
        ON may_new_users.roleid = payment.roleid
        AND payment.time >= may_new_users.register_date --首次付费时间须晚于注册时间
    GROUP BY may_new_users.roleid
)

--计算平均耗时（分钟）
SELECT
    CASE 
        WHEN COUNT(DISTINCT user_first_login.roleid) = 0 THEN NULL  --无活跃则NULL
        ELSE ROUND(
            AVG(
                --计算首次付费与首次登录的时间差（分钟），保留2位
                TIMESTAMPDIFF(MINUTE, user_first_login.first_login_time, user_first_payment.first_pay_time)
            ), 
            2 
        )
    END AS `平均耗时(分钟)`

FROM user_first_login
INNER JOIN user_first_payment  
    ON user_first_login.roleid = user_first_payment.roleid --保留“既有首次登录又有首次付费”的用户（无登录/无付费的用户不参与平均计算）

WHERE user_first_payment.first_pay_time >= user_first_login.first_login_time  --首次付费须早于首次登录
AND user_first_login.first_login_time IS NOT NULL  --首次登录时间须有效
AND user_first_payment.first_pay_time IS NOT NULL; --首次登付费时间须有效