This package is used to flag areas within a dbt project that are misaligned with dbt Labs' best practices.

# Contributing
If you'd like to add models to flag new areas, please update this README and add an integration test ([more details here](https://github.com/dbt-labs/pro-serv-dag-auditing/tree/main/integration_tests#adding-an-integration-test)).

# Contents

__[Documentation Coverage](#documentation-coverage)__

__[Test Coverage](#test-coverage)__

__[Project Organization](#project-organization)__

__[DAG Issues](#dag-issues)__
- [Direct Join to Source](#direct-join-to-source)
- [Model Fanout](#model-fanout)
- [Multiple Sources Joined](#multiple-sources-joined)
- [Rejoining of Upstream Concepts](#rejoining-of-upstream-concepts)
- [Root Models](#root-models)
- [Source Fanout](#source-fanout)
- [Unused Sources](#unused-sources)

## Documentation Coverage

`fct_undocumented_models` lists every model with no description configured.

`fct_documentation_coverage` calculates the percent of enabled models in the project that have a configured description.

Tip: We recommend you add descriptions to at least 75 percent of your models.

## Test Coverage

`fct_untested_models` lists every model with no tests.

`fct_test_coverage` contains metrics pertaining to project-wide test coverage.

Tip: We recommend [at a minimum](https://www.getdbt.com/analytics-engineering/transformation/data-testing/#what-should-you-test), every model should have `not_null` and `unique` tests set up on a primary key.

## Project Organization

`fct_unidentified_models` lists every model that doesn't fit into a [standard](https://discourse.getdbt.com/t/how-we-structure-our-dbt-projects/355) [modeling layer](https://www.youtube.com/watch?v=5W6VrnHVkCA). You can customize the names of each modeling layer by setting the following variables within your dbt_project.yml.

- `staging_folder_name`: The name of the folder where staging models go (default 'staging')
- `intermediate_folder_name`: The name of the folder where intermediate models go (default 'intermediate')
- `marts_folder_name`: The name of the folder where marts models go (default 'marts')
- `staging_designation`: The prefix or postfix for staging models (default 'stg')
- `intermediate_designation`: The prefix or postfix for intermediate models (default 'int')

## DAG Issues

### Bending Connections
###### Model

`fct_bending_connections` shows each parent/child relationship where models in the staging layer are dependent on each other.

###### Reason to Flag

###### How to Remediate

###### Example

`stg_model_1` is a parent of `stg_model_2`
<p align = "center">
<img width="800" alt="A DAG showing stg_model_1 as a parent of stg_model_2 and int_model" src="https://user-images.githubusercontent.com/91074396/157698052-06654cb2-6a8d-45f8-a29a-7154d73edf59.png">

### Direct Join to Source
###### Model

`fct_direct_join_to_source` shows each parent/child relationship where a model has a reference to both a model and a source.

###### Reason to Flag

###### How to Remediate

###### Example

`model_2` is pulling in both a model and a source.
<p align = "center">
<img width="800" alt="DAG showing a model and a source joining into a new model" src="https://user-images.githubusercontent.com/91074396/156454034-1f516133-ae52-48d6-9204-2358441ebb44.png">

### Model Fanout
###### Model

`fct_model_fanout` shows all parents with more direct leaf children than the threshold for fanout (determined by variable models_fanout_threshold, default 3)

###### Reason to Flag

###### How to Remediate

###### Example

`fct_model` has three direct leaf children.
<p align = "center">
<img width="800" alt="A DAG showing three models branching out of a fct model" src="https://user-images.githubusercontent.com/91074396/156635853-99bd1bea-662a-4247-875d-cd7cf33c6ac1.png">

### Multiple Sources Joined
###### Model

`fct_multiple_sources_joined` shows each parent/child relationship where a model references more than one source.

###### Reason to Flag

###### How to Remediate

###### Example

`model_1` references two source tables.
<p align = "center">
<img width="800" alt="A DAG showing two sources feeding into a model" src="https://user-images.githubusercontent.com/91074396/156641049-74bd9168-e012-4d77-b343-bfde16cad0d3.png">

### Rejoining of Upstream Concepts

###### Model

`fct_rejoining_of_upstream_concepts` shows all cases where one of the parent's direct children (child) is _also_ the direct child of _another_ one of the parent's direct children (parent_and_child). Only includes cases where the model "in between" the parent and child has NO other downstream dependencies.

###### Reason to Flag

###### How to Remediate

###### Example

`stg_model`, `int_model`, and `fct_model` create a "loop" in the DAG. `int_model` has no other downstream dependencies other than `fct_model`.
<p align = "center">
<img width="800" alt="A DAG showing four resources. A source is feeding into a staging model. The staging model is referenced by both an int model and a fct model. The int model is also being referenced by the fct model. This creates a 'loop' between the staging model, the int model, and the fct model." src="https://user-images.githubusercontent.com/91074396/156642410-d402a7c0-bf91-4b9a-8b3c-815aa7cbbccb.png">

### Root Models
###### Model

`fct_root_models` shows each model with 0 direct parents, meaning that the model cannot be traced back to a declared source or model in the dbt project. 

###### Reason to Flag

This likely means that the model (`model_4`  below) contains raw table references, either to a raw data source, or another model in the project without using the `{{ source() }}` or `{{ ref() }}` functions, respectively. This means that dbt is unable to interpret the correct lineage of this model, and could result in mis-timed execution and/or circular references depending on the model’s upstream dependencies. 

###### How to Remediate

Start by mapping any table references in the FROM clause of the model definition to the models or raw tables that they draw from, and replace those references with the {{ ref() }} if the dependency is another dbt model, or the {{ source() }} function if the table is a raw data source (this may require the declaration of a new source table). Then, visualize this model in the DAG, and refactor as appropriate according to best practices. 
###### Exceptions

This behavior may be observed in the case of a manually defined reference table that does not have any dependencies. A good example of this is a `dim_calendar` table that is generated by the `{{ dbt_utils.date_spine() }}` macro — this SQL logic is completely self contained, and does not require any external data sources to execute. 
###### Example

`model_4` has no direct parents
<p align = "center">
<img width="800" alt="A DAG showing three source tables, each being referenced by a staging model. Each staging model is being referenced by another accompanying model. model_4 is an independent resource not being referenced by any models " src="https://user-images.githubusercontent.com/91074396/156644411-83e269e7-f1f9-4f46-9cfd-bdee1c8e6b22.png">

### Source Fanout
###### Model

`fct_source_fanout` shows each parent/child relationship where a source is the direct parent of multiple resources in the DAG.

###### Reason to Flag

###### How to Remediate

###### Example

`source.table_1` has more than one direct child model.
<p align = "center">
<img width="800" alt="" src="https://user-images.githubusercontent.com/91074396/156636403-3bcfdbc3-cf48-4c8f-98dc-addc274ad321.png">

### Unused Sources
###### Model

`fct_unused_sources` shows each source with 0 children.

###### Reason to Flag

###### How to Remediate

###### Example

`source.table_4` isn't being referenced.
<p align = "center">
<img width="800" alt="A DAG showing three sources which are each being referenced by an accompanying staging model, and one source that isn't being referenced at all" src="https://user-images.githubusercontent.com/91074396/156637881-f67c1a28-93c7-4a91-9337-465aad94b73a.png">


# Limitation with BigQuery

BigQuery current support for recursive CTEs is limited.

For BigQuery, the model `int_all_dag_relationships` needs to be created by looping CTEs instead. The number of loops is defaulted to 9, which means that dependencies between models of more than 9 levels of separation won't show in the model `int_all_dag_relationships` but tests on the DAG will still be correct. With a number of loops higher than 9 BigQuery sometimes raises an error saying the query is too complex.
