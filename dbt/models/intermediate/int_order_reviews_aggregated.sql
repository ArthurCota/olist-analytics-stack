-- One row per reviewed order. 547 orders have more than one review:
-- the latest one is kept as the order's score, and the average is kept too.

with reviews as (

    select * from {{ ref('stg_olist__order_reviews') }}

),

aggregated as (

    select
        order_id,
        count(*)                                as review_count,
        avg(review_score)                       as avg_review_score,
        array_agg(review_score order by review_answered_at desc, review_created_at desc, review_id limit 1)[offset(0)]
                                                as review_score,
        min(review_created_at)                  as first_review_created_at

    from reviews
    group by order_id

)

select * from aggregated
