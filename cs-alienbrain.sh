#!/bin/bash
#
# Regards, the Alveare Solutions society -
#
# CHEAT SHEET

SCRIPT_NAME='Alien(B)Rain'
VERSION='CarpetBMB'
VERSION_NO='1.0'

function new_iptables_chain () {
    local NEW_CHAIN="$2"
    exec_msg "iptables -N $NEW_CHAIN"
    iptables -N "$NEW_CHAIN"
    return $?
}

function delete_existing_rules () {
    exec_msg "iptables -F"
    iptables -F
    return $?
}

function set_default_policies () {
    local POLICY="${2:-DROP}" # (DROP|ACCEPT)
    exec_msg "iptabels -P INPUT $POLICY"
    iptabels -P INPUT $POLICY
    exec_msg "iptabels -P FORWARD $POLICY"
    iptabels -P FORWARD $POLICY
    exec_msg "iptabels -P OUTPUT $POLICY"
    iptabels -P OUTPUT $POLICY
    return $?
}

function show_firewall_status () {
    exec_msg "iptables -L -n -v --line-numbers"
    iptables -L -n -v --line-numbers
    return $?
}

function block_ipv4_or_subnet () {
    local IPv4_OR_SUBNET="$2" # (1.2.3.4 | 10.0.0.0/8)
    exec_msg "iptables -A INPUT -s $IPv4_OR_SUBNET -j DROP"
    iptables -A INPUT -s "$IPv4_OR_SUBNET" -j DROP
    return $?
}

function white_list_ipv4 () {
    local INTERFACE="$2"
    local IPv4_ADDRS="$3"
    exec_msg "iptables -A INPUT -i $INTERFACE -s $IPv4_ADDRESS -j ACCEPT"
    iptables -A INPUT -i "$INTERFACE" -s "$IPv4_ADDRESS" -j ACCEPT
    return $?
}

function allow_loopback_access () {
    exec_msg "iptables -A INPUT -i lo -j ACCEPT"
    iptables -A INPUT -i lo -j ACCEPT
    exec_msg "iptables -A OUTPUT -o lo -j ACCEPT"
    iptables -A OUTPUT -o lo -j ACCEPT
    return $?
}

