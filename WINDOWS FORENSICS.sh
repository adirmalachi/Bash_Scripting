#!/bin/bash

HOME=/home/kali/Desktop
memory_path=/home/kali/Desktop/memdump.mem
ROOT_EXPORT_DIRECTORY="$HOME/Tools"

#  Check if user is root
if [[ $EUID -ne 0 ]]; then
echo "This progrem must be run as 'root'"
exit 1
fi

#  Allow user to specify filename
echo "[+] Creating a main directory on your Desktop...."
	mkdir $HOME/Tools > /dev/null 2>&1
	

read -p "Please enter a full path to your memory file:" file
echo "the path you entered is $file"

# Create a function to install the forensics tools if missing
tools() {
    local tools=("binwalk" "foremost" "strings" "volatility")

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo "$tool is not installed. Attempting to install..."
            if [[ -n "$(command -v apt-get)" ]]; then
                apt-get update
                apt-get install -y "$tool"
          
            else
                echo "Error: Unable to install $tool. Please install it manually."
            fi
        else
            echo "$tool is installed"
        fi
    done
}
echo "Volatillity is installed manually"
 git clone https://github.com/volatilityfoundation/volatility3.git
            cd /home/kali/Desktop/volatility3
            pip3 install -r requirements.txt
tools


if command -v bulk_extractor &> /dev/null; then
    echo "Bulk Extractor is already installed"
else
    echo "Bulk Extractor is not installed"

    if [[ -n "$(command -v apt-get)" ]]; then
        echo "[+] Installing Bulk Extractor..."
        apt-get update
        apt-get install -y bulk-extractor
    fi

    if command -v bulk_extractor &> /dev/null; then
        echo "Bulk Extractor has been successfully installed"
    else
        echo "Error: Failed to install Bulk Extractor. Please install it manually."
        exit 1
    fi
fi


#letting the user to choose which tool to use
HOME=/home/kali/Desktop

function VOL()
{
	# running the volatility cmds
	PLUGINS="pstree connscan pslist hivelist"
	PROFILE=$(/home/kali/Desktop/vol/./volatility_2.6_lin64_standalone_x64 -f $file imageinfo | grep Profile | awk '{print $4}' | sed 's/,/ /g')
	echo "$PROFILE" > $ROOT_EXPORT_DIRECTORY/Volatility
	
	for command in $PLUGINS
	do
		echo "[+] Executing the plugin command: $command"
		/home/kali/Desktop/vol/./volatility_2.6_lin64_standalone_x64 -f $file --profile=$PROFILE $command 2> /dev/null
		echo ""
	done
	
}

display_menu() {
    echo "Choose a tool:"
    echo "1. Bulk Extractor"
    echo "2. Binwalk"
    echo "3. Foremost"
    echo "4. Strings"
    echo "5. Volatility"
}

bulk_extractor_func() {
    echo "Executing Bulk Extractor..."
    OUTPUT_DIRECTORY="$ROOT_EXPORT_DIRECTORY/bulk_extractor"
    
    echo "output will be at $OUTPUT_DIRECTORY" 
    
    if [[ -d $OUTPUT_DIRECTORY ]]; then
		echo "removing..."
		rm -rf $OUTPUT_DIRECTORY
    fi;
    
    mkdir -p $OUTPUT_DIRECTORY
   
bulk_extractor $file -o $OUTPUT_DIRECTORY	
}


binwalk_func() {
   
   echo "Executing Binwalk..."
mkdir -p $ROOT_EXPORT_DIRECTORY/binwalk
binwalk -e $file -C $ROOT_EXPORT_DIRECTORY/binwalk --run-as=root
}

foremost_func() {
  echo "Executing Foremost..."
mkdir -p $ROOT_EXPORT_DIRECTORY/foremost
foremost -o $ROOT_EXPORT_DIRECTORY/foremost -i $file 

}
strings_func() {
    mkdir -p $ROOT_EXPORT_DIRECTORY/strings
    echo "Executing Strings..."

strings -o $file > $ROOT_EXPORT_DIRECTORY/strings/strings.txt
}


volatility_func() {
   mkdir -p $ROOT_EXPORT_DIRECTORY/volatility
    echo "Executing Volatility..."
}


main() {
    display_menu
    read -p "Enter your choice: " choice
    
    case $choice in
        1) bulk_extractor_func ;;
        2) binwalk_func ;;
        3) foremost_func ;;
        4) strings_func ;;
        5) VOL ;;
        *) echo "Invalid choice. Please enter a number between 1 and 5." ;;
    esac
}
main

# Saving the results
echo "General statistics:"
echo "Time of analysis: $(date)"
echo "Number of found files: $(find "$output_dir" -type f | wc -l)"

report_file="forensics_report.txt"
echo "Saving results into $report_file..."
echo "General statistics:" >> "$report_file"
echo "Time of analysis: $(date)" >> "$report_file"
echo "Number of found files: $(find "$ROOT_EXPORT_DIRECTORY" -type f | wc -l)" >> "$report_file"
echo "Extracted data directory: $ROOT_EXPORT_DIRECTORY" >> "$report_file"
echo "Network traffic: $network_traffic" >> "$report_file"


zip -r forensics_results.zip "$ROOT_EXPORT_DIRECTORY" "$report_file"
echo "Results saved in forensics_results.zip"
