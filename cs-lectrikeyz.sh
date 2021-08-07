#!/bin/bash
#
# Regards, the Alveare Solutions society -
#
# Lectrik Eyz (a.k.a. L:Eyz) - Cheat Sheet

SCRIPT_NAME='Lectrik:Eyz'
VERSION='Cnx:D/DoTZ'
VERSION_NO='1.0'
CATEGORY='Cheat Sheet'

# CHEATERS

function check_ip_address_blocked () {
    local IPV4_ADDRESS="$2"
    exec_msg "route -n | grep $IPV4_ADDRESS"
    route -n | grep "$IPV4_ADDRESS"
    return $?
}

function block_ip_address () {
    local IPV4_ADDRESS="$2"
    exec_msg "route add "$IPV4_ADDRESS" reject"
    route add "$IPV4_ADDRESS" reject
#   iptables -A INPUT 1 -s "$ADDRESS" -j DROP/REJECT
#   service iptables restart
#   service iptables save
#   killall -KILL httpd
#   service httpd startssl
    return $?
}

function fetch_connected_ipv4_addresses () {
    exec_msg "netstat -ntu | awk '{print $5}' | cut -d: -f1 -s | sort | uniq -c | sort -nk1 -r"
    netstat -ntu | awk '{print $5}' | cut -d: -f1 -s | sort | uniq -c | sort -nk1 -r
    return $?
}

function fetch_number_of_logical_processor_threads () {
    exec_msg "grep processor /proc/cpuinfo | wc -l"
    grep processor /proc/cpuinfo | wc -l
    return $?
}

function get_https_traffic () {
    exec_msg "tcpdump -nnSX port 443"
    tcpdump -nnSX port 443
    return $?
}

function everything_on_interface () {
    local INTERFACE="$2" # [ex]: (eth0 | wlan0)
    exec_msg "tcpdump -i $INTERFACE"
    tcpdump -i $INTERFACE
    return $?
}

function find_traffic_by_ip () {
#   Find Traffic by IP: One of the most common queries, using host, you can see
#   traffic that’s going to or from 1.1.1.1.
    local ADDRESS="$2"
    exec_msg "tcpdump host $ADDRESS"
    tcpdump host $ADDRESS
    return $?
}

function filtering_by_source_and_or_destination () {
    local TARGET="$2" # [ex]: (src | dst)
    local IPV4_ADDRESS="$3" # [ex]: 1.1.1.1
    exec_msg "tcpdump $TARGET $IPV4_ADDRESS"
    tcpdump $TARGET $IPV4_ADDRESS
    return $?
}

function find_packets_by_network () {
#   Finding Packets by Network: To find packets going to or from a particular
#   network or subnet, use the net option.
    local NETWORK="$2" # [ex]: 1.2.3.0/24
    exec_msg "tcpdump net $NETWORK"
    tcpdump net $NETWORK
    return $?
}

function get_packet_contents_with_hex_output () {
    exec_msg "tcpdump -c 1 -X icmp"
    tcpdump -c 1 -X icmp
    return $?
}

function show_traffic_related_to_a_specific_port () {
    local TARGET=$2  # [ex]: (src | dst | <port-no>)
    local PORT_NO=$3 # [ex]: 8080
    if [[ "$TARGET" != 'src' ]] && [[ "$TARGET" != 'dst' ]]; then
        local PORT_NO=$TARGET
        exec_msg "tcpdump port $PORT_NO"
        tcpdump port $PORT_NO
    else
        exec_msg "tcpdump $TARGET port $PORT_NO"
        tcpdump $TARGET port $PORT_NO
    fi
    return $?
}

function show_traffic_of_one_protocol () {
    local PROTOCOL="$2" # [ex]: icmp
    exec_msg "tcpdump $PROTOCOL"
    tcpdump $PROTOCOL
    return $?
}

function show_only_ip6_traffic () {
    exec_msg "tcpdump ip6"
    tcpdump ip6
    return $?
}

function find_traffic_using_port_ranges () {
    local PORT_RANGE="$2" # [ex]: 21-24)
    exec_msg "tcpdump portrange $PORT_RANGE"
    tcpdump portrange "$PORT_RANGE"
    return $?
}

function find_traffic_based_on_packet_size () {
    local COMPARISON="$2" # [ex]: (less | greater | <=)
    local VALUE="$3" # [ex]: 42
    exec_msg "tcpdump $COMPARISON $VALUE"
    tcpdump "$COMPARISON" $VALUE
    return $?
}

