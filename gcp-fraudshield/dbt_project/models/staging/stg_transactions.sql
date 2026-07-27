-- Limpieza y normalización de las transacciones crudas.
with source as (
    select * from {{ source('fraud_raw', 'transactions') }}
),

renamed as (
    select
        step,
        hour_of_day,
        type                         as transaction_type,
        cast(amount as float64)      as amount,
        name_orig                     as account_orig,
        cast(old_balance_orig as float64)  as old_balance_orig,
        cast(new_balance_orig as float64)  as new_balance_orig,
        name_dest                    as account_dest,
        cast(old_balance_dest as float64)  as old_balance_dest,
        cast(new_balance_dest as float64)  as new_balance_dest,
        cast(is_fraud as int64)            as is_fraud,
        cast(is_flagged_fraud as int64)    as is_flagged_fraud
    from source
)

select * from renamed