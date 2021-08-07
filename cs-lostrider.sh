#!/bin/bash
#
# Regards, the Alveare Solutions society -
#
# CHEAT SHEET

SCRIPT_NAME='LosTRider'
VERSION='sCanDrone'
VERSION_NO='1.0'

function scan_random_hosts () {
    local HOST_COUNT=${2:-100}
    exec_msg "nmap -iR $HOST_COUNT"
    nmap -iR $HOST_COUNT
    return $?
}

function scan_machine () {
    local IPv4_ADDRESSES=( ${@:2} ) # [ex]: 192.168.1.1 192.168.1.1-254 192.168.1.0/24
    exec_msg "nmap ${IPv4_ADDRESSES[@]}"
    nmap ${IPv4_ADDRESSES[@]}
    return $?
}

function scan_machine_no_dns () {
    local IPv4_ADDRESSES=( ${@:2} ) # [ex]: 192.168.1.1 192.168.1.1-254 192.168.1.0/24
    exec_msg "nmap ${IPv4_ADDRESSES[@]} -n"
    nmap ${IPv4_ADDRESSES[@]} -n
    return $?
}

function scan_machines_from_file () {
    local FILE_PATH="$2"
    nmap -iL "$FILE_PATH"
    return $?
}

function scan_using_fragmented_packets () {
    local IPv4_ADDRS="$2"
    exec_msg "nmap $IPv4_ADDRS -f"
    nmap "$IPv4_ADDRS" -f
    return $?
}

function scan_using_decoy_ips () {
    local IPv4_ADDRS="$2"
    local DECOY_IPv4_CSV="$3"
    nmap -D "$DECOY_IPv4_CSV" "$IPv4_ADDRS"
    return $?
}

function scan_from_decoy_machine () {
    local INTERFACE="$2"
    local DNS_DOMAIN="$3"
    local DECOY_DNS="$4"
    exec_msg "nmap -e $INTERFACE -Pn -S $DECOY_DNS $DNS_DOMAIN"
    nmap -e "$INTERFACE" -Pn -S "$DECOY_DNS" "$DNS_DOMAIN"
    return $?
}

function scan_from_source_port () {
    local IPv4_ADDRS="$2"
    local SRC_PORT=$3
    exec_msg "nmap -g $SRC_PORT $IPv4_ADDRS"
    nmap -g $SRC_PORT "$IPv4_ADDRS"
    return $?
}

function scan_through_http_socks4_proxy () {
    local IPv4_ADDRS="$2"
    local PROXY_CSV="$3" # [ex]: http://192.168.1.1:8080,http://192.168.1.2:8080
    exec_msg "nmap --proxies $PROXY_CSV $IPv4_ADDRS"
    nmap --proxies "$PROXY_CSV" "$IPv4_ADDRS"
    return $?
}

function scan_with_random_data_appended_to_packets () {
    local IPv4_ADDRS="$2"
    local DATA_LENGTH=$3
    exec_msg "nmap --data-length $DATA_LENGTH $IPv4_ADDRS"
    nmap --data-length $DATA_LENGTH "$IPv4_ADDRS"
    return $?
}

function scan_in_debug_mode () {
    local IPv4_ADDRS="$2"
    exec_msg "nmap $IPv4_ADDRS -dd"
    nmap "$IPv4_ADDRS" -dd
    return $?
}

function scan_running_web_servers () {
    local IPv4_RANGE="$2"
    exec_msg "nmap -p80 -sV -oG - --open $IPv4_RANGE | grep open"
    nmap -p80 -sV -oG - --open "$IPv4_RANGE" | grep 'open'
    return $?
}

function scan_machine_ipv6 () {
    local IPv6_ADDRS="$2"
    exec_msg "nmap -6 $IPv6_ADDRS"
    nmap -6 "$IPv6_ADDRS"
    return $?
}

function machine_port_scan () {
    local IPv4_ADDRS="$2"
    local PORT_CSV="$3" # [ex]: 95,100-110,U:53,T:21-25,http,https
    exec_msg "nmap "$IPv4_ADDRS" -p $PORT_CSV"
    nmap "$IPv4_ADDRS" -p $PORT_CSV
    return $?
}