function read_pcap_file () {
    # You can read PCAP files by using the -r switch. Note that you can use all the
    # regular commands within tcpdump while reading in a file; you’re only limited by
    # the fact that you can’t capture and process what doesn’t exist in the file already.
    local CAPTURE_FILE_PATH="$2"
    exec_msg "tcpdump -r $CAPTURE_FILE_PATH"
    tcpdump -r $CAPTURE_FILE_PATH
    return $?
}

function raw_output_view () {
    exec_msg "tcpdump -ttnnvvS"
    tcpdump -ttnnvvS
    return $?
}

function from_specific_ip_and_destined_for_a_specific_port () {
    local IPV4_ADDRS="$2" # [ex]: 10.5.2.3
    local PORT_NO="$3" # [ex]: 3389
    exec_msg "tcpdump -nnvvS src $IPV4_ADDRS and dst port $PORT_NO"
    tcpdump -nnvvS src $IPV4_ADDRS and dst port $PORT_NO
    return $?
}

function from_one_network_to_another () {
    local SRC_NETWORK="$2" # [ex]: 192.168.0.0/16
    local DST_NETWORK="$3" # [ex]: 10.0.0.0/8
    exec_msg "tcpdump -nvX src net $SRC_NETWORK and dst net $DST_NETWORK"
    tcpdump -nvX src net $SRC_NETWORK and dst net $DST_NETWORK
    return $?
}

function non_icmp_traffic_going_to_a_specific_ip () {
    local IPV4_ADDRS="$2" # [ex]: 192.168.0.2
    exec_msg "tcpdump dst $IPV4_ADDRS and not icmp"
    tcpdump dst $IPV4_ADDRS and not icmp
    return $?
}

function isolate_tcp_rst_flags () {
    exec_msg "tcpdump 'tcp[tcpflags] == tcp-rst'"
    tcpdump 'tcp[tcpflags] == tcp-rst'
#   tcpdump 'tcp[13] & 4!=0'
    return $?
}

function isolate_tcp_syn_flags () {
    exec_msg "tcpdump 'tcp[tcpflags] == tcp-syn'"
    tcpdump 'tcp[tcpflags] == tcp-syn'
#   tcpdump 'tcp[13] & 2!=0'
    return $?
}

function isolate_packets_that_have_both_the_syn_and_ack_flags_set () {
    exec_msg "tcpdump 'tcp[13]=18'"
    tcpdump 'tcp[13]=18'
    return $?
}

function isolate_tcp_urg_flags () {
    exec_msg "tcpdump 'tcp[tcpflags] == tcp-urg'"
    tcpdump 'tcp[tcpflags] == tcp-urg'
#   tcpdump 'tcp[13] & 32!=0'
    return $?
}

function isolate_tcp_ack_flags () {
    exec_msg "tcpdump 'tcp[tcpflags] == tcp-ack'"
    tcpdump 'tcp[tcpflags] == tcp-ack'
#   tcpdump 'tcp[13] & 16!=0'
    return $?
}

function isolate_tcp_psh_flags () {
    exec_msg "tcpdump 'tcp[tcpflags] == tcp-push'"
    tcpdump 'tcp[tcpflags] == tcp-push'
#   tcpdump 'tcp[13] & 8!=0'
    return $?
}

function isolate_tcp_fin_flags () {
    exec_msg "tcpdump 'tcp[tcpflags] == tcp-fin'"
    tcpdump 'tcp[tcpflags] == tcp-fin'
#   tcpdump 'tcp[13] & 1!=0'
    return $?
}

function find_both_syn_and_rst_set () {
    exec_msg "tcpdump 'tcp[13] = 6'"
    tcpdump 'tcp[13] = 6'
    return $?
}

function find_http_user_agents () {
    exec_msg "tcpdump -vvAls0 | grep 'User-Agent:'"
    tcpdump -vvAls0 | grep 'User-Agent:'
    return $?
}

function find_cleartext_get_requests () {
    exec_msg "tcpdump -vvAls0 | grep 'GET'"
    tcpdump -vvAls0 | grep 'GET'
    return $?
}

function find_http_host_headers () {
    exec_msg "tcpdump -vvAls0 | grep 'Host:'"
    tcpdump -vvAls0 | grep 'Host:'
    return $?
}

function find_http_cookies () {
    exec_msg "tcpdump -vvAls0 | grep 'Set-Cookie|Host:|Cookie:'"
    tcpdump -vvAls0 | grep 'Set-Cookie|Host:|Cookie:'
    return $?
}

