-- The source has ~1M rows with many coordinates per zip prefix (and some outside Brazil).
-- Here it is reduced to one row per zip prefix, ready to join with customers and sellers.

with source as (

    select * from {{ source('olist', 'geolocation') }}

),

in_brazil as (

    select *
    from source
    -- Brazil's bounding box: drops coordinates that are clearly wrong
    where geolocation_lat between -34 and 6
      and geolocation_lng between -74 and -34

),

aggregated as (

    select
        lpad(cast(geolocation_zip_code_prefix as string), 5, '0')  as zip_code_prefix,
        avg(geolocation_lat)                                        as latitude,
        avg(geolocation_lng)                                        as longitude,
        approx_top_count(geolocation_city, 1)[offset(0)].value      as city,
        upper(approx_top_count(geolocation_state, 1)[offset(0)].value) as state

    from in_brazil
    group by 1

)

select * from aggregated
