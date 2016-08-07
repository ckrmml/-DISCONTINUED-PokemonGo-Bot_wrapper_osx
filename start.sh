#!/bin/bash

#
#
#
#
# set -x
# PokemonGo-Bot variables
export BRANCH="" # dev or master
export ACTIVE_CONFIG="" # account to start

# git variables wrapper
export GITHUBLINK="https://github.com/ckrmml/PokemonGo-Bot_wrapper_osx.git"
export GITHUBBRANCH="master"
export REPO="origin"
export OLDHEAD=""
export CURBRANCH=""
export HEAD=""

# git variables bot
export GITHUBLINK_BOT="https://github.com/PokemonGoF/PokemonGo-Bot.git"
export REPO_BOT="origin"
export OLDHEAD_BOT=""
export CURBRANCH_BOT=""
export HEAD_BOT=""

# PokemonGo-Bot wrapper scrip variables
export BOT_UPDATE=0
export WRAPPER_UPDATE=0

# requirements arrays
TOOLS=(brew git python pip virtualenv) 
MISSINGTOOLS=()

# populate variables on start-up
populate_variables()
{
	if [[ -d ./PokemonGo-Bot ]] ; then
		move_to_dir "PokemonGo-Bot"
		print_msg " - Populating bot specific variables..."
		OLDHEAD_BOT="$(git rev-parse HEAD)"
		CURBRANCH_BOT="$(git rev-parse --abbrev-ref HEAD)"
		HEAD_BOT="$(git rev-parse "$REPO_BOT/$CURBRANCH_BOT")"
		print_msg_newline "[DONE]"
		cd ..
	fi
	print_msg " - Populating wrapper specific variables..."
	OLDHEAD="$(git rev-parse HEAD)"
	CURBRANCH="$(git rev-parse --abbrev-ref HEAD)"
	HEAD="$(git rev-parse "$REPO/$GITHUBBRANCH")"
	print_msg_newline "[DONE]"
}

# error message
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
		print_msg_newline " - Exiting..."
		sleep 5
		exit 1
	fi
}	

# requirement checks
check_req()
{
	print_msg " - Checking for PokemonGo-Bot requirements..."
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
	fi
	touch depmet
	print_msg_newline "[DONE]"
}

install_missing_tools()
{
	clear
	print_banner "PokemonGo-Bot Wrapper OSX"
	print_msg_newline "If installation should fail, you have to manually install using su or sudo command"
	rule
	for MISSINGTOOL in "${MISSINGTOOLS[@]}" ; do
		if [[ "$MISSINGTOOL" == brew ]] ; then
			print_msg_newline " > Attempting to install homebrew <"
			print_msg " - Using Homebrew install command..."
			/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"	
			done_or_fail
			print_msg_newline ""
			print_msg_newline "Restarting wrapper because homebrew is needed for some installations..."
			sleep 2
			exec ./start.sh
		elif [[ "$MISSINGTOOL" == git ]] ; then
			print_msg_newline " > Attempting to install git <"
			print_msg " - Using Homebrew git formula..."
			brew --quiet install git	
			done_or_fail
			print_msg_newline ""
		elif [[ "$MISSINGTOOL" == python ]] ; then
			print_msg_newline " > Attempting to install python <"
			print_msg " - Using Homebrew python formula..."
			brew --quiet install python	
			done_or_fail
			print_msg " - Updating pip..."
			pip install -qU pip
			done_or_fail
			print_msg_newline ""
			print_msg_newline "Restarting wrapper because installing python should also have installed pip and virtualenv..."
			sleep 2
			exec ./start.sh
		elif [[ "$MISSINGTOOL" == pip ]] ; then
			print_msg_newline " > Attempting to install pip <"
			mkdir downloads
			cd ./downloads
			print_msg " - Downloading get-pip.py..."
			wget --quiet https://bootstrap.pypa.io/get-pip.py			
			done_or_fail
			print_msg " - Executing get-pip.py..."
			python get-pip.py 2>/dev/null
			done_or_fail
			cd ..
			print_msg " - Cleaning up..."
			rm -rf ./downloads
			done_or_fail
			print_msg_newline ""
		elif [[ "$MISSINGTOOL" == virtualenv ]] ; then
			print_msg_newline " > Attempting to install virtualenv <"
			print_msg " - Using Homebrew virtualenv formula..."
			pip install -q virtualenv			
			done_or_fail
			print_msg_newline ""
		fi
	done
	print_msg_newline "Restarting wrapper..."
	sleep 2
	exec ./start.sh	
}

