function deve --description "Run the kannika dev env for a PR or branch in a deve workspace on the devbox's herdr session"
    # Deployment targets are private and live in ~/.config/fish/private.fish
    # (untracked): DEVE_DEVBOX, DEVE_REPO_PATH, DEVE_WORKTREE (the env builds
    # and runs there, leaving the main checkout alone), DEVE_GH_REPO
    # (owner/name on GitHub), DEVE_DOMAIN_NAME (domain the env is served on)
    if not set -q DEVE_DEVBOX; and test -f ~/.config/fish/private.fish
        source ~/.config/fish/private.fish
    end
    for v in DEVE_DEVBOX DEVE_REPO_PATH DEVE_WORKTREE DEVE_GH_REPO DEVE_DOMAIN_NAME
        if not set -q $v
            echo "deve: \$$v is not set; define it in ~/.config/fish/private.fish" >&2
            return 1
        end
    end
    set -l devbox $DEVE_DEVBOX
    set -l repo $DEVE_REPO_PATH
    set -l worktree $DEVE_WORKTREE
    set -l gh_repo $DEVE_GH_REPO
    set -l workspace_label deve
    # Taskfile variable carrying the domain
    set -l domain_var DEVE_DOMAIN
    set -l domain $DEVE_DOMAIN_NAME

    set -l usage "usage: deve [-s <scenario>] [--set <key>=<value>]... [<pr-number | branch>]
defaults to the current branch of the local git repo"
    argparse 's/scenario=' 'set=+' 'h/help' -- $argv
    or return 2
    if set -ql _flag_help
        echo $usage
        return 0
    end
    if test (count $argv) -gt 1
        echo $usage >&2
        return 2
    end

    # No target given: use the branch checked out here, if it's pushed
    set -l target $argv[1]
    if test -z "$target"
        set target (git rev-parse --abbrev-ref HEAD 2>/dev/null)
        if test -z "$target"; or test "$target" = HEAD
            echo "deve: not on a git branch here; give a PR number or branch" >&2
            echo $usage >&2
            return 2
        end
        if not git ls-remote --exit-code --heads origin $target >/dev/null 2>&1
            echo "deve: branch '$target' is not pushed to origin" >&2
            return 1
        end
    end

    # A number means a PR on $DEVE_GH_REPO, anything else is a branch
    # name. PRs fetch by pull/<n>/head, which outlives the head branch, so a
    # merged PR still runs; the branch name is only for display.
    set -l branch $target
    set -l src refs/heads/$branch
    # The ref scenarios are validated against: the head sha for PRs because a
    # merged PR's branch may be gone
    set -l tree_ref $branch
    if string match -qr '^[0-9]+$' -- $target
        set src pull/$target/head
        set -l head (gh pr view $target -R $gh_repo --json headRefName,headRefOid --jq '.headRefName, .headRefOid')
        if test (count $head) -ne 2
            echo "deve: cannot resolve PR #$target on $gh_repo" >&2
            return 1
        end
        set branch $head[1]
        set tree_ref $head[2]
    end

    # Scenarios live in the deployed ref's tree, so validate there before
    # touching the devbox
    if set -ql _flag_scenario
        if not gh api "repos/$gh_repo/contents/dev/scenarios/$_flag_scenario/values.yaml?ref=$tree_ref" >/dev/null 2>&1
            echo "deve: unknown scenario '$_flag_scenario' on $branch; available:" >&2
            gh api "repos/$gh_repo/contents/dev/scenarios?ref=$tree_ref" --jq '.[].name' 2>/dev/null | sed 's/^/  /' >&2
            return 1
        end
    end

    if not ssh -o ConnectTimeout=10 $devbox true
        echo "deve: cannot reach $devbox" >&2
        return 1
    end
    if not ssh $devbox "command -v herdr" >/dev/null
        echo "deve: herdr is not installed on the devbox" >&2
        return 1
    end
    if not ssh $devbox "test -d $repo"
        echo "deve: $repo is missing on the devbox" >&2
        return 1
    end
    # The default session is the one the herdr machines sidebar shows
    if not ssh $devbox "herdr pane list" >/dev/null 2>&1
        echo "deve: no herdr session running on the devbox; open the devbox from the herdr machines sidebar first" >&2
        return 1
    end

    # Reuse the deve workspace if it exists, otherwise create it without stealing focus
    set -l ws (ssh $devbox "herdr workspace list" | jq -r --arg l $workspace_label '[.result.workspaces[] | select(.label == $l)][0].workspace_id // empty')
    set -l pane
    if test -n "$ws"
        set pane (ssh $devbox "herdr pane list --workspace $ws" | jq -r '.result.panes[0].pane_id // empty')
    end
    if test -z "$pane"
        set pane (ssh $devbox "herdr workspace create --label $workspace_label --no-focus --cwd $repo" | jq -r '.result.root_pane.pane_id // empty')
    end
    if test -z "$pane"
        echo "deve: could not find or create the $workspace_label workspace" >&2
        return 1
    end

    # Scenario and ad hoc sets ride on the task invocation; double quotes only,
    # because the spinup travels single quoted through ssh into herdr
    set -l taskcmd "task dev:up $domain_var=$domain DEVE_HTTP_PORT=80"
    if set -ql _flag_scenario
        set taskcmd "$taskcmd SCENARIO=$_flag_scenario"
    end
    if set -ql _flag_set
        set -l sets
        for kv in $_flag_set
            set -a sets --set $kv
        end
        set taskcmd "KNK_HELM_EXTRA_ARGS=\"$sets\" $taskcmd"
    end

    # Interrupt whatever ran before so the last invocation wins, then inject
    # The pane runs fish: fetch into a fixed ref all worktrees share, add the
    # worktree on first use, retarget it after
    set -l spinup "cd $repo; and git fetch origin +$src:refs/deve/head; and begin; git worktree add --detach $worktree refs/deve/head 2>/dev/null; or git -C $worktree switch --detach refs/deve/head; end; and cd $worktree; and task env:fast-builds; and $taskcmd"
    ssh $devbox "herdr pane send-keys $pane ctrl+c; sleep 1; herdr pane run $pane '$spinup'"
    or return 1

    echo "deve: $branch is spinning up in the devbox herdr session, workspace '$workspace_label'"
    echo "  console  http://$domain"
    echo "  api      http://api.$domain  (/gql, /rest)"
end
