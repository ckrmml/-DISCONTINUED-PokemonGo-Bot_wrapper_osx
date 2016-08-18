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

# requirements arrays
TOOLS=(brew git python pip virtualenv wget ghead tor proxychains4) 
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
	PROXY=$1
    while read line ; do
        LASTFOUND="$line"
        if [[ -f "$line" ]] ; then
 			CHOICE="$(basename "$line")"
           	ACTIVE_CONFIG="$CHOICE"
            if [[ $PROXY -eq 1 ]] ; then
            	start_bot_file 1
            else
            	start_bot_file
            fi
        fi
    done < <(find ./PokemonGo-Bot/configs -type f -iname "*.json" -not -iname "*example*" -not -iname "*path*" -maxdepth 1)
}

check_admin() {
	log_msg "Checking if osx user is an admin..."
	if id -G $1 | grep -q -w 80 ; then
		print_msg_newline "[ADMIN]"
		touch tools/admin
	else
		local USER=$(whoami)
		print_msg_newline "[FAIL]"
		print_msg_newline ""
		printf '%s\t%s\n' "Error:" "Your OSX account [$USER] is not an admin account."
		printf '\t%s\n' "This can fail installing PokemonGo-Bot requirements and updating"
		printf '\t%s\n' "pip requirements, which in turn results in failing execution of the bot."
		print_msg_newline ""
		print_msg_newline ""
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
    	print_msg_newline ""
    	rule
    	print_msg_newline ""
    	printf '%s\t%s\n' "${RED}Error${NORMAL}:" "It looks like you don't have the required tool(s): "
		print_msg_newline ""
    	printf '\t' ""
    	printf '%s ' "${WHITE}${MISSINGTOOLS[@]}${NORMAL}"
    	print_msg_newline ""
    	print_msg_newline ""
    	printf '\t%s\n' "This check was made through 'which' command"
		printf '\t%s\n'	"Should we try to download and install the missing tools?"		
    	print_msg_newline ""
		rule
		read -p "Y/N: " CHOICE
		case "$CHOICE" in
        	y|Y) install_missing_tools ;;
        	n|N) 
        		rule 	
				print_msg_newline ""
        		printf '\t%s\n' "Please install missing tool(s) and relaunch PokemonGo-Bot wrapper script"
				print_msg_newline ""
				rule
				exit 1 ;;
    	esac	
	else
		print_msg_newline "[${GREEN}DONE${NORMAL}]"
	fi
	if [[ "$(brew list | grep protobuf >/dev/null; printf '%s\n' "$?")" -ne 0 ]] ; then
	    print_msg_newline ""
		rule
		print_msg_newline ""
		printf '%s\t%s\n' "${RED}Error${NORMAL}:" "It looks like you don't have"
		print_msg_newline ""
		printf '\t%s\n' "${WHITE}protobuf${NORMAL}"
		print_msg_newline ""
		printf '\t%s\n'	"installed. Should we try to download and install the missing tools?"		
		print_msg_newline ""
		rule
		read -p "Y/N: " CHOICE
		case "$CHOICE" in
			y|Y) install_missing_tools ;;
			n|N) 
				rule 	
				print_msg_newline ""
				printf '\t%s\n' "Please install protobuf and relaunch PokemonGo-Bot wrapper script"
				print_msg_newline ""
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
		print_msg_newline ""
		print_msg_newline "   Error code $OUT returned !! "
		print_msg_newline ""
		case $OUT in
			128) log_failure "This means the directory already exists" ;;
			*) log_failure "This error is unknown" ;;
		esac
		print_msg_newline ""
		log_msg "Exiting..."
		sleep 5
		exit 1
	fi
}