# text messages etc pp
press_enter()
{
    read -p "Press [Enter] key to continue..."
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

print_command() 
{
    command=$1
    description=$2
    printf '%s - %s\n' $command "$description"
}

rule()
{
	printf -v _hr "%*s" $(tput cols) && echo ${_hr// /${1--}}
}

print_banner()
{
	text=$1
	rule
	printf '%s\n' "$text" | fmt -c -w $(tput cols)
	rule
}

move_to_dir()
{
	dir=$1
	cd "$dir"
}

print_hu() 
{
	if [[ -d ./PokemonGo-Bot ]] ; then
		printf '%s\n' "You are currently on ["$CURBRANCH_BOT"] branch of PokemonGo-Bot"
		if [[ $BOT_UPDATE -eq 1 ]]; then
			print_msg_newline " -> Your local bot is on commit: [$OLDHEAD_BOT]"
			print_msg_newline " -> Newest commit on github is : [$HEAD_BOT]"
		else
			print_msg_newline " -> This is the newest version"
		fi
	else
			print_msg_newline " -> You have not installed PokemonGo-Bot yet"
	fi
}

# menu things
display_menu()
{
	clear
	if [[ $WRAPPER_UPDATE -eq 1 ]]; then
		print_banner "PokemonGo-Bot Wrapper OSX [Update available]"
	else
		print_banner "PokemonGo-Bot Wrapper OSX"
	fi
	print_hu
	if [[ ! -d ./PokemonGo-Bot ]] ; then
		rule
		print_command i "Choose and install PokemonGo-Bot branch"
	fi
	if [[ -d ./PokemonGo-Bot ]] && [[ -f clone ]] ; then
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
	elif [[ -d ./PokemonGo-Bot ]] && [[ ! -f clone ]] ; then
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
		else
			rule
			print_msg_newline ""
			printf '\t%s\n' "It looks like you copied over an instance of the bot you had installed before."
			printf '\t%s\n' "If starting a bot does not work, try entering setup as choice."
			print_msg_newline ""
			rule
		fi
	fi
	if [[ -d ./PokemonGo-Bot ]] && [[ ! -f ./PokemonGo-Bot/encrypt.so ]] ; then
		rule
		print_msg_newline ""
		printf '\t%s\n' "It looks like you don't have installed:"
		print_msg_newline ""
    	printf '\t%s\n' "encrypt.so"
		print_msg_newline ""
		printf '\t%s\n' "The bot won't work without it."
		printf '\t%s\n'	"Should we try to download and install the file?"		
		print_msg_newline ""
		rule
		read -p "Y/N: " CHOICE
		case "$CHOICE" in
       		y|Y) install_lib_crypt 1 ;;
       		n|N) install_lib_crypt 2 ;;
  		esac	
	elif [[ -d PokemonGo-Bot ]] && [[  -f ./PokemonGo-Bot/encrypt.so ]] ; then
		if [[ -n "$(find ./PokemonGo-Bot/configs -maxdepth 1 -name '*.json' -not -iname '*example*' -print -quit)" ]] ; then
			rule
			print_command s "Start PokemonGo-Bot"
			print_command w "Start web interface"
			if [[ $BOT_UPDATE -eq 1 ]] || [[ $WRAPPER_UPDATE -eq 1 ]] ; then
				print_command u "Update menu"
			fi
		fi
	fi
	print_command r "Restart wrapper"
	print_command x "Quit"
	rule
	read -p "Please choose: " CHOICE
    case "$CHOICE" in
        i|I) branch_menu ;;
        s|S) start_menu ;;
        u|U) update_menu ;;
        w|W) start_web_file ;;
        setup) 
			move_to_dir "PokemonGo-Bot"
			setup_virtualenv
			activate_virtualenv
			install_req
			init_sub
			cd ..
			exec ./start.sh ;;
        c) install_lib_crypt ;;
        r|R) exec ./start.sh ;;
        x|X) exit 0 ;;
    esac
}

branch_menu()
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

start_menu()
{
    clear
    local COUNT=0
    file_list=()
	print_banner "Start bot(s)"
    print_msg_newline "Searching for configuration files you've created in the past..."
    print_msg_newline "=-=-=-=-=-=-=-=-=-==-=-=-="
 	while IFS= read -d $'\0' -r file ; do     
 		((COUNT++))
		file_list=("${file_list[@]}" "$file")
 	done < <(find ./PokemonGo-Bot/configs -type f -iname "*.json" -not -iname "*example*" -maxdepth 1 -print0) # Avoid a subshell, because we must remember variables
	printf '%s\n' "$(basename "${file_list[@]}")"
    print_msg_newline "=-=-=-=-=-=-=-=-=-==-=-=-="
    print_msg_newline "$COUNT config files were found"
	print_msg_newline ""
    if [[ "$COUNT" -eq 1 ]]; then
        ACTIVE_CONFIG="$(basename "$LASTFOUND")" # If we have only one config file, there's nothing to choose from, so we can save some precious seconds
        start_bot_file
    fi
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
            	print_msg_newline "Invalid selection"
				press_enter        	
			fi
        done
        ;;
    esac
}

