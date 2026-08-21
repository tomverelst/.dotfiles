# Repair a fish_complete_path inherited flattened from a shell that exported it
set -l _paths
for entry in $fish_complete_path
    for p in (string split ' ' -- $entry)
        if test -d "$p"; and not contains -- $p $_paths
            set -a _paths $p
        end
    end
end
set -gu fish_complete_path $_paths
