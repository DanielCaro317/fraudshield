-- staging de quejas: limpieza técnica de fraud_raw.complaints.
-- Nota: ajusta los nombres de columna si tu carga difiere (revisa el esquema en la consola).
with source as (
    select * from `llm-496117`.`fraud_raw`.`complaints`
)

select
    -- Fecha: tolera los dos formatos comunes de CFPB (ISO o MM/DD/YYYY).
    -- El cast a string hace que funcione tanto si autodetect la dejó DATE como STRING.
    coalesce(
      safe.parse_date('%Y-%m-%d', nullif(trim(cast(date_received as string)), '')),
      safe.parse_date('%m/%d/%Y', nullif(trim(cast(date_received as string)), ''))
    )                                              as date_received,
    nullif(trim(product), '')                      as product,
    nullif(trim(sub_product), '')                  as sub_product,
    nullif(trim(issue), '')                        as issue,
    nullif(trim(sub_issue), '')                    as sub_issue,
    nullif(trim(consumer_complaint_narrative), '') as consumer_complaint_narrative,
    nullif(trim(company), '')                      as company,
    nullif(trim(state), '')                        as state,
    nullif(trim(zip_code), '')                     as zip_code,
    nullif(trim(submitted_via), '')                as submitted_via,
    -- Yes/No -> BOOL (limpieza de tipos)
    case lower(nullif(trim(timely_response), ''))
        when 'yes' then true when 'no' then false else null end as timely_response,
    current_timestamp()                            as _staged_at    -- marca de auditoría
from source