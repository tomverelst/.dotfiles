function ports --description 'List and kill processes listening on TCP/UDP ports'
    argparse h/help t/tcp u/udp -- $argv
    or return 1

    if set -q _flag_help
        __ports_usage
        return 0
    end

    # --tcp and --udp narrow; neither (or both) means both protocols
    set -l proto all
    if set -q _flag_tcp; and not set -q _flag_udp
        set proto tcp
    else if set -q _flag_udp; and not set -q _flag_tcp
        set proto udp
    end

    set -l cmd $argv[1]

    switch "$cmd"
        case ''
            __ports_fkill $proto
        case ls list
            __ports_list $proto --header
        case kill
            __ports_kill $proto $argv[2..]
        case fkill
            __ports_fkill $proto $argv[2]
        case '*'
            if string match -qr '^[0-9]+$' -- $cmd
                __ports_fkill $proto $cmd
            else
                echo "ports: unknown command '$cmd'" >&2
                __ports_usage >&2
                return 1
            end
    end
end

function __ports_usage
    echo "Usage: ports [--tcp|--udp] [<port>|ls|list|kill <port>...|fkill [<port>]]"
    echo
    echo "  ports              pick a bound process with fzf and kill it"
    echo "  ports <port>       same, limited to processes bound to <port>"
    echo "  ports ls|list      list every bound process"
    echo "  ports kill <port>  kill whatever holds <port> (no prompt)"
    echo
    echo "  --tcp              TCP listeners only"
    echo "  --udp              UDP sockets only"
    echo "                     (default: both)"
    echo "  -h, --help         show this message"
end

# lsof selector for a protocol, optionally scoped to one port.
# TCP is restricted to LISTEN; UDP has no such state.
function __ports_selector
    set -l proto $argv[1]
    set -l port $argv[2]
    # NB: must be an empty string, not an empty list — "-iTCP$suffix" with an
    # empty list expands to nothing at all and drops the selector entirely
    set -l suffix ""
    test -n "$port"; and set suffix ":$port"

    switch $proto
        case tcp
            echo -- -iTCP$suffix -sTCP:LISTEN
        case udp
            echo -- -iUDP$suffix
        case '*'
            echo -- -iTCP$suffix -sTCP:LISTEN -iUDP$suffix
    end
end

