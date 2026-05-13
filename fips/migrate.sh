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
 
    local psql_command="SELECT json_agg(t) FROM (SELECT ${id_column}, ${encrypted_column}, ${salt_column} FROM ${table_name} WHERE LENGTH(${salt_column}) BETWEEN 1 AND 15) t"
    psql -Atq -c "${psql_command}"
}

get_updated_encrypted_values() {
    local existing_encrypted_value=$1
    local existing_salt=$2
    local current_key_name=$3 

    export EXISTING_ENCRYPTED_VALUE="$existing_encrypted_value"
    export EXISTING_SALT="$existing_salt"
    export CURRENT_KEY_NAME="$current_key_name"

    rm -fr ${this_directory}/ruby_output.json
    touch ${this_directory}/ruby_output.json
    cat "${this_directory}/update-encryption.rb" | /var/vcap/jobs/cloud_controller_ng/bin/console &> /dev/null
    cat ruby_output.json
}

update_encrypted_values() {
    local table_name=$1
    local id_column=$2
    local encrypted_column=$3
    local salt_column=$4
    local id=$5
    local encrypted_value=$6
    local salt_value=$7

    local psql_command="UPDATE ${table_name} SET  ${encrypted_column} = '${encrypted_value}', ${salt_column} = '${salt_value}' WHERE ${id_column} = '${id}'"
    echo "UPDATING: $psql_command"
    psql -q -c "${psql_command}"
}

# PGDump - search for encrypted string to determine if it could be stored/copied in another column somewhere else. 
pg_dump > ${this_directory}/ccdb-dumb-fips.sql

while read -r table; do
    table_name=$(echo "$table" | jq -r '.table_name')
    id_column=$(echo "$table" | jq -r '.id_column')
    encrypted_column=$(echo "$table" | jq -r '.encrypted_column')
    salt_column=$(echo "$table" | jq -r '.salt_column')

    echo "Checking table $table_name with id ${id_column}, encrypted column ${encrypted_column}, and salt column ${salt_column}"

    table_data_to_be_reencrypted_json=$(get_table_data_to_be_reencrypted "$table_name" "$id_column" "$encrypted_column" "$salt_column")
    
    while read -r table_row_to_update; do
        id=$(echo "$table_row_to_update" | jq -r --arg id_column_name "$id_column" '.[$id_column_name]')
        existing_encrypted_value=$(echo "$table_row_to_update" | jq -r --arg encrypted_column_name "$encrypted_column" '.[$encrypted_column_name]')
        existing_salt=$(echo "$table_row_to_update" | jq -r --arg salt_column_name "$salt_column" '.[$salt_column_name]')
        current_key_name="$CURRENT_KEY_NAME"
        
        if [ ! -z "$existing_encrypted_value" ]; then 
            count=$(cat "${this_directory}/ccdb-dumb-fips.sql" | grep -c "$existing_encrypted_value") 
            if [ $count -gt 1 ]; then
                echo "WARNING: Found encrypted value in dump file: table_name=${table_name} encrypted_column=${encrypted_column} existing_encrypted_value=${existing_encrypted_value} count_in_dump=${count} (expected 1)"
            fi
        fi

        updated_encrypted_values=$(get_updated_encrypted_values "$existing_encrypted_value" "$existing_salt" "$current_key_name")
        is_error=$(echo "$updated_encrypted_values" | jq -r '.error' )
        new_encrypted_value=$(echo "$updated_encrypted_values" | jq -r '.new_encrypted_value' )
        new_salt=$(echo "$updated_encrypted_values" | jq -r '.new_salt' )
        if [ -z "$is_error" ]; then 
            echo "Error re-encrypting value: table_name=${table_name} encrypted_column=${encrypted_column} existing_encrypted_value=${existing_encrypted_value} existing_salt=${existing_salt} new_encrypted_value=${new_encrypted_value} new_salt=${new_salt}"
        else
            # update the db 
            update_encrypted_values "$table_name"  "$id_column" "$encrypted_column" "$salt_column" "$id" "$new_encrypted_value" "$new_salt"
        fi        

    done < <(echo "$table_data_to_be_reencrypted_json" | jq -c '.[]')
    
    # echo "$table_name"
done < <(cat "${this_directory}/tables.json" | jq -c '.tables[]')
