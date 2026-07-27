-- Features de fraude por transacción, con contexto de comportamiento de la cuenta.
with tx as (
    select * from `llm-496117`.`fraud_dbt`.`stg_transactions`
),

features as (
    select
        *,

        -- 1) ERROR DE SALDO (señal fuerte de fraude):
        -- en un movimiento legítimo, old_balance_orig - amount ≈ new_balance_orig
        round(old_balance_orig - amount - new_balance_orig, 2) as balance_error_orig,
        round(new_balance_dest - old_balance_dest - amount, 2) as balance_error_dest,

        -- 2) VELOCIDAD: nº de transacciones previas de la misma cuenta de origen
        count(*) over (
            partition by account_orig
            order by step
            rows between unbounded preceding and current row
        ) as tx_count_orig,

        -- 3) MONTO ACUMULADO por la cuenta de origen
        sum(amount) over (
            partition by account_orig
            order by step
            rows between unbounded preceding and current row
        ) as cum_amount_orig,

        -- 4) TIEMPO desde la transacción anterior de la misma cuenta (en steps/horas)
        step - lag(step) over (
            partition by account_orig order by step
        ) as steps_since_prev_orig,

        -- 5) ¿La cuenta de origen vacía su saldo? (patrón típico de fraude)
        case when new_balance_orig = 0 and old_balance_orig > 0 then 1 else 0 end as drained_account_flag

    from tx
)

select * from features