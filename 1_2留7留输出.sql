--一月每日新注册用户及注册日期
WITH daily_new_users AS (
    SELECT
        roleid,
        logymd AS register_date
    FROM register
    WHERE
        logymd BETWEEN '2025-01-01' AND '2025-01-31'  --限定日期区间为2025年1月
        AND roleid IS NOT NULL  --排除无效用户
    GROUP BY roleid, logymd --1个用户1天仅算1次新注册
),

--每日新注册用户数
daily_register_count AS (
    SELECT
        logymd,
        COUNT(DISTINCT roleid) AS new_user_count  --每日新注册用户数
    FROM daily_new_users
    GROUP BY logymd
),

--注册用户在2nd，7th日登录情况
user_retention_login AS (
    SELECT
        daily_new_users.register_date,
        daily_new_users.roleid,
        -- 标记“注册后第2日”是否登录：登录日期 = 注册日期 + 2天
        MAX(CASE WHEN login.logymd = DATE_ADD(daily_new_users.register_date, INTERVAL 2 DAY) THEN 1 ELSE 0 END) AS is_retention_2d,
        -- 标记“注册后第7日”是否登录：登录日期 = 注册日期 + 7天
        MAX(CASE WHEN login.logymd = DATE_ADD(daily_new_users.register_date, INTERVAL 7 DAY) THEN 1 ELSE 0 END) AS is_retention_7d
    FROM daily_new_users
    LEFT JOIN login
        ON daily_new_users.roleid = login.roleid  -- 关联用户登录记录
        AND login.logymd BETWEEN daily_new_users.register_date AND DATE_ADD(daily_new_users.register_date, INTERVAL 7 DAY)  --仅查注册后7天内的登录
    GROUP BY daily_new_users.register_date, daily_new_users.roleid  --按“注册日+用户”分组，避免重复统计登录
),

--2留，7留计算
daily_retention_count AS (
    SELECT
        register_date,
        SUM(is_retention_2d) AS retention_2d_count,  --每日2留人数
        SUM(is_retention_7d) AS retention_7d_count   --每日7留人数
    FROM user_retention_login
    GROUP BY register_date
)

--按格式要求输出
SELECT
    daily_register_count.register_date AS '注册日期',
    daily_register_count.new_user_count AS '当日新注册用户数',
--留存率 = 留存人数 / 新注册人数 保留2位小数
    ROUND(COALESCE(daily_retention_count.retention_2d_count, 0) / daily_register_count.new_user_count, 2) AS '2留',
    ROUND(COALESCE(daily_retention_count.retention_7d_count, 0) / daily_register_count.new_user_count, 2) AS '7留'
FROM daily_register_count
LEFT JOIN daily_retention_count 
    ON daily_register_count.register_date = daily_retention_count.register_date  --关联每日注册数与留存数
ORDER BY daily_register_count.register_date;  --按注册日期升序排列


