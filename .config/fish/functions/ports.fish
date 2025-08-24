function ports
  if test (count $argv) -eq 0
     __ports_fkill
     return
  end

  set -l cmd $argv[1]

  switch $cmd
      case 'ls'
           __ports_list
      case 'list'
          __ports_list
      case 'kill'
          __ports_kill $argv[2]
      case 'fkill'
          __ports_fkill
      case '*'
          __ports_fkill
      end
end

function __ports_list
    set -l port_info (lsof -iTCP -sTCP:LISTEN -P -n | awk 'NR > 1 {port=$9; sub(/.*:/, "", port); print $2 "_::_" $1 "_::_" port}')
    set -l ps_info (ps -o pid=,command= | rg -v '(^|/)fish( |$)' | rg -v 'rg' | rg -v 'fzf' | rg -v 'awk' | awk '{pid=$1; $1=""; cmd=substr($0,2); print pid "_::_" cmd}')

    set -l port_map
    set -l cmd_map
    set -l all_pids

    for item in $port_info
        set -l parts (string split '_::_' -- $item)
        set "port_map_$parts[1]" $parts[3]
        set "cmd_map_$parts[1]" $parts[2]
        if not contains $parts[1] $all_pids
            set -a all_pids $parts[1]
        end
    end

    for item in $ps_info
        set -l parts (string split '_::_' -- $item)
        set "cmd_map_$parts[1]" $parts[2]
        if not contains $parts[1] $all_pids
            set -a all_pids $parts[1]
        end
    end

    for pid in $all_pids
        set -l cmd_var_name "cmd_map_$pid"
        set -l port_var_name "port_map_$pid"

        set -l cmd (eval echo \$$cmd_var_name)
        set -l port "-"
        if set -q $port_var_name
            set port (eval echo \$$port_var_name)
        end

        printf "%-8s %-8s %s\n" $pid $port $cmd
    end
end


function __ports_kill
    if test -z "$argv[1]"
        echo "Usage: ports kill <port_number>"
        return 1
    end
    set -l port $argv[1]
    kill -9 (lsof -t -i :$port -sTCP:LISTEN)
end

function __ports_fkill
    set -l process (__ports_list | fzf --header "Select a process to kill")

    if test -n "$process"
        set -l pid (echo $process | string split ' ' -f1)

        if test -n "$pid"
            kill -9 $pid
            if test $status -eq 0
                echo "Successfully killed PID $pid."
            else
                echo "Failed to kill PID $pid. It may have already exited."
            end
        end
    end
end
