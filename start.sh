#!/bin/bash

# Most of this script is written by me.
# Requirements check function, update function and parts of the start bot menu 
# is taken from ArchiKitchen and was changed to fit the needs of this project.
# The config.pl Perl script is from Stephen Ostermiller on unix.stackexchange.com
# answer two in this thread: 
# http://unix.stackexchange.com/questions/139574/change-a-value-in-a-config-file-or-add-the-setting-if-it-doesnt-exist
# 


#	TO-DO
#
#
# - tor control over telnet to get real exit node
# - check real exit node vs chosen node
# - check localhost ip vs ip exit node
# - log bots 
# - periodically check bot logs if ip ban or complete ban
# - create bad node list of banned ips
# - move banned bots to banned dir and rename config.json_banned
# - create template for start commands
# - config.pl to change configs (bot, tor, proxychains)
# - tor command while loop to be able to restart after config change (perhaps per telnet??)
# - clean up logging
# - protobuf check & installation
# - get the script to clean up its mess in subdirs
# - sanitize admin account use
#

#set -x

# PokemonGo-Bot variables
export BRANCH="" # dev or master
export ACTIVE_CONFIG="" # account to start

# git variables wrapper
export GITHUBLINK="https://github.com/ckrmml/PokemonGo-Bot_wrapper_osx.git"
export GITHUBBRANCH="master"
export LOCAL_BRANCH=""
export REPO="origin"
export LOCAL_WRAPPER=""
export REMOTE_WRAPPER=""

# git variables bot
export GITHUBLINK_BOT="https://github.com/PokemonGoF/PokemonGo-Bot.git"
export LOCAL_BRANCH_BOT=""
export LOCAL_BOT=""
export REMOTE_BOT=""

# PokemonGo-Bot wrapper scrip variables
export BOT_UPDATE=0
export WRAPPER_UPDATE=0
export RUNNING_BOTS=0

# directory variables
export BOT_CFG=tools/bot_config
export CMD_DIR=tmp/cmd
export NODE_DIR=tools/tor_nodes
export PROXYCHAINS_CFG=tools/proxychains_configs
export TEMPLATE_DIR=tools/templates
export TMP_DIR=tmp 
export TOR_CFG=tools/tor_configs
export TOR_DATA=tools/tor_data

# file variables
export EXIT_TMP=exit_nodes
export PROXY_CONF=""
export TOR_CONF=""
export COUNTRY_CHOICE=""
export NODE_TMP=""
export CC_EXIT_NODES=""
export VALID_EXIT_NODES=""

# bot config variables
export AUTH_SERVICE=""
export USERNAME=""
export PASS=""
export LOCATION=""
export API_KEY=""
export WEBSOCKET_SERVER=""
export ALT_MAX=""
export ALT_MIN=""
export DAILY_CATCH_LIMIT=""
export DEBUG=""
export DISTANCE_UNIT=""
export HEALTH_RECORD=""
export HEARTBEAT_TRESHOLD=""
export LOCATION_CACHE=""
export LOGGING_COLOR=""
export MAP_OBJECT_CACHE_TIME=""
export RECONNECTING_TIMEOUT=""
export TEST=""
export WALK_MAX=""
export WALK_MIN=""

# requirements arrays
TOOLS=(brew git python pip virtualenv wget ghead gdate gstat tor proxychains4) 
MISSINGTOOLS=()

# colors
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
LIME_YELLOW=$(tput setaf 190)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)

# modules
source tools/tor.sh

## script functions
activate_virtualenv() {
	log_msg "Activating Python virtualenv..."
	source bin/activate 2>/dev/null && done_or_fail
}

batch_start() {
	for CONFIG in "${BATCH_ARRAY[@]}"; do 
		ACTIVE_CONFIG="$CONFIG"
        start_bot_file
    done
}

check_admin() {
	log_msg "Checking if osx user is an admin..."
	if id -G $1 | grep -q -w 80 ; then
		print_msg_newline "[ADMIN]"
		touch tools/admin
	else
		local USER=$(whoami)
		print_msg_newline "[FAIL]"
		log_empty
		printf '%s\t%s\n' "Error:" "Your OSX account [$USER] is not an admin account."
		printf '\t%s\n' "This can fail installing PokemonGo-Bot requirements and updating"
		printf '\t%s\n' "pip requirements, which in turn results in failing execution of the bot."
		log_empty
		log_empty
	fi
}

check_tools() {
	log_msg "Checking PokemonGo-Bot requirements..."
	if [[ "$(which "${TOOLS[@]}" >/dev/null; printf '%s\n' "$?")" -ne 0 ]] ; then
	    for TOOL in "${TOOLS[@]}"; do
	        if [[ -z "$(which $TOOL)" ]]; then
   	         	MISSINGTOOLS[$i]=$TOOL
   	         	i=$(($i+1))
   	     	fi
   		done
    	log_empty
    	rule
    	log_empty
    	printf '%s\t%s\n' "${RED}Error${NORMAL}:" "It looks like you don't have the required tool(s): "
		log_empty
    	printf '\t' ""
    	printf '%s ' "${WHITE}${MISSINGTOOLS[@]}${NORMAL}"
    	log_empty
    	log_empty
    	printf '\t%s\n' "This check was made through 'which' command"
		printf '\t%s\n'	"Should we try to download and install the missing tools?"		
    	log_empty
		rule
		read -p "Y/N: " CHOICE
		case "$CHOICE" in
        	y|Y) install_missing_tools ;;
        	n|N) 
        		rule 	
				log_empty
        		printf '\t%s\n' "Please install missing tool(s) and relaunch PokemonGo-Bot wrapper script"
				log_empty
				rule
				exit 1 ;;
    	esac	
	else
		print_msg_newline "[${GREEN}DONE${NORMAL}]"
	fi
	if [[ "$(brew list | grep protobuf >/dev/null; printf '%s\n' "$?")" -ne 0 ]] ; then
	    log_empty
		rule
		log_empty
		printf '%s\t%s\n' "${RED}Error${NORMAL}:" "It looks like you don't have"
		log_empty
		printf '\t%s\n' "${WHITE}protobuf${NORMAL}"
		log_empty
		printf '\t%s\n'	"installed. Should we try to download and install the missing tools?"		
		log_empty
		rule
		read -p "Y/N: " CHOICE
		case "$CHOICE" in
			y|Y) install_missing_tools ;;
			n|N) 
				rule 	
				log_empty
				printf '\t%s\n' "Please install protobuf and relaunch PokemonGo-Bot wrapper script"
				log_empty
				rule
				exit 1 ;;
		esac	
	fi
		touch tools/depmet
}

