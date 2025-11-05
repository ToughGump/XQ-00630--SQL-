--2025年1-3月每个用户的累计支付金额
WITH user_total_payment AS (
    SELECT 
        roleid
        ,SUM(money) AS total_pay_amount
    FROM payment
    WHERE 
        DATE(time) BETWEEN '2025-01-01' AND '2025-03-31'
        AND money >= 0
    GROUP BY roleid
),

--“累计支付金额前10%”的高价值用户
high_value_users AS (
    SELECT 
        roleid
        ,total_pay_amount

    FROM (
        SELECT 
            roleid
            ,total_pay_amount,
            --计算用户在支付金额排序中的百分位
            PERCENT_RANK() OVER (ORDER BY total_pay_amount DESC) AS pay_percent_rank
        FROM user_total_payment
    ) AS ranked_users

    WHERE pay_percent_rank < 0.1  --筛选前10%
),

--计算高价值用户在2025年1-3月的去重登录天数
user_login_days AS (
    SELECT 
        high_value_users.roleid
        ,COUNT(DISTINCT login.logymd) AS login_days  -去重
    FROM high_value_users
    LEFT JOIN login 
        ON high_value_users.roleid = login.roleid
        AND login.logymd BETWEEN '2025-01-01' AND '2025-03-31'
    GROUP BY high_value_users.roleid
)

--计算高价值用户的人均登录天数
SELECT
    (SELECT COUNT(DISTINCT roleid) FROM high_value_users) AS `累计支付金额排名前10%的用户人数)`
    ,ROUND(AVG(login_days), 2) AS `他们在1-3月人均登录天数`
FROM user_login_days;