function vpn --description "WireGuard tunnel home: vpn up | down | status"
    set -l name home
    set -l wgq (brew --prefix)/bin/wg-quick
    set -l wg (brew --prefix)/bin/wg

    switch "$argv[1]"
        case up
            sudo $wgq up $name
        case down
            sudo $wgq down $name
        case status
            # macOS names the interface utunN; wg-quick records which one
            set -l iface (sudo cat /var/run/wireguard/$name.name 2>/dev/null)
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
