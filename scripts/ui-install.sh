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
FLUIDDCFG_URL="https://github.com/fluidd-core/fluidd-config.git"
MAINSAILCFG_URL="https://github.com/mainsail-crew/mainsail-config.git"

# Function to display menu and get user selection
select_ui() {
    local valid_choices=("1" "2")
    local timeout=15

    report_status "Select UI:"
    echo "1. Fluidd"
    echo "2. Mainsail"

    # Read user input with timeout
    IFS= read -r -t "$timeout" -p "Enter choice (1 or 2, Enter for Fluidd): " CHOICE || true

    CHOICE=${CHOICE:-1}

    if [[ ! "${valid_choices[@]}" =~ "${CHOICE}" ]]; then
        report_status "Invalid choice or timeout. Defaulting to Fluidd."
        CHOICE=1
    fi
}

# Install ui system packages
install_packages_ui() {
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
            install_packages_ui
            install_fluidd
            install_nginxcfg_fluidd
            remove_default
            ;;
        2)
            stop_klipper
            install_packages_ui
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
    FILEFCFG=~/fluidd-config
    FILEM=~/mainsail-config
    if [ ! -d "$FILE" ]; then
        mkdir ~/fluidd
        cd ~/fluidd
        wget -q -O fluidd.zip ${FLUIDD_URL} && unzip fluidd.zip && rm fluidd.zip
        cd ~/
    fi

    if [ -e "$FILEM" ]; then
        unlink ~/printer_data/config/mainsail.cfg
        unlink ~/printer_data/config/mainsail-moonraker-update.conf
        sudo rm -r mainsail mainsail-config
    fi

    if [ ! -d "$FILEFCFG" ]; then
        git clone ${FLUIDDCFG_URL}
        ln -sf ~/fluidd-config/fluidd.cfg ~/printer_data/config/fluidd.cfg
        ln -sf ~/fluidd-config/fluidd-moonraker-update.conf ~/printer_data/config/fluidd-moonraker-update.conf
    else
        report_status "$FILE already exists. Skipping Fluidd installation."
    fi
}

# Option to install mainsail
install_mainsail() {
    FILE=~/mainsail
    FILEMCFG=~/mainsail-config
    FILEF=~/fluidd-config
    if [ ! -d "$FILE" ]; then
        mkdir ~/mainsail
        cd ~/mainsail
        wget -q -O mainsail.zip ${MAINSAIL_URL} && unzip mainsail.zip && rm mainsail.zip
        cd ~/
    fi

    if [ -e "$FILEF" ]; then
        unlink ~/printer_data/config/fluidd.cfg
        unlink ~/printer_data/config/fluidd-moonraker-update.conf
        sudo rm -r fluidd fluidd-config
    fi

    if [ ! -d "$FILEMCFG" ]; then
        git clone ${MAINSAILCFG_URL}
        ln -sf ~/mainsail-config/mainsail.cfg ~/printer_data/config/mainsail.cfg
        ln -sf ~/mainsail-config/mainsail-moonraker-update.conf ~/printer_data/config/mainsail-moonraker-update.conf
    else
        report_status "$FILE already exists. Skipping Mainsail installation."
    fi
}

# Function to remove a line from a file if it exists
remove_line_if_exists() {
    pattern="$1"
    file="$2"

    # Check if the pattern exists in the file
    if grep -qF "$pattern" "$file"; then
        # Use temporary file to preserve original contents
        tmpfile=$(mktemp)
        grep -vF "$pattern" "$file" > "$tmpfile"
        mv "$tmpfile" "$file"
    fi
}

# Function to add a line to the top of a file if it doesn't exist
add_line_to_top_if_not_exists() {
    if ! grep -qF "$1" "$2"; then
        sed -i "1s/^/$1\n/" "$2"
    fi
}

# Add Moonraker config
add_moon() {
    report_status "Add Moonraker config..."

    # Choose the appropriate moonraker.conf based on user choice
    if [ "$CHOICE" == "1" ]; then
        SOURCE_CONF_FILE="${KLIPPERUI}/moonraker_fluidd.conf"
        INCLUDE_LINE="[include fluidd.cfg]"
        OPPOSITE_LINE="[include mainsail.cfg]"
    elif [ "$CHOICE" == "2" ]; then
        SOURCE_CONF_FILE="${KLIPPERUI}/moonraker_mainsail.conf"
        INCLUDE_LINE="[include mainsail.cfg]"
        OPPOSITE_LINE="[include fluidd.cfg]"
    else
        report_status "Invalid choice. Exiting."
        exit 1
    fi

    # Backup printer.cfg
    if [ -f "${PRINTER_DATA}/config/printer.cfg" ]; then
        cp "${PRINTER_DATA}/config/printer.cfg" "${PRINTER_DATA}/config/printer.cfg.bak"
    fi

    # Copy the chosen config file to moonraker.conf
    cp "$SOURCE_CONF_FILE" "${PRINTER_DATA}/config/moonraker.conf"

    # Modify printer.cfg
    if [ -f "${PRINTER_DATA}/config/printer.cfg.bak" ]; then
        cp "${PRINTER_DATA}/config/printer.cfg.bak" "${PRINTER_DATA}/config/printer.cfg"

        # Remove opposite include line
        remove_line_if_exists "$OPPOSITE_LINE" "${PRINTER_DATA}/config/printer.cfg"

        # Add new include line
        add_line_to_top_if_not_exists "$INCLUDE_LINE" "${PRINTER_DATA}/config/printer.cfg"
    fi

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

# restart moonraker
restart_moonraker() {
    report_status "restarting moonraker..."
    sudo systemctl restart moonraker
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
    restart_moonraker
}
