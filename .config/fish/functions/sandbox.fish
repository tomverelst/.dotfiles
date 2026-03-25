# Sandbox naming: strip ~/git/ prefix, replace / with -, remove dots, append language suffix
# e.g. ~/git/cruxy/claude-workshops → cruxy-claude-workshops-rust
#      ~/git/cymo/kp/0.16/main      → cymo-kp-016-main-rust
function sandbox --description 'Spawn a Docker sandbox for the current directory, auto-detecting project type'
    set dir (pwd)
    set name (string replace -r '^'$HOME'/git/' '' $dir | string replace -a '/' '-' | string replace -a '.' '')

    if test -f $dir/Cargo.toml
        set image cruxy-eu/rust-workshop
        set name "$name-rust"
    else
        echo "Could not detect project type (no Cargo.toml found)"
        return 1
    end

    docker sandbox create --name $name -t $image --load-local-template claude $dir
    and docker sandbox run $name
end
