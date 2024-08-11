#!/bin/bash

HOME=/home/kali/Desktop

#1.1 Get from the user a network to scan
echo "Please enter the network to scan:"
read network

#1.2 Get from the user a name for the output directory
echo "Please enter a name for the output directory:"
read output_directory

mkdir -p $HOME/$output_directory 

echo "The directory $output_directory was created"


basic_option() {
    echo "You chose Basic option."
sleep 1
echo "Would you like to provide password database? (y/n)"  
read answer
if [ "$answer" == "y" ]
then echo "Please enter a full path:"
 read path
 nmap --script=ssh-brute.nse --script=smb-brute.nse --script-args passdb=$path $network

elif [ "$answer" == "n" ]
then echo "Ok , default password database will be used."
  sudo nmap $network --script=smb-brute.nse -sV

fi
}


full_option() {
    echo "You chose Full option."
    cd $HOME/$output_directory 
   nmap $network --script=smb-brute.nse --script=vulners.nse --script=ssh-brute.nse --script=telnet-brute.nse  -sV -oX scan.xml
   
  
}
#nmap -sV --script vulners -oX scan.xml <target>
#xsltproc scan.xml | grep -Eo 'CVE-[0-9]{4}-[0-9]{4,7}
main() {
  
    echo "Please choose an option:"
    echo "1. Basic"
    echo "2. Full"
    echo "3. Exit"

    read -p "Enter your choice: " choice

    case $choice in
        1)
            basic_option
            ;;
        2)
            full_option
            ;;
        3)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter a valid option."
            main
            ;;
    esac
}

main

 xsltproc scan.xml | grep -Eo 'CVE-[0-9]{4}-[0-9]{4,7}' > vulnerabilities.txt
 
  echo "Done."
  sleep 2

zip_results() {
    echo "Would you like to save the results in a zip file? (y/n)"
    read answer

    if [ "$answer" == "y" ]; then
        echo "Saving..."
        if [ ! -d "$HOME/$output_directory" ]; then
            echo "Output directory does not exist. Exiting."
            return 1
        fi
        
        cd "$HOME/$output_directory" || { echo "Failed to change directory. Exiting."; return 1; }
        zip Results.zip scan.xml vulnerabilities.txt || { echo "Failed to create zip file. Exiting."; return 1; }
        echo "All the results saved in a zip."
    elif [ "$answer" == "n" ]; then
        echo "Ok bye."
    else
        echo "Invalid input. Please enter 'y' or 'n'."
        return 1
    fi
}
zip_results