check_updates_bot()	{
	if [[ -d ./PokemonGo-Bot ]] ; then
		cd PokemonGo-Bot
		log_msg "Checking for PokemonGo-Bot updates..."
		if [[ "$(git remote | grep -qi "$REPO"; echo $?)" -ne 0 ]]; then
			git remote add -t "$LOCAL_BRANCH_BOT" -m "$LOCAL_BRANCH_BOT" "$REPO" "$GITHUBLINK_BOT"
		fi
		git fetch -q origin
		if [[ "$LOCAL_BOT" != "$REMOTE_BOT" ]] ; then
    		BOT_UPDATE=1
		fi			
		done_or_fail
		cd ..
	fi
}

check_updates_wrapper() {
	log_msg "Checking for wrapper updates..."
	if [[ "$(git remote | grep -qi "$REPO"; echo $?)" -ne 0 ]]; then
		git remote add -t "$LOCAL_BRANCH_WRAPPER" -m "$LOCAL_BRANCH_WRAPPER" "$REPO" "$GITHUBLINK"
	fi
	git fetch -q origin
	if [[ "$LOCAL_WRAPPER" != "$REMOTE_WRAPPER" ]]; then
		WRAPPER_UPDATE=1
	fi
	done_or_fail
}

clone_bot_git() {
	clear
	branch=$1
	print_banner "Installing PokemonGo-Bot"
	log_msg "Cloning $branch branch..."
	git clone -q -b $branch https://github.com/PokemonGoF/PokemonGo-Bot 2>/dev/null
	OUT=$?
	if [ $OUT -eq 0 ] ; then
	touch ./tools/clone
	log_done
	else
		log_fail
		log_empty
		print_msg_newline "   Error code $OUT returned !! "
		log_empty
		case $OUT in
			128) log_failure "This means the directory already exists" ;;
			*) log_failure "This error is unknown" ;;
		esac
		log_empty
		log_msg "Exiting..."
		sleep 5
		exit 1
	fi
}

config_wrapper() {
	TMP_CFG=tools/bot_config/$ACTIVE_CONFIG.config
	if [[ ! -f tools/bot_config/$ACTIVE_CONFIG.config ]] ; then
		clear
		print_banner "$ACTIVE_CONFIG configuration"
		print_msg_newline "Would you like to proxy this bot over TOR?"
		log_empty
		read -p "[Y/N]: " PROXY_THIS_BOT
		if [[ $PROXY_THIS_BOT == Y ]] || [[ $PROXY_THIS_BOT == y ]] ; then
			clear
			print_banner "Configuration"
			print_msg_newline "Would you like TOR to configure itself?"
			log_empty
			read -p "[Y/N]: " SELF_CHOSEN
			clear
			print_banner "Configuration"
			print_msg_newline "Please choose a country for the TOR exit node"
			log_empty
			read -p "[Country]: " COUNTRY
			if [[ $SELF_CHOSEN == N ]] || [[ $SELF_CHOSEN == n ]] ; then
				clear
				print_banner "Configuration"
				print_msg_newline "How many exit nodes should we pass TOR?"
				print_msg_newline "We can pass only one, but 2 or 3 is much safer if one stops running."
				log_empty
				read -p "[Any number]: " EXIT_NODES
				log_empty
			else 
				EXIT_NODES=0
			fi
		fi
		touch $TMP_CFG
		echo "PROXY_THIS_BOT=$PROXY_THIS_BOT" >> $TMP_CFG
		if [[ $PROXY_THIS_BOT == Y ]] || [[ $PROXY_THIS_BOT == y ]] ; then
			echo "COUNTRY=$COUNTRY" >> $TMP_CFG
			echo "SELF_CHOSEN=$SELF_CHOSEN" >> $TMP_CFG
			echo "EXIT_NODES=$EXIT_NODES" >> $TMP_CFG
		fi
		chmod +x $TMP_CFG
	else
		log_header "Loading $ACTIVE_CONFIG configuration file"
		source $TMP_CFG
		log_success "Successfully loaded $ACTIVE_CONFIG wrapper configuration file"
	fi
}

create_config() {
	clear
	print_banner "Create bot config file"
	print_command l "Login section"
	print_command r "Random settings section"
	print_command t "Tasks section"
	print_command c "Catch section"
	print_command r "Release section"
	broken_rule
	print_command x "Return"
	read -p "Please choose: " CHOICE
	case $CHOICE in
		l|L) login_section ;;
		r|R) random_section ;;
		t|T) task_section ;;
		c|C) catch_section ;;
		r|R) release_section ;;
	esac
}

login_section() {	
	clear
	print_banner "Create bot config file"	
	log_empty
	print_msg_newline "Now editing login section"
	log_empty
	rule
	log_header "Please enter your authentication service"
	rule
	read -p "google/ptc: " AUTH_SERVICE
	log_empty
	rule
	log_header "Please enter your username"
	rule
	read -p "Username: " USERNAME
	log_empty
	rule
	log_header "Please enter your password"
	rule
	read -p "Password: " -s PASS
	log_empty
	log_empty
	rule
	log_header "Please enter your location"
	rule
	read -p "Location: " LOCATION
	log_empty
	rule
	log_header "Please enter your google maps api key"
	rule
	read -p "GMaps API Key: " API_KEY
	log_empty
	rule
}

