#!/usr/bin/env bash

# MySQL Password
echo "mysql-server mysql-server/root_password password ffxiv" | debconf-set-selections &> /dev/null
echo "mysql-server mysql-server/root_password_again password ffxiv" | debconf-set-selections &> /dev/null

echo "Updating ..."
sudo apt-get update -y -qq

echo "Adding ubuntu toolchain"
sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y

echo "Installing: build-essentials"
sudo apt-get install build-essential -y -qq

echo "Installing: cmake, git, libboost, mysql-server, mysql-client, zlib"
sudo apt-get install mysql-server -y -q
sudo apt-get install cmake git libboost-dev libmysqlclient-dev zlib1g-dev -y -qq

echo "Installing: G++/GCC"
sudo apt-get install g++-4.9 -y -qq
sudo apt-get install gcc -y -qq

echo "Updating ..."
sudo apt-get update -y

# optional
# mysql_secure_installation

echo "Installing: DO Monitoring"
sudo curl -sSL https://agent.digitalocean.com/install.sh | sh

echo ""
echo "Cloning Sapphire"
git clone --recursive https://github.com/SapphireMordred/Sapphire.git sapphire
cd /root/Sapphire

echo "Building Sapphire Server"
sudo cmake . -DSAPPHIRE_BOOST_VER="1.58" && make

echo "Importing database"
cd /root/Sapphire/sql

echo "Logging into database"
mysql_config_editor set --login-path=local --host=localhost --user=root --password=ffxiv

echo "Creating sapphire database"
mysql --login-path=local -e 'CREATE DATABASE IF NOT EXISTS sapphire;'
for f in *.sql
  do
    [ "$f" = "update.sql" ] && continue;
    echo -n "importing $f into the database..."
    mysql --login-path=local sapphire < $f && echo "Success"
    CODE=$?
    if [ $CODE -ne 0 ]; then exit $CODE; fi
done
mysql --login-path=local sapphire < update.sql

cd /root/Sapphire/bin
ls -l /root/Sapphire/bin

#
# todo - Automate this
#

echo "All done, you will need to open 3 terminal windows and SSH into the"
echo "server on each one. Then run the 3 binary files:"
echo "/root/Sapphire/bin/sapphire_api"
echo "/root/Sapphire/bin/sapphire_lobby"
echo "/root/Sapphire/bin/sapphire_zone"
echo ""
echo "You will need to edit the config files in: /root/Sapphire/bin/config"
echo "In: settings_lobby.xml"
echo "    ListenIp, ZoneIp, RestHost = DigitalOcean Droplet IP"
echo "    ServerSecret = Set to something else, eg: hello_world"
echo "    Add pass to the Mysql bit = <Pass>ffxiv</Pass>"
echo ""
echo "In: settings_rest.xml"
echo "    ListenIp, LobbyHost, FrontierHost = DigitalOcean Droplet IP"
echo "    ServerSecret = Must be same as what you set in the lobby.xml file, eg: hello_world"
echo "    DataPath = Ensure correct path to the game files (you only need 0a files)"
echo "    Add pass to the Mysql bit = <Pass>ffxiv</Pass>"
echo "In: settings_zone.xml"
echo "    ListenIp = DigitalOcean Droplet IP"
echo "    DataPath = Ensure correct path to the game files (you only need 0a files)"
echo "    Add pass to the Mysql bit = <Pass>ffxiv</Pass>"
echo ""
echo "Provide the launcher to people, for the ServerUrl = http://<DigitalOcean Droplet IP>/login.html"
echo "Ensure their game-data path is correct, it should be the ffxiv_dx11.exe file"
echo "Create an account and enjoy!"
echo ""
