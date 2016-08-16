#!/bin/bash

# Most of this script is written by me.
# Requirements check function, update function and parts of the start bot menu 
# is taken from ArchiKitchen and was changed to fit the needs of this project.
# The config.pl Perl script is from Stephen Ostermiller on unix.stackexchange.com
# answer two in this thread: 
# http://unix.stackexchange.com/questions/139574/change-a-value-in-a-config-file-or-add-the-setting-if-it-doesnt-exist
# 


#
#	TO-DO
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

set -x

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
export TMP_DIR=tools/tmp 
export NODE_DIR=tools/tor_nodes
export TOR_CFG=tools/tor_configs
export TOR_DATA=tools/tor_data
export PROXYCHAINS_CFG=tools/proxychains_configs
export TEMPLATE_DIR=tools/templates

# file variables
export EXIT_TMP=exit_nodes
export PROXY_CONF=""
export TOR_CONF=""

# requirements arrays
TOOLS=(brew git python pip virtualenv ghead tor proxychains4) 
MISSINGTOOLS=()

## script functions
activate_virtualenv()
{
	print_msg ">>> Activating Python virtualenv..."
	source bin/activate 2>/dev/null && done_or_fail
}

batch_start()
{
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

check_admin()
{
	print_msg ">>> Checking if osx user is an admin..."
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
		printf '\t%s\n' "Trying to restart the script with sudo -k "
		print_msg_newline ""
    	printf '\t%s\n' "Please enter [$USER] login password when prompted."
    	print_msg_newline ""
    	exec sudo -k ./start.sh
	fi
}

check_ip()
{
	curl --socks5-hostname localhost:9048 http://ipecho.net/plain
}

check_port_uniqueness()
{
	if [[ ! -f $NODE_DIR/Ports ]] ; then
		touch $NODE_DIR/ports && chmod 755 $NODE_DIR/ports
		echo "$SOCKS_PORT" >>$NODE_DIR/ports
		echo "$CONTROL_PORT" >>$NODE_DIR/ports
		echo "SOCKSPort $SOCKS_PORT" >>$TOR_CFG/torrc.$COUNT_SCND
		echo "ControlPort $CONTROL_PORT" >>$TOR_CFG/torrc.$COUNT_SCND

	else
		print_msg_newline ">>> Checking if Ports are unique..."	
		if [[ "$(cat $NODE_DIR/ports | grep $SOCKS_PORT >/dev/null; printf '%s\n' "$?")" -ne 1 ]] ; then 
			print_msg_newline ""
			print_msg_newline "<!> SOCKSPort was used before <!>"
			print_msg_newline ""
			print_msg_newline ">>> Restarting Port generation..."
			socks_port_generation
		else	
			if [[ "$(cat $NODE_DIR/ports | grep $CONTROL_PORT >/dev/null; printf '%s\n' "$?")" -ne 1 ]] ; then 
				print_msg_newline ""
				print_msg_newline "<!> ControlPort was used before <!>"
				print_msg_newline ""
				print_msg_newline ">>> Restarting Port generation..."
				socks_port_generation
			else
				print_msg_newline "<x> Ports are unique <x>"
				echo "$SOCKS_PORT" >>$NODE_DIR/ports
				echo "$CONTROL_PORT" >>$NODE_DIR/ports
				echo "SOCKSPort $SOCKS_PORT" >>$TOR_CFG/torrc.$COUNT_SCND
				echo "ControlPort $CONTROL_PORT" >>$TOR_CFG/torrc.$COUNT_SCND
			fi
		fi
	fi
}

check_subnet_uniqueness()
{
	print_msg_newline ">>> Checking if remote DNS subnet valid..."	
	if [ "$REMOTE_SUBNET" -ge 0 -a "$REMOTE_SUBNET" -le 255 ] ; then
		print_msg_newline "<x> Remote DNS subnet is valid <x>"
		if [[ ! -f $NODE_DIR/subnets ]] ; then
			touch $NODE_DIR/subnets
			echo "$REMOTE_SUBNET" >>$NODE_DIR/subnets
		else
			print_msg_newline ">>> Checking if remote DNS subnet is unique..."	
			if [[ "$(cat $NODE_DIR/subnets | grep $REMOTE_SUBNET >/dev/null; printf '%s\n' "$?")" -ne 1 ]] ; then 
				print_msg_newline ""
				print_msg_newline "<!> Remote DNS subnet was used before <!>"
				print_msg_newline ""
				print_msg_newline ">>> Restarting subnet generation..."
				random_subnet_generation
			else	
				print_msg_newline "<x> Remote DNS subnet is unique <x>"
				echo "$REMOTE_SUBNET" >>$NODE_DIR/subnets
			fi
		fi
	else
		print_msg_newline ""
		print_msg_newline "<!> Remote DNS subnet is invalid <!>"
		print_msg_newline ""
		print_msg_newline ">>> Restarting subnet generation..."
		random_subnet_generation
	fi
}

check_tools()
{
	print_msg ">>> Checking for PokemonGo-Bot requirements..."
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
    	printf '%s\t%s\n' "Error:" "It looks like you don't have the required tool(s): "
		print_msg_newline ""
    	printf '\t' ""
    	printf '%s ' "${MISSINGTOOLS[@]}"
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
		touch tools/depmet
		print_msg_newline "[DONE]"
	fi
}

check_updates_bot()
{
	if [[ -d ./PokemonGo-Bot ]] ; then
		cd PokemonGo-Bot
		print_msg ">>> Checking for PokemonGo-Bot updates..."
		if [[ "$(git remote | grep -qi "$REPO"; echo $?)" -ne 0 ]]; then
			git remote add -t "$LOCAL_BRANCH_BOT" -m "$LOCAL_BRANCH_BOT" "$REPO" "$GITHUBLINK_BOT"
		fi
		git fetch -q origin
#		LOCAL_BRANCH_BOT="$(git rev-parse --abbrev-ref HEAD)"
#		LOCAL_BOT="$(git rev-parse @)"
#		REMOTE_BOT="$(git rev-parse origin/dev)"
		if [[ "$LOCAL_BOT" != "$REMOTE_BOT" ]] ; then
    		BOT_UPDATE=1
		fi			
		done_or_fail
		cd ..
	fi
}

check_updates_wrapper()
{
	print_msg ">>> Checking for wrapper updates..."
	if [[ "$(git remote | grep -qi "$REPO"; echo $?)" -ne 0 ]]; then
		git remote add -t "$LOCAL_BRANCH_WRAPPER" -m "$LOCAL_BRANCH_WRAPPER" "$REPO" "$GITHUBLINK"
	fi
	git fetch -q origin
	if [[ "$LOCAL_WRAPPER" != "$REMOTE_WRAPPER" ]]; then
		WRAPPER_UPDATE=1
	fi
	done_or_fail
}

choose_country()
{
	read -p "Please choose an exit country: " CHOICE
	while read line ; do
		COUNTRY_CHOICE=$(grep -i $CHOICE | grep -o '....$' | tail -c +2 | head -c +2)
		NODE_TMP=$COUNTRY_CHOICE.txt
		CC_EXIT_NODES=tmp_nodes_$COUNTRY_CHOICE.txt
		VALID_EXIT_NODES=$NODE_DIR/exit_nodes_$COUNTRY_CHOICE.txt
	done < tools/templates/country_codes
}

chosen_node()
{
	print_msg_newline ">>> Writing TOR config file" 
	echo "" >>$TOR_CFG/torrc.$COUNT_SCND
	echo "" >>$TOR_CFG/torrc.$COUNT_SCND
	echo "ExitNodes \$$NODE_CHOICE" >>$TOR_CFG/torrc.$COUNT_SCND
	echo "StrictNodes 1" >>$TOR_CFG/torrc.$COUNT_SCND
	echo "" >>$TOR_CFG/torrc.$COUNT_SCND
	echo "" >>$TOR_CFG/torrc.$COUNT_SCND
	echo "DataDirectory $PWD/$TOR_DATA/$COUNT_SCND" >>$TOR_CFG/torrc.$COUNT_SCND
#	mkdir $TOR_DATA/$COUNT_SCND && chmod 755 $TOR_DATA/$COUNT_SCND
	socks_port_generation
	print_msg_newline ">>> Finished writing TOR config file"
}

clone_bot_git()
{
	clear
	branch=$1
	print_banner "Installing PokemonGo-Bot"
	print_msg ">>> Cloning $branch branch..."
	git clone -q -b $branch https://github.com/PokemonGoF/PokemonGo-Bot 2>/dev/null
	OUT=$?
	if [ $OUT -eq 0 ] ; then
	touch ./tools/clone
	print_msg_newline "[DONE]"
	else
		print_msg_newline "[FAIL]"
		print_msg_newline ""
		print_msg_newline "   Error code $OUT returned !! "
		print_msg_newline ""
		case $OUT in
			128) print_msg_newline "<!> This means the directory already exists <!>" ;;
			*) print_msg_newline "<!> This error is unknown <!>" ;;
		esac
		print_msg_newline ""
		print_msg_newline ">>> Exiting..."
		sleep 5
		exit 1
	fi
}