function tcp_syn_port_scan () {
    local IPv4_ADDRS="$2"
    exec_msg "nmap $IPv4_ADDRS -sS"
    nmap "$IPv4_ADDRS" -sS
    return $?
}

function tcp_cnx_port_scan () {
    local IPv4_ADDRS="$2"
    exec_msg "nmap $IPv4_ADDRS -sT"
    nmap "$IPv4_ADDRS" -sT
    return $?
}

function udp_port_scan () {
    local IPv4_ADDRS="$2"
    exec_msg "nmap $IPv4_ADDRS -sU"
    nmap "$IPv4_ADDRS" -sU
    return $?
}

function tcp_ack_port_scan () {
    local IPv4_ADDRS="$2"
    exec_msg "nmap $IPv4_ADDRS -sA"
    nmap "$IPv4_ADDRS" -sA
    return $?
}

function tcp_window_port_scan () {
    local IPv4_ADDRS="$2"
    exec_msg "nmap $IPv4_ADDRS -sW"
    nmap "$IPv4_ADDRS" -sW
    return $?
}

function tcp_maimon_port_scan () {
    local IPv4_ADDRS="$2"
    exec_msg "nmap $IPv4_ADDRS -sM"
    nmap "$IPv4_ADDRS" -sM
    return $?
}

function host_discovery_no_port_scan () {
    local IPv4_RANGE="$2" # [ex]: 192.168.1.1/24
    exec_msg "nmap $IPv4_RANGE -sn"
    nmap "$IPv4_RANGE" -sn
    return $?
}

function port_scan_no_host_discovery () {
    local IPv4_RANGE="$2" # [ex]: 192.168.1.1-5
    exec_msg "nmap $IPv4_RANGE -Pn"
    nmap "$IPv4_RANGE" -Pn
    return $?
}

function tcp_syn_port_discovery () {
    local IPv4_RANGE="$2" # [ex]: 192.168.1.1-5
    local PORT_CSV="$3"
    exec_msg "nmap $IPv4_RANGE -PS ${PORT_CSV}"
    nmap "$IPv4_RANGE" -PS ${PORT_CSV}
    return $?
}

function tcp_ack_port_discovery () {
    local IPv4_RANGE="$2" # [ex]: 192.168.1.1-5
    local PORT_CSV="$3"
    exec_msg "nmap $IPv4_RANGE -PA ${PORT_CSV}"
    nmap "$IPv4_RANGE" -PA ${PORT_CSV}
    return $?
}

function udp_port_discovery () {
    local IPv4_RANGE="$2" # [ex]: 192.168.1.1-5
    local PORT_CSV="$3"
    exec_msg "nmap $IPv4_RANGE -PU ${PORT_CSV}"
    nmap "$IPv4_RANGE" -PU ${PORT_CSV}
    return $?
}

function arp_discovery () {
    local IPv4_RANGE="$2" # [ex]: 192.168.1.1-1/24
    exec_msg "nmap $IPv4_RANGE -PR"
    nmap "$IPv4_RANGE" -PR
    return $?
}

function scan_all_ports () {
    local IPv4_ADDRS="$2"
    exec_msg "nmap $IPv4_ADDRS -p-"
    nmap "$IPv4_ADDRS" -p-
    return $?
}

function fast_port_scan_top_100 () {
    local IPv4_ADDRS="$2"
    exec_msg "nmap $IPv4_ADDRS -F"
    nmap "$IPv4_ADDRS" -F
    return $?
}

function scan_top_ports () {
    local IPv4_ADDRS="$2"
    local PORT_COUNT=${3:-100}
    exec_msg "nmap $IPv4_ADDRS --top-ports $PORT_COUNT"
    nmap "$IPv4_ADDRS" --top-ports $PORT_COUNT
    return $?
}

function scan_service_version () {
    local IPv4_ADDRS="$2"
    local INTENSITY=${3:-9}
    exec_msg "nmap $IPv4_ADDRS -sV --version-intensity $INTENSITY"
    nmap "$IPv4_ADDRS" -sV --version-intensity $INTENSITY
    return $?
}

function light_scan_service_version () {
    local IPv4_ADDRS="$2"
    exec_msg "nmap $IPv4_ADDRS -sV --version-light"
    nmap "$IPv4_ADDRS" -sV --version-light
    return $?
}

