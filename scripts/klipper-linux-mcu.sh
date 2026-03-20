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

    sudo cp "$KLIPPER_MCU_SERVICE" "$SYSTEMDDIR/klipper-mcu.service"
    sudo systemctl enable klipper-mcu.service
    sudo systemctl daemon-reload
    sudo systemctl start klipper-mcu
}
