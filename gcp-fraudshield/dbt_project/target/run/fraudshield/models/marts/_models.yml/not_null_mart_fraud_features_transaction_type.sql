
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select transaction_type
from `llm-496117`.`fraud_dbt`.`mart_fraud_features`
where transaction_type is null



  
  
      
    ) dbt_internal_test