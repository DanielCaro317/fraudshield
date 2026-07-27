
    
    

with all_values as (

    select
        transaction_type as value_field,
        count(*) as n_records

    from `llm-496117`.`fraud_dbt`.`mart_fraud_features`
    group by transaction_type

)

select *
from all_values
where value_field not in (
    'CASH_IN','CASH_OUT','DEBIT','PAYMENT','TRANSFER'
)


