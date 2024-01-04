#!/bin/bash
# This script installs Klipper UI (mainsail/Fluidd) on Debian

# Constants
SYSTEMDDIR="/etc/systemd/system"
PYTHONDIR="$HOME/klippy-env"
PRINTER_DATA="$HOME/printer_data"
KLIPPER_USER=$(whoami)
KLIPPERDIR="$HOME/klipper"
KLIPPERUI="$HOME/KlipperUI/uiutils"
NGINXDIR="/etc/nginx/sites-available"
NGINXEN="/etc/nginx/sites-enabled"
NGINXVARS="/etc/nginx/conf.d/"
FLUIDD_URL="https://github.com/fluidd-core/fluidd/releases/latest/download/fluidd.zip"
MAINSAIL_URL="https://github.com/mainsail-crew/mainsail/releases/latest/download/mainsail.zip"


# Function to display menu and get user selection
select_ui() {
    local valid_choices=("1" "2")

    while true; do
        report_status "Select UI:"
        echo "1. Fluidd"
        echo "2. Mainsail"
        read -t 15 -p "Enter choice (1 or 2, Enter for Fluidd): " CHOICE

        CHOICE=${CHOICE:-1}

        if [[ "${valid_choices[@]}" =~ "${CHOICE}" ]]; then
            break
        else
            echo "Invalid choice. Please enter 1 or 2."
        fi
    done
}

# Install ui system packages
install_packages() {
    PKGLIST="wget gzip tar unzip dfu-util"

    report_status "Running apt-get update..."
    sudo apt-get update

    report_status "Installing packages..."
    sudo apt-get install --yes ${PKGLIST}
}

# Step 9: Install UI (Fluidd or Mainsail)
install_ui() {

    select_ui

    case $CHOICE in
        1)
            stop_klipper
            install_packages
            install_fluidd
            install_nginxcfg_fluidd
            remove_default
            ;;
        2)
            stop_klipper
            install_packages
            install_mainsail
            install_nginxcfg_mainsail
            remove_default
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
}

# Option to Install Fluidd
install_fluidd() {
    FILE=~/fluidd
    if [ ! -d "$FILE" ]; then
        mkdir ~/fluidd
        cd ~/fluidd
        wget -q -O fluidd.zip ${FLUIDD_URL} && unzip fluidd.zip && rm fluidd.zip
        cd ~/
    else
        report_status "$FILE already exists. Skipping Fluidd installation."
    fi
}

# Option to install mainsail
install_mainsail() {
    FILE=~/mainsail
    if [ ! -d "$FILE" ]; then
        mkdir ~/mainsail
        cd ~/mainsail
        wget -q -O mainsail.zip ${MAINSAIL_URL} && unzip mainsail.zip && rm mainsail.zip
        cd ~/
    else
        report_status "$FILE already exists. Skipping Mainsail installation."
    fi
}

# Add Moonraker config
add_moon() {
    report_status "Add Moonraker config..."

    # Choose the appropriate moonraker.conf based on user choice
    if [ "$CHOICE" == "1" ]; then
        SOURCE_CONF_FILE="${KLIPPERUI}/moonraker_fluidd.conf"
    elif [ "$CHOICE" == "2" ]; then
        SOURCE_CONF_FILE="${KLIPPERUI}/moonraker_mainsail.conf"
    else
        report_status "Invalid choice. Exiting."
        exit 1
    fi

    # Copy the chosen config file to moonraker.conf
    cp "$SOURCE_CONF_FILE" "${PRINTER_DATA}/config/moonraker.conf"

    report_status "Moonraker config for choice $CHOICE added."
}

# Install Nginx config for Fluidd
install_nginxcfg_fluidd() {
    # Remove existing Mainsail config if it exists
    if [ -e "$NGINXDIR/mainsail" ]; then
        sudo rm "$NGINXDIR/mainsail"
        sudo rm "$NGINXEN/mainsail"
    fi

    if [ ! -e "$NGINXDIR/fluidd" ]; then
        sudo /bin/sh -c "cp ${KLIPPERUI}/fluidd $NGINXDIR/"
        sudo sed -i "s#root /home/pi/fluidd;#root /home/${KLIPPER_USER}/fluidd;#" "$NGINXDIR/fluidd"
        sudo /bin/sh -c "cp ${KLIPPERUI}/upstreams.conf $NGINXVARS/"
        sudo /bin/sh -c "cp ${KLIPPERUI}/common_vars.conf $NGINXVARS/"
        sudo ln -s "$NGINXDIR/fluidd" "$NGINXEN"
    else
        report_status "Nginx config file already exists. Skipping installation."
    fi
}

# Install Nginx config for Mainsail
install_nginxcfg_mainsail() {
    # Remove existing Fluidd config if it exists
    if [ -e "$NGINXDIR/fluidd" ]; then
        sudo rm "$NGINXDIR/fluidd"
        sudo rm "$NGINXEN/fluidd"
    fi

    if [ ! -e "$NGINXDIR/mainsail" ]; then
        sudo /bin/sh -c "cp ${KLIPPERUI}/mainsail $NGINXDIR/"
        sudo sed -i "s#root /home/pi/mainsail;#root /home/$KLIPPER_USER/mainsail;#" "$NGINXDIR/mainsail"
        sudo /bin/sh -c "cp ${KLIPPERUI}/upstreams.conf $NGINXVARS/"
        sudo /bin/sh -c "cp ${KLIPPERUI}/common_vars.conf $NGINXVARS/"
        sudo ln -s "$NGINXDIR/mainsail" "$NGINXEN"
    else
        report_status "Nginx config file already exists. Skipping installation."
    fi
}

# remove NGINX default entry
remove_default(){
    # Remove default entries if it exists
    # Add debug statements
    report_status "Checking if Nginx default file exists..."

    # Remove default entries if it exists
    if [ -e "$NGINXDIR/default" ]; then
    report_status "Nginx default file found. Removing..."
    sudo rm "$NGINXDIR/default"
    sudo rm "$NGINXEN/default"
    report_status "Nginx default file removed."
   else
    report_status "Nginx default file does not exist. Skipping removal."
   fi
}

# stop klipper
stop_klipper() {
    report_status "stopping klipper..."
    sudo systemctl stop klipper
}

# start klipper
start_klipper() {
    report_status "starting klipper..."
    sudo systemctl start klipper
}

# restart nginx
restart_nginx() {
    report_status "restarting nginx..."
    sudo systemctl restart nginx
}

# Helper functions
report_status() {
    printf "\n\n###### %s\n" "$1"
}

verify_ready() {
    if [ "$EUID" -eq 0 ]; then
        report_status "This script must not run as root"
        exit -1
    fi
}

# function ui-install
ui_install(){
    verify_ready
    install_ui
    add_moon
    restart_nginx
    start_klipper
}
