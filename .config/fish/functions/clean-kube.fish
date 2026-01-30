function clean-kube --description 'Delete all kubectl contexts associated with GKE'
    # 1. Get all context names
    # 2. For each, check if the cluster string contains 'gke'
    # 3. If it does, delete it
    for ctx in (kubectl config get-contexts -o name)
        if kubectl config get-contexts $ctx | string match -q "*gke*"
            kubectl config delete-context $ctx
        end
    end
    echo "GKE context cleanup complete."
end
