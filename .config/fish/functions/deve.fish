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

    set -l usage "usage: deve [-s <scenario>[,<scenario>...]] [--set <key>=<value>]... [<context>]
context is a directory (its checked out branch or commit), a PR number, a
commit sha or a branch; defaults to the current directory. A branch with an
open PR runs as that PR."
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

    # A directory stands for what it has checked out: its branch, or its
    # commit when detached
    set -l target $argv[1]
    if test -z "$target"
        set target .
    end
    if test -d $target
        set -l ctx (git -C $target rev-parse --abbrev-ref HEAD 2>/dev/null)
        if test -z "$ctx"
            echo "deve: $target is not a git checkout" >&2
            return 2
        end
        if test "$ctx" = HEAD
            set target (git -C $target rev-parse HEAD)
        else
            set target $ctx
        end
    end

    set -l is_pr (string match -qr '^[0-9]+$' -- $target; and echo 1)
    set -l is_commit (string match -qr '^[0-9a-f]{7,40}$' -- $target; and echo 1)

    # A branch runs as its open PR when it has one, so the banner names the
    # PR and the run survives the branch being deleted on merge
    if test -z "$is_pr$is_commit"
        set -l pr (gh pr list -R $gh_repo --head $target --state open --json number --jq '.[0].number // empty' 2>/dev/null)
        if test -n "$pr"
            set target $pr
            set is_pr 1
        else if not gh api "repos/$gh_repo/branches/$target" >/dev/null 2>&1
            echo "deve: no open PR and no branch '$target' on $gh_repo" >&2
            return 1
        end
    end

    # PRs fetch by pull/<n>/head, which outlives the head branch, so a merged
    # PR still runs. The ref scenarios are validated against is the head sha
    # for PRs because a merged PR's branch may be gone.
    set -l branch $target
    set -l src refs/heads/$branch
    set -l tree_ref $branch
    if test -n "$is_pr"
        set src pull/$target/head
        set -l head (gh pr view $target -R $gh_repo --json headRefName,headRefOid --jq '.headRefName, .headRefOid')
        if test (count $head) -ne 2
            echo "deve: cannot resolve PR #$target on $gh_repo" >&2
            return 1
        end
        set branch $head[1]
        set tree_ref $head[2]
    else if test -n "$is_commit"
        if not gh api "repos/$gh_repo/commits/$target" --jq .sha >/dev/null 2>&1
            echo "deve: commit $target is not on $gh_repo" >&2
            return 1
        end
        set src $target
        set branch (string sub -l 12 -- $target)
    end

    # Scenarios live in the deployed ref's tree, so validate there before
    # touching the devbox
    if set -ql _flag_scenario
        for s in (string split , -- $_flag_scenario)
            if not gh api "repos/$gh_repo/contents/dev/scenarios/$s?ref=$tree_ref" >/dev/null 2>&1
                echo "deve: unknown scenario '$s' on $branch; available:" >&2
                gh api "repos/$gh_repo/contents/dev/scenarios?ref=$tree_ref" --jq '.[].name' 2>/dev/null | sed 's/^/  /' >&2
                return 1
            end
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

    # The worktree sits on the branch, reset to the fetched head and tracking
    # origin, so git in there behaves normally. Detached only for commits, or
    # when another worktree on the devbox has the branch checked out.
    set -l checkout "git -C $worktree switch --detach refs/deve/head"
    if test -z "$is_commit"
        set checkout "begin; git fetch origin +refs/heads/$branch:refs/remotes/origin/$branch 2>/dev/null; or true; end; and begin; git -C $worktree switch -C $branch refs/deve/head 2>/dev/null; or $checkout; end; and begin; git -C $worktree branch -u origin/$branch 2>/dev/null; or true; end"
    end

    # Interrupt whatever ran before so the last invocation wins, then inject
    # The pane runs fish: fetch into a fixed ref all worktrees share, add the
    # worktree on first use, retarget it after
    set -l spinup "cd $repo; and git fetch origin +$src:refs/deve/head; and begin; git worktree add --detach $worktree refs/deve/head 2>/dev/null; or true; end; and $checkout; and cd $worktree; and task env:fast-builds; and $taskcmd"
    ssh $devbox "herdr pane send-keys $pane ctrl+c; sleep 1; herdr pane run $pane '$spinup'"
    or return 1

    echo "deve: $branch is spinning up in the devbox herdr session, workspace '$workspace_label'"
    echo "  console  http://$domain"
    echo "  api      http://api.$domain  (/gql, /rest)"
    if set -ql _flag_scenario; and contains oauth (string split , -- $_flag_scenario)
        echo "  auth     http://auth.$domain  (realm kannika)"
    end
    if set -ql _flag_scenario; and contains rp (string split , -- $_flag_scenario)
        echo "  redpanda http://rp.$domain"
    end
end