function find_ssh_connections () {
    exec_msg "tcpdump 'tcp[(tcp[12]>>2):4] = 0x5353482D'"
    tcpdump 'tcp[(tcp[12]>>2):4] = 0x5353482D'
    return $?
}

function find_dns_traffic () {
    exec_msg "tcpdump -vvAs0 port 53"
    tcpdump -vvAs0 port 53
    return $?
}

function find_ftp_traffic () {
    exec_msg "tcpdump -vvAs0 port ftp or ftp-data"
    tcpdump -vvAs0 port ftp or ftp-data
    return $?
}

function find_ntp_traffic () {
    exec_msg "tcpdump -vvAs0 port 123"
    tcpdump -vvAs0 port 123
    return $?
}

function find_cleartext_passwords () {
    exec_msg "tcpdump port http or port ftp or port smtp or port imap or port pop3 or port \\
        telnet -lA | egrep -i -B5 'pass=|pwd=|log=|login=|user=|username=|pw=|passw=|passwd= |\\
        password=|pass:|user:|username:|password:|login:|pass |user '"
    tcpdump port http or port ftp or port smtp or port imap or port pop3 or port \
        telnet -lA | egrep -i -B5 'pass=|pwd=|log=|login=|user=|username=|pw=|passw=|passwd= |\
        password=|pass:|user:|username:|password:|login:|pass |user '
    return $?
}

function find_traffic_with_evil_bit () {
    exec_msg "tcpdump 'ip[6] & 128 != 0'"
    tcpdump 'ip[6] & 128 != 0'
    return $?
}


function find_who_has_maximum_access_to_server () {
#   We can detect the URL that is referred maximum in the server while DDOS attack,
#   using the tcpdump command. By the following netstat command, we will be able to
#   get the IP address that is having maximum access in the server.
    exec_msg "netstat -plane | grep :80 | awk {'print $5'} | cut -d ':' -f1 | sort -n | uniq -c | sort -n"
    netstat -plane | grep :80 | awk {'print $5'} | cut -d ':' -f1 | sort -n | uniq -c | sort -n
#   This will list the IP address as follows: number  — IP address
    return $?
}

function check_connection_from_source_ip () {
#   From this take the IP address that is having maximum access and check the connection
#   from this source IP address using the following command.
    local IPV4_ADDR="$2"
    exec_msg "tcpdump -A src $IPV4_ADDR -s 500 | grep -i refer"
    tcpdump -A src "$IPV4_ADDR" -s 500 | grep -i refer
#   -A  - is used to print the output in ASCII format
#   src - specify the source IP address here
#   s   - to specify the number of hops
#   -c  - can also be used to limit the count to a particular value.
    return $?
}

function check_connection_from_destination_ip () {
    local IPV4_ADDR="$2"
    exec_msg "tcpdump -A dst $IPV4_ADDR -s 500 | grep -i refer"
    tcpdump -A dst "$IPV4_ADDR" -s 500 | grep -i refer
    return $?
}

# DISPLAY

function exec_msg () {
    echo "[ EXEC ]: $@"
    return $?
}

function display_header () {
    cat<<EOF
    _______________________________________________________________________________

    *                       *  ${SCRIPT_NAME} CheatSheet  *                      *
    _____________________________________________________v.${VERSION}______________
                    Regards, the Alveare Solutions #!/Society -x

EOF
    return $?
}