function allow_mysql_from_specific_network () {
    local NETWORK="$2"
    local INTERFACE="$3"
    local SRC_PORT=${4:-3306}
    local DST_PORT=${5:-3306}{
    exec_msg "iptables -A INPUT -i $INTERFACE -p tcp -s $NETWORK --dport $DST_PORT -m state --state NEW,ESTABLISHED -j ACCEPT"
    iptables -A INPUT -i "$INTERFACE" -p tcp -s "$NETWORK" --dport $DST_PORT -m state --state NEW,ESTABLISHED -j ACCEPT
    exec_msg "iptables -A OUTPUT -o $INTERFACE -p tcp --sport $SRC_PORT -m state --state ESTABLISHED -j ACCEPT"
    iptables -A OUTPUT -o "$INTERFACE" -p tcp --sport $SRC_PORT -m state --state ESTABLISHED -j ACCEPT
    return $?
}

function prevent_dos_attack () {
    local PORT_NO=${2:-80}
    exec_msg "iptables -A INPUT -p tcp --dport $PORT_NO -m limit --limit 25/minute --limit-burst 1000 -j ACCEPT"
    iptables -A INPUT -p tcp --dport $PORT_NO -m limit --limit 25/minute --limit-burst 1000 -j ACCEPT
    # -m limit: This uses the limit iptables extension
    # --limit 25/minute: This limits only maximum of 25 connections per minute.
    # Change this value based on your specific requirement.
    # --limit-burst 1000: This value indicates that the limit/minute will be
    # enforced only after the total number of connections have reached the
    # limit-burst level
    return $?
}

function port_forwarding () {
    local INTERFACE="$2"
    local SRC_IPV4="$3"
    local DST_IPV4="$4"
    local DST_PORT=${5:-80}
    exec_msg "iptables -t nat -A PREROUTING -i $INTERFACE -p tcp --dport $DST_PORT -j DNAT --to ${DST_IPV4}:${DST_PORT}"
    iptables -t nat -A PREROUTING -i "$INTERFACE" -p tcp --dport $DST_PORT -j DNAT --to ${DST_IPV4}:${DST_PORT}
    exec_msg "iptables -t nat -A POSTROUTING -p tcp --dst $DST_IPV4 --dport $DST_PORT -j SNAT --to $SRC_IPV4"
    iptables -t nat -A POSTROUTING -p tcp --dst "$DST_IPV4" --dport $DST_PORT -j SNAT --to "$SRC_IPV4"
    exec_msg "iptables -t nat -A OUTPUT --dst $SRV_IPV4 -p tcp --dport $DST_PORT -j DNAT --to ${DST_IPV4}:${DST_PORT}"
    iptables -t nat -A OUTPUT --dst "$SRV_IPV4" -p tcp --dport $DST_PORT -j DNAT --to ${DST_IPV4}:${DST_PORT}
    return $?
}

function stop_port_forwarding () {
    local INTERFACE="$2"
    local SRC_IPV4="$3"
    local DST_IPV4="$4"
    local DST_PORT=${5:-80}
    exec_msg "iptables -t nat -D PREROUTING -i $INTERFACE -p tcp --dport $DST_PORT -j DNAT --to ${DST_IPV4}:${DST_PORT}"
    iptables -t nat -D PREROUTING -i "$INTERFACE" -p tcp --dport $DST_PORT -j DNAT --to ${DST_IPV4}:${DST_PORT}
    exec_msg "iptables -t nat -D POSTROUTING -p tcp --dst $DST_IPV4 --dport $DST_PORT -j SNAT --to $SRC_IPV4"
    iptables -t nat -D POSTROUTING -p tcp --dst "$DST_IPV4" --dport $DST_PORT -j SNAT --to "$SRC_IPV4"
    exec_msg "iptables -t nat -d OUTPUT --dst $SRC_IPV4 -p tcp --dport $DST_PORT -j DNAT --to ${DST_IPV4}:${DST_PORT}"
    iptables -t nat -d OUTPUT --dst "$SRC_IPV4" -p tcp --dport $DST_PORT -j DNAT --to ${DST_IPV4}:${DST_PORT}
    return $?
}

function block_access_to_website () {
    local REMOTE_ADDRESS="$2"
    exec_msg "iptables -A OUTPUT -p tcp -d $REMOTE_ADDRESS -j DROP"
    iptables -A OUTPUT -p tcp -d "$REMOTE_ADDRESS" -j DROP
    return $?
}

function allow_ping_from_outside () {
    exec_msg "iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT"
    iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
    exec_msg "iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT"
    iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT
    return $?
}

function allow_ping_to_outside () {
    exec_msg "iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT"
    iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT
    exec_msg "iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT"
    iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
    return $?
}

function allow_all_incomming_ssh () {
    local INTERFACE="$2"
    local PORT_NO=${3:-22}
    exec_msg "iptables -A INPUT -i $INTERFACE -p tcp --dport $PORT_NO -m state --state NEW,ESTABLISHED -j ACCEPT"
    iptables -A INPUT -i "$INTERFACE" -p tcp --dport $PORT_NO -m state --state NEW,ESTABLISHED -j ACCEPT
    exec_msg "iptables -A OUTPUT -o $INTERFACE -p tcp --sport $PORT_NO -m state --state ESTABLISHED -j ACCEPT"
    iptables -A OUTPUT -o "$INTERFACE" -p tcp --sport $PORT_NO -m state --state ESTABLISHED -j ACCEPT
    return $?
}

function allow_incomming_ssh_from_ipv4_or_network () {
    local INTERFACE="$2"
    local SRC_IPV4_OR_NETWORK="$3"
    local SRC_PORT=${4:-22}
    local DST_PORT=${5:-22}
    exec_msg "iptables -A INPUT -i $INTERFACE -p tcp -s $SRC_IPV4_OR_NETWORK --dport $DST_PORT -m state --state NEW,ESTABLISHED -j ACCEPT"
    iptables -A INPUT -i "$INTERFACE" -p tcp -s "$SRC_IPV4_OR_NETWORK" --dport $DST_PORT -m state --state NEW,ESTABLISHED -j ACCEPT
    exec_msg "iptables -A OUTPUT -o $INTERFACE -p tcp --sport $SRC_PORT -m state --state ESTABLISHED -j ACCEPT"
    iptables -A OUTPUT -o "$INTERFACE" -p tcp --sport $SRC_PORT -m state --state ESTABLISHED -j ACCEPT
    return $?
}

function allow_outgoing_ssh () {
    local INTERFACE="$2"
    local SRC_PORT=${3:-22}
    local DST_PORT=${4:-22}
    exec_msg "iptables -A OUTPUT -o $INTERFACE -p tcp --dport $DST_PORT -m state --state NEW,ESTABLISHED -j ACCEPT"
    iptables -A OUTPUT -o "$INTERFACE" -p tcp --dport $DST_PORT -m state --state NEW,ESTABLISHED -j ACCEPT
    exec_msg "iptables -A INPUT -i $INTERFACE -p tcp --sport $SRC_PORT -m state --state ESTABLISHED -j ACCEPT"
    iptables -A INPUT -i "$INTERFACE" -p tcp --sport $SRC_PORT -m state --state ESTABLISHED -j ACCEPT
    return $?
}

function allow_outgoing_ssh_to_ipv4_or_network () {
    local INTERFACE="$2"
    local SRC_IPV4_OR_NETWORK="$3"
    local SRC_PORT=${4:-22}
    local DST_PORT=${5:-22}
    exec_msg "iptables -A OUTPUT -o $INTERFACE -p tcp -d $SRC_IPV4_OR_NETWORK --dport $DST_PORT -m state --state NEW,ESTABLISHED -j ACCEPT"
    iptables -A OUTPUT -o "$INTERFACE" -p tcp -d "$SRC_IPV4_OR_NETWORK" --dport $DST_PORT -m state --state NEW,ESTABLISHED -j ACCEPT
    exec_msg "iptables -A INPUT -i $INTERFACE -p tcp --sport $SRC_PORT -m state --state ESTABLISHED -j ACCEPT"
    iptables -A INPUT -i "$INTERFACE" -p tcp --sport $SRC_PORT -m state --state ESTABLISHED -j ACCEPT
    return $?
}

function allow_http_web_traffic () {
    local SRC_PORT=${2:-80}
    local DST_PORT=${3:-80}
    exec_msg "iptables -A INPUT -p tcp --dport $DST_PORT -m state --state NEW,ESTABLISHED -j ACCEPT"
    iptables -A INPUT -p tcp --dport $DST_PORT -m state --state NEW,ESTABLISHED -j ACCEPT
    exec_msg "iptables -A OUTPUT -p tcp --sport $SRC_PORT -m state --state ESTABLISHED -j ACCEPT"
    iptables -A OUTPUT -p tcp --sport $SRC_PORT -m state --state ESTABLISHED -j ACCEPT
    return $?
}

function allow_https_web_traffic () {
    local SRC_PORT=${2:-443}
    local DST_PORT=${3:-443}
    exec_msg "iptables -A INPUT -p tcp --dport $DST_PORT -m state --state NEW,ESTABLISHED -j ACCEPT"
    iptables -A INPUT -p tcp --dport $DST_PORT -m state --state NEW,ESTABLISHED -j ACCEPT
    exec_msg "iptables -A OUTPUT -p tcp --sport $SRC_PORT -m state --state ESTABLISHED -j ACCEPT"
    iptables -A OUTPUT -p tcp --sport $SRC_PORT -m state --state ESTABLISHED -j ACCEPT
    return $?
}

function allow_incomming_on_multiple_ports () {
    local INTERFACE="$2"
    local SRC_PORT_CSV=$3
    local DST_PORT_CSV=${4:-$SRC_PORT_CSV}
    exec_msg "iptables -A INPUT -i $INTERFACE -p tcp -m multiport --dports $DST_PORT_CSV -m state --state NEW,ESTABLISHED -j ACCEPT"
    iptables -A INPUT -i "$INTERFACE" -p tcp -m multiport --dports $DST_PORT_CSV -m state --state NEW,ESTABLISHED -j ACCEPT
    exec_msg "iptables -A OUTPUT -o $INTERFACE -p tcp -m multiport --sports $SRC_PORT_CSV -m state --state ESTABLISHED -j ACCEPT"
    iptables -A OUTPUT -o "$INTERFACE" -p tcp -m multiport --sports $SRC_PORT_CSV -m state --state ESTABLISHED -j ACCEPT
    return $?
}

function load_balance_web_traffic () {
    local DST_PORT=${2:-80}
    local IPV4_ADDRESSES=( ${@:3} )
    local MACHINE_COUNT=${#IPV4_ADDRESSES[@]}
    local PACKET=0
    for machine_ipv4 in `seq $MACHINE_COUNT`; do
        exec_msg "iptables -A PREROUTING -p tcp --dport $DST_PORT -m state -m nth --every 3 --packet $PACKET -j DNAT --to-destination "$machine_ipv4""
        iptables -A PREROUTING -p tcp --dport $DST_PORT -m state -m nth --every 3 --packet $PACKET -j DNAT --to-destination "$machine_ipv4"
        local PACKET=$((PACKET + 1))
    done
    return $?
}

function allow_outbound_dns () {
    local INTERFACE="$2"
    local SRC_PORT=${3:-53}
    local DST_PORT=${4:-53}
    exec_msg "iptables -A OUTPUT -p udp -o $INTERFACE --dport $DST_PORT -j ACCEPT"
    iptables -A OUTPUT -p udp -o "$INTERFACE" --dport $DST_PORT -j ACCEPT
    exec_msg "iptables -A INPUT -p udp -i $INTERFACE --sport $SRC_PORT -j ACCEPT"
    iptables -A INPUT -p udp -i "$INTERFACE" --sport $SRC_PORT -j ACCEPT
    return $?
}

function allow_inbound_smtp_email_traffic () {
    local SRC_PORT=${2:-25}
    local DST_PORT=${3:-25}
    exec_msg "iptables -A INPUT -p tcp --dport $DST_PORT -m state --state NEW,ESTABLISHED -j ACCEPT"
    iptables -A INPUT -p tcp --dport $DST_PORT -m state --state NEW,ESTABLISHED -j ACCEPT
    exec_msg "iptables -A OUTPUT -p tcp --sport $SRC_PORT -m state --state ESTABLISHED -j ACCEPT"
    iptables -A OUTPUT -p tcp --sport $SRC_PORT -m state --state ESTABLISHED -j ACCEPT
    return $?
}

function allow_inbound_pop3_email_traffic () {
    local SRC_PORT=${2:-110}
    local DST_PORT=${3:-110}
    exec_msg "iptables -A INPUT -p tcp --dport $DST_PORT -m state --state NEW,ESTABLISHED -j ACCEPT"
    iptables -A INPUT -p tcp --dport $DST_PORT -m state --state NEW,ESTABLISHED -j ACCEPT
    exec_msg "iptables -A OUTPUT -p tcp --sport $SRC_PORT -m state --state ESTABLISHED -j ACCEPT"
    iptables -A OUTPUT -p tcp --sport $SRC_PORT -m state --state ESTABLISHED -j ACCEPT
    return $?
}

function port_forwarding_hide_source_behind_host () {
    local PROXY_IPV4_ADDRS="$2"
    local HOST_PRIVATE_IP="$3"
    exec_msg "iptables -t nat -A POSTROUTING -s $PROXY_IPV4_ADDRS -j SNAT --to-source $HOST_PRIVATE_IP"
    iptables -t nat -A POSTROUTING -s "$PROXY_IPV4_ADDRS" -j SNAT --to-source "$HOST_PRIVATE_IP"
    exec_msg "iptables -t nat -A POSTROUTING -j MASQUERADE"
    iptables -t nat -A POSTROUTING -j MASQUERADE
    exec_msg "echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf"
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    exec_msg "sysctl -p"
    sysctl -p
    exec_msg "echo 1 > /proc/sys/net/ipv4/ip_forward"
    echo 1 > /proc/sys/net/ipv4/ip_forward
    return $?
}

function access_external_network_with_intranet_message_of_snat () {
    # SNAT - Acces external network with the 192.168.0.0/24 message of thee intranet and
    # SNAT 1.1.1.1
    local NETWORK="$2" # 192.168.0.0/24
    local DST_IPV4="$3" # 1.1.1.1
    exec_msg "iptables -t nat -I POSTROUTING -s $NETWORK -j SNAT --to $DST_IPV4"
    iptables -t nat -I POSTROUTING -s $NETWORK -j SNAT --to $DST_IPV4
    return $?
}

function access_external_network_with_extranet_message_of_dnat () {
    # DNAT - Access the TCP 1.1.1.1:8080 message of the external network, and the
    # DNAT is 192.168.0.1:8080
    local NETWORK="$2" # 192.168.0.0/24
    local DST_IPV4="$3" # 1.1.1.1
    local DST_PORT=$4
    exec_msg "iptables -t nat -I PREROUTING -d $NETWORK -p tcp --dport $DST_PORT -j NAT --to ${DST_IPV4}:${DST_PORT}"
    iptables -t nat -I PREROUTING -d "$NETWORK" -p tcp --dport $DST_PORT -j NAT --to ${DST_IPV4}:${DST_PORT}
    return $?
}

function dnat_and_snat () {
    local NETWORK="$2" # 192.168.0.0/24
    local DST_IPV4="$3" # 1.1.1.1
    exec_msg "iptables -t nat -I POSTROUTING -s $NETWORK -j SNAT --to $DST_IPV4"
    iptables -t nat -I POSTROUTING -s "$NETWORK" -j SNAT --to "$DST_IPV4"
    # DNAT + SNAT - Access the tcp 1.1.1.1:8080 message of the external network,
    # and the DNAT is 192.168.0.1:8080. 192.168.0.2 can access 192.168.0.1:8080 by
    # accessing 1.1.1.1:8080. The intranet 192.168.0.0/24 message, SNAT is 1.1.1.1
    # to access the external network.
    return $?
}

function display_iptables_rules () {
    exec_msg "iptables -L || cat /etc/sysconfig/iptable"
    iptables -L || cat /etc/sysconfig/iptable
    return $?
}

function check_ipv4_exists_in_rule () {
    local IPV4_ADDRS="$2"
    exec_msg "iptables -nL | grep $IPV4_ADDRS"
    iptables -nL | grep "$IPV4_ADDRS"
    return $?
}

function save_current_iptables_rules () {
    local FILE_PATH="$2"
    exec_msg "iptables-save > $FILE_PATH"
    iptables-save > "$FILE_PATH"
    return $?
}

function restore_iptables_rules () {
    local FILE_PATH="$2"
    iptables-restore < "$FILE_PATH"
    return $?
}

# INIT

function init_cheat_sheet () {
    local INSTRUCTION="$1"
    case "$INSTRUCTION" in
        1|'new-iptables-chain')
            new_iptables_chain $@
            show_firewall_status
            ;;
        2|'delete-existing-rules')
            delete_existing_rules $@
            show_firewall_status
            ;;
        3|'set-default-policies')
            set_default_policies $@
            show_firewall_status
            ;;
        4|'show-firewall-status')
            show_firewall_status $@
            ;;
        5|'block-ipv4-subnet')
            block_ipv4_or_subnet $@
            show_firewall_status
            ;;
        6|'white-list-ipv4')
            white_list_ipv4 $@
            show_firewall_status
            ;;
        7|'allow-loopback-access')
            allow_loopback_access $@
            show_firewall_status
            ;;
        8|'allow-mysql-from-network')
            allow_mysql_from_specific_network $@
            show_firewall_status
            ;;
        9|'prevent-dos-attack')
            prevent_dos_attack $@
            show_firewall_status
            ;;
        10|'port-forwarding')
            port_forwarding $@
            show_firewall_status
            ;;
        11|'stop-port-forwarding')
            stop_port_forwarding $@
            show_firewall_status
            ;;
        12|'block-access-to-website')
            block_access_to_website $@
            show_firewall_status
            ;;
        13|'allow-ping-from-outside')
            allow_ping_from_outside $@
            show_firewall_status
            ;;
        14|'allow-ping-to-outside')
            allow_ping_to_outside $@
            show_firewall_status
            ;;
        15|'allow-all-incomming-ssh')
            allow_all_incomming_ssh $@
            show_firewall_status
            ;;
        16|'allow-incomming-ssh-from-ipv4-network')
            allow_incomming_ssh_from_ipv4_or_network $@
            show_firewall_status
            ;;
        17|'allow-outgoing-ssh')
            allow_outgoing_ssh $@
            show_firewall_status
            ;;
        18|'allow-outgoing-ssh-to-ipv4-network')
            allow_outgoing_ssh_to_ipv4_or_network $@
            show_firewall_status
            ;;
        19|'allow-http-web-traffic')
            allow_http_web_traffic $@
            show_firewall_status
            ;;
        20|'allow-https-web-traffic')
            allow_https_web_traffic $@
            show_firewall_status
            ;;
        21|'allow-incomming-multiport')
            allow_incomming_on_multiple_ports $@
            show_firewall_status
            ;;
        22|'load-balance-web-traffic')
            load_balance_web_traffic $@
            show_firewall_status
            ;;
        23|'allow-outbound-dns')
            allow_outbound_dns $@
            show_firewall_status
            ;;
        24|'allow-inbound-smtp-email')
            allow_inbound_smtp_email_traffic $@
            show_firewall_status
            ;;
        25|'allow-inbound-pop3-email')
            allow_inbound_pop3_email_traffic $@
            show_firewall_status
            ;;
        26|'port-forward-hide-source')
            port_forwarding_hide_source_behind_host $@
            show_firewall_status
            ;;
        27|'access-extranet-with-intranet-msg-of-snat')
            acces_external_network_with_intranet_message_of_snat $@
            show_firewall_status
            ;;
        28|'access-extranet-with-extranet-msg-of-dnat')
            access_external_network_with_extranet_message_of_dnat $@
            show_firewall_status
            ;;
        29|'dnat-and-snat')
            dnat_and_snat $@
            show_firewall_status
            ;;
        30|'display-iptables-rules')
            display_iptables_rules $@
            ;;
        31|'check-ipv4-rules')
            check_ipv4_exists_in_rule $@
            ;;
        32|'save-current-iptables-rules')
            save_current_iptables_rules $@
            ;;
        33|'restore-iptables-rules')
            restore_iptables_rules $@
            ;;
        -h|--help)
            display_usage $@
            ;;
        *)
            echo "[ WARNING ]: Invalid instruction! ($@)"
            ;;
    esac
    return $?
}