configure_menu()
{
 echo "Nothing yet"
 return 1
}

update_menu()
{
	clear
	print_banner "Update menu"
	if [[ $BOT_UPDATE -eq 1 ]] ; then
		print_command b "Update PokemonGo-Bot"
	elif [[ $WRAPPER_UPDATE -eq 1 ]] ; then
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

# subroutines for cloning, installation, updating and starting
clone_bot_git()
{
	clear
	branch=$1
	print_banner "Installing PokemonGo-Bot"
	print_msg " - Cloning $branch branch..."
	git clone -q -b $branch https://github.com/PokemonGoF/PokemonGo-Bot 2>/dev/null
	OUT=$?
	if [ $OUT -eq 0 ] ; then
	touch clone
	print_msg_newline "[DONE]"
	else
		print_msg_newline "[FAIL]"
		print_msg_newline ""
		print_msg_newline "   Error code $OUT returned !! "
		print_msg_newline ""
		case $OUT in
			128) print_msg_newline "This means the directory already exists." ;;
			*) print_msg_newline "This error is unknown" ;;
		esac
		print_msg_newline ""
		print_msg_newline " - Exiting..."
		sleep 5
		exit 1
	fi
}

setup_virtualenv()
{
	print_msg " - Setting up Python virtualenv..."
	virtualenv -q . 2>/dev/null && done_or_fail
}

activate_virtualenv()
{
	print_msg " - Activating Python virtualenv..."
	source bin/activate 2>/dev/null && done_or_fail
}

install_req()
{
	print_msg " - Install requirements..."
	pip install -qr requirements.txt 2>/dev/null && done_or_fail
}

update_req()
{
	print_msg " - Updating requirements..."	
	pip install --upgrade -qr requirements.txt 2>/dev/null && done_or_fail
}

init_sub()
{
	print_msg " - Initializing submodule..."
	cd ./web && git submodule -q init 2>/dev/null && done_or_fail && cd ..	
	print_msg " - Updating submodule..."
	git submodule -q update 2>/dev/null && done_or_fail
}

install_bot()
{
	clone_bot_git $BRANCH
	move_to_dir "PokemonGo-Bot"
	setup_virtualenv
	activate_virtualenv
	install_req
	init_sub
	cd ..
	install_lib_crypt 1
}

install_lib_crypt()
{
	choice=$1
	clear
	print_banner "Installing libencrypt.so"
	if [[ $choice -eq 1 ]] ; then
		print_msg " - Attempting to download pgoencrypt.tar.gz..."
		mkdir downloads
		cd ./downloads
		wget --quiet http://pgoapi.com/pgoencrypt.tar.gz
		done_or_fail
		print_msg " - Unarchiving pgoencrypt.tar.gz..."
		tar -xf pgoencrypt.tar.gz
		done_or_fail
		cd ./pgoencrypt/src/
		print_msg " - Attempting to make libencrypt.so..."
		make -s 2>/dev/null 
		done_or_fail
		print_msg " - Renaming libencrypt.so to encrypt.so..."		
		mv libencrypt.so encrypt.so
		done_or_fail
		cd .. && cd .. && cd ..
		print_msg " - Moving encrypt.so to PokemonGo-Bot directory..."		
		ditto ./downloads/pgoencrypt/src/encrypt.so ./PokemonGo-Bot/encrypt.so
		done_or_fail
		print_msg " - Cleaning up..."
		rm -rf ./downloads
		done_or_fail
		print_msg_newline ""
		print_msg_newline "   Installation of encrypt.so complete. Restarting wrapper..."
		sleep 3
		exec ./start.sh
	elif [[ $choice -eq 2 ]] ; then
		print_msg_newline ""
		printf '\t%s\n' "Download http://pgoapi.com/pgoencrypt.tar.gz and make file."
		printf '\t%s\n' "Rename libencrypt.so to encrypt.so and move the file into PokemonGo-Bot directory."
		printf '\t%s\n' "After you have done this, please restart the wrapper."
		print_msg_newline ""
		rule
	fi
}

