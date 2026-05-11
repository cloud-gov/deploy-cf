#!/bin/bash

this_directory=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Define required variables
REQUIRED_VARS=("PGDATABASE" "PGHOST" "PGPASSWORD" "PGUSER")

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
 
    local psql_command="SELECT json_agg(t) FROM (SELECT ${id_column}, ${encrypted_column}, ${salt_column} FROM ${table_name} WHERE LENGTH(salt) < 16) t"
    psql -Atq -c "${psql_command}"
}

get_updated_encrypted_values() {
    local existing_encrypted_value=$1
    local existing_salt=$2
    local current_key_name=$3 

    export EXISTING_ENCRYPTED_VALUE="$existing_encrypted_value"
    export EXISTING_SALT="$existing_salt"
    export CURRENT_KEY_NAME="$current_key_name"

    cat "${this_directory}/update-encryption.rb" | /var/vcap/jobs/cloud_controller_ng/bin/console | grep "UPDATE_ENCRYPTION_RESULT: " | sed 's/UPDATE_ENCRYPTION_RESULT: //' 
}

# PGDump - search for encrypted string to determine if it could be stored/copied in another column somewhere else. 
pg_dump > ccdb-dumb-fips.sql

while read -r table; do
    table_name=$(echo "$table" | jq -r '.table_name')
    id_column=$(echo "$table" | jq -r '.id_column')
    encrypted_column=$(echo "$table" | jq -r '.encrypted_column')
    salt_column=$(echo "$table" | jq -r '.salt_column')

    table_data_to_be_reencrypted_json=$(get_table_data_to_be_reencrypted "$table_name" "$id_column" "$encrypted_column" "$salt_column")
    echo "$table_data_to_be_reencrypted_json"
    # while row
    
    
    # echo "$table_name"
done < <(cat "${this_directory}/tables.json" | jq -c '.tables.[]')
