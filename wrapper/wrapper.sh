#!/bin/bash

# Function to execute PostgreSQL query
getschemas_query()
{
   local database_name="$1"
   psql -t -c "select schema_name from information_schema.schemata where catalog_name = '$database_name' and schema_name <> 'public';"
}

# Function to replace "schemas" tag in YAML with comma-delimited schema list
replace_schemas_tag() {

    local yml_file=$1
    local database=$2

    # get the list of schemas for this database
    local query_results=$(getschemas_query "$database")
    echo $query_results

    # Get results as a comma delimited string
    local schema_list=$(echo "$query_results" | tr '\n' ',' | sed 's/,$//')

    schema_list="${schema_list// /}"

    #output list of schemas found.
    echo "Schemas found: '$schema_list'"

    local updated_yaml=$(sed "s/schema:.*/schema: [$schema_list]/g" $yml_file)

    echo "$updated_yaml" > new_ldap2pg.yml
}

# Main script starts here

# Check if YAML file is provided as argument
if [ $# -ne 2 ]; then
    echo "Missing YML file and databases to update.  Usage: $0 <input_yaml_file> <pg_database_name>"
    exit 1
fi

replace_schemas_tag "$1" "$2"
echo "Done!"