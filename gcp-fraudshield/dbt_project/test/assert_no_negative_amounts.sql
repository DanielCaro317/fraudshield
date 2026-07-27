-- Falla si hay montos negativos (calidad de datos).
select *
from {{ ref('stg_transactions') }}
where amount < 0