create_node_list()
{
	print_msg ">>> Creating exit node list..."
	if [[ ! -f $VALID_EXIT_NODES ]] ; then
		curl "https://onionoo.torproject.org/summary?flag=exit" 2>/dev/null >$TMP_DIR/$EXIT_TMP
		curl "https://onionoo.torproject.org/summary?country=$COUNTRY_CHOICE" 2>/dev/null >$TMP_DIR/$NODE_TMP

		awk 'FNR==NR{a[$1];next}($1 in a){print}' "$TMP_DIR/$NODE_TMP" "$TMP_DIR/$EXIT_TMP" >$TMP_DIR/$CC_EXIT_NODES
		awk 'FNR==NR{a[$1];next}($1 in a){print}' "$TMP_DIR/$NODE_TMP" "$TMP_DIR/$EXIT_TMP" | tail -n +4 | ghead -n -4 | cut -d "\"" -f 8 | grep -v '^[\.[:digit:]]*$' >$VALID_EXIT_NODES

		rm -f tmp/$EXIT_TMP
		rm -f tmp/$NODE_TMP
		print_msg_newline "[DONE]"
	else
		print_msg_newline ""
		print_msg_newline ">>> There already is an exit node list for that country. Should we generate a new one?"
		print_msg_newline ""
		read -p "[Y/N]: " CHOICE
		case $CHOICE in
			y|Y)
				rm -f $VALID_EXIT_NODES
				create_node_list
				;;
			n|N) return 0
		esac
	fi
}