random_section() {
	clear
	print_banner "Create bot config file"
	log_empty
	print_msg_newline "Now editing random config section"
	log_empty
	rule
	log_header "Do you use a websocket server?"
	rule
	read -p "Y/N: " ws
	case $ws in
		y|Y) WEBSOCKET_SERVER=true ;;
		n|N) WEBSOCKET_SERVER=false	;;
	esac
	log_empty
	rule
	log_header "Please choose heartbeat treshold"
	log_msg "Standard is 10"
	log_empty
	rule
	read -p "Any number: " HEARTBEAT_TRESHOLD
	log_empty
	rule
	log_header "Please choose map object cache time"
	log_msg "Standard is 5"
	log_empty
	rule
	read -p "Map object cache time: " MAP_OBJECT_CACHE_TIME
	log_empty
	rule
	log_header "Please choose walking speed"
	print_msg_newline "Standards:"
	log_msg "Maximum standard is 4.16"
	log_empty
	log_msg "Minimum standard is 2.16"
	log_empty
	log_msg "Alternation minimum standard is 0.75"
	log_empty
	log_msg "Alternation maximum standard is 2.5"
	log_empty
	rule
	read -p "Max: " WALK_MAX
	read -p "Min: " WALK_MIN
	read -p "Alt. min: " ALT_MIN
	read -p "Alt. max: " ALT_MAX
	log_empty
	rule
	log_header "Would you like to enable debug mode?"
	log_msg "Standard is off"
	log_empty
	rule
	read -p "Y/N: " de
	case $de in
		y|Y) DEBUG=true ;;
		n|N) DEBUG=false ;;
	esac
	log_empty
	rule
	log_header "Would you like to enable test mode?"
	log_msg "Standard is off. Some dev option, leave disabled if you do not develop"
	log_empty
	rule
	read -p "Y/N: " te
	case $te in
		y|Y) TEST=true ;;
		n|N) TEST=false ;;
	esac
	log_empty
	rule
	log_header "Would you like to enable health record?"
	log_msg "Sends data about bot failures back to developers"
	log_empty
	rule
	read -p "Y/N: " hr
	case $he in
		y|Y) HEALTH_RECORD=true ;;
		n|N) HEALTH_RECORD=false ;;
	esac
	log_empty
	rule
	log_header "Would you like to enable location cache?"
	log_msg "Standard is on"
	log_empty
	rule
	read -p "Y/N: " lc
	case $lc in
		y|Y) LOCATION_CACHE=true ;;
		n|N) LOCATION_CACHE=false ;;
	esac
	log_empty
	rule
	log_header "Please choose a distance unit"
	log_msg "km for kilometers, mi for miles, ft for feet"
	log_empty
	rule
	read -p "Unit: " DISTANCE_UNIT
	log_empty
	rule
	log_header "Please enter a reconnection timeout time"
	log_msg "Standard is 15"
	log_empty
	rule
	read -p "Any number: " RECONNECTING_TIMEOUT
	log_empty
	rule
	log_header "Would you like the bot to log with colors?"
	rule
	read -p "Y/N: " cl
	case $cl in
		y|Y) LOGGING_COLOR=true ;;
		n|N) LOGGING_COLOR=false ;;
	esac
	log_empty
	rule
	log_header "Would you like to set a daily catch limit?"
	log_msg "Standard is 800"
	log_empty
	rule
	read -p "Any number: " dcl
	case $dcl in
		y|Y) DAILY_CATCH_LIMIT=true ;;
		n|N) DAILY_CATCH_LIMIT=false ;;
	esac
}	
	
debug_screen() {
echo "BRANCH=$BRANCH" # dev or master
echo "ACTIVE_CONFIG=$ACTIVE_CONFIG" # account to start

# git variables wrapper
echo "GITHUBLINK=$GITHUBLINK"
echo "GITHUBBRANCH=$GITHUBBRANCH"
echo "LOCAL_BRANCH=$LOCAL_BRANCH"
echo "REPO=$REPO"
echo "LOCAL_WRAPPER=$LOCAL_WRAPPER"
echo "REMOTE_WRAPPER=$REMOTE_WRAPPER"

# git variables bot
echo "GITHUBLINK_BOT=$GITHUBLINK_BOT"
echo "LOCAL_BRANCH_BOT=$LOCAL_BRANCH_BOT"
echo "LOCAL_BOT=$LOCAL_BOT"
echo "REMOTE_BOT=$REMOTE_BOT"

# PokemonGo-Bot wrapper scrip variables
echo "BOT_UPDATE=$BOT_UPDATE"
echo "WRAPPER_UPDATE=$WRAPPER_UPDATE"
}

done_or_fail() {
	OUT=$?
	if [[ $OUT -eq 0 ]] ; then
		log_done
	else
		log_fail
		log_empty
		print_msg_newline "   Error code $OUT returned !! "
		log_empty
		log_msg "Exiting..."
		sleep 5
		exit 1
	fi
}
	
inflate_directories() {
	if [[ ! -d $TMP_DIR ]] ; then
		log_msg "Inflating tmp dir..."
		mkdir $TMP_DIR
		log_done
	fi	
	if [[ ! -d $BOT_CFG ]] ; then
		log_msg "Inflating bot config dir..."
		mkdir $BOT_CFG
		log_done
	fi
	if [[ ! -d $CMD_DIR ]] ; then
		log_msg "Inflating command dir..."
		mkdir $CMD_DIR
		log_done
	fi
}

init_sub() {
	log_msg "Initializing submodule..."
	cd web && git submodule -q init 2>/dev/null && done_or_fail && cd ..	
	log_msg "Updating submodule..."
	git submodule -q update 2>/dev/null && done_or_fail
}

install_bot() {
	clone_bot_git $BRANCH
	cd "PokemonGo-Bot"
	setup_virtualenv
	activate_virtualenv
	install_pip_req
	init_sub
	cd ..
	install_lib_crypt
}

install_lib_crypt() {
	log_header "Installing libencrypt.so"
	log_msg "Attempting to download pgoencrypt.tar.gz..."
	cd $TMP_DIR
	wget --quiet http://pgoapi.com/pgoencrypt.tar.gz 
	done_or_fail
	log_msg "Unarchiving pgoencrypt.tar.gz..."
	tar -xf pgoencrypt.tar.gz
	done_or_fail
	cd pgoencrypt/src/
	log_msg "Attempting to make libencrypt.so..."
	make -s 2>/dev/null 
	done_or_fail
	log_msg "Renaming libencrypt.so to encrypt.so..."		
	mv libencrypt.so encrypt.so
	done_or_fail
	cd .. && cd .. && cd ..
	log_msg "Moving encrypt.so to PokemonGo-Bot directory..."		
	ditto $TMP_DIR/pgoencrypt/src/encrypt.so PokemonGo-Bot/encrypt.so
	done_or_fail
	log_msg "Cleaning up..."
	rm -rf $TMP_DIR/pgoencrypt
	rm -rf $TMP_DIR/pgoencrypt.tar.gz
	done_or_fail
	log_success "Installation of encrypt.so complete"
	log_msg "Restarting wrapper..." 
    log_empty
	sleep 3
	exec ./start.sh
}

