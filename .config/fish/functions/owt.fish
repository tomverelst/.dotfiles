function owt --description 'Opens a kannika-platform worktree'
    set git_dir $HOME/git/cymo/kp

    set -l dir_list (find $git_dir -maxdepth 1 -type d | grep -vE "^\$git_dir\$|\.bare")
    set selected (printf "%s\n%s\n" "Create New Worktree" $dir_list | fzf)
    set -l fzf_status $status

    # Check if fzf was cancelled and returned a non-zero exit code
    if test $fzf_status -ne 0
        echo "Operation cancelled."
        return 1
    end

    # Create a new worktree
    if test "$selected" = "Create New Worktree"

        set -l branch_list (git -C $git_dir branch -a)
        set selected_branch (printf "%s\n%s\n" "Create New Branch" $branch_list | fzf)
        set -l git_status $status

        if test $git_status -ne 0
            echo "Operation cancelled"
            return 1
        end

        if test $selected_branch = "Create New Branch"
            echo "Enter the name of the new branch:"
            read wt_branch
            set new_branch true
            set remote_branch false
        else
            set wt_branch $selected_branch
            set remote_branch (string match -r "^remotes/" -- $wt_branch; and echo "true"; or echo "false")
            set new_branch false
        end

        echo "Enter the name of the new worktree:"
        read wt_name

        if test -n "$wt_name" -a -n "$wt_branch"

        else
            echo "Both worktree and branch names must be non-empty. Try again."
            return 1
        end

        echo "Branch: $wt_branch"
        echo "Worktree: $wt_name"
        echo "New Branch: $new_branch"
        echo "Remote: $remote_remote"

        #git -C $HOME/git/cymo/kp worktree add --guess-remote $HOME/git/cymo/kp/$wt_name $wt_branch
        #set -l git_status $status
        #if test $git_status -eq 0
        #idea $HOME/git/cymo/kp/$wt_name
        #end
    else
        idea $selected
        # idea $selected
    end
end