config_wrapper() {
	if [[ ! -f tools/$ACTIVE_CONFIG.config ]] ; then
		clear
		print_banner "Configuration"
		print_msg_newline "Would you like to proxy this bot over TOR?"
		print_msg_newline ""
		read -p "[Y/N]: " PROXY_THIS_BOT
		print_msg_newline ""
		print_msg_newline "Please choose a country for the TOR exit node"
		print_msg_newline ""
		read -p "[Y/N]: " COUNTRY
		print_msg_newline ""
		print_msg_newline "Would you like TOR to configure itself??"
		print_msg_newline ""
		read -p "[Y/N]: " SELF_CHOSEN
		print_msg_newline ""
		touch tools/$ACTIVE_CONFIG.config
		echo "PROXY_THIS_BOT=$PROXY_THIS_BOT" >> tools/$ACTIVE_CONFIG.config
		echo "COUNTRY=$COUNTRY" >> tools/$ACTIVE_CONFIG.config
		echo "SELF_CHOSEN=$SELF_CHOSEN" >> tools/$ACTIVE_CONFIG.config
		chmod +x tools/$ACTIVE_CONFIG.config
	else
		source tools/$ACTIVE_CONFIG.config
		log_success "Successfully loaded $ACTIVE_CONFIG wrapper configuration file"
	fi
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
		print_msg_newline ""
		print_msg_newline "   Error code $OUT returned !! "
		print_msg_newline ""
		log_msg "Exiting..."
		sleep 5
		exit 1
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
	done_or_fail
	log_success "Installation of encrypt.so complete"
	log_msg "Restarting wrapper..." 
    print_msg_newline ""
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
			print_msg_newline ""
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
		elif [[ "$MISSINGTOOL" == ghead ]] ; then
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
    print_msg_newline ""
	sleep 2
	exec ./start.sh	
}

install_pip_req() {
	log_msg "Install requirements..."
	pip install -qr requirements.txt 2>/dev/null && done_or_fail
}

log_done() {
	printf '%s\n' "[${GREEN}DONE${NORMAL}]"
}

log_fail() {
	printf '%s\n' "[${RED}FAIL${NORMAL}]"
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

menu_configure() {
 echo "Nothing yet"
 return 1
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
	if [[ -d ./PokemonGo-Bot ]] && [[ -f ./tools/clone ]] ; then
		if [[ ! -n "$(find ./PokemonGo-Bot/configs -maxdepth 1 -name '*.json' -not -iname '*example*' -print -quit)" ]] ; then
			rule
			print_msg_newline ""
			printf '\t%s\n' "Please go to "
			print_msg_newline ""
			printf '\t%s\n' "$PWD/PokemonGo-Bot/configs"
			print_msg_newline ""
			printf '\t%s\n' "and create a configuration file to continue."
			printf '\t%s\n' "After you have done this, please enter 'r' "
			printf '\t%s\n' "or 'R' as choice or restart the wrapper."
			print_msg_newline ""
			rule
		fi
	elif [[ -d ./PokemonGo-Bot ]] && [[ ! -f ./tools/clone ]] ; then
		if [[ ! -n "$(find ./PokemonGo-Bot/configs -maxdepth 1 -name '*.json' -not -iname '*example*' -print -quit)" ]] ; then
			rule
			print_msg_newline ""
			printf '\t%s\n' "Please go to "
			print_msg_newline ""
			printf '\t%s\n' "$PWD/PokemonGo-Bot/configs"
			print_msg_newline ""
			printf '\t%s\n' "and create a configuration file to continue."
			printf '\t%s\n' "After you have done this, please enter 'r' "
			printf '\t%s\n' "or 'R' as choice or restart the wrapper."
			print_msg_newline ""
		else
			rule
			print_msg_newline ""
			printf '\t%s\n' "It looks like you copied over an instance of the bot you had installed before."
			printf '\t%s\n' "If starting a bot does not work, try entering setup as choice."
			print_msg_newline ""
		fi
	fi
	if [[ -d PokemonGo-Bot ]] && [[  -f ./PokemonGo-Bot/encrypt.so ]] ; then
		if [[ -n "$(find ./PokemonGo-Bot/configs -maxdepth 1 -name '*.json' -not -iname '*example*' -print -quit)" ]] ; then
			rule
			print_command s "Start PokemonGo-Bot"
			print_command w "Start web interface"
			if [[ $BOT_UPDATE -eq 1 ]] && [[ $WRAPPER_UPDATE -eq 1 ]] ; then
				print_command u "Update menu"
        	elif [[ $BOT_UPDATE -eq 1 ]] && [[ $WRAPPER_UPDATE -eq 0 ]] ; then
				print_command u "Update bot"
        	elif [[ $BOT_UPDATE -eq 0 ]] && [[ $WRAPPER_UPDATE -eq 1 ]] ; then
				print_command u "Update wrapper"
        	fi
		fi
	fi
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
        setup) 
			cd "PokemonGo-Bot"
			setup_virtualenv
			activate_virtualenv
			install_pip_req
			init_sub
			cd ..
			exec ./start.sh ;;
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
    print_msg_newline ""
    print_msg_newline "=-=-=-=-=-=-=-=-=-==-=-=-="
 	while IFS= read -d $'\0' -r file ; do     
 		((COUNT++))
     	file_list[$i]=$file
  		i=$(($i+1))
	printf '%s\n' "$(basename "${file_list[@]}")"
 	done < <(find PokemonGo-Bot/configs -type f -iname "*.json" -not -iname "*example*" -not -iname "*path*" -maxdepth 1 -print0) # Avoid a subshell, because we must remember variables
    print_msg_newline "=-=-=-=-=-=-=-=-=-==-=-=-="
    print_msg_newline "$COUNT config files were found"
	print_msg_newline ""
    read -p "Please choose (x to return): " CHOICE
	case "$CHOICE" in
	  	x|X) return 0 ;;
        a|A) batch_start ;; 
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
	print_command x "Return"
	rule
	read -p "Please choose: " CHOICE
    case "$CHOICE" in
        b|B) update_bot ;;
        w|W) update_wrapper ;;
        x|X) return 0 ;;
    esac
}