install_missing_tools() {
	clear
	print_banner "PokemonGo-Bot Wrapper OSX"
	log_failure "If installation should fail, you have to manually install from an admin account"
	rule
	for MISSINGTOOL in "${MISSINGTOOLS[@]}" ; do
		if [[ "$MISSINGTOOL" == brew ]] ; then
			log_header "Attempting to install homebrew"
			log_msg "Using Homebrew install command..."
			log_empty
			/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"	
			log_msg "Restarting wrapper because homebrew is needed for some installations..."
			sleep 2
			exec ./start.sh
		elif [[ "$MISSINGTOOL" == git ]] ; then
			log_header "Attempting to install git"
			log_msg "Using Homebrew git formula..."
			brew install git >/dev/null
			done_or_fail
		elif [[ "$MISSINGTOOL" == python ]] ; then
			log_header "Attempting to install python"
			log_msg "Using Homebrew python formula..."
			brew install python	>/dev/null
			done_or_fail
			log_msg "Updating pip..."
			pip install -qU pip
			done_or_fail
			log_msg "Restarting wrapper because installing python should also have installed pip and virtualenv..."
			sleep 2
			exec ./start.sh
		elif [[ "$MISSINGTOOL" == pip ]] ; then
			log_header "Attempting to install pip"
			cd $TMP_DIR
			log_msg "Downloading get-pip.py..."
			wget --quiet https://bootstrap.pypa.io/get-pip.py			
			done_or_fail
			log_msg "Executing get-pip.py..."
			python get-pip.py 2>/dev/null
			done_or_fail
			cd ..
			log_msg "Cleaning up..."
			rm -rf $TMP_DIR/get-pip.py
			done_or_fail
		elif [[ "$MISSINGTOOL" == virtualenv ]] ; then
			log_header "Attempting to install virtualenv"
			log_msg "Using pip virtualenv command..."
			pip install -q virtualenv			
			done_or_fail
		elif [[ "$MISSINGTOOL" == ghead ]] || [[ "$MISSINGTOOL" == gstat ]] || [[ "$MISSINGTOOL" == gdate ]] ; then
			log_header "Attempting to install ghead"
			log_msg "Using Homebrew coreutils formula..."
			brew install coreutils >/dev/null
			done_or_fail
		elif [[ "$MISSINGTOOL" == tor ]] ; then
			log_header "Attempting to install tor"
			log_msg "Using Homebrew tor formula..."
			brew install tor >/dev/null	
			done_or_fail
		elif [[ "$MISSINGTOOL" == proxychains4 ]] ; then
			log_header "Attempting to install proxychains4"
			log_msg "Using Homebrew proxychains4 formula..."
			brew install proxychains-ng	>/dev/null
			done_or_fail
		elif [[ "$MISSINGTOOLS" == wget ]] ; then
			log_header "Attempting to install wget"
			log_msg "Using Homebrew wget formula..."
			brew install wget --with-libressl >/dev/null
			done_or_fail
		fi
	done
	log_msg "Restarting wrapper..."
    log_empty
	sleep 2
	exec ./start.sh	
}

install_pip_req() {
	log_msg "Install requirements..."
	pip install -qr requirements.txt 2>/dev/null && done_or_fail
}

log_done() {
	printf '%s\n' "${WHITE}[${GREEN}DONE${WHITE}]${NORMAL}"
}

log_empty() {
	printf '\n'
}

log_fail() {
	printf '%s\n' "${WHITE}[${RED}FAIL${WHITE}]${NORMAL}"
}

log_failure() {
	text=$1
	printf '%s %s %s\n' "${RED}<!>${NORMAL}" "${YELLOW}$text${NORMAL}" "${RED}<!>${NORMAL}"
}

log_header() {
	text=$1
	printf '%s %s %s\n' "   " "${BRIGHT}$text${NORMAL}" "   " 
}
	
	
log_msg() {
	newline=$1
	text=$1
	printf '%s %s' "${BLUE}>>>${NORMAL}" "${WHITE}$text${NORMAL}"
}

log_success() {
	text=$1
	printf '%s %s %s\n' "${GREEN}<!>${NORMAL}" "${YELLOW}$text${NORMAL}" "${GREEN}<!>${NORMAL}" 
}

menu_bot_config() {
	clear
	print_banner "Create/change bot configuration file(s)"
	if [[ ! -n "$(find ./PokemonGo-Bot/configs -maxdepth 1 -name '*.json' -not -iname '*example*' -print -quit)" ]] ; then
		create_config
	else
		print_command c "Create_config"
		print_command e "Edit config"
		rule_broken
		print_command x "Return"
		rule
		read -p "Please choose: " CHOICE
		case $CHOICE in
			c) create_config ;;
			e) edit_config ;;
			x) exec .start.sh ;;
		esac
	fi
}
#	cd $pokebotpath
#read -p "enter 1 for google or 2 for ptc 
#" auth
#read -p "Input username 
#" username
#read -p "Input password 
#" -s password
#read -p "
#Input location 
#" location
#read -p "Input gmapkey 
#" gmapkey
#cp -f configs/config.json.example configs/config.json && chmod 755 configs/config.json
#if [ "$auth" = "2" ] || [ "$auth" = "ptc" ]
#then
#sed -i "s/google/ptc/g" configs/config.json
#fi
#sed -i "s/YOUR_USERNAME/$username/g" configs/config.json
#sed -i "s/YOUR_PASSWORD/$password/g" configs/config.json
#sed -i "s/SOME_LOCATION/$location/g" configs/config.json
#sed -i "s/GOOGLE_MAPS_API_KEY/$gmapkey/g" configs/config.json
#echo "Edit ./configs/config.json to modify any other config."
#}

menu_branch() {
	clear
	print_banner "PokemonGo-Bot Wrapper OSX"
	print_hu
	rule
	print_command m "Choose master branch"
	print_command d "Choose dev branch"
	print_command x "Return"
	rule
	read -p "Please choose: " CHOICE
    case "$CHOICE" in
        m|M) BRANCH=master 
        	install_bot ;;
        d|D) BRANCH=dev 
        	install_bot ;;
        x|X) return 0 ;;
    esac
}

