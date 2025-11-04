--分层付费分析(按国家)：2025年Q2各国家活跃与付费指标
SELECT
    register.country AS 用户国家,
    
    --去重活跃人数：2025年Q2有登录行为的用户
    COUNT(DISTINCT CASE 
        WHEN login.logymd BETWEEN '2025-04-01' AND '2025-06-30' 
        THEN login.roleid 
        ELSE NULL 
    END) AS 去重活跃人数,

    --去重付费人数：2025年Q2有付费行为的用户
    COUNT(DISTINCT CASE 
        WHEN payment.logymd BETWEEN '2025-04-01' AND '2025-06-30' 
        THEN payment.roleid 
        ELSE NULL 
    END) AS 去重付费人数,

    --总付费金额：2025年Q2所有有效付费记录的总和
    ROUND(SUM(CASE 
        WHEN payment.logymd BETWEEN '2025-04-01' AND '2025-06-30' 
        THEN payment.money 
        ELSE 0 
    END), 2) AS `总付费金额(单位：分)`,

    --付费率：付费人数 / 活跃人数，保留2位，百分比
    ROUND(
        CASE 
            WHEN COUNT(DISTINCT CASE 
                WHEN login.logymd BETWEEN '2025-04-01' AND '2025-06-30' 
                THEN login.roleid 
                ELSE NULL 
            END) = 0 
            THEN NULL --活跃人数为0，则NULL

            ELSE COUNT(DISTINCT CASE 
                WHEN payment.logymd BETWEEN '2025-04-01' AND '2025-06-30' 
                THEN payment.roleid 
                ELSE NULL 
            END) / COUNT(DISTINCT CASE 
                WHEN login.logymd BETWEEN '2025-04-01' AND '2025-06-30' 
                THEN login.roleid 
                ELSE NULL 
            END) * 100 
        END, 
        2
    ) AS 付费率,


    --ARPU：总付费金额/活跃人数 保留2位
    ROUND(
        CASE 
            WHEN COUNT(DISTINCT CASE 
                WHEN login.logymd BETWEEN '2025-04-01' AND '2025-06-30' 
                THEN login.roleid 
                ELSE NULL 
            END) = 0 
            THEN NULL --活跃人数为0，则NULL
            ELSE SUM(CASE 
                WHEN payment.logymd BETWEEN '2025-04-01' AND '2025-06-30' 
                THEN payment.money 
                ELSE 0 
            END) / COUNT(DISTINCT CASE 
                WHEN login.logymd BETWEEN '2025-04-01' AND '2025-06-30' 
                THEN login.roleid 
                ELSE NULL 
            END) 
        END, 
        2
    ) AS ARPU


FROM
    register
LEFT JOIN login 
    ON register.roleid = login.roleid
LEFT JOIN payment 
    ON register.roleid = payment.roleid

--按国家显示且按去重活跃人数降序
GROUP BY
    register.country
ORDER BY
    去重活跃人数 DESC; 