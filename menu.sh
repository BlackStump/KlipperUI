#!/bin/bash
MENU_SCRIPTS="$HOME/KlipperUI/scripts"

# Source the scripts
source ${MENU_SCRIPTS}/klipper-install.sh
source ${MENU_SCRIPTS}/moonraker-install.sh
source ${MENU_SCRIPTS}/nginx-install.sh
source ${MENU_SCRIPTS}/ui-install.sh
source ${MENU_SCRIPTS}/klipper-linux-mcu.sh
source ${MENU_SCRIPTS}/can-install.sh

# Function to install both Klipper and UI
install_klipper_and_ui() {
    klipper_install
    moonraker_install
    check_nginx
    ui_install
}

# Function to change UI
change_ui() {
    moonraker_install
    check_nginx
    ui_install
}

# Function for the main menu
main_menu() {
    while true; do
        echo "Main Menu:"
        echo "1. Install Klipper"
        echo "2. Install Both Klipper and UI (Fluidd/Mainsail)"
        echo "3. Install Klipper Linux MCU"
        echo "4. Change UI (Fluidd/Mainsail)"
        echo "5. Install CAN (Networkd)"
        echo "6. Exit"
        read -p "Enter your choice (1-6): " main_choice
        case $main_choice in
            1)
                klipper_install
                ;;
            2)
                install_klipper_and_ui
                ;;
            3)
                install_klipper_mcu_service
                ;;
            4)
                change_ui
                ;;
            5)
                can_install
                ;;
            6)
                echo "Exiting script."
                exit 0
                ;;
            *)
                echo "Invalid choice. Please enter a number between 1 and 6."
                ;;
        esac
        read -p "Do you want to go back to the main menu? (y/n): " continue_choice
        case $continue_choice in
            [nN])
                echo "Exiting script."
                exit 0
                ;;
            *)
                ;;
        esac
    done
}

main_menu
