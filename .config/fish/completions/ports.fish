functions -q ports

complete -c ports -f

complete -c ports -n __fish_use_subcommand -a ls -d 'List listening processes'
complete -c ports -n __fish_use_subcommand -a list -d 'List listening processes'
complete -c ports -n __fish_use_subcommand -a kill -d 'Kill by port number'
complete -c ports -n __fish_use_subcommand -a fkill -d 'Pick a process with fzf'
complete -c ports -s h -l help -d 'Show usage'
complete -c ports -s t -l tcp -d 'TCP listeners only'
complete -c ports -s u -l udp -d 'UDP sockets only'

# Live port numbers, described by the process holding them
complete -c ports -n 'not __fish_seen_subcommand_from ls list fkill' -a '(__ports_complete_ports)'
