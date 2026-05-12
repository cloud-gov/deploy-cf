#!/bin/bash

this_directory=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Define required variables
REQUIRED_VARS=("CURRENT_KEY_NAME" "PGDATABASE" "PGHOST" "PGPASSWORD" "PGUSER")

missing_envar=false
for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "Error: Required environment variable '$var' is not set."
        missing_envar=true
    fi
done
if [ "$missing_envar" == "true" ]; then 
    exit 1
fi 

get_table_data_to_be_reencrypted() {
    local table_name=$1
    local id_column=$2
    local encrypted_column=$3
    local salt_column=$4
 
    local psql_command="SELECT json_agg(t) FROM (SELECT ${id_column}, ${encrypted_column}, ${salt_column} FROM ${table_name} WHERE LENGTH(${salt_column}) < 16) t"
    psql -Atq -c "${psql_command}"
}

get_updated_encrypted_values() {
    local existing_encrypted_value=$1
    local existing_salt=$2
    local current_key_name=$3 

    export EXISTING_ENCRYPTED_VALUE="$existing_encrypted_value"
    export EXISTING_SALT="$existing_salt"
    export CURRENT_KEY_NAME="$current_key_name"

    "${this_directory}/update-encryption.rb" | /var/vcap/jobs/cloud_controller_ng/bin/console
    cat ruby_output.json
}

# PGDump - search for encrypted string to determine if it could be stored/copied in another column somewhere else. 
pg_dump > ${this_directory}/ccdb-dumb-fips.sql

while read -r table; do
    table_name=$(echo "$table" | jq -r '.table_name')
    id_column=$(echo "$table" | jq -r '.id_column')
    encrypted_column=$(echo "$table" | jq -r '.encrypted_column')
    salt_column=$(echo "$table" | jq -r '.salt_column')

    table_data_to_be_reencrypted_json=$(get_table_data_to_be_reencrypted "$table_name" "$id_column" "$encrypted_column" "$salt_column")
    
    while read -r table_row_to_update; do
        echo " "
        echo "table_row_to_update: $table_row_to_update"
        echo " "
        existing_encrypted_value=$(echo "$table_row_to_update" | jq -r --arg encrypted_column_name "$encrypted_column" '.[$encrypted_column_name]')
        existing_salt=$(echo "$table_row_to_update" | jq -r --arg salt_column_name "$salt_column" '.[$salt_column_name]')
        current_key_name="$CURRENT_KEY_NAME"

        updated_encrypted_values=$(get_updated_encrypted_values "$existing_encrypted_value" "$existing_salt" "$current_key_name")
        echo " "
        echo "updated_encrypted_values $updated_encrypted_values"
        echo " "
        

    done < <(echo "$table_data_to_be_reencrypted_json" | jq -c '.[]')
    
    # echo "$table_name"
done < <(cat "${this_directory}/tables.json" | jq -c '.tables[]')
