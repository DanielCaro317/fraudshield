
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select amount
from `llm-496117`.`fraud_dbt`.`stg_transactions`
where amount is null



  
  
      
    ) dbt_internal_test