menu_main() {
	clear
	if [[ $WRAPPER_UPDATE -eq 1 ]]; then
		print_banner "PokemonGo-Bot Wrapper OSX [Update available]"
	else
		print_banner "PokemonGo-Bot Wrapper OSX"
	fi
#	debug_screen
	print_hu
	if [[ ! -d ./PokemonGo-Bot ]] ; then
		rule
		print_command i "Choose and install PokemonGo-Bot branch"
	fi
	if [[ -d ./PokemonGo-Bot ]] ; then
		if [[ ! -n "$(find ./PokemonGo-Bot/configs -maxdepth 1 -name '*.json' -not -iname '*example*' -print -quit)" ]] ; then
			if [[ -f ./tools/clone ]] ; then
				rule
#				log_empty
#				printf '\t%s\n' "Please go to "
#				log_empty
#				printf '\t%s\n' "$PWD/PokemonGo-Bot/configs"
#				log_empty
#				printf '\t%s\n' "and create a configuration file to continue."
#				printf '\t%s\n' "After you have done this, please enter 'r' "
#				printf '\t%s\n' "or 'R' as choice or restart the wrapper."
#				log_empty
#				rule
				print_command c "Create bot config"
			elif [[ ! -f ./tools/clone ]] ; then
				rule
#				log_empty
#				printf '\t%s\n' "Please go to "
#				log_empty
#				printf '\t%s\n' "$PWD/PokemonGo-Bot/configs"
#				log_empty
#				printf '\t%s\n' "and create a configuration file to continue."
#				printf '\t%s\n' "After you have done this, please enter 'r' "
#				printf '\t%s\n' "or 'R' as choice or restart the wrapper."
#				log_empty
				rule
				log_empty
				printf '\t%s\n' "It looks like you copied over an instance of the bot you had installed before."
				printf '\t%s\n' "If starting a bot does not work, try entering setup as choice."
				printf '\t%s\n' "To disable this message, enter clone as choice."
				log_empty
				rule
				print_command c "Create bot config"
			fi
		elif [[ -n "$(find ./PokemonGo-Bot/configs -maxdepth 1 -name '*.json' -not -iname '*example*' -print -quit)" ]] ; then
			rule
			print_command s "Start PokemonGo-Bot"
			print_command w "Start web interface"
			rule_broken
			print_command c "Create/edit bot config"
			if [[ -n "$(find tools/bot_config -maxdepth 1 -name '*.config' -print -quit)" ]] ; then
				if [[ -n "$(find ./PokemonGo-Bot/configs -maxdepth 1 -name '*.json' -not -iname '*example*' -print -quit)" ]] ; then
					print_command t "Change wrapper configuration file(s)"
				else
					rule_broken
					print_command t "Change wrapper configuration file(s)"	
				fi
			fi
			if [[ $BOT_UPDATE -eq 1 ]] && [[ $WRAPPER_UPDATE -eq 1 ]] ; then
				rule_broken
				print_command u "Update menu"
        	elif [[ $BOT_UPDATE -eq 1 ]] && [[ $WRAPPER_UPDATE -eq 0 ]] ; then
				rule_broken
				print_command u "Update bot"
        	elif [[ $BOT_UPDATE -eq 0 ]] && [[ $WRAPPER_UPDATE -eq 1 ]] ; then
				rule_broken
				print_command u "Update wrapper"
        	fi
		fi
	fi
	rule_broken
	print_command r "Restart wrapper"
	print_command x "Quit"
	rule
	read -p "Please choose: " CHOICE
    case "$CHOICE" in
        i|I) menu_branch ;;
        s|S) menu_start ;;
        u|U) 
        	if [[ $BOT_UPDATE -eq 1 ]] && [[ $WRAPPER_UPDATE -eq 1 ]] ; then
        		menu_update 
        	elif [[ $BOT_UPDATE -eq 1 ]] && [[ $WRAPPER_UPDATE -eq 0 ]] ; then
        		update_bot
        	elif [[ $BOT_UPDATE -eq 0 ]] && [[ $WRAPPER_UPDATE -eq 1 ]] ; then
        		update_wrapper
        	fi
        	;;
        w|W) start_web_file ;;
        c|C) menu_bot_config ;;
        setup) 
			cd "PokemonGo-Bot"
			setup_virtualenv
			activate_virtualenv
			install_pip_req
			init_sub
			cd ..
			exec ./start.sh ;;
		clone)
			cd tools
			touch clone
			cd ..
			exec ./start.sh ;;
		t|T) menu_wrapper_config_choice ;;
        r|R) exec ./start.sh ;;
        x|X) exit 0 ;;
    esac
}

menu_start() {
    clear
    local COUNT=0
    file_list=()
	print_banner "Start bot(s)"
    log_msg "Searching for configuration files you've created in the past..."
	log_empty
	rule
	log_empty
    print_msg_newline "=-=-=-=-=-=-=-=-=-==-=-=-="
 	while IFS= read -d $'\0' -r file ; do     
 		((COUNT++))
     	file_list[$i]=$file
	printf '%s\n' "$(basename "${file_list[@]}")"
 	done < <(find PokemonGo-Bot/configs -type f -iname "*.json" -not -iname "*example*" -not -iname "*path*" -maxdepth 1 -print0) # Avoid a subshell, because we must remember variables
    print_msg_newline "=-=-=-=-=-=-=-=-=-==-=-=-="
	log_empty
    print_msg_newline "$COUNT config files were found"
	rule
    if [[ "$COUNT" -eq 1 ]]; then
        ACTIVE_CONFIG="$(basename "${file_list[@]}")" # If we have only one database, there's nothing to choose from, so we can save some precious seconds
		start_bot_file
    fi
    read -p "Please choose (x to return): " CHOICE
	log_empty
	case "$CHOICE" in
	  	x|X) return 0 ;;
        a|A) 
			while read line ; do
        		LASTFOUND="$(basename $line)"
					BATCH_ARRAY[$i]=$LASTFOUND
			    	i=$(($i+1))
   			 done < <(find PokemonGo-Bot/configs -type f -iname "*.json" -not -iname "*example*" -not -iname "*path*" -maxdepth 1)
			 batch_start 
			;; 
       	*)
			for config in $CHOICE ; do
        		if [[ -f "./PokemonGo-Bot/configs/$config" ]] ; then
            		ACTIVE_CONFIG="$config"
            		start_bot_file
				else
           			log_failure "Invalid selection"
					press_enter        	
				fi
        	done
        	;;
    	esac
}

menu_update() {
	clear
	print_banner "Update menu"
	if [[ $BOT_UPDATE -eq 1 ]] ; then
		print_command b "Update PokemonGo-Bot"
	fi
	if [[ $WRAPPER_UPDATE -eq 1 ]] ; then
		print_command w "Update wrapper"
	fi
	broken_rule
	print_command x "Return"
	rule
	read -p "Please choose: " CHOICE
    case "$CHOICE" in
        b|B) update_bot ;;
        w|W) update_wrapper ;;
        x|X) return 0 ;;
    esac
}

