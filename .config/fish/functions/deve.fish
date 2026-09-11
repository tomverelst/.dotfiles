function deve --description "Run the kannika dev env for a PR or branch in a deve workspace on the devbox's herdr session"
    set -l devbox tom@devbox.local.cruxy.eu
    set -l repo /home/tom/git/kp/kannika-platform
    # The env builds and runs here, leaving the main checkout alone
    set -l worktree /home/tom/git/kp/deve
    set -l workspace_label deve
    # Domain the dev env is served on, passed to the Taskfile
    set -l domain_var DEVE_DOMAIN
    set -l domain deve.local.cruxy.eu

    if test (count $argv) -ne 1
        echo "usage: deve <pr-number | branch>" >&2
        return 2
    end

    # A number means a PR on cymo-eu/kannika-platform, anything else is a branch name
    set -l branch $argv[1]
    set -l banner "Testing $branch"
    if string match -qr '^[0-9]+$' -- $branch
        if not set branch (gh pr view $branch -R cymo-eu/kannika-platform --json headRefName -q .headRefName)
            echo "deve: cannot resolve PR #$argv[1] on cymo-eu/kannika-platform" >&2
            return 1
        end
        set banner "Testing PR #$argv[1] ($branch)"
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

    # Interrupt whatever ran before so the last invocation wins, then inject
    # The pane runs fish: add the worktree on first use, retarget it after
    set -l spinup "cd $repo; and git fetch origin $branch; and begin; git worktree add --detach $worktree origin/$branch 2>/dev/null; or git -C $worktree switch --detach origin/$branch; end; and cd $worktree; and task env:fast-builds; and task dev:up $domain_var=$domain DEVE_HTTP_PORT=80 DEVE_BANNER=\"$banner\""
    ssh $devbox "herdr pane send-keys $pane ctrl+c; sleep 1; herdr pane run $pane '$spinup'"
    or return 1

    echo "deve: $branch is spinning up in the devbox herdr session, workspace '$workspace_label'"
    echo "  console  http://$domain"
    echo "  api      http://api.$domain  (/gql, /rest)"
end
