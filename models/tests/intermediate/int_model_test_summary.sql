with 

all_graph_resources as (
    select * from {{ ref('stg_all_graph_resources') }}
),

relationships as (
    select * from {{ ref('int_direct_relationships') }}
),

agg_test_relationships as (
    
    select 
        relationships.direct_parent_id, 
        count(distinct relationships.resource_id) as tests_per_model 
    from all_graph_resources
    left join relationships
        on all_graph_resources.resource_id = relationships.resource_id
    where all_graph_resources.resource_type = 'test'
    group by 1
),

final as (
    select 
        all_graph_resources.resource_name, 
        coalesce(agg_test_relationships.tests_per_model, 0) as tests_per_model
    from all_graph_resources
    left join agg_test_relationships
        on all_graph_resources.resource_id = agg_test_relationships.direct_parent_id
    where all_graph_resources.resource_type = 'model'
)

select * from final

