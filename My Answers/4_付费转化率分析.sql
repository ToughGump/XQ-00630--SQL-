--2025年5月“七日礼包”活动的所有去重参与者
WITH seven_day_pack_participants AS (
    SELECT 
        DISTINCT roleid  --去重
    FROM activity
    WHERE 
        DATE(time) BETWEEN '2025-05-01' AND '2025-05-31'
        AND activity_name = '7day_pack'
),

--参与者中2025年5月有付费行为的用户
paying_participants AS (
    SELECT 
        DISTINCT seven_day_pack_participants.roleid
    FROM seven_day_pack_participants
    LEFT JOIN payment 
        ON seven_day_pack_participants.roleid = payment.roleid
        AND DATE(payment.time) BETWEEN '2025-05-01' AND '2025-05-31'
    WHERE 
        payment.roleid IS NOT NULL
)

--付费转化率
SELECT
    (SELECT COUNT(roleid) FROM seven_day_pack_participants) AS `活动参与人数`
    ,(SELECT COUNT(roleid) FROM paying_participants) AS `付费人数`
    --计算转化率：付费人数/活动参与人数，保留2位小数，百分比
    ,ROUND(
        CASE 
            WHEN (SELECT COUNT(roleid) FROM seven_day_pack_participants) = 0 
            THEN NULL  --参与人数为0则NULL
            ELSE (SELECT COUNT(roleid) FROM paying_participants) / (SELECT COUNT(roleid) FROM seven_day_pack_participants) * 100 
        END, 
        2
    ) AS `付费转化率`;