function scan_all_service_versions () {
    local IPv4_ADDRS="$2"
    exec_msg "nmap $IPv4_ADDRS -sV --version-all"
    nmap "$IPv4_ADDRS" -sV --version-all
    return $?
}

function paranoid_scan () {
    local IPv4_ADDRS="$2"
    exec_msg "nmap $IPv4_ADDRS -T0"
    nmap "$IPv4_ADDRS" -T0
    return $?
}

function sneaky_scan () {
    local IPv4_ADDRS="$2"
    exec_msg "nmap $IPv4_ADDRS -T1"
    nmap "$IPv4_ADDRS" -T1
    return $?
}

function polite_scan () {
    local IPv4_ADDRS="$2"
    exec_msg "nmap $IPv4_ADDRS -T2"
    nmap "$IPv4_ADDRS" -T2
    return $?
}

function aggressive_scan () {
    local IPv4_ADDRS="$2"
    exec_msg "nmap $IPv4_ADDRS -A"
    nmap "$IPv4_ADDRS" -A
    return $?
}

function insane_scan () {
    local IPv4_ADDRS="$2"
    exec_msg "nmap $IPv4_ADDRS -T5"
    nmap "$IPv4_ADDRS" -T5
    return $?
}

function non_intrusive_scan () {
    local IPv4_ADDRS="$2"
    exec_msg "nmap $IPv4_ADDRS --script 'not intrusive'"
    nmap "$IPv4_ADDRS" --script "not intrusive"
    return $?
}

function list_machines_in_range () {
    local IPv4_RANGE="$2" # [ex]: 192.168.1.1-3
    exec_msg "nmap $IPv4_RANGE -sL"
    nmap "$IPv4_RANGE" -sL
    return $?
}

function tcp_ip_remote_os_detection () {
    local IPv4_ADDRS="$2"
    exec_msg "nmap $IPv4_ADDRS -O"
    nmap "$IPv4_ADDRS" -O
    return $?
}

function aggresive_remote_os_detection () {
    local IPv4_ADDRS="$2"
    exec_msg "nmap $IPv4_ADDRS -O --osscan-guess"
    nmap "$IPv4_ADDRS" -O --osscan-guess
    return $?
}

function fast_search_rand_web_servers () {
    exec_msg "nmap -n -Pn -p 80 --open -sV -vvv --script banner,http-title -iR 1000"
    nmap -n -Pn -p 80 --open -sV -vvv --script banner,http-title -iR 1000
    return $?
}

function brute_force_dns_subdomain () {
    local DNS_DOMAIN="$2"
    exec_msg "nmap -Pn --script=dns-brute $DNS_DOMAIN"
    nmap -Pn --script=dns-brute "$DNS_DOMAIN"
    return $?
}

function run_safe_smb_scripts () {
    local IPv4_ADDRS="$2"
    exec_msg "nmap -n -Pn -vv -O -sV --script smb-enum*,smb-ls,smb-mbenum,smb-os-discovery,smb-s*,smb-vuln*,smbv2* -vv $IPv4_ADDRS"
    nmap -n -Pn -vv -O -sV --script smb-enum*,smb-ls,smb-mbenum,smb-os-discovery,smb-s*,smb-vuln*,smbv2* -vv "$IPv4_ADDRS"
    return $?
}

function whois_query () {
    local DNS_DOMAIN="$2"
    exec_msg "nmap --script whois* $DNS_DOMAIN"
    nmap --script whois* "$DNS_DOMAIN"
    return $?
}

function detect_cross_site_scripting_vuln () {
    local DNS_DOMAIN="$2"
    exec_msg "nmap -p80 --script http-unsafe-output-escaping $DNS_DOMAIN"
    nmap -p80 --script http-unsafe-output-escaping "$DNS_DOMAIN"
    return $?
}

function detech_sql_injection_vuln () {
    local DNS_DOMAIN="$2"
    exec_msg "nmap -p80 --script http-sql-injection $DNS_DOMAIN"
    nmap -p80 --script http-sql-injection "$DNS_DOMAIN"
    return $?
}

function show_host_interfaces_and_routes () {
    exec_msg "map --iflist"
    nmap --iflist
    return $?
}

function traceroute_random_targets () {
    exec_msg "nmap -iR 10 -sn -traceroute"
    nmap -iR 10 -sn -traceroute
    return $?
}

