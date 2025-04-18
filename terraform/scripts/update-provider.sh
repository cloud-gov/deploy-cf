set -e

if [ -z "$1" ]; then
    echo "Specify env: $0 dev | stage | prod"
    exit
fi

env=$1

this_directory=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

pushd $this_directory/../stacks/cf

    # # Add provider
    git checkout d7c0aaefe5db36a530d2190713e5fb30c99fd969

    terraform show -json > existing.json

    addresses=$(cat existing.json | jq -r '.values.root_module.resources[] | select(.provider_name == "registry.terraform.io/cloudfoundry-community/cloudfoundry") | .address')
    
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

    echo -n "Download, modify, and upload the tfstate file for the entitlement resource. Then hit any key to continue."
    read user_input

    # Dual provider with v3 tf
    git checkout a8462c6e15ba095b768cd65c57c8c48330985258

    for address in $addresses; do
        if [[ "$address" =~ ^data* ]]; then
            echo "Skipping import of data object: $address"
        else
            existing_type=$(cat existing.json | jq -r --arg address "$address" '.values.root_module.resources[] | select(.address==$address) | .type')
            tf_id=$(cat existing.json | jq -r --arg address "$address" '.values.root_module.resources[] | select(.address==$address) | .values.id')
            name=$(cat existing.json | jq -r --arg address "$address" '.values.root_module.resources[] | select(.address==$address) | .name')
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
            terraform import -var-file=${env}-vars.tfvars "${new_type}.${name}" "$tf_id"
        fi
    done
    #rm existing.json
popd