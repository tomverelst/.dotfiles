function __dave_setup
    set -g DAVE_PROJECT_PREFIX "prj-"
    set -g DAVE_GCP_REGION "europe-west1"
    set -g DAVE_CONTEXT_PREFIX "dave-"
    set -g DAVE_PROJECT_ID "prj-dave-prod-2f94"
    set -g DAVE_NAME_LABEL "dave-name"

    function __dave_gcp_id
        set -l name $argv[1]
        set -l project_id (gcloud projects list --filter="labels.$DAVE_NAME_LABEL:$name" | awk 'NR==2 {print $1}')
        echo $project_id
    end

    function __dave_ctx_create
        set -l name $argv[1]
        set -l project_id (__dave_gcp_id $name)
        set -l cluster_name "gke-$name"
        if test -n "$project_id"
            echo "Getting credentials for $cluster_name"
            gcloud container clusters get-credentials $cluster_name --region $DAVE_GCP_REGION --project $project_id
            kubectl config rename-context (kubectl config current-context) dave-$name
            echo "Created $DAVE_CONTEXT_PREFIX-$name kubectl context"
        else
            echo "No project found with name $name"
            return 1
        end
    end

    function __dave_ctx
        set -l name $argv[1]

        if not __dave_ctx_exists $name
            if not __dave_ctx_create $name
                return 1
            end
        end

        kubectl config use-context $DAVE_CONTEXT_PREFIX$name
    end

    function __dave_ctx_exists
        set -l name $argv[1]
        if test (kubectl config get-contexts | grep -c dave-$name) -gt 0
            return 0
        else
            return 1
        end
    end

    function __dave_env_list
        gcloud projects list --filter="labels.$DAVE_NAME_LABEL:*" --format="value(labels.$DAVE_NAME_LABEL)"
    end

    function __dave_env_create
        set -l registry (__prompt_env)

        switch $registry
            case 'development'
                __dave_env_create_dev
            case 'prerelease'
                __dave_env_create_pre
            case '*'
                echo "Unknown registry: $environment"
                return 1
         end
    end

    function __dave_env_create_dev
        set -l name (__prompt "environment name")
        set -l pipelineNumber (__prompt "pipeline number")
        set -l username (__prompt "username")
        set -l password (__prompt "password")

        echo "Creating development environment $name"

         # Initialize an empty JSON object
         set -l data '{}'

         # Add the "name" field
         set -l data (insert $data '.name = $name' --arg name "$name")

         # Add the "source_artifacts" object
         set -l data (insert $data '.source_artifacts = $source_artifacts' --argjson source_artifacts '{"env": "development", "pipeline_number":"'$pipelineNumber'"}')

         # Add the "username" field under "kannika_helm_values.api.config.security"
         set -l data (insert $data '.kannika_helm_values.api.config.security.username = $username' --arg username "$username")

         # Add the "password" field under "kannika_helm_values.api.config.security"
         set -l data (insert $data '.kannika_helm_values.api.config.security.password = $password' --arg password "$password")

         # Output the final JSON
         echo $data

#         gcloud workflows run projects/$DAVE_PROJECT_ID/locations/$DAVE_GCP_REGION/workflows/apply \
#         --data='{"name":"'$name'","source_artifacts":{"env": "development", "pipeline_number":"'$pipelineNumber'"},"username":"'$username'","password":"'$password'"}'
    end

    # Function to update JSON using jq
    function insert
        set -l json_data $argv[1]  # Get the current JSON
        set -l jq_filter $argv[2]  # Get the jq filter
        shift; shift  # Shift arguments to get remaining ones for jq
        set -l args $argv

        # Use jq to update the JSON and return the new data
        echo $json_data | jq $jq_filter $args
    end

    function __dave_env_create_pre
        set -l name (__prompt "environment name")
        set -l tag (__prompt "tag")
        set -l username (__prompt "username")
        set -l password (__prompt "password")

        echo "Creating prerelease environment $name"
        gcloud workflows run projects/$DAVE_PROJECT_ID/locations/$DAVE_GCP_REGION/workflows/apply \
        --data='{"name":"'$name'","appVersion":"'$appVersion'","username":"'$username'","password":"'$password'"}'
    end

    function __dave_env_delete
         set -l name $argv[1]

         if test -z "$name"
            echo "Environment name is required. Exiting..."
            return 1
         end

        gcloud workflows run --location $DAVE_GCP_REGION projects/$DAVE_PROJECT_ID/locations/$DAVE_GCP_REGION/workflows/destroy --data='{"name":"'$name'"}'
    end

    function __dave_env_destroy
        set -l name $argv[1]

        if test -z "$name"
            echo "Environment name is required. Exiting..."
            return 1
        end

        gcloud workflows run --location $DAVE_GCP_REGION projects/$DAVE_PROJECT_ID/locations/$DAVE_GCP_REGION/workflows/destroy --data='{"name":"'$name'"}'
    end

    function __prompt_env
        set -l environment (printf "development\nprerelease" | fzf --prompt "Select source registry: ")
        if test -z "$environment"
            echo "No source registry selected. Please choose 'development' or 'prerelease'."
            return 1
        end
        echo $environment
    end

    function __prompt
        set -l fieldName $argv[1]
        set -l value
        read -P "Enter $fieldName: " value
        if test -z "$value"
            echo "$fieldName is required. Exiting..."
            return 1
        end
        echo $value
    end




    function dave
        if test (count $argv) -eq 0
            echo "Usage: dave [COMMAND]"
            return 1
        end

        switch $argv[1]
            case 'ctx'
                if test (count $argv) -eq 2
                    __dave_ctx $argv[2]
                else
                    echo "Usage: dave ctx [NAME]"
                    return 1
                end
            case 'env'
                switch $argv[2]
                    case 'create'
                        __dave_env_create
                    case 'destroy'
                        __dave_env_destroy $argv[3]
                    case 'delete'
                        __dave_env_delete $argv[3]
                    case 'list'
                        __dave_env_list
                    case '*'
                        echo "Unknown command: $argv[2]"
                        return 1
                end
            case '*'
                echo "Unknown command: $argv[1]"
                return 1
        end
    end
end

__dave_setup
