with source as (

    select * from {{ source('olist', 'order_reviews') }}

),

renamed as (

    select
        -- review_id alone is NOT unique in the source (a few reviews cover several orders),
        -- so the grain is review_id + order_id
        {{ dbt_utils.generate_surrogate_key(['review_id', 'order_id']) }}  as review_key,
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        datetime(review_creation_date)      as review_created_at,
        datetime(review_answer_timestamp)   as review_answered_at

    from source

)

select * from renamed
