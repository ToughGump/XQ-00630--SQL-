--筛选2025年4月去重新注册用户
WITH april_new_users AS (
    SELECT 
        roleid,
        logymd AS register_date  -- 提取注册纯日期，用于计算30天边界
    FROM register
    WHERE 
        register_date BETWEEN '2025-04-01' AND '2025-04-30'
    GROUP BY roleid, register_date
),

--4月新用户在“注册后30天内”的总付费金额
april_new_user_30d_payment AS (
    SELECT 
        april_new_users.roleid,

        SUM(CASE 
            WHEN payment.time BETWEEN april_new_users.register_date 
                            AND DATE_ADD(april_new_users.register_date, INTERVAL 30 DAY) --限定30天
                THEN payment.money 
            ELSE 0 
        END) AS 30d_total_pay

    FROM april_new_users

    LEFT JOIN payment
        ON april_new_users.roleid = payment.roleid
        AND payment.money >= 0  --排除负金额
    GROUP BY april_new_users.roleid
)

--计算LTV30
SELECT
    (SELECT COUNT(DISTINCT roleid) FROM april_new_users) AS `注册人数`,
    --LTV30=总付费金额/新用户总数，保留2位小数
    ROUND(
        SUM(30d_total_pay) / (SELECT COUNT(DISTINCT roleid) FROM april_new_users),
        2
    ) AS `LTV30`
FROM april_new_user_30d_payment;