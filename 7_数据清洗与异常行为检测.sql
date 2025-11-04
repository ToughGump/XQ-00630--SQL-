--过滤“金额<0或>10000”的基础异常记录
WITH filtered_payment AS (
    SELECT
        payment_id,
        roleid,
        item_id,
        money,
        payment.time  
    FROM payment
    WHERE money >= 0 AND money <= 10000
),

--对过滤后的数据获取添加同一用户+同一商品的上一条支付时间
prev_payment_added AS (
    SELECT
        payment_id,
        roleid,
        money,
        filtered_payment.time AS paytime,
        
        LAG(filtered_payment.time, 1) OVER (
            PARTITION BY roleid, item_id --按“user_id+item_id”分组
            ORDER BY paytime ASC  --按支付时间升序排序
        ) AS prev_pay_time

    FROM filtered_payment
)

--从prev_payment_added筛选“1小时内重复支付”的异常记录并输出
SELECT
    payment_id,
    roleid,
    money,
    prev_payment_added.paytime AS time
FROM prev_payment_added
WHERE

    TIMESTAMPDIFF(HOUR, prev_pay_time, paytime) <= 1  --当前支付与上一条支付的时间差≤1小时
    AND prev_pay_time IS NOT NULL  --且“上一条记录”存在
ORDER BY paytime ASC;  --按支付时间升序排列