no_update_found() {
	log_done
	print_msg_newline ""
	print_msg_newline ""
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
		printf '%s\n' "You are currently on [${YELLOW}"$LOCAL_BRANCH_BOT"${NORMAL}] branch of PokemonGo-Bot"
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

setup_virtualenv() {
	log_msg "Setting up Python virtualenv..."
	virtualenv -q . 2>/dev/null && done_or_fail
}

start_bot_file() {
	export PROXY_THIS_BOT=""
	export COUNTRY=""
	export SELF_CHOSEN=""
    config_wrapper
    echo "$PROXY_THIS_BOT"
    echo "$COUNTRY"
    echo "$SELF_CHOSEN"
    TMP_FILE="$CMD_DIR/$ACTIVE_CONFIG.command"
	if [[ $PROXY_THIS_BOT == y ]] ; then
		proxy_bot
	fi
	log_header "Generating bot start command"
	log_msg "Read and copy template file..."
	while read line ; do
		echo "$line" >> $TMP_FILE
	done < $TEMPLATE_DIR/command_template
	done_or_fail
	log_msg "Copying over routines..."
    # Change to directory
    echo "cd $(pwd)" >> $TMP_FILE
	echo "" >> $TMP_FILE
    # Copy over while loop
	echo "print_msg_newline \"\"" >> $TMP_FILE
	echo "cd "PokemonGo-Bot"" >> $TMP_FILE
	echo "echo $PWD" >> $TMP_FILE
	echo "activate_virtualenv" >> $TMP_FILE
	echo "print_msg_newline \" - Executing PokemonGo-Bot with config $ACTIVE_CONFIG...\"" >> $TMP_FILE
	echo "print_msg_newline \"\"" >> $TMP_FILE
	echo "while true ; do" >> $TMP_FILE
	if [[ $PROXY_THIS_BOT == y ]] ; then
		echo "	proxychains4 -f $PROXY_CONF python pokecli.py -cf configs/$ACTIVE_CONFIG" >> $TMP_FILE
	else
		echo "	python pokecli.py -cf configs/$ACTIVE_CONFIG" >> $TMP_FILE
	fi
	echo "	print_msg_newline \"\"" >> $TMP_FILE
	echo "	print_msg_newline \" - PokemonGo-Bot exited...\"" >> $TMP_FILE
	echo "	print_msg_newline \" - Restarting in five seconds...\"" >> $TMP_FILE
	echo "	print_msg_newline \"\"" >> $TMP_FILE
	echo "	sleep 5;" >> $TMP_FILE
	echo "done" >> $TMP_FILE
	done_or_fail
	log_msg "Executing bot start command file..."
    chmod +x "$TMP_FILE"
    open -b com.apple.terminal "$TMP_FILE"
    done_or_fail
    log_success "Finished writing bot start command"
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
	sleep 2
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
    print_msg_newline ""
    print_msg_newline "Should we open localhost:8000 in you standard webbrowser?"
	print_msg_newline ""
	read -p "[Y|N]: " CHOICE
	case $CHOICE in
		y|Y)
			print_msg_newline ""
			log_msg "Opening web interface..."
			open http://localhost:8000
			log_done
			;;
		n|N)
			print_msg_newline ""
    		printf '\t%s\n' "Open your browser and visit the site:"
    		printf '\t%s\n' "http://localhost:8000"
    		printf '\t%s\n' "to view the map"
			print_msg_newline ""
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
		print_msg_newline ""
		print_msg_newline ""
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
		print_msg_newline ""
		print_msg_newline "Continue updating PokemonGo-Bot?"
		print_msg_newline ""
		read -p "Y/N: " CHOICE
		case "$CHOICE" in
        	y|Y) 		
        		git pull -q >/dev/null 2>&1 || (print_msg_newline ""; printf '%s\t%s\n' "WARNING:" "PokemonGo-Bot_wrapper_osx could not apply update due to conflicts, forced update mode will be used now."; printf '\t\t%s\n' "Please make proper backups if you need any of your past projects before going to the next step"; print_msg_newline ""; press_enter; print_msg_newline ""; git reset -q --hard; git clean -qfd; git pull -q "$REPO" "$LOCAL_BRANCH_BOT")
        		OUT=$?
        		if [[ $OUT -eq 0 ]] ; then
					print_msg_newline ""
					log_success "PokemonGo-Bot has been updated"
					print_msg_newline ""
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
    print_msg_newline ""
					sleep 2
					exec ./start.sh
				else
					log_msg "Resetting bot variables..."
					LOCAL_BRANCH_BOT=""
					LOCAL_BOT=""
					REMOTE_BOT=""
					BOT_UPDATE=0
					log_done
					print_msg_newline ""
					log_failure "PokemonGo-Bot update failed"
					print_msg_newline ""
					log_msg "Restarting wrapper..."
    print_msg_newline ""
					cd ..
					sleep 2
					exec ./start.sh
				fi
 				;;
        	n|N) 
				print_msg_newline ""
				log_failure "Update aborted"
				print_msg_newline ""
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

