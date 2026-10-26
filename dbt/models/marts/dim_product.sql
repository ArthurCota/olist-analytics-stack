with products as (

    select * from {{ ref('stg_olist__products') }}

),

translations as (

    select product_category_name, product_category_name_english
    from {{ ref('stg_olist__product_category_translation') }}

    union all

    -- categories missing from the source translation file
    select product_category_name, product_category_name_english
    from {{ ref('category_translation_overrides') }}

),

final as (

    select
        products.product_id,
        coalesce(products.product_category_name, 'unknown')                as category_name_pt,
        coalesce(translations.product_category_name_english,
                 products.product_category_name, 'unknown')                 as category_name,
        products.product_name_length,
        products.product_description_length,
        products.product_photos_qty,
        products.product_weight_g,
        products.product_length_cm,
        products.product_height_cm,
        products.product_width_cm,
        products.product_length_cm * products.product_height_cm * products.product_width_cm
                                                                             as product_volume_cm3

    from products
    left join translations
        on products.product_category_name = translations.product_category_name

)

select * from final