menu_wrapper_config_choice() {
	clear 
	local COUNT=0
    file_list=()
	print_banner "Change wrapper configuration file(s)"
    log_msg "Searching for configuration files you've created in the past..."
	log_empty
	rule
	log_empty
    print_msg_newline "=-=-=-=-=-=-=-=-=-==-=-=-="
 	while IFS= read -d $'\0' -r file ; do     
 		((COUNT++))
     	file_list[$i]=$file
	printf '%s\n' "$(basename "${file_list[@]}")"
 	done < <(find tools/bot_config -type f -iname "*.config" -maxdepth 1 -print0) # Avoid a subshell, because we must remember variables
    print_msg_newline "=-=-=-=-=-=-=-=-=-==-=-=-="
    print_msg_newline "$COUNT config files were found"
    if [[ "$COUNT" -eq 1 ]]; then
        CONFIG="$(basename "${file_list[@]}")" # If we have only one database, there's nothing to choose from, so we can save some precious seconds
		menu_wrapper_config
    fi
	log_empty
	rule
    read -p "Please choose (x to return): " CONFIG
    case $CONFIG in
    	x|X) return 0 ;;
    	*) menu_wrapper_config ;;
	esac
}

menu_wrapper_config() {	
	clear
	local EXIT_NODES=""
	local COUNTRY=""
	local SELF_CHOSEN=""
	local PROXY_THIS_BOT=""
	source $BOT_CFG/$CONFIG
	print_banner "Change $CONFIG configuration file(s)"
	if [[ $PROXY_THIS_BOT == Y ]] || [[ $PROXY_THIS_BOT == y ]] ; then
		log_msg "At the moment the bot gets proxied through TOR"
		log_empty
	else
		log_msg "At the moment the bot does not get proxied through TOR"
		log_empty
	fi
	if [[ $SELF_CHOSEN == Y ]] || [[ $SELF_CHOSEN == y ]] ; then
		log_msg "At the moment TOR does configure itself"
		log_empty
	else
		log_msg "At the moment TOR does not configure itself"
		log_empty
	fi
	log_msg "At the moment TOR exits in $COUNTRY"
	log_empty
 	if [[ $SELF_CHOSEN == N ]] || [[ $SELF_CHOSEN == n ]] ; then
		log_msg "At the moment TOR has $EXIT_NODES exit nodes"
		log_empty
	fi
	rule
	print_command t "Change if bot should get proxied through TOR"
	print_command s "Change if TOR should configure itself"
	print_command c "Change exit country"
	if [[ $SELF_CHOSEN == n ]] || [[ $SELF_CHOSEN == N ]] ; then
		print_command e "Change exit node number"
	fi
	rule_broken
	print_command o "Change another config file"
	print_command x "Return"
	rule
	read -p "Please choose: " CHOICE
    case "$CHOICE" in
        t|T) 
 			if [[ $PROXY_THIS_BOT == Y ]] || [[ $PROXY_THIS_BOT == y ]] ; then
		       	./tools/config.pl PROXY_THIS_BOT=n $PWD/$BOT_CFG/$CONFIG
		       	menu_wrapper_config
			else
       			./tools/config.pl PROXY_THIS_BOT=y $PWD/$BOT_CFG/$CONFIG
       			menu_wrapper_config
			fi
         	;;
        s|S) 
 			if [[ $SELF_CHOSEN == Y ]] || [[ $SELF_CHOSEN == y ]] ; then
		       	./tools/config.pl SELF_CHOSEN=n $PWD/$BOT_CFG/$CONFIG
		       	menu_wrapper_config
			else
       			./tools/config.pl SELF_CHOSEN=y $PWD/$BOT_CFG/$CONFIG
       			menu_wrapper_config
			fi
         	;;

        c|C) update_exit ;;
        e|E) update_nodes ;;
        o|O) menu_wrapper_config_choice ;;
        x|X) exec ./start.sh ;;
    esac	
}

no_update_found() {
	log_done
	log_empty
	log_empty
	log_msg "No new updates found"
	sleep 1
}

populate_variables() {
	if [[ -d ./PokemonGo-Bot ]] ; then
		cd "PokemonGo-Bot"
		log_msg "Populating bot specific variables..."
		LOCAL_BRANCH_BOT="$(git rev-parse --abbrev-ref HEAD)"
		LOCAL_BOT="$(git rev-parse @)"
		REMOTE_BOT="$(git rev-parse origin/$LOCAL_BRANCH_BOT)"
		log_done
		cd ..
	fi
	log_msg "Populating wrapper specific variables..."
	LOCAL_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
	LOCAL_WRAPPER="$(git rev-parse @)"
	REMOTE_WRAPPER="$(git rev-parse @{u})"
	log_done
} 

press_enter() {
    read -p "Press [Enter] key to continue..."
}

print_banner() {
	text=$1
	rule
	printf '%s' "$text" | fmt -c -w $(tput cols)
	rule
}

print_command() {
    command=$1
    description=$2
    printf ' %s - %s\n' $command "$description"
}

print_hu() {
	if [[ -d ./PokemonGo-Bot ]] ; then
		printf '%s\n' "${WHITE}You are currently on [${YELLOW}"$LOCAL_BRANCH_BOT"${WHITE}] branch of PokemonGo-Bot${NORMAL}"
		if [[ $BOT_UPDATE -eq 1 ]]; then
			print_msg "${BLUE}"
			print_msg " -> "
			print_msg "${WHITE}"
			print_msg "Your local bot is on commit: "
			print_msg "${NORMAL}"
			print_msg "${YELLOW}"
			print_msg "$LOCAL_BOT" | cut -c1-7
			print_msg "${BLUE}"
			print_msg " -> "
			print_msg "${WHITE}"
			print_msg "Newest commit on github is : "
			print_msg "${NORMAL}"
			print_msg "${GREEN}"
			print_msg "$REMOTE_BOT" | cut -c1-7
			print_msg "${NORMAL}"
		else
			print_msg "${BLUE}"
			print_msg " -> "
			print_msg "${WHITE}"
			print_msg_newline "This is the newest version"
			print_msg "${NORMAL}"
		fi
	else
			print_msg "${BLUE}"
			print_msg " -> "
			print_msg "${WHITE}"
			print_msg_newline "You have not installed PokemonGo-Bot yet"
			print_msg "${NORMAL}"
	fi
#	print_msg_newline "At the moment you have $(ps a | grep "*.json.command" | wc -l) bots running."
}