function display_usage () {
    display_header
    cat<<EOF
 1. find-traffic-with-evil-bit_____________________________________________________tcpdump 'ip[6] & 128 != 0'
 2. find-cleartext-passwords_______________________________________________________tcpdump port http or port ftp or port smtp or port imap or port pop3 or port \\
                                                                               telnet -lA | egrep -i -B5 'pass=|pwd=|log=|login=|user=|username=|pw=|passw=|passwd= |\\
                                                                               password=|pass:|user:|username:|password:|login:|pass |user '
 3. find-ntp-traffic_______________________________________________________________tcpdump -vvAs0 port 123
 4. find-ftp-traffic_______________________________________________________________tcpdump -vvAs0 port ftp or ftp-data
 5. find-dns-traffic_______________________________________________________________tcpdump -vvAs0 port 53
 6. find-ssh-cnx___________________________________________________________________tcpdump 'tcp[(tcp[12]>>2):4] = 0x5353482D'
 7. find-http-cookies______________________________________________________________tcpdump -vvAls0 | grep 'Set-Cookie|Host:|Cookie:'
 8. find-http-host-headers_________________________________________________________tcpdump -vvAls0 | grep 'Host:'
 9. find-cleartext-get-requests____________________________________________________tcpdump -vvAls0 | grep 'GET'
10. find-http-user-agents__________________________________________________________tcpdump -vvAls0 | grep 'User-Agent:'
11. find-both-syn-and-rst-set______________________________________________________tcpdump 'tcp[13] = 6'
12. find-traffic-based-on-packet-size_____________<OPERATOR> <PACKET-SIZE>_________tcpdump <comparison-operator> <packet-size>
13. find-traffic-using-port-range_________________<START-PORT>-<END-PORT>__________tcpdump portrange <start-port>-<end-port>
14. find-packets-by-network_______________________<NETWORK>________________________tcpdump net <network>
15. find-traffic-by-ip____________________________<IPv4-ADDRESS>___________________tcpdump host <ipv4-address>
16. isolate-tcp-rst-flags__________________________________________________________tcpdump 'tcp[tcpflags] == tcp-rst'
17. isolate-tcp-syn-flags__________________________________________________________tcpdump 'tcp[tcpflags] == tcp-syn'
18. isolate-syn-and-ack-flags-set__________________________________________________tcpdump 'tcp[13]=18'
19. isolate-tcp-urg-flags__________________________________________________________tcpdump 'tcp[tcpflags] == tcp-urg'
20. isolate-tcp-ack-flags__________________________________________________________tcpdump 'tcp[tcpflags] == tcp-ack'
21. isolate-tcp-psh-flags__________________________________________________________tcpdump 'tcp[tcpflags] == tcp-push'
22. isolate-tcp-fin-flags__________________________________________________________tcpdump 'tcp[tcpflags] == tcp-fin'
23. show-only-ipv6-traffic_________________________________________________________tcpdump ip6
24. show-traffic-of-protocol______________________<PROTOCOL>_______________________tcpdump <protocol>
25. show-traffic-on-port__________________________<TARGET(optional)> <PORT-NO>_____tcpdump <target (optional)> port <port-no>
26. check-cnx-from-dst-ip_________________________<IPv4-ADDRESS>___________________tcpdump -A dst <ipv4-address> -s 500 | grep -i refer
27. check-ip-addr-blocked_________________________<IPv4-ADDRESS>___________________route -n | grep <address>
28. check-cnx-from-src-ip_________________________<IPv4-ADDRESS>___________________tcpdump -A src <ipv4-address> -s 500 | grep -i refer
29. from-one-network-to-another___________________<SRC-NET> <DST-NET>______________tcpdump -nvX src net <src-network> and dst net <dst-network>
30. from-specific-ip-and-dst-for-specific-port____<IPv4-ADDRESS> <PORT-NO>_________tcpdump -nnvvS src <ipv4-addrs> and dst port <port-no>
31. fetch-connected-ipv4-addrs_____________________________________________________netstat -ntu | awk '{print $5}' | cut -d: -f1 -s | sort | uniq -c | sort -nk1 -r
32. non-icmp-traffic-going-to-ip__________________<IPv4-ADDRESS>___________________tcpdump dst <ipv4-addrs> and src net and not icmp
33. raw-output-view________________________________________________________________tcpdump -ttnnvvS
34. read-pcap-file________________________________<FILE-PATH>______________________tcpdump -r <file-path>
35. who-has-maximum-access-to-server_______________________________________________netstat -plane | grep :80 | awk {'print $5'} | cut -d ':' -f1 | sort -n | uniq -c | sort -n
36. get-packet-contents-hex-output_________________________________________________tcpdump -c 1 -X icmp
37. filter-by-src-dst-addr________________________<TARGET> <IPv4-ADDRESS>__________tcpdump <target> <ipv4-address>
38. everything-on-interface_______________________<INTERFACE>______________________tcpdump -i <interface>
39. get-https-traffic______________________________________________________________tcpdump -nnSX port 443
40. count-logical-processor-threads________________________________________________grep processor /proc/cpuinfo | wc -l
41. block-ip-addr_________________________________<IPv4-ADDRESS>___________________route add <ipv4-address> reject
-h | --help________________________________________________________________________Display this message.

[ EXAMPLE ]: ~$ ./`basename $0` find-traffic-using-port-range 21-25
[ EXAMPLE ]: ~$ ./`basename $0` find-traffic-based-on-packet-size less 112
[ EXAMPLE ]: ~$ ./`basename $0` 12 greater 35
[ EXAMPLE ]: ~$ ./`basename $0` from-one-network-to-another 192.168.0.0/16 10.0.0.0/8
[ EXAMPLE ]: ~$ ./`basename $0` find-ssh-cnx

EOF
}

