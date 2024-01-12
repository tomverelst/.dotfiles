function ken --argument resource_name
    if not kubectl get backup $resource_name > /dev/null 2>&1
        echo "Backup $resource_name does not exist."
        return 1
    end

    set -l current_status (kubectl get backup $resource_name -o jsonpath='{.spec.enabled}' 2>/dev/null)

    set -l new_status "false"
    if test -n "$current_status" -a "$current_status" = "false"
        set new_status "true"
    end

    set -l patch "{\"spec\":{\"enabled\":$new_status}}"

    kubectl patch backup $resource_name --type merge -p $patch > /dev/null 2>&1

    if test "$new_status" = "true"
        echo "Backup $resource_name enabled"
    else
        echo "Backup $resource_name disabled"
    end
end