print_msg() {
    text=$1
    printf '%s' "$text"
}

print_msg_newline() {
    text=$1
    printf '%s\n' "$text"
}

rule() {
	printf -v _hr "%*s" $(tput cols) && echo ${_hr// /${1--}}
}

rule_broken() {
	printf -v _hr "%*s" $(($(tput cols)/2)) && echo ${_hr// /${1- -}}
}

setup_virtualenv() {
	log_msg "Setting up Python virtualenv..."
	virtualenv -q . 2>/dev/null && done_or_fail
}

start_bot_file() {
	export PROXY_THIS_BOT=""
	export COUNTRY=""
	export SELF_CHOSEN=""
	export EXIT_NODES=""
    config_wrapper
    local TMP_CMD="$CMD_DIR/$ACTIVE_CONFIG.command"
	if [[ $PROXY_THIS_BOT == y ]] ; then
		proxy_bot
	fi
	log_header "Generating bot start command"
	log_msg "Read and copy template file..."
	while read line ; do
		echo "$line" >> $TMP_CMD
	done < $TEMPLATE_DIR/command_template
	done_or_fail
	log_msg "Copying over routines..."
    # Change to directory
    echo "cd $(pwd)" >> $TMP_CMD
	echo "" >> $TMP_CMD
    # Copy over while loop
	echo "print_msg_newline \"\"" >> $TMP_CMD
	echo "cd "PokemonGo-Bot"" >> $TMP_CMD
	echo "echo $PWD" >> $TMP_CMD
	echo "activate_virtualenv" >> $TMP_CMD
	echo "print_msg_newline \" - Executing PokemonGo-Bot with config $ACTIVE_CONFIG...\"" >> $TMP_CMD
	echo "print_msg_newline \"\"" >> $TMP_CMD
	echo "while true ; do" >> $TMP_CMD
	if [[ $PROXY_THIS_BOT == y ]] ; then
		echo "	proxychains4 -f $PROXY_CONF python pokecli.py -cf configs/$ACTIVE_CONFIG" >> $TMP_CMD
	else
		echo "	python pokecli.py -cf configs/$ACTIVE_CONFIG" >> $TMP_CMD
	fi
	echo "	print_msg_newline \"\"" >> $TMP_CMD
	echo "	print_msg_newline \" - PokemonGo-Bot exited...\"" >> $TMP_CMD
	echo "	print_msg_newline \" - Restarting in five seconds...\"" >> $TMP_CMD
	echo "	print_msg_newline \"\"" >> $TMP_CMD
	echo "	sleep 5;" >> $TMP_CMD
	echo "done" >> $TMP_CMD
	done_or_fail
    log_success "Finished writing bot start command"
	log_msg "Executing bot start command file..."
    chmod +x "$TMP_CMD"
    open -b com.apple.terminal "$TMP_CMD"
    done_or_fail
    sleep 3
    log_msg "Returning to main menu..."
}

start_up_checks() {
	if [[ ! -f tools/admin ]] ; then
		check_admin
	fi
	if [[ ! -f tools/depmet ]] ; then
		check_tools
	fi
	populate_variables
	check_updates_bot
	check_updates_wrapper
}

start_web_file() {
	clear
	print_banner "Writing and executing web interface start command file"
	TMP_FILE="web.command"
	log_msg "Copying over routines..."
    # Change to directory
    echo "cd $(pwd)/PokemonGo-Bot/web" >> $TMP_FILE
	echo "" >> $TMP_FILE		
    # Copy over while loop
	echo "while true ; do" >> $TMP_FILE
	echo "	python -m SimpleHTTPServer" >> $TMP_FILE
	echo "print_msg_newline \"\"" >> $TMP_FILE
	echo "	print_msg_newline \" - Restarting in five seconds...\"" >> $TMP_FILE
	echo "print_msg_newline \"\"" >> $TMP_FILE
	echo "	sleep 5;" >> $TMP_FILE
	echo "done" >> $TMP_FILE	
    chmod +x "$TMP_FILE"
    done_or_fail
	log_msg "Executing web interface start command file..."    
    open -b com.apple.terminal "$TMP_FILE"    
    done_or_fail
    sleep 3
    log_msg "Deleting web start command file..."
    rm -f ./*.command    
    done_or_fail
    
    clear
    print_banner "PokemonGo-Bot web interface"
    log_empty
    print_msg_newline "Should we open localhost:8000 in you standard webbrowser?"
	log_empty
	read -p "[Y|N]: " CHOICE
	case $CHOICE in
		y|Y)
			log_empty
			log_msg "Opening web interface..."
			open http://localhost:8000
			log_done
			;;
		n|N)
			log_empty
    		printf '\t%s\n' "Open your browser and visit the site:"
    		printf '\t%s\n' "http://localhost:8000"
    		printf '\t%s\n' "to view the map"
			log_empty
			;;
	esac
    log_msg "Returning to main menu..."
    sleep 5    
    exec ./start.sh
}

update_bot() {
	clear
	local COUNT=0
    local LASTFOUND=""
	print_banner "Updating PokemonGo-Bot in progress"
	cd "PokemonGo-Bot"
	log_msg "Fetching current version..."
	git fetch -q "$REPO" "$LOCAL_BRANCH_BOT"
	if [[ "$LOCAL_BOT" != "$REMOTE_BOT" ]]; then
		log_empty
		log_empty
		print_msg_newline "Found new version!"
		print_msg_newline "Changelog:"
		print_msg_newline "=========="
    	while read line; do
        	((COUNT++))
        	LASTFOUND="$line"
        	printf '%s\n' "$LASTFOUND"
    	done < <(git --no-pager log --abbrev-commit --decorate --date=relative --pretty=format:'%C(bold red)%h%Creset %C(bold green)(%cr)%Creset - %C(bold yellow)%s%Creset %C(bold blue)commited by%Creset %C(bold cyan)%an%Creset' "$LOCAL_BOT..$REMOTE_BOT")
		print_msg_newline "=========="
    	print_msg_newline "There is a difference of $COUNT commits between your version and the version on github"
		log_empty
		print_msg_newline "Continue updating PokemonGo-Bot?"
		log_empty
		read -p "Y/N: " CHOICE
		case "$CHOICE" in
        	y|Y) 		
        		git pull -q >/dev/null 2>&1 || (log_empty; printf '%s\t%s\n' "WARNING:" "PokemonGo-Bot_wrapper_osx could not apply update due to conflicts, forced update mode will be used now."; printf '\t\t%s\n' "Please make proper backups if you need any of your past projects before going to the next step"; log_empty; press_enter; log_empty; git reset -q --hard; git clean -qfd; git pull -q "$REPO" "$LOCAL_BRANCH_BOT")
        		OUT=$?
        		if [[ $OUT -eq 0 ]] ; then
					log_empty
					log_success "PokemonGo-Bot has been updated"
					log_empty
					# update requirements after update
					activate_virtualenv
					update_req
					init_sub
					cd ..
					log_msg "Resetting bot variables..."
					LOCAL_BRANCH_BOT=""
					LOCAL_BOT=""
					REMOTE_BOT=""
					BOT_UPDATE=0
					log_done
					log_msg "Restarting wrapper..."
    				log_empty
					sleep 2
					exec ./start.sh
				else
					log_msg "Resetting bot variables..."
					LOCAL_BRANCH_BOT=""
					LOCAL_BOT=""
					REMOTE_BOT=""
					BOT_UPDATE=0
					log_done
					log_empty
					log_failure "PokemonGo-Bot update failed"
					log_empty
					log_msg "Restarting wrapper..."
    				log_empty
					cd ..
					sleep 2
					exec ./start.sh
				fi
 				;;
        	n|N) 
				log_empty
				log_failure "Update aborted"
				log_empty
				cd ..
				log_msg "Resetting bot variables..."
				LOCAL_BRANCH_BOT=""
				LOCAL_BOT=""
				REMOTE_BOT=""
				BOT_UPDATE=0
				log_done
				log_msg "Restarting wrapper.."
				sleep 2 
				exec ./start.sh
				;;
    	esac	
	else
		no_update_found		
		cd ..
		exec ./start.sh
	fi
}
update_exit() {
	clear
	print_banner "Change TOR exit country for bot $CONFIG"
	local COUNTRY=""
	source $BOT_CFG/$CONFIG
	print_msg_newline "At the moment TOR exits in $COUNTRY"
	rule
	log_msg "Just enter a name"
	log_empty
	rule
	read -p "Please choose: " N_COUNTRY
	case "$N_COUNTRY" in
		x) menu_wrapper_config ;;
		*)
		   ./tools/config.pl COUNTRY=$N_COUNTRY $PWD/$BOT_CFG/$CONFIG
		   menu_wrapper_config
		   ;;
	esac
}

update_nodes() {
	clear
	print_banner "Change number of TOR exit nodes for bot $CONFIG"
	local EXIT_NODES=""
	source $BOT_CFG/$CONFIG
	print_msg_newline "At the moment TOR has $EXIT_NODES exit nodes"
	rule
	log_msg "Just enter a number greater than 0"
	log_empty
	log_msg "Foolproof is for loosers, so really enter a number else it won't work"
	log_empty
	rule
	read -p "Please choose: " NODE
	case $NODE in
		x) menu_wrapper_config ;;
		*)
			./tools/config.pl EXIT_NODES=$NODE $PWD/$BOT_CFG/$CONFIG 
    		menu_wrapper_config
    		;;
    esac

}

update_req() {
	log_msg "Updating requirements..."	
	pip install --upgrade -qr requirements.txt && done_or_fail
}

update_wrapper() {
	clear
	print_banner "Updating PokemonGo-Bot wrapper in progress"
	log_msg "Checking branch..."
	if [[ "$LOCAL_BRANCH" != "$GITHUBBRANCH" ]]; then
		log_empty
		log_empty
		printf '%s\t%s\n' "WARNING: You're currently using $CURBRANCH branch, and this is not the default $GITHUBBRANCH branch."
		log_empty
		press_enter
		return 0
	fi
	print_msg_newline "[DONE]"
	log_msg "Fetching current version..."
	git fetch -q "$REPO" "$GITHUBBRANCH"
	if [[ "$LOCAL_WRAPPER" != "$REMOTE_WRAPPER" ]]; then
		log_empty
		log_empty
		print_msg_newline "Found new version!"
		print_msg_newline "Changelog:"
		print_msg_newline "=========="
    	while read line; do
        	((COUNT++))
        	LASTFOUND="$line"
        	printf '%s\n' "$LASTFOUND"
		done < <(git --no-pager log --abbrev-commit --decorate --date=relative --pretty=format:'%C(bold red)%h%Creset %C(bold green)(%cr)%Creset - %C(bold yellow)%s%Creset %C(bold blue)commited by%Creset %C(bold cyan)%an%Creset' "$LOCAL_WRAPPER..$REMOTE_WRAPPER")
		print_msg_newline "=========="
    	print_msg_newline "There is a difference of $COUNT commits between your version and the version on github"
		log_empty
		print_msg_newline "Continue updating PokemonGo-Bot_wrapper_osx?"
		log_empty
		read -p "Y/N: " CHOICE
		case "$CHOICE" in
        	y|Y) 		
				git pull -q "$REPO" "$GITHUBBRANCH" >/dev/null 2>&1 || (log_empty; printf '%s\t%s\n' "WARNING:" "PokemonGo-Bot_wrapper_osx could not apply update due to conflicts, forced update mode will be used now."; printf '\t\t%s\n' "Please make proper backups if you need any of your past projects before going to the next step"; log_empty; press_enter; log_empty; git reset -q --hard; git clean -qfd; git pull -q "$REPO" "$GITHUBBRANCH")
        		OUT=$?
        		if [[ $OUT -eq 0 ]] ; then
					log_empty
					log_success "PokemonGo-Bot_wrapper_osx has been updated"
					log_empty
					log_msg "Restarting wrapper..."
    				log_empty
					sleep 2
					exec ./start.sh
				else
					log_empty
					log_failure "PokemonGo-Bot_wrapper_osx update failed"
					log_empty
					log_msg "Restarting wrapper..."
    				log_empty
					sleep 2
					exec ./start.sh
				fi
 				;;
        	n|N) 
				log_empty
				log_failure "Update aborted"
				log_empty
				log_msg "Restarting wrapper..."
    			log_empty
				sleep 2 
				exec ./start.sh
				;;
    	esac	
	else
		no_update_found
		exec ./start.sh
	fi
}

# core app
start_up_checks
inflate_directories
while true ; do
	menu_main
done
