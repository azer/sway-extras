DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

case $($DIR/prompt -o "Lock,Exit,Sleep,Reboot,Shut down" -q "Session:") in
    'Lock')
        $DIR/lock-screen
        ;;
    'Exit')
        swaymsg exit
        ;;
    'Suspend')
        systemctl suspend
        ;;
    'Reboot')
        sudo reboot
        ;;
    'Shut down')
        sudo shutdown -h now
        ;;
esac
