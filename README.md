# wifi
A simple tool to manage wifi connections from the linux command line. It automatically selects and brings up your wireless interface, then scans for wifi signals and uses dmenu to display a list of available networks along with their signal strength. After selecting a network it will connect to it, prompting for a password if required.

There is also functionality for disconnecting from wifi and forgetting known networks, as well as resetting the wireless interface (useful to fix a bug explained below).

### Installation
It's just a single bash script. You can copy the text right from your browser into your favorite text editor.
To copy wifi into `/usr/local/bin` you can run the install script.
```
git clone https://github.com/0xdanelia/wifi
cd wifi
./install.sh
```
There is also a version that uses my very own cmenu instead of dmenu if you have it installed.
> https://github.com/0xdanelia/cmenu
```
git clone https://github.com/0xdanelia/wifi
cd wifi
./install-cmenu.sh
```

There is a dependency on the iwd package. You will be asked to install it if the script cannot find the `iwctl` command.

### Usage

`wifi [connect] [SSID]`   - Default parameter. Select and connect to a wifi network.

`wifi disconnect`   - Disconnect the current wifi connection.

`wifi forget [SSID]`   - Forget name and password of known network.

`wifi status`   - Show current connection status.

`wifi reset`   - Bring wifi interface down, then up again. User requires 'sudo' permissions.

`wifi help`   - Print the useful information you see here.

### Bugs
If you kill the process (with CTRL+c for example) while entering the password for a wifi network, you will not be able to connect to it in the future. Instead of being asked for the password again, you will see the message "Operation already in progress."

To fix this issue, simply call `wifi reset` and try to connect again.
