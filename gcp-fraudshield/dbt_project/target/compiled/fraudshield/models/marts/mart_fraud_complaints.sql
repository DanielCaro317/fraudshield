-- Config de dbt: tabla PARTICIONADA por mes + CLUSTERED. Nivel senior.
-- ⚠️ Partición MENSUAL (no diaria): CFPB abarca años y una partición por día
--    supera el límite de 4000 particiones de BigQuery.


with clean as (
    select * from `llm-496117`.`fraud_dbt`.`stg_complaints`
)

select
    *,
    -- Trazabilidad: ¿dónde apareció la señal de fraude? (auditoría/explicabilidad)
    case
      when regexp_contains(lower(concat(coalesce(issue,''), ' ', coalesce(sub_issue,''))),
             r'\b(fraud\w*|scam\w*|unauthorized|identity theft|stolen)\b')
        then 'issue_or_sub_issue'
      when regexp_contains(lower(concat(coalesce(product,''), ' ', coalesce(sub_product,''))),
             r'\b(fraud\w*|scam\w*|unauthorized|identity theft|stolen)\b')
        then 'product_or_sub_product'
      else 'consumer_narrative'
    end                    as fraud_match_source,
    current_timestamp()    as _curated_at
from clean
where consumer_complaint_narrative is not null