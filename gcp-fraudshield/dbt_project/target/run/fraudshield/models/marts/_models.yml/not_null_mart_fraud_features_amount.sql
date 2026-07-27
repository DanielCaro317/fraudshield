
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select amount
from `llm-496117`.`fraud_dbt`.`mart_fraud_features`
where amount is null



  
  
      
    ) dbt_internal_test