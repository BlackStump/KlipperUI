# KlipperUI

USE AT OWN RISK

Tested on Orangepi Zeroplus with Armbian and Beaglebone Black both with Bookworm OS both had this issue [here](https://klipper.discourse.group/t/klipper-mcu-service-fails-to-start/12219)

command to fix issue 
````python
sudo echo "kernel.sched_rt_runtime_us = -1" | sudo tee /etc/sysctl.d/10-disable-rt-group-limit.conf
````
Now reboot the system
````python
sudo reboot now
````
commands to use script
````python
sudo apt install git
git clone https://github.com/BlackStump/KlipperUI.git
cd ~/
./KlipperUI/menu.sh
````
This script will now present a menu.

         "1. Install Klipper"
         "2. Install Both Klipper and UI (Fluidd/Mainsail)"
         "3. Install Klipper Linux MCU"
         "4. Change UI (Fluidd/Mainsail)"
         
klipper-mcu service will not work until klipper linux mcu is flashed!

There will be a menu choice of Fluidd or Mainsail if no choice is made it will default to Fluidd, UI install includes Moonraker and Nginx.

Then continue to setup Klipper for the mcu that you have per klipper instructions [here](https://www.klipper3d.org/Installation.html#obtain-a-klipper-configuration-file)

The Script will install a bare bones printer.cfg if no printer.cfg exists.

The GUI of choice should be accessable so you can edit the printer.cfg from the GUI.


printer.cfg entry for klipper-mcu
````python
[mcu host]
serial: ~/printer_data/comms/host-mcu.serial
````
------
Flashing Linux mcu
````python
cd ~/klipper/
make menuconfig
````
In the menu, set "Microcontroller Architecture" to "Linux process," then save and exit.
````python
sudo systemctl stop klipper
make flash
sudo systemctl start klipper
````
------

Useful commands

check Klipper-mcu status
````python
sudo systemctl status klipper-mcu
````
restart Klipper-mcu
````python
sudo systemctl restart klipper-mcu
````
check klipper status
````python
sudo systemctl status klipper
````
restart klipper
````python
sudo systemctl restart klipper
