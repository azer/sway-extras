#!/bin/bash

# Defaults
keyboard_binding="Mod+v" # Only used by notifications.
screenshots_folder="/home/azer/Screenshots"
screencasts_folder="/home/azer/Screencasts"
gifcasts_folder="/home/azer/Gifcasts"

# Look for prompt script in same folder
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Save PID files to
screencast_pid=/tmp/.screencast.pid
gifcast_pid=/tmp/.gifcast.pid
gifcast_mp4_filename=/tmp/.gifcast_filename
gifcast_palette=/tmp/.gifcast_palette.png

screenshot() {
    mkdir -p $screenshots_folder
    grim -g "$(slurp)" $screenshots_folder/`date +%Y-%m-%d.%H:%M:%S`.png
    notify-send 'New Screenshot' "Saved to $screenshots_folder folder." -u low
}

full_screenshot() {
    mkdir -p $screenshots_folder
    grim $screenshots_folder/`date +%Y-%m-%d.%H:%M:%S`.png
    notify-send 'New Screenshot' "Saved to $screenshots_folder folder." -u low
}

convert_mp4_to_gif() {
    filename=$gifcasts_folder/`date +%Y-%m-%d.%H:%M:%S`.gif
    echo "Converting $1 to $filename"
    palette="/tmp/palette.png"
    filters="fps=15,scale=$2:-1:flags=lanczos"
    ffmpeg -v warning -i "file:$1" -vf "$filters,palettegen" -y $gifcast_palette
    ffmpeg -v warning -i "file:$1" -i $gifcast_palette -lavfi "$filters [x]; [x][1:v] paletteuse" -y "file:$filename"
}

record_screen() {
    geometry=$(slurp)  || exit 1
    notify-send -t 3000 "Starting 3 seconds..." "Stop the cast by pressing $keyboard_binding"
    sleep 3
    wf-recorder -g "$geometry" -f $1 & echo $! > $2
}

start_screencast() {
    mkdir -p $screencasts_folder
    record_screen $screencasts_folder/`date +%Y-%m-%d.%H:%M:%S`.mp4 "$screencast_pid"
}

stop_screencast() {
    kill -INT `cat $screencast_pid`
    rm $screencast_pid
    notify-send "Screencast Stopped" "The video was saved into ~/Screencasts folder."
}

start_gifcast() {
    mkdir -p $gifcasts_folder
    filename=$screencasts_folder/`date +%Y-%m-%d.%H:%M:%S`.mp4
    echo $filename > $gifcast_mp4_filename
    record_screen $filename $gifcast_pid
}

stop_gifcast() {
    kill -INT `cat $gifcast_pid`
    rm $gifcast_pid
    notify-send "Gifcast Stopped" "Processing the gif might take some time..."

    mp4_source=`cat $gifcast_mp4_filename`

    max_width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=s=x:p=0 $mp4_source)
    scale=$max_width

    if (( $max_width > 1080 )); then
        scale=$($DIR/prompt -o "$max_width,1080,720,480,360,240" -q "Scale GIF resolution (width) to:")
    elif (( $max_width > 720 )); then
        scale=$($DIR/prompt -o "$max_width,720,480,360,240" -q "Scale GIF resolution (width) to:")
    elif (( $max_width > 480 )); then
        scale=$($DIR/prompt -o "$max_width,480,360,240" -q "Scale GIF resolution (width) to:")
    elif (( $max_width > 360 )); then
        scale=$($DIR/prompt -o "$max_width,360,240" -q "Scale GIF resolution (width) to:")
    fi

    notify-send "Processing" "Processing the gif might take some time..."
    convert_mp4_to_gif $mp4_source $scale

    notify-send "Gifcast Ready" "Gifcast was processed and saved to $gifcasts_folder"
}

if [ -f "$screencast_pid" ]; then
    stop_screencast
    exit 0
fi

if [ -f "$gifcast_pid" ]; then
    stop_gifcast
    exit 0
fi

case $($DIR/prompt -o "Screenshot,Screencast,Gifcast,Full Screenshot" -q "Capture Screen:") in
    'Screenshot')
        screenshot -s
        ;;
    'Screencast')
        start_screencast
        ;;
    'Gifcast')
        start_gifcast
        ;;
    'Full Screenshot')
        full_screenshot
        ;;
esac
