Keyboard from https://keyboard-hoarders.com // https://keyboardhoarders.etsy.com

Original customization instructions: https://keyboard-hoarders.com/pages/guides-1

# Building Firmware Locally

## Prerequisites (Ubuntu)

Install the required dependencies:

```bash
sudo apt-get update
sudo apt-get install git python3 cmake device-tree-compiler wget tar xz-utils
```

Install `uv` (Python package manager):

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

## Build Firmware

Run the build script:

```bash
./build.sh
```

This will:
- Check for all required dependencies
- Install Zephyr SDK (if not already installed)
- Set up the west workspace
- Build firmware for left side (with Studio), right side, and settings reset
- Output firmware files to `./firmware/`

# Customizing Your Keymap

To customize your keyboard layout, edit the keymap file at `config/corne.keymap`. This file defines all your key bindings, layers, and behaviors.

For detailed documentation on keymap configuration, see the [ZMK Keymap Configuration Guide](https://zmk.dev/docs/config/keymap).

After making changes, rebuild the firmware using `./build.sh` and flash it to your keyboard.

# Flashing the New Firmware
*From the original customization guide above

Make sure both halves are powered on the entire time. Also when transferring files you may get an error.  This is due to auto unmounting.  You can ignore this error and continue to the next step.

* Plug in the left half of the keyboard.  Once plugged in you need to press the physical reset button twice that is located on the sides of each half.  This will put the keyboard into bootloader mode and open a new directory on your computer.

* Open the new directory and drag and drop the settings_reset file shown with the green box in the image.

* Now unplug the left half and plug in the right half.  Press the reset button twice.

* Drag and drop the same Settings_reset file shown with the green box into the right half keyboard directory.

* Now plug in the left half of the keyboard again.  Drag and drop sofle_left nice_view if you have a keyboard with screens shown with the red box otherwise if you dont have displays choose the other one sofle_left-nice_nano.

* Now unplug the left half and plug in the right half. Press the reset button twice.  Drag and drop sofle_right nice_view shown with the red box if you have displays otherwise if you dont have displays choose the sofle_right-nice_nano

* Now you need to go to your computer or device and find your bluetooth device history list.  You should see a sofle device thats not connected or maybe its even showing its connected then disconnects.  You need to delete this from your device list.

* Pair the keyboard as a new device.
