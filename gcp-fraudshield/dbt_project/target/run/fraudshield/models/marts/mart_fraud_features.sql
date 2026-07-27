
  
    

    create or replace table `llm-496117`.`fraud_dbt`.`mart_fraud_features`
      
    
    

    
    OPTIONS()
    as (
      -- Tabla final de features lista para entrenar el modelo de fraude (Manual 04).
with f as (
    select * from `llm-496117`.`fraud_dbt`.`int_account_activity`
)

select
    -- identificadores / contexto
    step,
    hour_of_day,
    transaction_type,
    is_high_risk_type,

    -- montos y saldos
    amount,
    old_balance_orig,
    new_balance_orig,
    old_balance_dest,
    new_balance_dest,

    -- features derivadas
    balance_error_orig,
    balance_error_dest,
    tx_count_orig,
    cum_amount_orig,
    coalesce(steps_since_prev_orig, -1) as steps_since_prev_orig,
    drained_account_flag,

    -- etiqueta objetivo
    is_fraud

from (
    select
        *,
        case when transaction_type in ('TRANSFER', 'CASH_OUT') then 1 else 0 end as is_high_risk_type
    from f
)
    );
  