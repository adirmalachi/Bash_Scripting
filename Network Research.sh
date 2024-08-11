#!/bin/bash
REMOTE_REQUIREMENTS=("Nipe,Sshpass,Torify,nmap,whois")
cd /home/kali/Desktop
echo "You need to install this following Progrems - $REMOTE_REQUIREMENTS"
sleep 2
echo "Checking if the progrems installed first ..."
sleep 2 
if dpkg -s Whois | grep Package 
dpkg -s Whois | grep Status
then echo [+] Whois Already Installed

else echo "Whois not installed, Would you like to install it? [y/n]"
read answer
if [ "$answer" == "y" ]
then echo Installing [+]Whois ...
 sudo apt install whois
elif [ "$answer" == "n" ]
then echo "ok,bye."
fi
fi
sleep 2

if dpkg -s sshpass | grep Package 
dpkg -s sshpass | grep Status
then echo [+] Sshpass already Installed

else echo "Sshpass not installed, Would you like to install it? [y/n]"
read answer
if [ "$answer" == "y" ]
then echo Installing [+]Sshpass ...
 sudo apt install sshpass
elif [ "$answer" == "n" ]
then echo "ok,bye."
fi
fi

sleep 2

if dpkg -s nmap | grep Package 
dpkg -s nmap | grep Status
then echo [+] Nmap Already Installed

else echo "Nmap not installed, Would you like to install it? [y/n]"
read answer
if [ "$answer" == "y" ]
then echo Installing [+]nmap ...
 sudo apt install nmap
elif [ "$answer" == "n" ]
then echo "ok,bye."
fi
fi

sleep 2

echo "checking if Nipe installed..."
sleep 2
if dpkg -s nipe | grep installed
then [+] looks like Nipe is already installed.

else echo "seems like Nipe isn't installed would you like to install it? (y/n)"
read answer
if [ "$answer" == "y" ]
then echo Installing [+] Nipe ...
 mkdir nipe
     cd nipe
     git clone https://github.com/htrgouvea/nipe
    sudo cpan install Try::Tiny Config::Simple JSON
cd nipe
sudo perl nipe.pl install
echo "[+] Nipe succsessfully installed."
elif [ "$answer" == "n" ]
then echo "ok,bye."
sleep 2
fi
fi

echo "checking if Torify installed..."
sleep 2
if dpkg -s Tor| grep installed
then echo "[+] looks like Torify is already installed."

else echo "seems like tor isn't installed would you like to install it? (y/n)"
read answer
if [ "$answer" == "y" ]
then "echo Installing [+]Tor ..."
sudo apt install tor
echo "[+] tor succsessfully installed."
elif [ "$answer" == "n" ]
then echo "ok,bye."
sleep 2
fi
fi

echo "You are all set! now lets get to work anonymously O_o"


echo "turning your connection into unknown .."
cd /home/kali/Desktop/nipe/nipe
sudo perl nipe.pl stop
sudo perl nipe.pl status
sudo perl nipe.pl restart
sudo perl nipe.pl start
sudo perl nipe.pl status 

sleep 3 

echo "YoUr conncection is nOw AnOnymOus..."

sleep 2

xdg-open https://dnsleaktest.com/

sleep 3

echo "Please enter the IP that you want to scan"

read IP

echo "scanning $IP"

nmap -p 1-1000 $IP > Nmap_$IP.txt


sudo service ssh start
ifconfig | grep -i inet

echo "Please type again an IP address to see where is it from"
read IP

geoiplookup $IP > Country.txt
geoiplookup $IP

echo "Do you want to know the uptime? (y/n)"
read answer
if [ "$answer" == "y" ]
then echo "Showing uptime.."
uptime -s $IP
elif [ "$answer" == "n" ]
then echo "ok,bye."
fi

echo "Now i will show you who you are..."
sleep 3
ssh kali@$IP whois $IP

ssh kali@$IP whois $IP > WhoIS_$IP.txt

sleep 2
ssh kali@$IP nmap $IP
ssh kali@$IP nmap $IP > Nmap_$IP.txt