# Emits one tab-separated row per (pid, protocol, bind address):
#   pid \t proto \t port,port,... \t address \t command \t full-command-line
function __ports_rows
    set -l sel (__ports_selector $argv[1] | string split ' ')

    set -l rows (lsof -nP +c0 $sel -F pcnP 2>/dev/null | awk '
        # macOS awk has no asort(), so sort the port list by hand
        function sortports(s,   a, n, i, j, t, out) {
            n = split(s, a, ",")
            for (i = 2; i <= n; i++) {
                t = a[i]
                for (j = i - 1; j >= 1 && a[j] + 0 > t + 0; j--) a[j + 1] = a[j]
                a[j + 1] = t
            }
            out = a[1]
            for (i = 2; i <= n; i++) out = out "," a[i]
            return out
        }

        /^p/ { pid = substr($0, 2); next }
        /^c/ { name[pid] = substr($0, 2); next }
        /^P/ { proto = substr($0, 2); next }
        /^n/ {
            n = substr($0, 2)
            if (n ~ /->/) next                 # connected socket, not a bound port
            port = n; sub(/.*:/, "", port)     # greedy: splits on the LAST colon
            if (port !~ /^[0-9]+$/) next       # skip unbound UDP (*:*)
            addr = n; sub(/:[^:]*$/, "", addr)
            gsub(/[\[\]]/, "", addr)           # [::1] -> ::1
            key = pid SUBSEP proto SUBSEP addr
            if (!((key SUBSEP port) in seen)) {   # dedup IPv4/IPv6 twins
                seen[key, port] = 1
                ports[key] = (key in ports) ? ports[key] "," port : port
                if (!(key in rank)) { rank[key] = ++k; seq[k] = key }
            }
        }
        END {
            for (i = 1; i <= k; i++) {
                split(seq[i], a, SUBSEP)
                print a[1] "\t" a[2] "\t" sortports(ports[seq[i]]) "\t" a[3] "\t" name[a[1]] "\t" name[a[1]]
            }
        }
    ')

    set -l pids
    for row in $rows
        set -a pids (string split -f1 \t -- $row)
    end
    test (count $pids) -gt 0; or return 0

    # lsof's +c0 name is already untruncated; ps upgrades it to the full command line
    set -l psout (ps -p (string join , $pids) -o pid=,command= 2>/dev/null)

    for row in $rows
        set -l f (string split \t -- $row)
        # CMD stays lsof's process name; PATH becomes the full ps command line
        set -l full (string match -r "^\s*$f[1]\s+(.+)" -- $psout)
        test (count $full) -ge 2; and set f[6] $full[2]
        printf '%s\t%s\t%s\t%s\t%s\t%s\n' $f[1] $f[2] $f[3] $f[4] $f[5] $f[6]
    end
end

# Takes row order (pid proto ports addr cmd path); prints display order (proto first)
function __ports_row_format
    printf '%-6s %-8s %-18s %-16s %-18s %s' $argv[2] $argv[1] $argv[3] $argv[4] $argv[5] $argv[6]
end

function __ports_list
    if contains -- --header $argv
        __ports_row_format PID PROTO 'PORT(S)' ADDRESS CMD PATH
        echo
    end

    for row in (__ports_rows $argv[1])
        __ports_row_format (string split \t -- $row)
        echo
    end
end

function __ports_kill
    set -l proto $argv[1]
    set -l wanted $argv[2..]

    if test (count $wanted) -eq 0
        echo "Usage: ports kill <port>..." >&2
        return 1
    end

    set -l failed 0
    for port in $wanted
        if not string match -qr '^[0-9]+$' -- $port
            echo "ports: '$port' is not a port number" >&2
            set failed 1
            continue
        end

        set -l sel (__ports_selector $proto $port | string split ' ')
        set -l pids (lsof -t -nP $sel 2>/dev/null | sort -un)

        if test (count $pids) -eq 0
            echo "No process bound to port $port." >&2
            set failed 1
            continue
        end

        for pid in $pids
            if kill -9 $pid 2>/dev/null
                echo "Killed PID $pid on port $port."
            else
                echo "Failed to kill PID $pid. It may have already exited." >&2
                set failed 1
            end
        end
    end

    return $failed
end

function __ports_fkill
    set -l proto $argv[1]
    set -l filter $argv[2]
    set -l rows (__ports_rows $proto)

    if test -n "$filter"
        set -l matched
        for row in $rows
            set -l ports (string split -f3 \t -- $row | string split ',')
            contains -- $filter $ports; and set -a matched $row
        end

        if test (count $matched) -eq 0
            echo "No process found bound to port $filter." >&2
            return 1
        end
        set rows $matched
    else if test (count $rows) -eq 0
        echo "Nothing is bound to a TCP or UDP port." >&2
        return 1
    end

    set -l lines (__ports_row_format PID PROTO 'PORT(S)' ADDRESS CMD PATH)
    for row in $rows
        set -a lines (__ports_row_format (string split \t -- $row))
    end

    set -l selected (printf '%s\n' $lines | fzf --multi --header-lines=1 \
        --header 'Select process(es) to kill — TAB to mark')
    or return 1

    # One process can appear as both a TCP and a UDP row; kill it once
    set -l pids
    for line in $selected
        # display order is PROTO PID ... — the pid is the second column
        set -l pid (string match -r '^\s*\S+\s+(\d+)' -- $line)[2]
        test -n "$pid"; and not contains -- $pid $pids; and set -a pids $pid
    end

    set -l failed 0
    for pid in $pids
        if kill -9 $pid 2>/dev/null
            echo "Successfully killed PID $pid."
        else
            echo "Failed to kill PID $pid. It may have already exited." >&2
            set failed 1
        end
    end

    return $failed
end

# Completion helper: one "port<TAB>description" per bound port,
# honouring any --tcp/--udp already typed on the command line
function __ports_complete_ports
    set -l proto all
    __fish_contains_opt -s t tcp; and set proto tcp
    __fish_contains_opt -s u udp; and set proto udp

    for row in (__ports_rows $proto)
        set -l f (string split \t -- $row)
        for port in (string split ',' -- $f[3])
            printf '%s\t%s %s\n' $port $f[2] $f[5]
        end
    end
end
