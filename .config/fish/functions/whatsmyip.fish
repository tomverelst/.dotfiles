function whatsmyip
ifconfig | awk '/inet /{print $2}'
end
