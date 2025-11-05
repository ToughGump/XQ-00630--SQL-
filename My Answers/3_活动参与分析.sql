--2025年5月新注册用户
WITH may_new_users AS (
    SELECT 
        roleid 
    FROM register 
    WHERE logymd BETWEEN '2025-05-01' AND '2025-05-31'
    GROUP BY roleid  --去重
),

--2025年5月每个用户的活动参与情况
user_activity_status AS (
    SELECT 
        roleid
        ,MAX(CASE WHEN activity_name = 'newbie_pack' THEN 1 ELSE 0 END) AS joined_newbie  --是否参与“新手礼包”活动
        ,MAX(CASE WHEN activity_name = 'challenge_complete' THEN 1 ELSE 0 END) AS joined_challenge --是否参与“挑战任务”活动
    FROM activity
    WHERE 
        DATE(time) BETWEEN '2025-05-01' AND '2025-05-31'  -- 限定5月
        AND activity_name IN ('newbie_pack', 'challenge_complete')  --限定两个目标活动内
    GROUP BY roleid
),

--2025年5月活跃用户
may_active_users AS (
    SELECT DISTINCT roleid 
    FROM login 
    WHERE logymd BETWEEN '2025-05-01' AND '2025-05-31'
)

--按“是否当月新注册”分组，计算各指标
SELECT
    --判断用户是否为2025年5月新注册（是/否）
    CASE 
        WHEN may_new_users.roleid IS NOT NULL THEN '是' 
        ELSE '否' 
    END AS `是否当月新注册玩家`

    --5月当月活跃人数
    ,COUNT(DISTINCT may_new_users.roleid) AS `当月活跃人数`

    --仅参与“新手礼包”的人数
    ,COUNT(DISTINCT CASE 
        WHEN user_activity_status.joined_newbie = 1 AND user_activity_status.joined_challenge = 0 
        THEN user_activity_status.roleid 
        ELSE NULL 
    END) AS `仅参与“新手礼包”活动的人数`

    --仅参与“挑战任务”的人数
    ,COUNT(DISTINCT CASE 
        WHEN user_activity_status.joined_newbie = 0 AND user_activity_status.joined_challenge = 1 
        THEN user_activity_status.roleid 
        ELSE NULL 
    END) AS `仅参与“挑战任务”活动的人数`

    --两个活动都参与的人数
    ,COUNT(DISTINCT CASE 
        WHEN user_activity_status.joined_newbie = 1 AND user_activity_status.joined_challenge = 1 
        THEN user_activity_status.roleid 
        ELSE NULL 
    END) AS `两个活动都参与过的人数`

FROM
    (
        SELECT roleid FROM may_new_users
        UNION 
        SELECT roleid FROM may_active_users
        UNION 
        SELECT roleid FROM user_activity_status
    ) AS all_users  --合并用户

LEFT JOIN may_new_users 
    ON all_users.roleid = may_new_users.roleid
LEFT JOIN may_active_users 
    ON all_users.roleid = may_active_users.roleid
LEFT JOIN user_activity_status 
    ON all_users.roleid = user_activity_status.roleid

--“是否当月新注册”分组
GROUP BY
    CASE 
        WHEN may_new_users.roleid IS NOT NULL THEN '是' 
        ELSE '否' 
    END）
ORDER BY
    `是否当月新注册玩家` ASC; --升序排列