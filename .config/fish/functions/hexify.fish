function hexify --description "Print stdin as 0xNN bytes"
    read -z input
    printf "%s" "$input" | xxd -p -u | sed 's/../0x& /g; s/ $//'
end
