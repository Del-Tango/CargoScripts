#!/bin/bash
#
# Regards, the Alveare Solutions society -
#
# Star Link (a.k.a Stink) - Cheat Sheet

SCRIPT_NAME='StarLink'
VERSION='TurbulentJuice'
VERSION_NO='1.0'
CATEGORY='Cheat Sheet'

function format_tshark_interface_args () {
    local INTERFACES_CSV="$1"
    local INTERFACE_SET=( `echo "$INTERFACES" | tr ',' ' '` )
    local FORMATTED_INTERFACES=""
    if [ -z "$INTERFACES_CSV" ]; then
        return 1
    elif [ ${#INTERFACE_SET[@]} -eq 1 ]; then
        local FORMATTED_INTERFACES="-i $INTERFACES_CSV"
    else
        for interface in ${INTERFACE_SET[@]}; do
            local FORMATTED_INTERFACES="$FORMATTED_INTERFACES -i $interface"
        done
    fi
    echo "$FORMATTED_INTERFACES"
    return $?
}

# CHEAT SHEET

function list_interfaces_available_for_capture () {
    exec_msg "tshark -D"
    tshark -D
    return $?
}

function capture_on_interfaces () {
    local INTERFACES="$2"
    local FORMATTED_INTERFACES=`format_tshark_interface_args "$INTERFACES"`
    exec_msg "tshark $FORMATTED_INTERFACES"
    tshark $FORMATTED_INTERFACES
    return $?
}

function capture_on_all_interfaces () {
    exec_msg "tshark -i any"
    tshark -i any
    return $?
}

function filtered_capture_on_interfaces () {
    local INTERFACES="$2"
    local FILTER_TEXT="${@:3}"
    local FORMATTED_INTERFACES=`format_tshark_interface_args "$INTERFACES"`
    exec_msg "tshark -f $FILTER_TEXT $FORMATTED_INTERFACES"
    tshark -f "$FILTER_TEXT" $FORMATTED_INTERFACES
    return $?
}

function filtered_capture_on_all_interfaces () {
    local FILTER_TEXT="${@:2}"
    exec_msg "tshark -f $FILTER_TEXT -i any"
    tshark -f "$FILTER_TEXT" -i any
    return $?
}

function filtered_capture_on_interface_to_file () {
    local FILE_PATH="$2"
    local INTERFACES="$3"
    local FILTER_TEXT="${@:4}"
    local FORMATTED_INTERFACES=`format_tshark_interface_args "$INTERFACES"`
    exec_msg "tshark -f $FILTER_TEXT $FORMATTED_INTERFACES -w $FILE_PATH"
    tshark -f "$FILTER_TEXT" $FORMATTED_INTERFACES -w "$FILE_PATH"
    return $?
}

function filtered_capture_on_all_interfaces_to_file () {
    local FILE_PATH="$2"
    local FILTER_TEXT="${@:3}"
    exec_msg "tshark -f $FILTER_TEXT -i any -w $FILE_PATH"
    tshark -f "$FILTER_TEXT" -i any -w "$FILE_PATH"
    return $?
}

function read_all_packets_from_capture_file () {
    local FILE_PATH="$2"
    exec_msg "tshark -r $FILE_PATH"
    tshark -r "$FILE_PATH"
    return $?
}

function read_captured_packets_with_host_ip_from_file () {
    local FILE_PATH="$2"
    local IPV4_ADDRS="$3"
    exec_msg "tshark -r $FILE_PATH ip.host==$IPV4_ADDRS"
    tshark -r "$FILE_PATH" ip.host=="$IPV4_ADDRS"
    return $?
}

function read_captured_packets_with_src_ip_from_file () {
    local FILE_PATH="$2"
    local IPV4_ADDRS="$3"
    exec_msg "tshark -r $FILE_PATH ip.src==$IPV4_ADDRS"
    tshark -r "$FILE_PATH" ip.src=="$IPV4_ADDRS"
    return $?
}

function read_captured_packets_with_dst_ip_from_file () {
    local FILE_PATH="$2"
    local IPV4_ADDRS="$3"
    exec_msg "tshark -r $FILE_PATH ip.dst==$IPV4_ADDRS"
    tshark -r "$FILE_PATH" ip.dst=="$IPV4_ADDRS"
    return $?
}

function read_captured_packets_with_ip_address_from_file () {
    local FILE_PATH="$2"
    local IPV4_ADDRS="$3"
    exec_msg "tshark -Y ip.addr==${IPV4_ADDRS} -r $FILE_PATH"
    tshark -Y "ip.addr==${IPV4_ADDRS}" -r "$FILE_PATH"
    return $?
}

function read_top10_urls_from_capture_file () {
    local FILE_PATH="$2"
    exec_msg "tshark -r $FILE_PATH -Y http.request -T fields -e http.host -e"\
        "http.request.uri | sed -e 's/?.*$//' | sed -e 's#^(.*)t(.*)$#http://12#’"\
        "| sort | uniq -c | sort -rn | head'"
    tshark -r "$FILE_PATH" -Y http.request -T fields -e http.host \
        -e http.request.uri | sed -e 's/?.*$//' | \
        sed -e 's#^(.*)t(.*)$#http://12#' | sort | uniq -c | sort -rn | head
    return $?
}

function display_http_response_codes () {
    local INTERFACES="$2"
    local FORMATTED_INTERFACES=`format_tshark_interface_args "$INTERFACES"`
    exec_msg "tshark -o tcp.desegment_tcp_streams:TRUE $FORMATTED_INTERFACES"\
        "-Y http.response -T fields -e http.response.code"
    tshark -o "tcp.desegment_tcp_streams:TRUE" $FORMATTED_INTERFACES \
        -Y "http.response" -T fields -e http.response.code
    return $?
}

function display_src_ip_and_mac_address_csv () {
    local INTERFACES="$2"
    local FORMATTED_INTERFACES=`format_tshark_interface_args "$INTERFACES"`
    exec_msg "tshark $FORMATTED_INTERFACES -nn -e ip.src -e eth.src -Tfields -E separator=, -Y ip"
    tshark $FORMATTED_INTERFACES -nn -e ip.src -e eth.src -Tfields -E separator=, -Y ip
    return $?
}

function display_dst_ip_and_mac_address_csv () {
    local INTERFACES="$2"
    local FORMATTED_INTERFACES=`format_tshark_interface_args "$INTERFACES"`
    exec_msg "tshark $FORMATTED_INTERFACES -nn -e ip.dst -e eth.dst -Tfields -E separator=, -Y ip"
    tshark $FORMATTED_INTERFACES -nn -e ip.dst -e eth.dst -Tfields -E separator=, -Y ip
    return $?
}

function display_src_dst_ipv4_csv () {
    local INTERFACES="$2"
    local FORMATTED_INTERFACES=`format_tshark_interface_args "$INTERFACES"`
    exec_msg "tshark $FORMATTED_INTERFACES -nn -e ip.src -e ip.dst -Tfields -E separator=, -Y ip"
    tshark $FORMATTED_INTERFACES -nn -e ip.src -e ip.dst -Tfields -E separator=, -Y ip
    return $?
}

function display_src_dst_ips () {
    exec_msg "tshark -o column.format:'Source, %s,Destination, %d' -Ttext"
    tshark -o column.format:'"Source", "%s","Destination", "%d"' -Ttext
    return $?
}

function source_ip_and_dns_query () {
    local INTERFACES="$2"
    local FORMATTED_INTERFACES=`format_tshark_interface_args "$INTERFACES"`
    exec_msg "tshark $FORMATTED_INTERFACES -nn -e ip.src -e dns.qry.name -E separator=';' -T fields port 53"
    tshark $FORMATTED_INTERFACES -nn -e ip.src -e dns.qry.name -E separator=";" -T fields port 53
    return $?
}

function pcap_analysis_procedure01 () {
    local FILE_PATH="$2"
    local IPV4_ADDRS="$3"
    exec_msg "tshark -r $FILE_PATH -qz io,stat,1,tcp.analysis.retransmission"\
        "ip.addr==${IPV4_ADDRS}"
    tshark -r "$FILE_PATH" -qz io,stat,1,tcp.analysis.retransmission \
        ip.addr=="${IPV4_ADDRS}"
    return $?
}

function pcap_analysis_procedure02 () {
    local FILE_PATH="$2"
    local IPV4_ADDRS="$3"
    exec_msg "tshark -r $FILE_PATH -qz io,stat,120, ip.addr==${IPV4_ADDRS}"\
        "&& tcp COUNT(tcp.analysis.retransmission)ip.addr==${IPV4_ADDRS}"\
        "&& tcp.analysis.retransmission"
    tshark -r "$FILE_PATH" -qz io,stat,120,"ip.addr==${IPV4_ADDRS} && tcp","COUNT(tcp.analysis.retransmission)ip.addr==${IPV4_ADDRS} && tcp.analysis.retransmission"
    return $?
}

function pcap_analysis_procedure03 () {
    local FILE_PATH="$2"
    exec_msg "tshark -r $FILE_PATH -qz io,stat,30,"\
        "COUNT(tcp.analysis.retransmission) tcp.analysis.retransmission"
    tshark -r "$FILE_PATH" -qz io,stat,30,"COUNT(tcp.analysis.retransmission) tcp.analysis.retransmission"
    return $?
}

function pcap_analysis_procedure04 () {
    local FILE_PATH="$2"
    exec_msg "tshark -r $FILE_PATH -qz io,stat,30,"\
        "COUNT(tcp.analysis.retranmission) tcp.analysis.retransmission", \
        "AVG(tcp.window_size)tcp.window_sizeтАЭ, тАЭMAX(tcp.window_size)", \
        "MIN(tcp.window_size)tcp.window_size"
    tshark -r "$FILE_PATH" -qz io,stat,30,"COUNT(tcp.analysis.retransmission) tcp.analysis.retransmission","AVG(tcp.window_size)tcp.window_size,MAX(tcp.window_size)","MIN(tcp.window_size)tcp.window_size"
    return $?
}

function pcap_analysis_procedure05 () {
    local FILE_PATH="$2"
    exec_msg "tshark -r $FILE_PATH -qz io,stat,5,"\
        "COUNT(tcp.analysis.retransmission) tcp.analysis.retransmission",\
        "COUNT(tcp.analysis.duplicate_ack) tcp.analysis.duplicate_ack",\
        "COUNT(tcp.analysis.lost_segment) tcp.analysis.lost_segment",\
        "COUNT(tcp.analysis.fast_retransmission) tcp.analysis.fast_retransmission"
    tshark -r "$FILE_PATH" -qz io,stat,5,"COUNT(tcp.analysis.retransmission) tcp.analysis.retransmission","COUNT(tcp.analysis.duplicate_ack) tcp.analysis.duplicate_ack","COUNT(tcp.analysis.lost_segment) tcp.analysis.lost_segment","COUNT(tcp.analysis.fast_retransmission) tcp.analysis.fast_retransmission"
    return $?
}

function pcap_analysis_procedure06 () {
    local FILE_PATH="$2"
    exec_msg "tshark -r $FILE_PATH -qz io,stat,5,"\
        "MIN(tcp.analysis.ack_rtt) tcp.analysis.ack_rtt",\
        "MAX(tcp.analysis.ack_rtt)tcp.analysis.ack_rtt",\
        "AVG(tcp.analysis.ack_rtt) tcp.analysis.ack_rtt"
    tshark -r "$FILE_PATH" -qz io,stat,5,"MIN(tcp.analysis.ack_rtt) tcp.analysis.ack_rtt","MAX(tcp.analysis.ack_rtt)tcp.analysis.ack_rtt","AVG(tcp.analysis.ack_rtt) tcp.analysis.ack_rtt"
    return $?
}

function pcap_analysis_procedure07 () {
    local FILE_PATH="$2"
    exec_msg "tshark -r $FILE_PATH -qz ip_hosts,tree"
    tshark -r "$FILE_PATH" -qz ip_hosts,tree
    return $?
}

function pcap_analysis_procedure08 () {
    local FILE_PATH="$2"
    exec_msg "tshark -r $FILE_PATH -q -z conv,tcp"
    tshark -r "$FILE_PATH" -q -z conv,tcp
    return $?
}

function pcap_analysis_procedure09 () {
    local FILE_PATH="$2"
    exec_msg "tshark -r $FILE_PATH -q -z ptype,tree"
    tshark -r "$FILE_PATH" -q -z ptype,tree
    return $?
}

# DISPLAY

function exec_msg () {
    local MSG="$@"
    echo "[ EXEC ]: ${MSG}"
    return $?
}

function display_header () {
    cat<<EOF
    _______________________________________________________________________________________________

    *                                *  ${SCRIPT_NAME} CheatSheet  *                             *
    ___________________________________________________________________v.${VERSION}____________
                            Regards, the Alveare Solutions #!/Society -x

EOF
    return $?
}

function display_usage () {
    display_header
    cat<<EOF
 1. list-interfaces-available-for-capture__________________________________________________________tshark -D
 2. capture-on-interfaces_______________________________<INTERFACE1>,<INTERFACE2>,_________________tshark -i <interface> -i <interface>
 3. capture-on-all-interfaces______________________________________________________________________tshark -i any
 4. filtered-capture-on-interfaces______________________<INTERFACE1>, <FILTER-TEXT>________________tshark -f "<filter-text>" -i <interface>
 5. filtered-capture-on-all-interfaces__________________<FILTER-TEXT>______________________________tshark -f "<filter-text>" -i any
 6. filtered-capture-on-interface-to-file_______________<FILE-PATH> <INTERFACE1>, <FILTER-TEXT>____tshark -f "<filter-text>" -i <interface> -w <file-path>
 7. filtered-capture-on-all-interfaces-to-file__________<FILE-PATH> <FILTER-TEXT>__________________tshark -f "<filter-text>" -i any -w <file-path>
 8. read-all-packets-from-capture-file__________________<FILE-PATH>________________________________tshark -r <file-path>
 9. read-captured-packets-with-host-ip-from-file________<FILE-PATH> <IPv4-ADDRESS>_________________tshark -r <file-path> ip.host=="<ipv4-address>"
10. read-captured-packets-with-src-ip-from-file_________<FILE-PATH> <IPv4-ADDRESS>_________________tshark -r <file-path> ip.src=="<ipv4-address>"
11. read-captured-packets-with-dst-ip-from-file_________<FILE-PATH> <IPv4-ADDRESS>_________________tshark -r <file-path> ip.dst=="<ipv4-address>"
12. read-captured-packets-with-ip-address-from-file_____<FILE-PATH> <IPv4-ADDRESS>_________________tshark -Y "ip.addr==<ipv4-address>" -r <file-path>
13. read-top10-urls-from-capture-file___________________<FILE-PATH>________________________________tshark -r <file-path> -Y http.request -T fields -e http.host \\
                                                                                                    -e http.request.uri | sed -e ‘s/?.*$//’ | \\
                                                                                                    sed -e ‘s#^(.*)t(.*)$#http://12#’ | sort | uniq -c | sort -rn | head
14. display-http-response-codes_________________________<INTERFACE1>,______________________________tshark -o “tcp.desegment_tcp_streams:TRUE” -i <interface> \\
                                                                                                    -Y “http.response” -T fields -e http.response.code
15. display-src-ip-and-mac-address-csv__________________<INTERFACE1>,______________________________tshark -i <interface> -nn -e ip.src -e eth.src -Tfields -E separator=, -Y ip
16. display-dst-ip-and-mac-address-csv__________________<INTERFACE1>,______________________________tshark -i <interface> -nn -e ip.dst -e eth.dst -Tfields -E separator=, -Y ip
17. display-src-dst-ipv4-csv____________________________<INTERFACE1>,______________________________tshark -i <interface> -nn -e ip.src -e ip.dst -Tfields -E separator=, -Y ip
18. display-src-dst-ips____________________________________________________________________________tshark -o column.format:’”Source”, “%s”,”Destination”, “%d”‘ -Ttext
19. source-ip-and-dns-query_____________________________<INTERFACE1>,______________________________tshark -i <interface> -nn -e ip.src -e dns.qry.name -E separator=”;” -T fields port 53
20. pcap-analysis-procedure01___________________________<FILE-PATH> <IPv4-ADDRESS>_________________tshark -r <file-path> -qz io,stat,1,0,sum(tcp.analysis.retransmission) \\
                                                                                                    ”ip.addr==<ipv4-address>″
21. pcap-analysis-procedure02___________________________<FILE-PATH> <IPv4-ADDRESS>_________________tshark -r <file-path> -qz io,stat,120,”ip.addr==<ipv4-address> && tcp”, \\
                                                                                                    ”COUNT(tcp.analysis.retransmission)ip.addr==<ipv4-address> \\
                                                                                                    && tcp.analysis.retransmission”
22. pcap-analysis-procedure03___________________________<FILE-PATH>________________________________tshark -r <file-path> -q -z io,stat,30,”COUNT(tcp.analysis.retransmission) \\
                                                                                                    tcp.analysis.retransmission”
23. pcap-analysis-procedure04___________________________<FILE-PATH>________________________________tshark -r <file-path> -q -z io,stat,30, “COUNT(tcp.analysis.retranmission) \\
                                                                                                    tcp.analysis.retransmission”, “AVG(tcp.window_size)tcp.window_sizeтАЭ, \\
                                                                                                    тАЭMAX(tcp.window_size)”, “MIN(tcp.window_size)tcp.window_size”
24. pcap-analysis-procedure05___________________________<FILE-PATH>________________________________tshark -r <file-path> -q -z io,stat,5,”COUNT(tcp.analysis.retransmission) \\
                                                                                                    tcp.analysis.retransmission”,”COUNT(tcp.analysis.duplicate_ack) \\
                                                                                                    tcp.analysis.duplicate_ack”, “COUNT(tcp.analysis.lost_segment) \\
                                                                                                    tcp.analysis.lost_segment”, “COUNT(tcp.analysis.fast_retransmission) \\
                                                                                                    tcp.analysis.fast_retransmission”
25. pcap-analysis-procedure06___________________________<FILE-PATH>________________________________tshark -r <file-path> -q -z io,stat,5,”MIN(tcp.analysis.ack_rtt) \\
                                                                                                    tcp.analysis.ack_rtt”, “MAX(tcp.analysis.ack_rtt)tcp.analysis.ack_rtt”, \\
                                                                                                    ”AVG(tcp.analysis.ack_rtt) tcp.analysis.ack_rtt”
26. pcap-analysis-procedure07___________________________<FILE-PATH>________________________________tshark -r <file-path> -q -z ip_hosts,tree
27. pcap-analysis-procedure08___________________________<FILE-PATH>________________________________tshark -r <file-path> -q -z conv,tcp
28. pcap-analysis-procedure09___________________________<FILE-PATH>________________________________tshark -r <file-path> -q -z ptype,tree

[ EXAMPLE ]: ./`basename $0` capture-on-interfaces eth0,wlan0
[ EXAMPLE ]: ./`basename $0` display-http-response-codes wlan0
[ EXAMPLE ]: ./`basename $0` filtered-capture-on-interface-to-file /tmp/captured.pcap wlan0 tcp port 80
[ EXAMPLE ]: ./`basename $0` pcap-analysis-procedure01 /tmp/captured.pcap 192.168.100.1

EOF
}

# INIT

function init_cheatsheet () {
    for opt in $@; do
        case "$opt" in
            -h|--help)
                display_usage; exit $?
                ;;
            1|'list-interfaces-available-for-capture')
                list_interfaces_available_for_capture $@
                ;;
            2|'capture-on-interfaces')
                capture_on_interfaces $@
                ;;
            3|'capture-on-all-interfaces')
                capture_on_all_interfaces $@
                ;;
            4|'filtered-capture-on-interfaces')
                filtered_capture_on_interfaces $@
                ;;
            5|'filtered-capture-on-all-interfaces')
                filtered_capture_on_all_interfaces $@
                ;;
            6|'filtered-capture-on-interface-to-file')
                filtered_capture_on_interface_to_file $@
                ;;
            7|'filtered-capture-on-all-interfaces-to-file')
                filtered_capture_on_all_interfaces_to_file $@
                ;;
            8|'read-all-packets-from-capture-file')
                read_all_packets_from_capture_file $@
                ;;
            9|'read-captured-packets-with-host-ip-from-file')
                read_captured_packets_with_host_ip_from_file $@
                ;;
            10|'read-captured-packets-with-src-ip-from-file')
                read_captured_packets_with_src_ip_from_file $@
                ;;
            11|'read-captured-packets-with-dst-ip-from-file')
                read_captured_packets_with_dst_ip_from_file $@
                ;;
            12|'read-captured-packets-with-ip-address-from-file')
                read_captured_packets_with_ip_address_from_file $@
                ;;
            13|'read-top10-urls-from-capture-file')
                read_top10_urls_from_capture_file $@
                ;;
            14|'display-http-response-codes')
                display_http_response_codes $@
                ;;
            15|'display-src-ip-and-mac-address-csv')
                display_src_ip_and_mac_address_csv $@
                ;;
            16|'display-dst-ip-and-mac-address-csv')
                display_dst_ip_and_mac_address_csv $@
                ;;
            17|'display-src-dst-ipv4-csv')
                display_src_dst_ipv4_csv $@
                ;;
            18|'display-src-dst-ips')
                display_src_dst_ips $@
                ;;
            19|'source-ip-and-dns-query')
                source_ip_and_dns_query $@
                ;;
            20|'pcap-analysis-procedure01')
                pcap_analysis_procedure01 $@
                ;;
            21|'pcap-analysis-procedure02')
                pcap_analysis_procedure02 $@
                ;;
            22|'pcap-analysis-procedure03')
                pcap_analysis_procedure03 $@
                ;;
            23|'pcap-analysis-procedure04')
                pcap_analysis_procedure04 $@
                ;;
            24|'pcap-analysis-procedure05')
                pcap_analysis_procedure05 $@
                ;;
            25|'pcap-analysis-procedure06')
                pcap_analysis_procedure06 $@
                ;;
            26|'pcap-analysis-procedure07')
                pcap_analysis_procedure07 $@
                ;;
            27|'pcap-analysis-procedure08')
                pcap_analysis_procedure08 $@
                ;;
            28|'pcap-analysis-procedure09')
                pcap_analysis_procedure09 $@
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
