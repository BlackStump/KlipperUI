#!/bin/bash
# Installs Klipper and Fluidd on Debian based systems

# Constants
SYSTEMDDIR="/etc/systemd/system"
KLIPPER_MCU_SERVICE="$HOME/klipper/scripts/klipper-mcu.service"
KLIPPER_USER=$(whoami)
KLIPPERDIR="$HOME/klipper"

# Install Klipper-mcu startup script
install_klipper-mcu_service() {
    echo "Installing Klipper-mcu system start script..."

    # Check if the Klipper service file already exists
    if [ -e "$SYSTEMDDIR/klipper-mcu.service" ]; then
        echo "Klipper service already installed. Skipping installation."
        return
    fi
    sudo /bin/sh -c "cp $KLIPPER_MCU_SERVICE $SYSTEMDDIR/klipper-mcu.service"
    sudo sed -i 's#Environment=KLIPPER_HOST_MCU_SERIAL=/tmp/klipper_host_mcu#Environment=KLIPPER_HOST_MCU_SERIAL=/home/pi/printer_data/comms/host-mcu.serial#' $SYSTEMDDIR/klipper-mcu.service
    sudo sed -i "s#Environment=KLIPPER_HOST_MCU_SERIAL=/home/pi/printer_data/comms/host-mcu.serial#Environment=KLIPPER_HOST_MCU_SERIAL=/home/${KLIPPER_USER}/printer_data/comms/host-mcu.serial#" $SYSTEMDDIR/klipper-mcu.service
    sudo systemctl enable klipper-mcu.service
    sudo systemctl daemon-reload
    sudo systemctl start klipper-mcu
}