update_req() {
	log_msg "Updating requirements..."	
	pip install --upgrade -qr requirements.txt && done_or_fail
}

update_wrapper() {
	clear
	print_banner "Updating PokemonGo-Bot wrapper in progress"
	log_msg "Checking branch..."
	if [[ "$LOCAL_BRANCH" != "$GITHUBBRANCH" ]]; then
		print_msg_newline ""
		print_msg_newline ""
		printf '%s\t%s\n' "WARNING: You're currently using $CURBRANCH branch, and this is not the default $GITHUBBRANCH branch."
		print_msg_newline ""
		press_enter
		return 0
	fi
	print_msg_newline "[DONE]"
	log_msg "Fetching current version..."
	git fetch -q "$REPO" "$GITHUBBRANCH"
	if [[ "$LOCAL_WRAPPER" != "$REMOTE_WRAPPER" ]]; then
		print_msg_newline ""
		print_msg_newline ""
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
		print_msg_newline ""
		print_msg_newline "Continue updating PokemonGo-Bot_wrapper_osx?"
		print_msg_newline ""
		read -p "Y/N: " CHOICE
		case "$CHOICE" in
        	y|Y) 		
				git pull -q "$REPO" "$GITHUBBRANCH" >/dev/null 2>&1 || (print_msg_newline ""; printf '%s\t%s\n' "WARNING:" "PokemonGo-Bot_wrapper_osx could not apply update due to conflicts, forced update mode will be used now."; printf '\t\t%s\n' "Please make proper backups if you need any of your past projects before going to the next step"; print_msg_newline ""; press_enter; print_msg_newline ""; git reset -q --hard; git clean -qfd; git pull -q "$REPO" "$GITHUBBRANCH")
        		OUT=$?
        		if [[ $OUT -eq 0 ]] ; then
					print_msg_newline ""
					log_success "PokemonGo-Bot_wrapper_osx has been updated"
					print_msg_newline ""
					log_msg "Restarting wrapper..."
    print_msg_newline ""
					sleep 2
					exec ./start.sh
				else
					print_msg_newline ""
					log_failure "PokemonGo-Bot_wrapper_osx update failed"
					print_msg_newline ""
					log_msg "Restarting wrapper..."
    print_msg_newline ""
					sleep 2
					exec ./start.sh
				fi
 				;;
        	n|N) 
				print_msg_newline ""
				log_failure "Update aborted"
				print_msg_newline ""
				log_msg "Restarting wrapper..."
    print_msg_newline ""
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
log_msg "Inflating tmp dir..."
if [[ ! -d $TMP_DIR ]] ; then
	mkdir $TMP_DIR
fi
log_done
while true ; do
	menu_main
done
