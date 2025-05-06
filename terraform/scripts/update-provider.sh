set -e

if [ -z "$1" ]; then
    echo "Specify env: $0 dev | stage | prod"
    exit
fi

env=$1

this_directory=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $this_directory/sensitive.cfg

pushd $this_directory/../stacks/cf
    git checkout 2389b98bb44dd870224d7725900d6196eb6f02d5

    # # Add provider
    if [[ "$env" == "dev" ]]; then
        backend_config_key="cf-development/terraform.tfstate"
    elif [[ "$env" == "stage" ]]; then
        backend_config_key="cf-staging/terraform.tfstate"
    elif [[ "$env" == "prod" ]]; then
        backend_config_key="cf-production/terraform.tfstate"
    else 
        echo "Missing backend_config_key for the environment ${env}. Exiting."
    fi
    init_args=(
        "-backend=true"
        "-backend-config=encrypt=true"
        "-backend-config=bucket=terraform-state"
        "-backend-config=key=${backend_config_key}"
        "-backend-config=region=us-gov-west-1"
    )
    terraform init -upgrade "${init_args[@]}"

    terraform show -json > existing.json

    root_addresses=$(cat existing.json | jq -r '.values.root_module.resources[] | select(.provider_name == "registry.terraform.io/cloudfoundry-community/cloudfoundry") | .address')
    module_addresses=$(cat existing.json | jq -r '.values.root_module.child_modules[].resources[] | select(.provider_name == "registry.terraform.io/cloudfoundry-community/cloudfoundry") | .address')
    addresses="${root_addresses} ${module_addresses}" 
    for address in $addresses; do
        existing_type=$(cat existing.json | jq -r --arg address "$address" '.values.root_module.resources[] | select(.address==$address) | .type')
        case $existing_type in
            cloudfoundry_isolation_segment_entitlement)
                echo "Skipping delete of cloudfoundry_isolation_segment_entitlement.${name} as state will be modified directly (new resource is not importable)."
                continue
                ;;
            *)
                echo "Removing state for $address"
                terraform state rm $address
                ;;
            esac
    done

    echo -n "Download, modify, and upload the tfstate file for the entitlement resource (remove the id and update the provider). Then hit any key to continue."
    read user_input

    # Dual provider with v3 tf
    git checkout 3a10959c8e95203e038e132a0b7cebcf7ec1aa4d

    if [[ "$env" == "dev" ]]; then
        backend_config_key="cf-development/terraform.tfstate"
    elif [[ "$env" == "stage" ]]; then
        backend_config_key="cf-staging/terraform.tfstate"
    elif [[ "$env" == "prod" ]]; then
        backend_config_key="cf-production/terraform.tfstate"
    else 
        echo "Missing backend_config_key for the environment ${env}. Exiting."
    fi
    init_args=(
        "-backend=true"
        "-backend-config=encrypt=true"
        "-backend-config=bucket=terraform-state"
        "-backend-config=key=${backend_config_key}"
        "-backend-config=region=us-gov-west-1"
    )
    terraform init -upgrade "${init_args[@]}"


    for address in $addresses; do
        mode=$(cat existing.json | jq -r --arg address "$address" '.values.root_module.resources[] | select(.address==$address) | .mode')
        if [ -z "$mode" ]; then
            mode=$(cat existing.json | jq -r --arg address "$address" '.values.root_module.child_modules[].resources[] | select(.address==$address) | .mode')
        fi 
        if [[ "data" == "$mode" ]] || [[ "$address" =~ ^data* ]]; then
            echo "Skipping import of data object: $address"
        else
            existing_type=$(cat existing.json | jq -r --arg address "$address" '.values.root_module.resources[] | select(.address==$address) | .type')
            if [ -z "$existing_type" ]; then
                existing_type=$(cat existing.json | jq -r --arg address "$address" '.values.root_module.child_modules[].resources[] | select(.address==$address) | .type')
            fi 
            if [ -z "$existing_type" ]; then
                echo "ERROR: Missing type for $address"
                exit 1
            else 
                tf_id=$(cat existing.json | jq -r --arg address "$address" '.values.root_module.resources[] | select(.address==$address) | .values.id')
                if [ -z "$tf_id" ]; then
                    tf_id=$(cat existing.json | jq -r --arg address "$address" '.values.root_module.child_modules[].resources[] | select(.address==$address) | .values.id')
                fi 
                name=$(cat existing.json | jq -r --arg address "$address" '.values.root_module.resources[] | select(.address==$address) | .name')
                if [ -z "$name" ]; then
                    name=$(cat existing.json | jq -r --arg address "$address" '.values.root_module.child_modules[].resources[] | select(.address==$address) | .name')
                fi 
                case $existing_type in
                    cloudfoundry_asg)
                        new_type="cloudfoundry_security_group"
                        ;;
                    cloudfoundry_default_asg)
                        echo "Skipping import of cloudfoundry_default_asg.${name} as it no longer exists in the new provider."
                        continue
                        ;;
                    cloudfoundry_isolation_segment_entitlement)
                        echo "Skipping import of cloudfoundry_isolation_segment_entitlement.${name} as it is not currently importable."
                        continue
                        ;;
                    *)
                        new_type="$existing_type"
                        ;;
                esac
                echo "Importing "${new_type}.${name}" $tf_id"
                terraform import -var-file=${env}.tfvars "${new_type}.${name}" "$tf_id"
            fi
        fi
    done
popd

pushd $this_directory/..
    echo "Removing old provider"
    git checkout cf-provider-v3
popd    

pushd $this_directory/../stacks/cf
    if [[ "$env" == "dev" ]]; then
        backend_config_key="cf-development/terraform.tfstate"
    elif [[ "$env" == "stage" ]]; then
        backend_config_key="cf-staging/terraform.tfstate"
    elif [[ "$env" == "prod" ]]; then
        backend_config_key="cf-production/terraform.tfstate"
    else 
        echo "Missing backend_config_key for the environment ${env}. Exiting."
    fi
    init_args=(
        "-backend=true"
        "-backend-config=encrypt=true"
        "-backend-config=bucket=terraform-state"
        "-backend-config=key=${backend_config_key}"
        "-backend-config=region=us-gov-west-1"
    )
    terraform init -upgrade "${init_args[@]}"
    changes=$(terraform plan -json -var-file=${env}.tfvars -out output | tail -n 1 | jq -r '.changes')
    to_add=$(echo "$changes" | jq -r '.add')
    to_change=$(echo "$changes" | jq -r '.change')
    to_import=$(echo "$changes" | jq -r '.import')
    to_remove=$(echo "$changes" | jq -r '.remove')
    if [ $to_add -gt 0 ] || [ $to_change -gt 0 ] || [ $to_import -gt 0 ] || [ $to_remove -gt 0 ]; then
        echo "CHANGES DETECTED. Something is still wrong. Exiting."
        terraform show output
        exit 1
    else 
        echo "Old provider removed. Good work."
    fi
popd