{#
    dev (default): use the custom schema name as-is -> staging, intermediate, marts
    ci:            prefix with the target schema    -> ci_staging, ci_intermediate, ci_marts
                   so pipeline runs never overwrite the real tables.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- elif target.name == 'ci' -%}
        {{ target.schema }}_{{ custom_schema_name | trim }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
