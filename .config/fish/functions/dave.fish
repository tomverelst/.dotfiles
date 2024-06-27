function __dave_gcp_id
    set -l name $argv[1]
    set -l project_id (gcloud projects list --filter=prj-$name | awk 'NR==2 {print $1}')
    echo $project_id
end

function __dave_ctx_create
    set -l name $argv[1]
    set -l project_id (__dave_gcp_id $name)
    if test -n "$project_id"
        gcloud container clusters get-credentials gke-$name-t-europe-west1 --region europe-west1 --project $project_id
        kubectl config rename-context (kubectl config current-context) dave-$name
        echo "Created dave-$name kubectl context"
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

    kubectl config use-context dave-$name
end

function __dave_ctx_exists
    set -l name $argv[1]
    if test (kubectl config get-contexts | grep -c dave-$name) -gt 0
        return 0
    else
        return 1
    end
end

function dave
    if test (count $argv) -eq 0
        echo "Usage: dave ctx [NAME]"
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
        case '*'
            echo "Unknown command: $argv[1]"
            return 1
    end
end