batch_start()
{
    while read line ; do
        LASTFOUND="$line"
        if [[ -f "$line" ]] ; then
 			CHOICE="$(basename "$line")"
           	ACTIVE_CONFIG="$CHOICE"
            start_bot_file
        fi
    done < <(find ./PokemonGo-Bot/configs -type f -iname "*.json" -not -iname "*example*" -maxdepth 1)
}

start_bot_file() 
{
	clear
	print_banner "Writing and executing bot start command file"
    TMP_FILE="$ACTIVE_CONFIG.command"
	print_msg " - Read and copy template file..."
	while read line ; do
		echo "$line" >> $TMP_FILE
	done < command_template
	done_or_fail
	print_msg " - Copying over routines..."
	# Copy over vars
	echo "export ACTIVE_CONFIG="$ACTIVE_CONFIG"" >> $TMP_FILE
	echo "" >> $TMP_FILE
    # Change to directory
    echo "cd $(pwd)" >> $TMP_FILE
	echo "" >> $TMP_FILE
    # Copy over while loop
	echo "print_msg_newline \"\"" >> $TMP_FILE
	echo "move_to_dir "PokemonGo-Bot"" >> $TMP_FILE
	echo "activate_virtualenv" >> $TMP_FILE
	echo "print_msg_newline \" - Executing PokemonGo-Bot with config $ACTIVE_CONFIG...\"" >> $TMP_FILE
	echo "print_msg_newline \"\"" >> $TMP_FILE
	echo "while true ; do" >> $TMP_FILE
	echo "	python pokecli.py -cf configs/$ACTIVE_CONFIG" >> $TMP_FILE
	echo "	print_msg_newline \"\"" >> $TMP_FILE
	echo "	print_msg_newline \" - PokemonGo-Bot exited...\"" >> $TMP_FILE
	echo "	print_msg_newline \" - Restarting in five seconds...\"" >> $TMP_FILE
	echo "print_msg_newline \"\"" >> $TMP_FILE
	echo "	sleep 5;" >> $TMP_FILE
	echo "done" >> $TMP_FILE
	done_or_fail
	print_msg " - Executing bot start command file..."
    chmod +x "$TMP_FILE"
    open -b com.apple.terminal "$TMP_FILE"
    done_or_fail
    sleep 3
    print_msg " - Deleting bot start command file..."
    rm -f ./*.command
    done_or_fail
    print_msg_newline " -> Returning to main menu"
}

start_web_file()
{
	clear
	print_banner "Writing and executing web interface start command file"
	TMP_FILE="web.command"
	print_msg " - Copying over routines..."
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
	print_msg "Executing web interface start command file..."    
    open -b com.apple.terminal "$TMP_FILE"    
    done_or_fail
    sleep 3
    print_msg "Deleting bot start command file..."
    rm -f ./*.command    
    done_or_fail
    print_msg_newline "Open your browser and visit the site:"
    print_msg_newline "http://localhost:8000"
    print_msg_newline "to view the map"
    sleep 5    
    exec ./start.sh
}

# update features
update_wrapper() 
{
	clear
	print_banner "Updating PokemonGo-Bot wrapper in progress"
	print_msg " - Checking branch..."
	if [[ "$CURBRANCH" != "$GITHUBBRANCH" ]]; then
		print_msg_newline ""
		print_msg_newline ""
		printf '%s\t%s\n' "WARNING: You're currently using $CURBRANCH branch, and this is not the default $GITHUBBRANCH branch."
		print_msg_newline ""
		press_enter
		return 0
	fi
	print_msg_newline "[DONE]"
	if [[ "$(git remote | grep -qi "$REPO"; echo $?)" -ne 0 ]]; then
		git remote add -t "$GITHUBBRANCH" -m "$GITHUBBRANCH" "$REPO" "$GITHUBLINK"
	fi
	print_msg " - Fetching current version..."
	git fetch -q "$REPO" "$GITHUBBRANCH"
	if [[ ! -z "$HEAD" && "$OLDHEAD" != "$HEAD" ]]; then
		print_msg_newline ""
		print_msg_newline ""
		print_msg_newline "Found new version!"
		print_msg_newline "Changelog:"
		print_msg_newline "=========="
		git --no-pager log --abbrev-commit --decorate --date=relative --pretty=format:'%C(bold red)%h%Creset %C(bold green)(%cr)%Creset - %C(bold yellow)%s%Creset %C(bold blue)commited by%Creset %C(bold cyan)%an%Creset' "$OLDHEAD..$HEAD"
		print_msg_newline "" # Because git log doesn't finish with newline
		print_msg_newline "=========="
		git pull -q "$REPO" "$GITHUBBRANCH" >/dev/null 2>&1 || (print_msg_newline ""; printf '%s\t%s\n' "WARNING:" "PokemonGo-Bot_wrapper_osx could not apply update due to conflicts, forced update mode will be used now."; printf '\t\t%s\n' "Please make proper backups if you need any of your past projects before going to the next step"; press_enter; git reset -q --hard; git clean -qfd; git pull -q "$REPO" "$GITHUBBRANCH")
		print_msg_newline ""
		print_msg_newline " > PokemonGo-Bot_wrapper_osx has been updated <"
		print_msg_newline ""
		exec ./start.sh
	else
		no_update_found
		exec ./start.sh
	fi
}

update_bot() 
{
	clear
	print_banner "Updating PokemonGo-Bot in progress"
	move_to_dir "PokemonGo-Bot"
	print_msg " - Checking branch..."
	if [[ "$(git remote | grep -qi "$REPO_BOT"; echo $?)" -ne 0 ]]; then
		git remote add -t "$CURBRANCH_BOT" -m "$CURBRANCH_BOT" "$REPO_BOT" "$GITHUBLINK_BOT"
	fi
	done_or_fail
	print_msg " - Fetching current version..."
	git fetch -q "$REPO_BOT" "$CURBRANCH_BOT"
	if [[ ! -z "$HEAD_BOT" && "$OLDHEAD_BOT" != "$HEAD_BOT" ]]; then
		print_msg_newline ""
		print_msg_newline ""
		print_msg_newline "Found new version!"
		print_msg_newline "Changelog:"
		print_msg_newline "=========="
		git --no-pager log --abbrev-commit --decorate --date=relative --pretty=format:'%C(bold red)%h%Creset %C(bold green)(%cr)%Creset - %C(bold yellow)%s%Creset %C(bold blue)commited by%Creset %C(bold cyan)%an%Creset' "$OLDHEAD_BOT..$HEAD_BOT"
		print_msg_newline "" # Because git log doesn't finish with newline
		print_msg_newline "=========="
		print_msg_newline ""
		press_enter
		git pull -q >/dev/null 2>&1 || (print_msg_newline ""; printf '%s\t%s\n' "WARNING:" "PokemonGo-Bot_wrapper_osx could not apply update due to conflicts, forced update mode will be used now."; printf '\t\t%s\n' "Please make proper backups if you need any of your past projects before going to the next step"; press_enter; git reset -q --hard; git clean -qfd; git pull -q "$REPO_BOT" "$GITHUBBRANCH_BOT")
		print_msg_newline ""
		print_msg_newline " > PokemonGo-Bot has been updated <"
		print_msg_newline ""
		# update requirements after update
		activate_virtualenv
		update_req
		init_sub
		cd ..
		exec ./start.sh
	else
		no_update_found		
		cd ..
		exec ./start.sh
	fi
}

no_update_found()
{
	print_msg "[DONE]"
	print_msg_newline ""
	print_msg_newline ""
	print_msg_newline "No new updates found"
	sleep 1
}

check_for_updates_bot()
{
	if [[ -d ./PokemonGo-Bot ]] ; then
		move_to_dir "PokemonGo-Bot"
		print_msg " - Checking for PokemonGo-Bot updates..."
		if [[ "$(git remote | grep -qi "$REPO_BOT"; echo $?)" -ne 0 ]]; then
			git remote add -t "$CURBRANCH_BOT" -m "$CURBRANCH_BOT" "$REPO_BOT" "$GITHUBLINK_BOT"
		fi
		git fetch -q "$REPO_BOT" "$CURBRANCH_BOT"
		if [[ ! -z "$HEAD_BOT" && "$OLDHEAD_BOT" != "$HEAD_BOT" ]]; then
			BOT_UPDATE=1
		fi
		print_msg_newline "[DONE]"
		cd ..
	fi
}

check_for_updates_wrapper()
{
	print_msg " - Checking for wrapper updates..."
	if [[ "$(git remote | grep -qi "$REPO"; echo $?)" -ne 0 ]]; then
		git remote add -t "$GITHUBBRANCH" -m "$GITHUBBRANCH" "$REPO" "$GITHUBLINK"
	fi
	git fetch -q "$REPO" "$GITHUBBRANCH"
	if [[ ! -z "$HEAD" && "$OLDHEAD" != "$HEAD" ]]; then
		WRAPPER_UPDATE=1
	fi
	done_or_fail
}

# boot things
clear
print_banner "Start-up checks"
if [[ ! -f depmet ]] ; then
	check_req
fi
populate_variables
check_for_updates_bot
check_for_updates_wrapper
print_msg_newline ""
print_msg_newline "   Checks complete"
sleep 3
# core app
while true ; do
	display_menu
done