debug_screen()
{
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

done_or_fail()
{
	OUT=$?
	if [[ $OUT -eq 0 ]] ; then
		print_msg_newline "[DONE]"
	else
		print_msg_newline "[FAIL]"
		print_msg_newline ""
		print_msg_newline "   Error code $OUT returned !! "
		print_msg_newline ""
		print_msg_newline ">>> Exiting..."
		sleep 5
		exit 1
	fi
}	

dump_cookie()
{
	print_msg ">>> Dumping tor auth cookie..."
	AUTH_COOKIE="$(hexdump -e '32/1 "%02x""\n"' tools/tor_data$COUNT_SCND/control_auth_cookie)"
	print_msg_newline "[DONE]"
}

inflate_dirs()
{
	print_msg ">>> Inflating directories..."
	if [[ $OPTION -eq 2 ]] ; then
		if [[ ! -d $TMP_DIR ]] ; then
			mkdir $TMP_DIR
		fi

		if [[ ! -d $NODE_DIR ]] ; then
			mkdir $NODE_DIR
		fi
	fi
	if [[ ! -d $PROXYCHAINS_CFG ]] ; then
		mkdir $PROXYCHAINS_CFG
	fi
		
	if [[ ! -d $tmp_cmd ]] ; then
		mkdir tmp_cmd
	fi
	
	if [[ ! -d $TOR_CFG ]] ; then
		mkdir $TOR_CFG
	fi

	if [[ ! -d $TOR_DATA ]] ; then
		mkdir $TOR_DATA
	fi
	
	print_msg_newline "[DONE]"
}

init_sub()
{
	print_msg ">>> Initializing submodule..."
	cd web && git submodule -q init 2>/dev/null && done_or_fail && cd ..	
	print_msg ">>> Updating submodule..."
	git submodule -q update 2>/dev/null && done_or_fail
}

install_bot()
{
	clone_bot_git $BRANCH
	cd "PokemonGo-Bot"
	setup_virtualenv
	activate_virtualenv
	install_pip_req
	init_sub
	cd ..
	install_lib_crypt
}

install_lib_crypt()
{
	print_msg_newline ""
	print_msg_newline ">>> Installing libencrypt.so <<<"
	print_msg_newline ""
	print_msg ">>> Attempting to download pgoencrypt.tar.gz..."
	cd $TMP_DIR
	wget --quiet http://pgoapi.com/pgoencrypt.tar.gz 
	done_or_fail
	print_msg ">>> Unarchiving pgoencrypt.tar.gz..."
	tar -xf pgoencrypt.tar.gz
	done_or_fail
	cd pgoencrypt/src/
	print_msg ">>> Attempting to make libencrypt.so..."
	make -s 2>/dev/null 
	done_or_fail
	print_msg ">>> Renaming libencrypt.so to encrypt.so..."		
	mv libencrypt.so encrypt.so
	done_or_fail
	cd .. && cd .. && cd ..
	print_msg ">>> Moving encrypt.so to PokemonGo-Bot directory..."		
	ditto $TMP_DIR/pgoencrypt/src/encrypt.so PokemonGo-Bot/encrypt.so
	done_or_fail
	print_msg ">>> Cleaning up..."
	rm -rf $TMP_DIR/pgoencrypt
	done_or_fail
	print_msg_newline ""
	print_msg_newline "<x> Installation of encrypt.so complete <x>"
	print_msg_newline ""
	print_msg_newline ">>> Restarting wrapper..." 
	sleep 3
	exec ./start.sh
}

install_missing_tools()
{
	clear
	print_banner "PokemonGo-Bot Wrapper OSX"
	print_msg_newline "If installation should fail, you have to manually install from an admin account"
	rule
	for MISSINGTOOL in "${MISSINGTOOLS[@]}" ; do
		if [[ "$MISSINGTOOL" == brew ]] ; then
			print_msg_newline ">>> Attempting to install homebrew <<<"
			print_msg_newline ">>> Using Homebrew install command..."
			print_msg_newline ""
			/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"	
			print_msg_newline ""
			print_msg_newline ">>>Restarting wrapper because homebrew is needed for some installations..."
			sleep 2
			exec ./start.sh
		elif [[ "$MISSINGTOOL" == git ]] ; then
			print_msg_newline ">>> Attempting to install git <<<"
			print_msg ">>> Using Homebrew git formula..."
			brew --quiet install git	
			done_or_fail
			print_msg_newline ""
		elif [[ "$MISSINGTOOL" == python ]] ; then
			print_msg_newline ">>> Attempting to install python <<<"
			print_msg ">>> Using Homebrew python formula..."
			brew --quiet install python	
			done_or_fail
			print_msg ">>> Updating pip..."
			pip install -qU pip
			done_or_fail
			print_msg_newline ""
			print_msg_newline ">>> Restarting wrapper because installing python should also have installed pip and virtualenv..."
			sleep 2
			exec ./start.sh
		elif [[ "$MISSINGTOOL" == pip ]] ; then
			print_msg_newline ">>> Attempting to install pip <<<"
			cd $TMP_DIR
			print_msg ">>> Downloading get-pip.py..."
			wget --quiet https://bootstrap.pypa.io/get-pip.py			
			done_or_fail
			print_msg ">>> Executing get-pip.py..."
			python get-pip.py 2>/dev/null
			done_or_fail
			cd ..
			print_msg ">>> Cleaning up..."
			rm -rf $TMP_DIR/get-pip.py
			done_or_fail
			print_msg_newline ""
		elif [[ "$MISSINGTOOL" == virtualenv ]] ; then
			print_msg_newline ">>> Attempting to install virtualenv <<<"
			print_msg ">>> Using pip virtualenv command..."
			pip install -q virtualenv			
			done_or_fail
			print_msg_newline ""
		elif [[ "$MISSINGTOOL" == ghead ]] ; then
			print_msg_newline ">>> Attempting to install ghead <<<"
			print_msg ">>> Using Homebrew coreutils formula..."
			brew --quiet install coreutils			
			done_or_fail
			print_msg_newline ""
		elif [[ "$MISSINGTOOL" == tor ]] ; then
			print_msg_newline ">>> Attempting to install tor <<<"
			print_msg ">>> Using Homebrew tor formula..."
			brew --quiet install tor			
			done_or_fail
			print_msg_newline ""
		elif [[ "$MISSINGTOOL" == proxychains4 ]] ; then
			print_msg_newline ">>> Attempting to install proxychains4 <<<"
			print_msg ">>> Using Homebrew proxychains4 formula..."
			brew --quiet install proxychains-ng			
			done_or_fail
			print_msg_newline ""
		fi
	done
	print_msg_newline ">>> Restarting wrapper..."
	sleep 2
	exec ./start.sh	
}

install_pip_req()
{
	print_msg ">>> Install requirements..."
	pip install -qr requirements.txt 2>/dev/null && done_or_fail
}

menu_branch()
{
	clear
	print_banner "PokemonGo-Bot Wrapper OSX"
	print_msg_newline ""
	print_command m "Choose master branch"
	print_command d "Choose dev branch"
	print_msg_newline ""
	print_command x "Return"
	print_msg_newline ""
	read -p "Please choose: " CHOICE
    case "$CHOICE" in
        m|M) BRANCH=master 
        	install_bot ;;
        d|D) BRANCH=dev 
        	install_bot ;;
        x|X) return 0 ;;
    esac
}

