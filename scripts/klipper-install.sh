#!/bin/bash
# This script installs Klipper on Debian

# Constants
SYSTEMDDIR="/etc/systemd/system"
PYTHONDIR="$HOME/klippy-env"
PRINTER_DATA="$HOME/printer_data"
KLIPPER_USER=$(whoami)
KLIPPERDIR="$HOME/klipper"
SRCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"

# Step 1: Install system packages
install_packages() {
    # Packages for python cffi
    PKGLIST="python3-virtualenv python3-dev libffi-dev build-essential"
    # kconfig requirements
    PKGLIST+=" libncurses-dev"
    # hub-ctrl
    PKGLIST+=" libusb-dev"
    # AVR chip installation and building
    PKGLIST+=" avrdude gcc-avr binutils-avr avr-libc"
    # ARM chip installation and building
    PKGLIST+=" stm32flash libnewlib-arm-none-eabi"
    PKGLIST+=" gcc-arm-none-eabi binutils-arm-none-eabi libusb-1.0 pkg-config"

    report_status "Running apt-get update..."
    sudo apt-get update

    report_status "Installing packages..."
    sudo apt-get install --yes ${PKGLIST}
}

# Step 2: Clone Klipper
clone_klipper() {
    report_status "Cloning Klipper..."
    cd ~/
    if [ ! -d "${HOME}/klipper" ]; then
        git clone https://github.com/Klipper3d/klipper.git
    else
        echo "Directory ${HOME}/klipper already exists. Skipping clone step."
    fi
}

# Step 3: Create python virtual environment
create_virtualenv() {
    report_status "Updating Python virtual environment..."

    if [ -d "${PYTHONDIR}" ] && [ -f "${PYTHONDIR}/bin/python" ] && \
       [ -f "${PYTHONDIR}/bin/pip" ] && \
       ${PYTHONDIR}/bin/pip show -q -f "${KLIPPERDIR}/scripts/klippy-requirements.txt"
    then
        report_status "Python virtual environment and requirements are already installed. Skipping."
        return
    fi

    [ ! -d ${PYTHONDIR} ] && virtualenv -p python3 ${PYTHONDIR}
    ${PYTHONDIR}/bin/pip install -r ${KLIPPERDIR}/scripts/klippy-requirements.txt

    report_status "Python virtual environment and requirements installed."
}

# Step 4: Make directories
make_dir() {
    report_status "Making directories..."

    if [ -d "${PRINTER_DATA}/config" ] && [ -d "${PRINTER_DATA}/logs" ] && \
       [ -d "${PRINTER_DATA}/gcodes" ] && [ -d "${PRINTER_DATA}/systemd" ] && \
       [ -d "${PRINTER_DATA}/comms" ] && [ -d "${PRINTER_DATA}/backup" ] && \
       [ -d "${PRINTER_DATA}/certs" ]; then
        report_status "Directories already exist. Skipping."
        return
    fi

    mkdir -p ${PRINTER_DATA}/{config,logs,gcodes,systemd,comms,backup,certs}
    report_status "Directories created."
}

# Step 5: Install args
install_args() {
    if [ -e "${PRINTER_DATA}/systemd/klipper.env" ] && \
       [ -e "${PRINTER_DATA}/config/printer.cfg" ]; then
        report_status "Klipper configurations already installed. Skipping."
        return
    fi

    /bin/sh -c "cat > ${PRINTER_DATA}/systemd/klipper.env" << EOF
KLIPPER_ARGS="${HOME}/klipper/klippy/klippy.py 
${PRINTER_DATA}/config/printer.cfg -l
${PRINTER_DATA}/logs/klippy.log -I
${PRINTER_DATA}/comms/klippy.serial -a
${PRINTER_DATA}/comms/klippy.sock"
EOF
# install bare bones printer.cfg if one does not exist
    if [ ! -e "${PRINTER_DATA}/config/printer.cfg" ]; then
        /bin/sh -c "cat >> ${PRINTER_DATA}/config/printer.cfg" << EOF
[mcu]
serial: /dev/serial/by-id/<your-mcu-id>

[pause_resume]

[display_status]

[virtual_sdcard]
path: ~/printer_data/gcodes
on_error_gcode: CANCEL_PRINT

[printer]
kinematics: none
max_velocity: 1000
max_accel: 1000
EOF
        report_status "Klipper configurations installed."
    else
        report_status "printer.cfg already exists. Skipping appending step."
    fi
}

# Step 6: Install startup script
install_klipper_service() {
    report_status "Installing Klipper system start script..."

    # Check if the Klipper service file already exists
    if [ -e "$SYSTEMDDIR/klipper.service" ]; then
        report_status "Klipper service already installed. Skipping installation."
        return
    fi

    sudo /bin/sh -c "cat > $SYSTEMDDIR/klipper.service" << EOF
[Unit]
Description=Klipper 3D Printer Firmware SV1
Documentation=https://www.klipper3d.org/
After=network-online.target
Wants=udev.target

[Install]
WantedBy=multi-user.target

[Service]
Type=simple
User=${KLIPPER_USER}
RemainAfterExit=yes
WorkingDirectory=${PYTHONDIR} 
EnvironmentFile=${PRINTER_DATA}/systemd/klipper.env
ExecStart=${PYTHONDIR}/bin/python \$KLIPPER_ARGS
Restart=always
RestartSec=10
EOF

    sudo sed -i "s/User=pi/User=${KLIPPER_USER}/" $SYSTEMDDIR/klipper.service
    sudo sed -i "s/WorkingDirectory=\/home\/pi\/klipper/WorkingDirectory=\/home\/${KLIPPER_USER}\/klipper/" $SYSTEMDDIR/klipper.service
    sudo systemctl enable klipper.service
    sudo systemctl daemon-reload
}

# Step 7: Start host software
start_software() {
    report_status "Launching Klipper host software..."
    sudo systemctl start klipper
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

# Force script to exit if an error occurs
set -e

# Run installation steps defined above
klipper_install() {
verify_ready
install_packages
clone_klipper
create_virtualenv
make_dir
install_args
install_klipper_service
start_software
}