# INIT

function init_cheatsheet () {
    for opt in $@; do
        case "$opt" in
            -h|--help)
                display_usage; exit $?
                ;;
            1|'find-traffic-with-evil-bit')
                find_traffic_with_evil_bit $@
                ;;
            2|'find-cleartext-passwords')
                find_cleartext_passwords $@
                ;;
            3|'find-ntp-traffic')
                find_ntp_traffic $@
                ;;
            4|'find-ftp-traffic')
                find_ftp_traffic $@
                ;;
            5|'find-dns-traffic')
                find_dns_traffic $@
                ;;
            6|'find-ssh-cnx')
                find_ssh_connections $@
                ;;
            7|'find-http-cookies')
                find_http_cookies $@
                ;;
            8|'find-http-host-headers')
                find_http_host_headers $@
                ;;
            9|'find-cleartext-get-requests')
                find_cleartext_get_requests $@
                ;;
            10|'find-http-user-agents')
                find_http_user_agents $@
                ;;
            11|'find-both-syn-and-rst-set')
                find_both_syn_and_rst_set $@
                ;;
            12|'find-traffic-based-on-packet-size')
                find_traffic_based_on_packet_size $@
                ;;
            13|'find-traffic-using-port-range')
                find_traffic_using_port_ranges $@
                ;;
            14|'find-packets-by-network')
                find_packets_by_network $@
                ;;
            15|'isolate-tcp-rst-flags')
                isolate_tcp_rst_flags $@
                ;;
            16|'find-traffic-by-ip')
                find_traffic_by_ip $@
                ;;
            17|'isolate-tcp-syn-flags')
                isolate_tcp_syn_flags $@
                ;;
            18|'isolate-syn-and-ack-flags-set')
                isolate_packets_that_have_both_the_syn_and_ack_flags_set $@
                ;;
            19|'isolate-tcp-urg-flags')
                isolate_tcp_urg_flags $@
                ;;
            20'isolate-tcp-ack-flags')
                isolate_tcp_ack_flags $@
                ;;
            21|'isolate-tcp-psh-flags')
                isolate_tcp_psh_flags $@
                ;;
            22|'isolate-tcp-fin-flags')
                isolate_tcp_fin_flags $@
                ;;
            23|'show-only-ipv6-traffic')
                show_only_ip6_traffic $@
                ;;
            24|'show-traffic-of-protocol')
                show_traffic_of_one_protocol $@
                ;;
            25|'show-traffic-on-port')
                show_traffic_related_to_a_specific_port $@
                ;;
            26|'check-cnx-from-dst-ip')
                check_connection_from_destination_ip $@
                ;;
            27|'check-ip-addr-blocked')
                check_ip_address_blocked $@
                ;;
            28|'check-cnx-from-src-ip')
                check_connection_from_source_ip $@
                ;;
            29|'from-one-network-to-another')
                from_one_network_to_another $@
                ;;
            30|'from-specific-ip-and-dst-for-specific-port')
                from_specific_ip_and_destined_for_a_specific_port $@
                ;;
            31|'fetch-connected-ipv4-addrs')
                fetch_connected_ipv4_addresses $@
                ;;
            32|'non-icmp-traffic-going-to-ip')
                non_icmp_traffic_going_to_a_specific_ip $@
                ;;
            33|'raw-output-view')
                raw_output_view $@
                ;;
            34|'read-pcap-file')
                read_pcap_file $@
                ;;
            35|'who-has-maximum-access-to-server')
                find_who_has_maximum_access_to_server $@
                ;;
            36|'get-packet-contents-hex-output')
                get_packet_contents_with_hex_output $@
                ;;
            37|'filter-by-src-dst-addr')
                filtering_by_source_and_or_destination $@
                ;;
            38|'everything-on-interface')
                everything_on_interface $@
                ;;
            39|'get-https-traffic')
                get_https_traffic $@
                ;;
            40|'count-logical-processor-threads')
                fetch_number_of_logical_processor_threads $@
                ;;
            41|'block-ip-addr')
                block_ip_address $@
                ;;
        esac
    done
    return $?
}

# MISCELLANEOUS

if [ $# -eq 0 ]; then
    display_usage
    exit 1
fi

init_cheatsheet $@
exit $?

# CODE DUMP