menu_configure()
{
 echo "Nothing yet"
 return 1
}

menu_main()
{
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

menu_start()
{
    clear
    print_banner "Proxy bots over TOR"
	print_msg_newline "Start bots over TOR?"
    print_msg_newline ""
    read -p "[Y/N] :" PROXY
    
    clear
    local COUNT=0
    file_list=()
	print_banner "Start bot(s)"
    print_msg_newline "Searching for configuration files you've created in the past..."
    print_msg_newline "=-=-=-=-=-=-=-=-=-==-=-=-="
 	while IFS= read -d $'\0' -r file ; do     
 		((COUNT++))
		file_list=("${file_list[@]}" "$file")
 	done < <(find ./PokemonGo-Bot/configs -type f -iname "*.json" -not -iname "*example*" -not -iname "*path*" -maxdepth 1 -print0) # Avoid a subshell, because we must remember variables
	printf '%s\n' "$(basename "${file_list[@]}")"
    print_msg_newline "=-=-=-=-=-=-=-=-=-==-=-=-="
    print_msg_newline "$COUNT config files were found"
	print_msg_newline ""
    if [[ "$COUNT" -eq 1 ]]; then
        ACTIVE_CONFIG="$(basename "$LASTFOUND")" # If we have only one config file, there's nothing to choose from, so we can save some precious seconds
        start_bot_file
    fi
    case $PROXY in
    	y|Y)
    		read -p "Please choose (x to return): " CHOICE
    		case "$CHOICE" in
        	x|X) return 0 ;;
        	a|A) batch_start 1 
        		;; 
       	 	*)
				for config in $CHOICE ; do
        			if [[ -f "./PokemonGo-Bot/configs/$config" ]] ; then
            			ACTIVE_CONFIG="$config"
            			start_bot_file 1
					else
            			print_msg_newline "<!> Invalid selection <!>"
						press_enter        	
					fi
        		done
        		;;
    		esac
    		;;
    	n|N)
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
            			print_msg_newline "<!> Invalid selection <!>"
						press_enter        	
					fi
        		done
        		;;
    		esac
    		;;
    esac
}

