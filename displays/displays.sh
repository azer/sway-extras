#!/bin/bash

task=$1

# Convert all parameters to variables
while [ $# -gt 0 ]; do
    if [[ ${1:0:2} == "--" ]]; then
        v="${1/--/}"
        v="${v/-/_}"
        declare $v="$2"
        declare $v"_param_set"="1"
    elif [[ ${1:0:1} == "-" ]]; then
        v="${1/-/}"
        v="${v/-/_}"
        declare $v="$2"
        declare $v"_param_set"="1"
    fi
    shift
done

configFile=~/.displays
touch $configFile

get_displays() {
    result=$(swaymsg -t get_outputs | grep -iEo "\"name\": \"[a-zA-Z0-9-]+\"" | sed 's/"name": "//' | sed 's/"$//' | sort)
    echo "${result}"
}

get_config_key() {
    displays=$(get_displays)
    key=$(echo "$displays" | tr '\n' ',' | sed 's/,$//')
    echo "$key"
}

get_config_contents() {
    result=$(cat $configFile | sed "/^#/d")
    echo "${result}"
}

get_current_config() {
    key=$(get_config_key)
    contents=$(get_config_contents)
    result=$(echo "$contents" | grep "^\[$key\] " <<< "$contents" | sed "s/^\[$key\] //")
    echo "${result}"
}

remove_display_config() {
    display=$1
    key=$(get_config_key)
    contents=$(get_config_contents)
    result=$(echo "$contents" | sed "/\[$key\] output $display/d")
    echo "${result}"
}

set_display_config() {
    display=$1
    disable=$2
    resolution=$3

    key=$(get_config_key)
    result=$(remove_display_config $display)

    echo "${result}" > $configFile

    if [ $disable -eq 1 ]; then
        echo "[$key] output $display disable" >> $configFile
    else
        echo "[$key] output $display enable" >> $configFile
        echo "[$key] output $display resolution $resolution" >> $configFile
    fi
}

execute_config() {
    config=$(get_current_config)

    if [[ -z "${config// }" ]]; then
        show_all_output_menus
    else
        while read -r line; do
            swaymsg $line
        done <<< "$config"
    fi
}

background() {
    last_executed_key="$(get_config_key)-"
    execute_config

    while true; do
        current_key=$(get_config_key)

        if [[ "$last_executed_key" != "$current_key" ]]; then
            execute_config
            last_executed_key="$current_key"

            if [[ -n "${on_plug// }" ]]; then
                eval $on_plug
            fi
        fi

        updated_config=$(get_current_config)
        if [[ -z "${updated_config// }" ]]; then
            show_all_output_menus
        fi

	      sleep 3
    done
}

show_output_menu() {
    selected_output=$1
    modes=$(swaymsg -t get_outputs | jq ".[] | select(.name == \"$selected_output\") | .modes | map(\"\(.width)x\(.height)\") | .[]" | sed 's/"//g' | uniq | tac | tr '\n' ',' | sed 's/,$//')
    selected_mode=$(~/.happy-desktop/bin/prompt -o "disable,$modes" -q "Select a mode for $selected_output:")
    if [[ -z "${selected_mode// }" ]]; then
        exit 1
    fi

    if [ $selected_mode == "disable" ]; then
        set_display_config $selected_output 1
    else
        set_display_config $selected_output 0 $selected_mode
    fi
}

show_all_output_menus() {
    displays=$(get_displays)
    while read -r line; do
        show_output_menu $line
    done <<< "$displays"
}

show_menu() {
    displays=$(get_displays | tr '\n' ',' | sed 's/,$//')
    if [[ -z "${displays// }" ]]; then
        echo "No outputs found."
        exit 1
    fi

    selected_output=""

    if [[ $displays == *","* ]]; then
        selected_output=$(~/.happy-desktop/bin/prompt -o $displays -q "Select a display:")
        if [[ -z "${selected_output// }" ]]; then
            exit 1
        fi
    else
        selected_output="$displays"
    fi

    show_output_menu $selected_output

    execute_config
}

if [[ $task == "detect" ]]; then
    execute_config
elif [[ $task == "configure" ]]; then
    output=${output:-$o}
    resolution=${resolution:-$r}
    disable=${disable_param_set:-0}

    if [[ -z "${output// }" ]]; then
        echo "Valid output needed"
        exit 1
    fi

    if [[ -z "${resolution// }" ]]; then
        echo "Valid resolution needed"
        exit 1
    fi

    set_display_config $output $disable $resolution
    execute_config
elif [[ $task == "menu" ]]; then
    show_menu
elif [[ $task == "background" ]]; then
    background
elif [[ $task == "icon" ]]; then
    display_count=$(get_displays | wc -l)
    if [[ $display_count -gt 1 ]]; then
        echo "⎚"
    fi
else
    echo
    echo "SYNOPSIS"
    echo "    displays [detect|configure|menu|background|icon]"
    echo
    echo "OPTIONS"
    echo "    -o --output"
    echo "    Output name. e.g eDP-1"
    echo "    -r --resolution"
    echo "    Set resolution for specified output"
    echo "    --disable"
    echo "    Disable specified output"
    echo "    --on-plug"
    echo "    Call given script when a display gets plugged"
    echo "    -h --help"
    echo "    Show help"
fi