# DISPLAY

function exec_msg () {
    local MSG="$@"
    echo "[ EXEC ]: $MSG"
    return $?
}

function display_header () {
    echo "
    ___________________________________________________________________________

     *            *          ${SCRIPT_NAME} - Cheat Sheet         *            *
    _______________________________________________________v.${VERSION}_________
                        Regards, the Alveare Solutions society.
    "

}

function display_usage () {
    display_header
    cat <<EOF
 1. new-iptables-chain________________________<CHAIN-NAME>__________________________________________________iptables -N <chain-name>
 2. delete-existing-rules___________________________________________________________________________________iptables -F
 3. set-default-policies______________________<DROP|ACCEPT>_________________________________________________iptabels -P INPUT <policy>; iptabels -P FORWARD <policy>; iptabels -P OUTPUT <policy>
 4. show-firewall-status____________________________________________________________________________________iptables -L -n -v --line-numbers
 5. block-ipv4-subnet_________________________<IPv4|SUBNET-ADDRS>___________________________________________iptables -A INPUT -s <ipv4|subnet> -j DROP
 6. white-list-ipv4___________________________<INTERFACE> <IPv4-ADDRS>______________________________________iptables -A INPUT -i <interface> -s <ipv4-addrs> -j ACCEPT
 7. allow-loopback-access___________________________________________________________________________________iptables -A INPUT -i lo -j ACCEPT; iptables -A OUTPUT -o lo -j ACCEPT
 8. allow-mysql-from-network__________________<NETWORK> <INTERFACE> (SRC-PORT|3306) (DST-PORT|3306)_________iptables -A INPUT -i <interface> -p tcp -s <network> --dport <dst-port> -m state --state NEW,ESTABLISHED -j ACCEPT; iptables -A OUTPUT -o <interface> -p tcp --sport <src-port> -m state --state ESTABLISHED -j ACCEPT
 9. prevent-dos-attack________________________(PORT_NO|80)__________________________________________________iptables -A INPUT -p tcp --dport <port-no> -m limit --limit 25/minute --limit-burst 1000 -j ACCEPT
10. port-forwarding___________________________<INTERFACE> <SRC-IPv4> <DST-IPv4> (DST-PORT|80)_______________iptables -t nat -A PREROUTING -i <interface> -p tcp --dport <dst-port> -j DNAT --to <dst-ipv4>:<dst-port>; iptables -t nat -A POSTROUTING -p tcp --dst <dst-ipv4> --dport <dst-port> -j SNAT --to <src-ipv4>; iptables -t nat -A OUTPUT --dst <srv-ipv4> -p tcp --dport <dst-port> -j DNAT --to <dst-ipv4>:<dst-port>
11. stop-port-forwarding______________________<INTERFACE> <SRC-IPv4> <DST-IPv4> (DST-PORT|80)_______________iptables -t nat -D PREROUTING -i <interface> -p tcp --dport <dst-port> -j DNAT --to <dst-ipv4>:<dst-port>; iptables -t nat -D POSTROUTING -p tcp --dst <dst-ipv4> --dport <dst-port> -j SNAT --to <src-ipv4>; iptables -t nat -d OUTPUT --dst <srv-ipv4> -p tcp --dport <dst-port> -j DNAT --to <dst-ipv4>:<dst-port>
12. block-access-to-website___________________<REMOTE-ADDRS>________________________________________________iptables -A OUTPUT -p tcp -d <remote-address> -j DROP
13. allow-ping-from-outside_________________________________________________________________________________iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT; iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT
14. allow-ping-to-outside___________________________________________________________________________________iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT; iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
15. allow-all-incomming-ssh___________________<INTERFACE> (PORT_NO|22)______________________________________iptables -A INPUT -i <interface> -p tcp --dport <port-no> -m state --state NEW,ESTABLISHED -j ACCEPT; iptables -A OUTPUT -o <interface> -p tcp --sport <port-no> -m state --state ESTABLISHED -j ACCEPT
16. allow-incomming-ssh-from-ipv4-network_____<INTERFACE> <SRC-IPv4|NETWORK> (SRC-PORT|22) (DST-PORT|22)____iptables -A INPUT -i <interface> -p tcp -s <src-ipv4|network> --dport <dst-port> -m state --state NEW,ESTABLISHED -j ACCEPT; iptables -A OUTPUT -o <interface> -p tcp --sport <src-port> -m state --state ESTABLISHED -j ACCEPT
17. allow-outgoing-ssh________________________<INTERFACE> (SRC-PORT|22) (DST-PORT|22)_______________________iptables -A OUTPUT -o <interface> -p tcp --dport <dst-port> -m state --state NEW,ESTABLISHED -j ACCEPT; iptables -A INPUT -i <interface> -p tcp --sport <src-port> -m state --state ESTABLISHED -j ACCEPT
18. allow-outgoing-ssh-to-ipv4-network________<INTERFACE> <SRC-IPv4|NETWORK> (SRC-PORT|22) (DST-PORT|22)____iptables -A OUTPUT -o <interface> -p tcp -d <src-ipv4|network> --dport <dst-port> -m state --state NEW,ESTABLISHED -j ACCEPT; iptables -A INPUT -i <interface> -p tcp --sport <src-port> -m state --state ESTABLISHED -j ACCEPT
19. allow-http_web-traffic____________________(SRC-PORT|80) (DST-PORT|80)___________________________________iptables -A INPUT -p tcp --dport <dst-port> -m state --state NEW,ESTABLISHED -j ACCEPT; iptables -A OUTPUT -p tcp --sport <src-port> -m state --state ESTABLISHED -j ACCEPT
20. allow-https_web-traffic___________________(SRC-PORT|443) (DST-PORT|443)_________________________________iptables -A INPUT -p tcp --dport <dst-port> -m state --state NEW,ESTABLISHED -j ACCEPT; iptables -A OUTPUT -p tcp --sport <src-port> -m state --state ESTABLISHED -j ACCEPT
21. allow-incomming-multiport_________________<INTERFACE> <SRC-PORT-CSV> (DST-PORT-CSV|SRC-PORT-CSV)________iptables -A INPUT -i <interface> -p tcp -m multiport --dports <dst-port-csv> -m state --state NEW,ESTABLISHED -j ACCEPT; iptables -A OUTPUT -o <interface> -p tcp -m multiport --sports <src-port-csv> -m state --state ESTABLISHED -j ACCEPT
22. allow-outbound-dns________________________<INTERFACE> (SRC-PORT|53) (DST-PORT|53)_______________________iptables -A OUTPUT -p udp -o <interface> --dport <dst-port> -j ACCEPT; iptables -A INPUT -p udp -i <interface> --sport <src-port> -j ACCEPT
23. allow-inbound-smtp_email__________________(SRC-PORT|25) (DST-PORT|25)___________________________________iptables -A INPUT -p tcp --dport <dst-port> -m state --state NEW,ESTABLISHED -j ACCEPT; iptables -A OUTPUT -p tcp --sport <src-port> -m state --state ESTABLISHED -j ACCEPT
24. allow-inbound-pop3_email__________________(SRC-PORT|110) (DST-PORT|110)_________________________________iptables -A INPUT -p tcp --dport <dst-port> -m state --state NEW,ESTABLISHED -j ACCEPT; iptables -A OUTPUT -p tcp --sport <src-port> -m state --state ESTABLISHED -j ACCEPT
25. load-balance-web-traffic__________________<DST-PORT> <IPv4-ADDR1> <IPv4-ADDR2>..._______________________iptables -A PREROUTING -p tcp --dport <dst-port> -m state -m nth --every 3 --packet <ipv4-index> -j DNAT --to-destination <ipv4-addrs>
26. port-forwarding-hide-source_______________<PROXY-IPv4> <HOST-IPv4>______________________________________iptables -t nat -A POSTROUTING -s <proxy-ipv4> -j SNAT --to-source <host-ip>; iptables -t nat -A POSTROUTING -j MASQUERADE; echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf; sysctl -p; echo 1 > /proc/sys/net/ipv4/ip_forward
27. access-extranet-with-intranet-msg-of-snat_<NETWORK> <DST-IPv4>__________________________________________iptables -t nat -I POSTROUTING -s <network> -j SNAT --to <dst-ipv4>
28. access-extranet-with-extranet-msg-of-dnat_<NETWORK> <DST-IPv4> <DST-PORT>_______________________________iptables -t nat -I PREROUTING -d <network> -p tcp --dport <dst-port> -j NAT --to <dst-ipv4>:<dst-port>
29. dnat-and-snat_____________________________<NETWORK> <DST-IPv4>__________________________________________iptables -t nat -I POSTROUTING -s <network> -j SNAT --to <dst-ipv4>
30. display-iptables-rules__________________________________________________________________________________iptables -L || cat /etc/sysconfig/iptable
31. check-ipv4-rules__________________________<IPv4-ADDRS>__________________________________________________iptables -nL | grep <ipv4-addrs>
32. save-current-iptables-rules_______________<FILE-PATH>___________________________________________________iptables-save > <file-path>
33. restore-iptables-rules____________________<FILE-PATH>___________________________________________________iptables-restore < <file-path>
-h | --help_________________________________________________________________________________________________Display this message.

[ EXAMPLE ]: `basename $0` block-ipv4-subnet 192.168.0.0/24
[ EXAMPLE ]: `basename $0` 5 192.168.0.0/24
[ EXAMPLE ]: `basename $0` port-forwarding wlan0 192.168.0.2 192.168.0.3 22
[ EXAMPLE ]: `basename $0` allow-incomming-multiport wlan0 22,80,443

EOF
}

# MISCELLANEOUS

if [ $EUID -ne 0 ]; then
    echo "[ WARNING ]: `basename $0` requires elevated priviledges. Are you root?"
fi

init_cheat_sheet $@
exit $?

# CODE DUMP