function query_dns_server_for_host_range () {
    local DNS_SERV_IPv4="$2" # [ex]: 192.168.1.1
    local IPv4_RANGE="$3"    # [ex]: 192.168.1.1-50
    exec_msg "nmap $IPV4_RANGE -sL --dns-server $DNS_SERV_IPV4"
    nmap "$IPV4_RANGE" -sL --dns-server "$DNS_SERV_IPV4"
    return $?
}

# DISPLAY

function display_header () {
    echo "
    ___________________________________________________________________________

     *            *          ${SCRIPT_NAME} - Cheat Sheet         *            *
    _______________________________________________________v.${VERSION}_________
                        Regards, the Alveare Solutions society.
    "
    return $?
}

function display_usage () {
    display_header
    cat <<EOF
 1. scan-random-hosts________________(HOST-COUNT|100)___________________________nmap -iR <host-count>
 2. scan-machine_____________________<IPv4-ADDR1> <IPv4-ADDR2>..._______________nmap <ipv4-addr1> <ipv4-addr2>...
 3. scan-machine-no-dns______________<IPv4-ADDR1> <IPv4-ADDR2>..._______________nmap <ipv4-addr1> <ipv4-addr2>... -n
 4. scan-machines-from-file__________<FILE-PATH>________________________________nmap -iL <file-path>
 5. scan-using-fragmented-packets____<IPv4-ADDRS>_______________________________nmap <ipv4-addrs> -f
 6. scan-using-decoy-ips_____________<IPv4-ADDRS> <DECOY-IPv4-CSV>______________nmap -D <decoy-ipv4-csv> <ipv4-addrs>
 7. scan-from-decoy__________________<INTERFACE> <DNS-DOMAIN> <DECOY-DNS>_______nmap -e <interface> -Pn -S <decoy-dns> <dns-domain>
 8. scan-from-src-port_______________<IPv4-ADDRS> <SRC-PORT>____________________nmap -g <src-port> <ipv4-addrs>
 9. scan-through-http-socks4-proxy___<IPv4-ADDRS> <PROXY-CSV>___________________nmap --proxies <proxy-csv> <ipv4-addrs>
10. scan-with-random-data-to-packets_<IPv4-ADDRS> <DATA-LENGTH>_________________nmap --data-length <data-length> <ipv4-addrs>
11. scan-in-debug-mode_______________<IPv4-ADDRS>_______________________________nmap <ipv4-addrs> -dd
12. scan-running-web-servers_________<IPv4-RANGE>_______________________________nmap -p80 -sV -oG - --open <ipv4-range> | grep open
13. scan-machine-ipv6________________<IPv6-ADDRS>_______________________________nmap -6 <ipv6-addrs>
14. machine-port-scan________________<IPv4-ADDRS> <PORT-CSV>____________________nmap <ipv4-addrs> -p <port-csv>
15. tcp-syn-port-scan________________<IPv4-ADDRS>_______________________________nmap <ipv4-addrs> -sS
16. tcp-cnx-port-scan________________<IPv4-ADDRS>_______________________________nmap <ipv4-addrs> -sT
17. udp-port-scan____________________<IPv4-ADDRS>_______________________________nmap <ipv4-addrs> -sU
18. tcp-ack-port-scan________________<IPv4-ADDRS>_______________________________nmap <ipv4-addrs> -sA
19. tcp-window-port-scan_____________<IPv4-ADDRS>_______________________________nmap <ipv4-addrs> -sW
20. tcp-maimon-port-scan_____________<IPv4-ADDRS>_______________________________nmap <ipv4-addrs> -sM
21. host-discovery-no-port-scan______<IPv4-RANGE>_______________________________nmap <ipv4-range> -sn
22. port-scan-no-host-discovery______<IPv4-RANGE>_______________________________nmap <ipv4-range> -Pn
23. tcp-syn-port-discovery___________<IPv4-RANGE> <PORT-CSV>____________________nmap <ipv4-range> -PS<port-csv>
24. tcp-ack-port-discovery___________<IPv4-RANGE> <PORT-CSV>____________________nmap <ipv4-range> -PA<port-csv>
25. udp-port-discovery_______________<IPv4-RANGE> <PORT-CSV>____________________nmap <ipv4-range> -PU<port-csv>
26. arp-discovery____________________<IPv4-RANGE>_______________________________nmap <ipv4-range> -PR
27. scan-all-ports___________________<IPv4-ADDRS>_______________________________nmap <ipv4-addrs> -p-
28. fast-port-scan-top-100___________<IPv4-ADDRS>_______________________________nmap <ipv4-addrs> -F
29. scan-top-ports___________________<IPv4-ADDRS> (PORT-COUNT|100)______________nmap <ipv4-addrs> --top-ports <port-count>
30. scan-service-version_____________<IPv4-ADDRS> (INTENSITY|9)_________________nmap <ipv4-addrs> -sV --version-intensity <intensity>
31. light-scan-service-version_______<IPv4-ADDRS>_______________________________nmap <ipv4-addrs> -sV --version-light
32. scan-all-service-versions________<IPv4-ADDRS>_______________________________nmap <ipv4-addrs> -sV --version-all
33. paranoid-scan____________________<IPv4-ADDRS>_______________________________nmap <ipv4-addrs> -T0
34. sneaky-scan______________________<IPv4-ADDRS>_______________________________nmap <ipv4-addrs> -T1
35. polite-scan______________________<IPv4-ADDRS>_______________________________nmap <ipv4-addrs> -T2
36. aggressive-scan__________________<IPv4-ADDRS>_______________________________nmap <ipv4-addrs> -A
37. insane-scan______________________<IPv4-ADDRS>_______________________________nmap <ipv4-addrs> -T5
38. non-intrusive-scan_______________<IPv4-ADDRS>_______________________________nmap <ipv4-addrs> --script "not intrusive"
39. list-machines-in-range___________<IPv4-RANGE>_______________________________nmap <ipv4-range> -sL
40. tcp-ip-remote-os-detection_______<IPv4-ADDRS>_______________________________nmap <ipv4-addrs> -O
41. aggresive-remote-os-detection____<IPv4-ADDRS>_______________________________nmap <ipv4-addrs> -O --osscan-guess
42. fast-search-rand-web-servers________________________________________________nmap -n -Pn -p 80 --open -sV -vvv --script banner,http-title -iR 1000
43. brute-force-dns-subdomain________<DNS-DOMAIN>_______________________________nmap -Pn --script=dns-brute <dns-domain>
44. run-safe-smb-scripts_____________<IPv4-ADDRS>_______________________________nmap -n -Pn -vv -O -sV --script smb-enum*,smb-ls,smb-mbenum,smb-os-discovery,smb-s*,smb-vuln*,smbv2* -vv <ipv4-addrs>
45. whois-query______________________<DNS-DOMAIN>_______________________________nmap --script whois* <dns-domain>
46. detect-cross-site-scripting-vuln_<DNS-DOMAIN>_______________________________nmap -p80 --script http-unsafe-output-escaping <dns-domain>
47. detech-sql-injection-vuln________<DNS-DOMAIN>_______________________________nmap -p80 --script http-sql-injection <dns-domain>
48. show-host-interfaces-and-routes_____________________________________________nmap --iflist
49. traceroute-random-targets___________________________________________________nmap -iR 10 -sn -traceroute
50. query-dns-for-hosts______________<DNS-SERV-IPv4> <IPv4-RANGE>_______________nmap <ipv4-range> -sL --dns-server <dns-serv-ipv4>

[ EXAMPLE ]: ./`basename $0` scan-from-decoy wlan0 victim.com decoy.com
[ EXAMPLE ]: ./`basename $0` 9 192.168.0.2 http://192.168.0.3:8080,http://192.168.0.4:8080
[ EXAMPLE ]: ./`basename $0` detect-cross-site-scripting-vuln victim.com
[ EXAMPLE ]: ./`basename $0` query-dns-for-hosts 192.168.1.1 192.168.1.1-50

EOF
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
        -h|--help)
            display_usage
            ;;
        1|'scan-random-hosts')
            scan_random_hosts $@
            ;;
        2|'scan-machine')
            scan_machine $@
            ;;
        3|'scan-machine-no-dns')
            scan_machine_no_dns $@
            ;;
        4|'scan-machines-from-file')
            scan_machines_from_file $@
            ;;
        5|'scan-using-fragmented-packets')
            scan_using_fragmented_packets $@
            ;;
        6|'scan-using-decoy-ips')
            scan_using_decoy_ips $@
            ;;
        7|'scan-from-decoy')
            scan_from_decoy_machine $@
            ;;
        8|'scan-from-src-port')
            scan_from_source_port $@
            ;;
        9|'scan-through-http-socks4-proxy')
            scan_through_http_socks4_proxy $@
            ;;
        10|'scan-with-random-data-to-packets')
            scan_with_random_data_appended_to_packets $@
            ;;
        11|'scan-in-debug-mode')
            scan_in_debug_mode $@
            ;;
        12|'scan-running-web-servers')
            scan_running_web_servers $@
            ;;
        13|'scan-machine-ipv6')
            scan_machine_ipv6 $@
            ;;
        14|'machine-port-scan')
            machine_port_scan $@
            ;;
        15|'tcp-syn-port-scan')
            tcp_syn_port_scan $@
            ;;
        16|'tcp-cnx-port-scan')
            tcp_cnx_port_scan $@
            ;;
        17|'udp-port-scan')
            udp_port_scan $@
            ;;
        18|'tcp-ack-port-scan')
            tcp_ack_port_scan $@
            ;;
        19|'tcp-window-port-scan')
            tcp_window_port_scan $@
            ;;
        20|'tcp-maimon-port-scan')
            tcp_maimon_port_scan $@
            ;;
        21|'host-discovery-no-port-scan')
            host_discovery_no_port_scan $@
            ;;
        22|'port-scan-no-host-discovery')
            port_scan_no_host_discovery $@
            ;;
        23|'tcp-syn-port-discovery')
            tcp_syn_port_discovery $@
            ;;
        24|'tcp-ack-port-discovery')
            tcp_ack_port_discovery $@
            ;;
        25|'udp-port-discovery')
            udp_port_discovery $@
            ;;
        26|'arp-discovery')
            arp_discovery $@
            ;;
        27|'scan-all-ports')
            scan_all_ports $@
            ;;
        28|'fast-port-scan-top-100')
            fast_port_scan_top_100 $@
            ;;
        29|'scan-top-ports')
            scan_top_ports $@
            ;;
        30|'scan-service-version')
            scan_service_version $@
            ;;
        31|'light-scan-service-version')
            light_scan_service_version $@
            ;;
        32|'scan-all-service-versions')
            scan_all_service_versions $@
            ;;
        33|'paranoid-scan')
            paranoid_scan $@
            ;;
        34|'sneaky-scan')
            sneaky_scan $@
            ;;
        35|'polite-scan')
            polite_scan $@
            ;;
        36|'aggressive-scan')
            aggressive_scan $@
            ;;
        37|'insane-scan')
            insane_scan $@
            ;;
        38|'non-intrusive-scan')
            non_intrusive_scan $@
            ;;
        39|'list-machines-in-range')
            list_machines_in_range $@
            ;;
        40|'tcp-ip-remote-os-detection')
            tcp_ip_remote_os_detection $@
            ;;
        41|'aggresive-remote-os-detection')
            aggresive_remote_os_detection $@
            ;;
        42|'fast-search-rand-web-servers')
            fast_search_rand_web_servers $@
            ;;
        43|'brute-force-dns-subdomain')
            brute_force_dns_subdomain $@
            ;;
        44|'run-safe-smb-scripts')
            run_safe_smb_scripts $@
            ;;
        45|'whois-query')
            whois_query $@
            ;;
        46|'detect-cross-site-scripting-vuln')
            detect_cross_site_scripting_vuln $@
            ;;
        47|'detech-sql-injection-vuln')
            detech_sql_injection_vuln $@
            ;;
        48|'show-host-interfaces-and-routes')
            show_host_interfaces_and_routes $@
            ;;
        49|'traceroute-random-targets')
            traceroute_random_targets $@
            ;;
        50|'query-dns-for-hosts')
            query_dns_server_for_host_range $@
            ;;
        *)
            echo "[ WARNING ]: Invalid instruction! ($@)"
            ;;
    esac
    return $?
}

# MISCELLANEOUS

if [ $EUID -ne 0 ]; then
    echo "[ WARNING ]: Some ($SCRIPT_NAME) commands require elevated priviledges."
fi

init_cheat_sheet $@
exit $?

# CODE DUMP