menu_update()
{
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

no_update_found()
{
	print_msg "[DONE]"
	print_msg_newline ""
	print_msg_newline ""
	print_msg_newline ">>> No new updates found"
	sleep 1
}

populate_variables() 
{
	if [[ -d ./PokemonGo-Bot ]] ; then
		cd "PokemonGo-Bot"
		print_msg ">>> Populating bot specific variables..."
		LOCAL_BRANCH_BOT="$(git rev-parse --abbrev-ref HEAD)"
		LOCAL_BOT="$(git rev-parse @)"
		REMOTE_BOT="$(git rev-parse origin/$LOCAL_BRANCH_BOT)"
		print_msg_newline "[DONE]"
		cd ..
	fi
	print_msg ">>> Populating wrapper specific variables..."
	LOCAL_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
	LOCAL_WRAPPER="$(git rev-parse @)"
	REMOTE_WRAPPER="$(git rev-parse @{u})"
	print_msg_newline "[DONE]" 
} 

press_enter()
{
    read -p "Press [Enter] key to continue..."
}

print_banner()
{
	text=$1
	rule
	printf '%s\n' "$text" | fmt -c -w $(tput cols)
	rule
}

print_command() 
{
    command=$1
    description=$2
    printf ' %s - %s\n' $command "$description"
}

print_hu() 
{
	if [[ -d ./PokemonGo-Bot ]] ; then
		printf '%s\n' "You are currently on ["$LOCAL_BRANCH_BOT"] branch of PokemonGo-Bot"
		if [[ $BOT_UPDATE -eq 1 ]]; then
			print_msg " -> Your local bot is on commit: "
			print_msg "$LOCAL_BOT" | cut -c1-7
			print_msg " -> Newest commit on github is : "
			print_msg "$REMOTE_BOT" | cut -c1-7
		else
			print_msg_newline " -> This is the newest version"
		fi
	else
			print_msg_newline " -> You have not installed PokemonGo-Bot yet"
	fi
#	print_msg_newline "At the moment you have $(ps a | grep "*.json.command" | wc -l) bots running."
}

print_msg() 
{
    text=$1
    printf '%s' "$text"
}

print_msg_newline() 
{
    text=$1
    printf '%s\n' "$text"
}

proxy_bot()
{
	clear
	print_banner "Configuring TOR proxy"
	tor_configurator
	proxychains_configurator
}

proxychains_configurator()
{
	random_subnet_generation
	print_msg ">>> Generating proxychains4 config file..."
	cp -f tools/templates/proxychains.conf.sample $PROXYCHAINS_CFG/pc$COUNT_SCND.conf && chmod 755 $PROXYCHAINS_CFG/pc$COUNT_SCND.conf
	echo "proxy_dns" >>$PROXYCHAINS_CFG/pc$COUNT_SCND.conf
	echo "remote_dns_subnet $REMOTE_SUBNET" >>$PROXYCHAINS_CFG/pc$COUNT_SCND.conf
	echo ""
	echo "[ProxyList]" >>$PROXYCHAINS_CFG/pc$COUNT_SCND.conf
	echo "socks4 	127.0.0.1 $SOCKS_PORT" >>$PROXYCHAINS_CFG/pc$COUNT_SCND.conf
	print_msg_newline "[DONE]"
	PROXY_CONF=$PWD/$PROXYCHAINS_CFG/pc$COUNT_SCND.conf
}

random_subnet_generation()
{
	print_msg ">>> Generating random remote DNS subnet..."
	REMOTE_SUBNET=$(head -200 /dev/urandom | cksum | cut -f1 -d " " | fold -w 3 | head -n 1)
	print_msg_newline "[DONE]"
	check_subnet_uniqueness
}

rule()
{
	printf -v _hr "%*s" $(tput cols) && echo ${_hr// /${1--}}
}


setup_virtualenv()
{
	print_msg ">>> Setting up Python virtualenv..."
	virtualenv -q . 2>/dev/null && done_or_fail
}

socks_port_generation()
{
	print_msg ">>> Generating random SOCKSPort..."
	SOCKS_PORT=$(head -200 /dev/urandom | cksum | cut -f1 -d " " | fold -w 4 | head -n 1)
	print_msg_newline "[DONE]"
	
	print_msg ">>> Generating random ControlPort..."
	CONTROL_PORT=$(($SOCKS_PORT+1))
	print_msg_newline "[DONE]"
	
	check_port_uniqueness
}

start_bot_file() 
{
	PROXY=$1
	clear
	if [[ $PROXY -eq 1 ]] ; then
		proxy_bot
	fi
	print_banner "Writing and executing bot start command file"
    TMP_FILE="tmp_cmd/$ACTIVE_CONFIG.command"
	print_msg ">>> Read and copy template file..."
	while read line ; do
		echo "$line" >> $TMP_FILE
	done < $TEMPLATE_DIR/command_template
	done_or_fail
	print_msg ">>> Copying over routines..."
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
	if [[ $PROXY -eq 1 ]] ; then
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
	print_msg ">>> Executing bot start command file..."
    chmod +x "$TMP_FILE"
    open -b com.apple.terminal "$TMP_FILE"
    done_or_fail
    sleep 3
    #print_msg ">> Deleting bot start command file..."
    #rm -f ./*.command
    #done_or_fail
    print_msg_newline ">>> Returning to main menu..."
}

start_up_checks() 
{
	clear
	print_banner "Start-up checks"
	if [[ ! -f tools/admin ]] ; then
		check_admin
	fi
	if [[ ! -f tools/depmet ]] ; then
		check_tools
	fi
	populate_variables
	check_updates_bot
	check_updates_wrapper
	print_msg_newline ""
	print_msg_newline ">>> Checks complete"
	sleep 2
}

start_web_file()
{
	clear
	print_banner "Writing and executing web interface start command file"
	TMP_FILE="web.command"
	print_msg ">>> Copying over routines..."
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
	print_msg ">>> Executing web interface start command file..."    
    open -b com.apple.terminal "$TMP_FILE"    
    done_or_fail
    sleep 3
    print_msg ">>> Deleting web start command file..."
    rm -f ./*.command    
    done_or_fail
	print_msg_newline ""
    printf '\t%s\n' "Open your browser and visit the site:"
    printf '\t%s\n' "http://localhost:8000"
    printf '\t%s\n' "to view the map"
	print_msg_newline ""
    print_msg_newline ">>> Returning to main menu..."
    open http://localhost:8000
    sleep 5    
    exec ./start.sh
}

tor_command()
{
	print_msg_newline ">>> Writing and executing TOR start command file <<<"
	TMP_FILE="tmp_cmd/\"$COUNT_SCND\"_tor.command"
	print_msg ">>> Copying over routines..."
	echo "mkdir $PWD/PokemonGo-Bot/$TOR_DATA/$COUNT_SCND" >> $TMP_FILE
	echo "tor -f $TOR_CONF" >> $TMP_FILE	
    chmod +x "$TMP_FILE"
    done_or_fail
	print_msg ">>> Executing TOR start command file..."    
    open -b com.apple.terminal "$TMP_FILE"    
    done_or_fail
    sleep 3
#   print_msg ">> Deleting TOR start command file..."
#   rm -f tmp_cmd/*.command    
#    done_or_fail
	print_msg_newline ""
}
	
tor_configurator()
{
	# find out how many tor configuration files there are already
	local COUNT=0
	while IFS= read -d $'\0' -r file ; do     
 		((COUNT++))
	done < <(find $TOR_CFG -type f -name "torrc.*" -maxdepth 1 -print0) # Avoid a subshell, because we must remember variables

	COUNT_SCND="$COUNT"
	NEW_NAME_COUNT="$((COUNT_SCND++))"

	print_msg_newline "There are two ways to configure TOR, you can"
	print_msg_newline ""
	print_msg_newline " 1 - choose to use one random exit node"
	print_msg_newline "     This way TOR configures itself"
	print_msg_newline ""
	print_msg_newline " 2 - choose to use a specific exit node"
	print_msg_newline "     This way we try to force TOR to use one given exit node"
	print_msg_newline ""
	print_msg_newline "for your chosen exit country."
	print_msg_newline ""
	
	read -p "Choose 1 or 2: " OPTION
	case $OPTION in 
		1)
			print_msg_newline ""
			choose_country
			print_msg_newline ""			
			inflate_dirs
			print_msg_newline ">>> Writing TOR config file"
			cp -f $TEMPLATE_DIR/torrc.sample $TOR_CFG/torrc.$COUNT_SCND && chmod 755 $TOR_CFG/torrc.$COUNT_SCND
			echo "" >>$TOR_CFG/torrc.$COUNT_SCND
			echo "" >>$TOR_CFG/torrc.$COUNT_SCND
			echo "ExitNodes {$COUNTRY_CHOICE}" >>$TOR_CFG/torrc.$COUNT_SCND
			echo "StrictNodes 1" >>$TOR_CFG/torrc.$COUNT_SCND
			echo "" >>$TOR_CFG/torrc.$COUNT_SCND
			echo "" >>$TOR_CFG/torrc.$COUNT_SCND
			echo "DataDirectory $PWD/$TOR_DATA/$COUNT_SCND" >>tor_configs/torrc.$COUNT_SCND
			socks_port_generation
			print_msg_newline ">>> Finished writing TOR config file"
			TOR_CONF=$PWD/$TOR_CFG/torrc.$COUNT_SCND
			tor_command
			;;
		2)
			print_msg_newline ""
			choose_country
			print_msg_newline ""
			inflate_dirs
			create_node_list
			print_msg ">>> Choosing tor exit node..." 
			head -1 $VALID_EXIT_NODES >$NODE_DIR/chosen_nodes
			tail +2 $VALID_EXIT_NODES >$NODE_DIR/tmp_nodes && mv $NODE_DIR/tmp_nodes $VALID_EXIT_NODES
			cp -f $TEMPLATE_DIR/torrc.sample $TOR_CFG/torrc.$COUNT_SCND && chmod 755 $TOR_CFG/torrc.$COUNT_SCND
			print_msg_newline "[DONE]"
			while read line ; do
				NODE_CHOICE=$line
			done <$NODE_DIR/chosen_nodes
			chosen_node
			head -1 $NODE_DIR/chosen_nodes >>$NODE_DIR/used_nodes
			TOR_CONF=$PWD/$TOR_CFG/torrc.$COUNT_SCND			
			tor_command
			;;
	esac
}

tor_control()
{
	telnet localhost CONTROL_PORT
}

update_bot() 
{
	clear
	local COUNT=0
    local LASTFOUND=""
	print_banner "Updating PokemonGo-Bot in progress"
	cd "PokemonGo-Bot"
	print_msg ">>> Fetching current version..."
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
					print_msg_newline "<x> PokemonGo-Bot has been updated <x>"
					print_msg_newline ""
					# update requirements after update
					activate_virtualenv
					update_req
					init_sub
					cd ..
					print_msg_newline ""
					print_msg ">>> Resetting bot variables..."
					LOCAL_BRANCH_BOT=""
					LOCAL_BOT=""
					REMOTE_BOT=""
					BOT_UPDATE=0
					print_msg_newline "[DONE]"
					print_msg_newline ""
					print_msg_newline ">>> Restarting wrapper..."
					sleep 2
					exec ./start.sh
				else
					print_msg_newline ""
					print_msg ">>> Resetting bot variables..."
					LOCAL_BRANCH_BOT=""
					LOCAL_BOT=""
					REMOTE_BOT=""
					BOT_UPDATE=0
					print_msg_newline "[DONE]"
					print_msg_newline ""
					print_msg_newline "<!> PokemonGo-Bot update failed <!>"
					print_msg_newline ""
					print_msg_newline ">>> Restarting wrapper..."
					cd ..
					sleep 2
					exec ./start.sh
				fi
 				;;
        	n|N) 
				print_msg_newline ""
				print_msg_newline "<!> Update aborted <!>"
				print_msg_newline ""
				cd ..
				print_msg ">>> Resetting bot variables..."
				LOCAL_BRANCH_BOT=""
				LOCAL_BOT=""
				REMOTE_BOT=""
				BOT_UPDATE=0
				print_msg_newline "[DONE]"
				print_msg_newline ""
				print_msg_newline ">>> Restarting wrapper.."
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

update_req()
{
	print_msg ">>> Updating requirements..."	
	pip install --upgrade -r requirements.txt && done_or_fail
}

update_wrapper() 
{
	clear
	print_banner "Updating PokemonGo-Bot wrapper in progress"
	print_msg ">>> Checking branch..."
	if [[ "$LOCAL_BRANCH" != "$GITHUBBRANCH" ]]; then
		print_msg_newline ""
		print_msg_newline ""
		printf '%s\t%s\n' "WARNING: You're currently using $CURBRANCH branch, and this is not the default $GITHUBBRANCH branch."
		print_msg_newline ""
		press_enter
		return 0
	fi
	print_msg_newline "[DONE]"
	print_msg ">> Fetching current version..."
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
					print_msg_newline "<x> PokemonGo-Bot_wrapper_osx has been updated <x>"
					print_msg_newline ""
					print_msg_newline ">>> Restarting wrapper..."
					sleep 2
					exec ./start.sh
				else
					print_msg_newline ""
					print_msg_newline ">!< PokemonGo-Bot_wrapper_osx update failed >!<"
					print_msg_newline ""
					print_msg_newline ">>> Restarting wrapper..."
					sleep 2
					exec ./start.sh
				fi
 				;;
        	n|N) 
				print_msg_newline ""
				print_msg_newline ">!< Update aborted >!<"
				print_msg_newline ""
				print_msg_newline ">>> Restarting wrapper..."
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
while true ; do
	menu_main
done