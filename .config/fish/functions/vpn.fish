function vpn --description "WireGuard tunnel home: vpn up | down | status"
    set -l name home
    set -l wgq (brew --prefix)/bin/wg-quick
    set -l wg (brew --prefix)/bin/wg

    # wg-quick writes this file while the tunnel is up
    set -l state /var/run/wireguard/$name.name

    switch "$argv[1]"
        case up
            if sudo test -f $state
                echo "already up"
                return 0
            end
            sudo $wgq up $name
        case down
            if not sudo test -f $state
                # A tunnel that died on its own leaves its DNS set on every service
                set -l conf (brew --prefix)/etc/wireguard/$name.conf
                set -l dns (sudo sed -n 's/^DNS *= *//p' $conf | string split , | string trim)
                for svc in (networksetup -listallnetworkservices | tail -n +2 | string replace -r '^\*' '')
                    set -l cur (networksetup -getdnsservers $svc)
                    if contains -- $cur[1] $dns
                        sudo networksetup -setdnsservers $svc empty
                        sudo networksetup -setsearchdomains $svc empty
                        echo "cleared leftover DNS on $svc"
                    end
                end
                echo "already down"
                return 0
            end
            sudo $wgq down $name
        case status
            # macOS names the interface utunN; wg-quick records which one
            set -l iface (sudo cat $state 2>/dev/null)
            or begin
                echo down
                return 0
            end
            sudo $wg show $iface
        case '*'
            echo "usage: vpn up | down | status" >&2
            return 1
    end
end
