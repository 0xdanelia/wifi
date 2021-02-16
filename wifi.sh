#!/bin/bash
# wifi connection front-end for iwd

# Check for valid parameters
if [[ ! -z $1 ]];
then
	case $1 in 
		help | connect | disconnect | forget | status | reset )
		;;
		*)
			echo "Invalid parameter $1"
			echo "Use 'wifi help' for more info"
			exit 1
		;;
	esac
fi

# Display help
if [[ $1 == "help" ]];
then
	printf "\n"
	printf " wifi parameters\n"
	printf "=================\n\n"
	printf "wifi connect [SSID]\n"
	printf "    Default parameter. Select and connect to a wifi network.\n\n"
	printf "wifi disconnect\n"
	printf "    Disconnect the current wifi connection.\n\n"
	printf "wifi forget [SSID]\n"
	printf "    Forget name and password of known network.\n\n"
	printf "wifi status\n"
	printf "    Show current connection status.\n\n"
	printf "wifi reset\n"
	printf "    Bring wifi interface down, then up again. User requires 'sudo' permissions.\n\n"
	exit 0
fi
	
# Check if iwd is installed first
if ! command -v iwctl &> /dev/null
then
	echo "Could not find command 'iwctl'"
	echo "Please install 'iwd'"
	exit 1
fi

# Forget selected wifi network
# >$ wifi forget [SSID]
if [[ $1 == forget ]];
then
	if [[ -z $2 ]];
	then
		# Select from list of known networks
		WIFI_KNOWN_LIST=$(
			iwctl known-networks list | 
			awk '{if(NR>4)print}' | 
			grep '[a-zA-Z0-9]' |
			sed 's/ *\(psk\|open\|8021x\)    .*//g' | 
			sed 's/^ *//g' | 
			sed 's/ *$//g'
		)
		if [[ -z $WIFI_KNOWN_LIST ]];
		then
			echo "No known networks"
			exit 1
		fi
		WIFI_NETWORK=$( echo "$WIFI_KNOWN_LIST" | dmenu -p "Select wifi network" -l 30 )
		# Exit if user presses 'ESC' in dmenu
		if [[ -z $WIFI_NETWORK ]];
		then
			exit 0
		fi
	else
		WIFI_NETWORK=$2
	fi
	iwctl known-networks "$WIFI_NETWORK" forget &&
	echo "Forgot $WIFI_NETWORK"
	exit 0
fi

# Select wifi interface device
if ip link | egrep -q '^[0-9]+: w.* state UP '
then
	# Priortize devices that are up already
	WIFI_DEVICE_LIST=$(
		ip link |
		egrep -i '^[0-9]+: w.* state UP ' | 
		sed 's/^[0-9]\+: //g' | 
		sed 's/:.*//g'
	)
else
	WIFI_DEVICE_DOWN=1
	WIFI_DEVICE_LIST=$(
		ip link |
		egrep -i '^[0-9]+: w' | 
		sed 's/^[0-9]\+: //g' | 
		sed 's/:.*//g'
	)
fi

if [ -z "$WIFI_DEVICE_LIST" ]
then
	echo "No available wifi devices"
	echo "Use 'ip link' to check status"
	exit 1
elif echo $WIFI_DEVICE_LIST | grep -q " "
then
	# Pipe list of devices to dmenu if there is more than one
	WIFI_DEVICE=$(
		echo "$WIFI_DEVICE_LIST" | dmenu -p "Select wifi interface" -l 30
	)
	# Exit if user presses 'ESC' in dmenu
	if [[ -z $WIFI_DEVICE ]];
	then
		exit 0
	fi
else
	# Skip dmenu if there is only one device
	WIFI_DEVICE="$WIFI_DEVICE_LIST"
fi

# Manually disconnect from wifi
if [[ $1 == disconnect ]];
then
	iwctl station "$WIFI_DEVICE" disconnect &&
	echo "Disconnected from wifi"
	exit 0
fi

# Print connection status
if [[ $1 == status ]];
then
	echo ""
	iwctl station "$WIFI_DEVICE" show
	exit 0
fi

# Bring down wifi interface, then bring it back up
# Requires sudo
if [[ $1 == reset ]];
then
	sudo ip link set "$WIFI_DEVICE" down &&
	sudo ip link set "$WIFI_DEVICE" up &&
	echo "$WIFI_DEVICE has been reset"
	exit 0
fi

# Try to bring up wifi interface if it is down
# Requires sudo
if [[ $WIFI_DEVICE_DOWN ]];
then
	echo "Device $WIFI_DEVICE is down"
	echo "Attempting to bring it up"
	sudo ip link set "$WIFI_DEVICE" up &&
	echo "Success" ||
	echo "Could not bring device up"
fi

# Select wifi network to connect to
iwctl station "$WIFI_DEVICE" scan

# Set SSID manually if given through command line
# >$ wifi connect 'SSID'
if [[ $1 == connect && ! -z $2 ]];
then
	WIFI_NETWORK=$2
fi

if [[ -z $2 ]];
then
	# Remove colors
	WIFI_NETWORK_LIST=$(
		iwctl station "$WIFI_DEVICE" get-networks | 
		awk '{if(NR>4)print}' | 
		sed 's/\x1b\[[0-9;]*m\*\?//g'
	)
	if [[ -z $WIFI_NETWORK_LIST ]];
	then
		echo "No wifi networks found"
		echo "Use 'ip link' to make sure wifi device is up"
		exit 1
	fi
	# Trim selected network for SSID
	WIFI_NETWORK=$(
		echo "$WIFI_NETWORK_LIST" |
		dmenu -p "$WIFI_DEVICE: Select wifi network" -l 30 | 
		sed 's/ *\(psk\|open\|8021x\) \+\*\+//g' | 
		sed 's/^ *>\? *//g' | 
		sed 's/ *$//g'
	)
	# Exit if user presses 'ESC' in dmenu
	if [[ -z $WIFI_NETWORK ]];
	then
		exit 0
	fi
fi

# Connect to wifi
# This command will prompt for password first if required
iwctl station "$WIFI_DEVICE" connect "$WIFI_NETWORK" &&
echo "Connected to $WIFI_NETWORK" ||
echo "Could not connect to $WIFI_NETWORK"
