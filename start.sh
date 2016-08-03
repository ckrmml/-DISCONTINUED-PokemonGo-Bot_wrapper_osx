#!/bin/bash

#
#
#
#

# PokemonGo-Bot variables
export BRANCH="" # dev or master
export ACTIVE_CONFIG="" # account to start
export GITHUBLINK_BOT="https://github.com/PokemonGoF/PokemonGo-Bot-Desktop.git"
# PokemonGo-Bot wrapper scrip variables
export GITHUBLINK="https://github.com/ckrmml/PokemonGo-Bot_wrapper_osx.git"
export AUTOUPDATE=1 # Defines if we should turn on auto updates, if available
export GITHUBBRANCH="master"
export NEEDEDGIT="1.8"
export CLONE_OR_COPY=0

# check for requirements
TOOLS=(python pip git virtualenv brew)
if [[ "$(which "${TOOLS[@]}" >/dev/null; printf '%s\n' "$?")" -ne 0 ]] ; then
    MISSINGTOOLS=""
    for TOOL in "${TOOLS[@]}"; do
        if [[ -z "$(which $TOOL)" ]]; then
            MISSINGTOOLS+=" $TOOL"
        fi
    done
    printf "\n"
    printf '%s\t%s\n' "Error:"  "It looks like you don't have the required tool(s): "
    printf "\n"
    printf '\t%s\n' "$MISSINGTOOLS"
    printf "\n"
    printf '\t%s\n' "This check was made through 'which' command"
    printf '\t%s\n' "Please install missing tool(s) and relaunch"
    printf "\n"
    exit 1 
fi
printf "\n"

# check for clone or copy
if [[ -d ./PokemonGo-Bot ]] ; then
	if [[ -f clone ]] ; then
		CLONE_OR_COPY=1
	else
		touch copy
	fi
fi
if [[ -f copy ]] ; then
	CLONE_OR_COPY=2
fi

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

print_msg_new() 
{
    text=$1
    printf '%s\n' "$text"
}

print_done()
{
	printf '%s\n' "[DONE]"
}

print_fail()
{
	printf '%s\n' "[FAILED]"
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

print_hu() 
{
	case dirname in
		PokemonGo-Bot) printf '%s\n' " -> You are on $BRANCH branch" ;;
		*) printf '%s\n' " -> You are currently not in bot directory" ;;
	esac
}

display_menu()
{
	clear
	print_banner "PokemonGo-Bot Wrapper OSX"
	print_msg_new ""
	if [[ ! -d ./PokemonGo-Bot ]] ; then
		print_command i "Choose and install PokemonGo-Bot branch"
	fi
	if [[ -d ./PokemonGo-Bot ]] && [[ "$CLONE_OR_COPY" -eq 1 ]] ; then
		if [[ ! -n "$(find ./PokemonGo-Bot/configs -maxdepth 1 -name '*.json' -not -iname '*example*' -print -quit)" ]] ; then
			print_msg_new ""
			printf '\t%s\n' "Please go to "
			print_msg_new ""
			printf '\t%s\n' "$PWD/PokemonGo-Bot/configs"
			print_msg_new ""
			printf '\t%s\n' "and create a configuration file to continue."
			printf '\t%s\n' "After you have done this, please enter 'r' "
			printf '\t%s\n' "or 'R' as choice or restart the wrapper."
			print_msg_new ""
		fi
	elif [[ -d ./PokemonGo-Bot ]] && [[ "$CLONE_OR_COPY" -eq 2 ]] ; then
		if [[ ! -n "$(find ./PokemonGo-Bot/configs -maxdepth 1 -name '*.json' -not -iname '*example*' -print -quit)" ]] ; then
			print_msg_new ""
			printf '\t%s\n' "Please go to "
			print_msg_new ""
			printf '\t%s\n' "$PWD/PokemonGo-Bot/configs"
			print_msg_new ""
			printf '\t%s\n' "and create a configuration file to continue."
			printf '\t%s\n' "After you have done this, please enter 'r' "
			printf '\t%s\n' "or 'R' as choice or restart the wrapper."
			print_msg_new ""
		else
			print_msg_new ""
			printf '\t%s\n' "It looks like you copied over an instance of the bot you had installed before."
			printf '\t%s\n' "If starting a bot does not work, try entering setup as choice."
			print_msg_new ""
			print_msg_new ""
#			move_to_dir
#			setup_virtualenv
#			activate_virtualenv
#			install_req
#			cd ..
#			exec ./start.sh
		fi
	fi
	if [[ -d ./PokemonGo-Bot/configs ]] ; then
		if [[ -n "$(find ./PokemonGo-Bot/configs -maxdepth 1 -name '*.json' -not -iname '*example*' -print -quit)" ]] ; then
			print_command s "Start PokemonGo-Bot"
			print_command w "Start web interface"
			print_command u "Update Bot"
			print_msg_new ""
			print_command r "Restart wrapper"
		fi
	fi
	print_msg_new ""
	print_command x "Quit"
	print_msg_new ""
	read -p "Please choose: " CHOICE
    case "$CHOICE" in
        i|I) branch_menu ;;
        s|S) start_menu ;;
        u|U) update_bot ;;
        w|W) start_web ;;
        setup) 
			move_to_dir
			setup_virtualenv
			activate_virtualenv
			install_req
			init_sub
			cd ..
			exec ./start.sh ;;
        r|R) exec ./start.sh ;;
        x|X) exit 0 ;;
    esac
}

branch_menu()
{
	clear
	print_banner "PokemonGo-Bot Wrapper OSX"
	print_msg_new ""
	print_command m "Choose master branch"
	print_command d "Choose dev branch"
	print_msg_new ""
	print_command x "Return"
	print_msg_new ""
	read -p "Please choose: " CHOICE
    case "$CHOICE" in
        m|M) BRANCH=master 
        	install_bot ;;
        d|D) BRANCH=dev 
        	install_bot ;;
        x|X) return 0 ;;
    esac
}

move_to_dir()
{
	print_msg " - Moving to bot directory..."
	cd ./PokemonGo-Bot
	print_done
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
	print_done
	else
		print_fail
		print_msg_new ""
		print_msg_new "   Error code $OUT returned !! "
		print_msg_new ""
		case $OUT in
			128) print_msg_new "This means the directory already exists." ;;
			*) print_msg_new "This error is unknown" ;;
		esac
		print_msg_new ""
		print_msg_new " - Exiting..."
		sleep 5
		exit 1
	fi
}

setup_virtualenv()
{
	printf '%s' " - Setting up Python virtualenv..."
	virtualenv -q .
	OUT=$?
	if [ $OUT -eq 0 ] ; then
		print_done
	else
		print_fail
		print_msg_new ""
		print_msg_new "   Error code $OUT returned !! "
		print_msg_new ""
		print_msg_new " - Exiting..."
		sleep 5
		exit 1
	fi
}

activate_virtualenv()
{
	printf '%s' " - Activating Python virtualenv..."
	source bin/activate
	OUT=$?
	if [ $OUT -eq 0 ] ; then
		print_done
	else
		print_fail
		print_msg_new ""
		print_msg_new "   Error code $OUT returned !! "
		print_msg_new ""
		print_msg_new " - Exiting..."
		sleep 5
		exit 1
	fi
}

install_req()
{
	printf '%s' " - Install requirements..."
	pip install -qr requirements.txt
	OUT=$?
	if [ $OUT -eq 0 ] ; then
		print_done
	else
		print_fail
		print_msg_new ""
		print_msg_new "   Error code $OUT returned !! "
		print_msg_new ""
		print_msg_new " - Exiting..."
		sleep 5
		exit 1
	fi
}

init_sub()
{
	printf '%s' " - Moving to submodule dir..."
	cd ./web
	OUT=$?
	if [ $OUT -eq 0 ] ; then
		print_done
	else
		print_fail
		print_msg_new ""
		print_msg_new "   Error code $OUT returned !! "
		print_msg_new ""
		print_msg_new " - Exiting..."
		sleep 5
		exit 1
	fi
	
	printf '%s' " - Initializing submodule..."
	git submodule -q init && cd ..
	OUT=$?
	if [ $OUT -eq 0 ] ; then
		print_done
	else
		print_fail
		print_msg_new ""
		print_msg_new "   Error code $OUT returned !! "
		print_msg_new ""
		print_msg_new " - Exiting..."
		sleep 5
		exit 1
	fi
	
	printf '%s' " - Updating submodule..."
	git submodule -q update
	OUT=$?
	if [ $OUT -eq 0 ] ; then
		print_done
	else
		print_fail
		print_msg_new ""
		print_msg_new "   Error code $OUT returned !! "
		print_msg_new ""
		print_msg_new " - Exiting..."
		sleep 5
		exit 1
	fi
}

install_bot()
{
	clone_bot_git $BRANCH
	move_to_dir
	setup_virtualenv
	activate_virtualenv
	install_req
	init_sub
	cd ..
	exec ./start.sh
}

update_bot() 
{
	clear
	if [[ -d ".git" && ! -z "$(which git)" ]]; then
		print_banner "PokemonGo-Bot in progress"
		move_to_dir
		print_msg " - Checking git version..."
		local GITVERSION="$(git --version | cut -d' ' -f3)"
		if version_less_than "$GITVERSION" "$NEEDEDGIT"; then
			print_msg_new ""
			print_msg_new ""
			printf '%s\t%s\n' "WARNING: Your git version is lower than the required!"
			printf '\t%s\n' "Your git version: $GITVERSION"
			printf '\t%s\n' "Required git version: $NEEDEDGIT"
			printf '\t%s\n' "Auto-update feature has been disabled, please update your git to latest version"
			press_enter
			return 0
		fi
		print_done
		print_msg " - Checking network connection..."
		if [[ "$(wget --spider github.com >/dev/null 2>&1; echo $?)" -ne 0 ]]; then
			print_msg_new ""
			print_msg_new ""
			printf '%s\t%s\n' "WARNING: Could not connect to github.com, probably your network is down"
			printf '\t%s\n' "Auto-update feature has been disabled"
			press_enter
			return 0
		else
			print_done
		fi
		
		local REPO="origin"
		local OLDHEAD="$(git rev-parse HEAD)"
		local CURBRANCH="$(git rev-parse --abbrev-ref HEAD)"
		print_msg " - Checking branch..."
		print_done
		if [[ "$(git remote | grep -qi "$REPO"; echo $?)" -ne 0 ]]; then
			git remote add -t "$CURBRANCH" -m "$CURBRANCH" "$REPO" "$GITHUBLINK_BOT"
		fi
		print_msg " - Fetching current version..."
		git fetch -q "$REPO" "$CURBRANCH"
		local HEAD="$(git rev-parse "$REPO/$CURBRANCH")"
		if [[ ! -z "$HEAD" && "$OLDHEAD" != "$HEAD" ]]; then
			print_msg_new ""
			print_msg_new ""
			print_msg_new "Found new version!"
			print_msg_new "Changelog:"
			print_msg_new "=========="
			git --no-pager log --abbrev-commit --decorate --date=relative --pretty=format:'%C(bold red)%h%Creset %C(bold green)(%cr)%Creset - %C(bold yellow)%s%Creset %C(bold blue)commited by%Creset %C(bold cyan)%an%Creset' "$OLDHEAD..$HEAD"
			print_msg_new "" # Because git log doesn't finish with newline
			print_msg_new "=========="
			press_enter
			git pull -q "$REPO" "$GITHUBBRANCH" >/dev/null 2>&1 || (echo; echo "WARNING: PokemonGo-Bot_wrapper_osx could not apply update due to conflicts, forced update mode will be used now. Please make proper backups if you need any of your past projects before going to the next step"; press_enter; git reset -q --hard; git clean -qfd; git pull -q "$REPO" "$GITHUBBRANCH")
			print_msg_new "PokemonGo-Bot_wrapper_osx has been updated, it will now restart itself"
			press_enter
			exec ./start.sh
		else
			print_msg_new ""
			print_msg_new ""
			print_msg_new "No new updates found"
			sleep 1
		fi
	fi
	
	activate_virtualenv
	
	printf '%s' " - Updating requirements..."	
	pip install --upgrade -qr requirements.txt
	OUT=$?
	if [ $OUT -eq 0 ] ; then
		print_done
	else
		print_fail
		print_msg_new ""
		print_msg_new "   Error code $OUT returned !! "
		print_msg_new ""
		print_msg_new " - Exiting..."
		sleep 5
		exit 1
	fi
	cd ..
	exec ./start.sh
}

configure_menu()
{
 echo "Nothing yet"
 return 1
}

start_menu()
{
    clear
    local COUNT=0
    file_list=()
	print_banner "Start bot(s)"
    print_msg_new "Searching for configuration files you've created in the past..."
    print_msg_new "=-=-=-=-=-=-=-=-=-==-=-=-="
 	while IFS= read -d $'\0' -r file ; do     
 		((COUNT++))
		file_list=("${file_list[@]}" "$file")
 	done < <(find ./PokemonGo-Bot/configs -type f -iname "*.json" -not -iname "*example*" -maxdepth 1 -print0) # Avoid a subshell, because we must remember variables
	printf '%s\n' "$(basename "${file_list[@]}")"
    print_msg_new "=-=-=-=-=-=-=-=-=-==-=-=-="
    print_msg_new "$COUNT config files were found"
	print_msg_new ""
    if [[ "$COUNT" -eq 1 ]]; then
        ACTIVE_CONFIG="$(basename "$LASTFOUND")" # If we have only one config file, there's nothing to choose from, so we can save some precious seconds
        start_bot
    fi
    read -p "Please choose (x to return): " CHOICE
    case "$CHOICE" in
        x|X) return 0 ;;
        a|A) batch_start ;; 
        *)
		for config in $CHOICE ; do
        	if [[ -f "./PokemonGo-Bot/configs/$config" ]] ; then
            	ACTIVE_CONFIG="$config"
            	start_bot
			else
            	print_msg_new "Invalid selection"
				press_enter        	
			fi
        done
        ;;
    esac
}

batch_start()
{
    while read line ; do
        LASTFOUND="$line"
        if [[ -f "$line" ]] ; then
 			CHOICE="$(basename "$line")"
           	ACTIVE_CONFIG="$CHOICE"
            start_bot
        fi
    done < <(find ./PokemonGo-Bot/configs -type f -iname "*.json" -not -iname "*example*" -maxdepth 1)
}

start_bot() 
{
    TMP_FILE="$ACTIVE_CONFIG.command"

	while read line ; do
		echo "$line" >> $TMP_FILE
	done < command_template
	
	# Copy over vars
	echo "export ACTIVE_CONFIG="$ACTIVE_CONFIG"" >> $TMP_FILE
	echo "" >> $TMP_FILE

    # Change to directory
    echo "cd $(pwd)" >> $TMP_FILE
	echo "" >> $TMP_FILE
		
    # Copy over while loop
	echo "print_msg_new \"\"" >> $TMP_FILE
	echo "move_to_dir" >> $TMP_FILE
	echo "activate_virtualenv" >> $TMP_FILE
	echo "print_msg_new \" - Executing PokemonGo-Bot with config $ACTIVE_CONFIG...\"" >> $TMP_FILE
	echo "print_msg_new \"\"" >> $TMP_FILE
	echo "while true ; do" >> $TMP_FILE
	echo "	./pokecli.py -cf configs/$ACTIVE_CONFIG" >> $TMP_FILE
	echo "	print_msg_new \"\"" >> $TMP_FILE
	echo "	print_msg_new \" - PokemonGo-Bot exited...\"" >> $TMP_FILE
	echo "	print_msg_new \" - Restarting in five seconds...\"" >> $TMP_FILE
	echo "print_msg_new \"\"" >> $TMP_FILE
	echo "	sleep 5;" >> $TMP_FILE
	echo "done" >> $TMP_FILE
	
    chmod +x "$TMP_FILE"
    open -b com.apple.terminal "$TMP_FILE"
    
    sleep 2
    rm -f ./*.command
}

start_web()
{
	TMP_FILE="web.command"
	
    # Change to directory
    echo "cd $(pwd)/PokemonGo-Bot/web" >> $TMP_FILE
	echo "" >> $TMP_FILE
		
    # Copy over while loop
	echo "while true ; do" >> $TMP_FILE
	echo "	python -m SimpleHTTPServer" >> $TMP_FILE
	echo "print_msg_new \"\"" >> $TMP_FILE
	echo "	print_msg_new \" - Restarting in five seconds...\"" >> $TMP_FILE
	echo "print_msg_new \"\"" >> $TMP_FILE
	echo "	sleep 5;" >> $TMP_FILE
	echo "done" >> $TMP_FILE
	
    chmod +x "$TMP_FILE"
    open -b com.apple.terminal "$TMP_FILE"
    
    sleep 5
    rm -f ./*.command
    
    print_msg_new "Open your browser and visit the site:"
    print_msg_new "http://localhost:8000"
    print_msg_new "to view the map"
    sleep 5
    
    exec ./start.sh
}

# auto-update feature
check_update() 
{
	clear
	if [[ -d ".git" && ! -z "$(which git)" ]]; then
		print_banner "Auto-update in progress"
		
		print_msg " - Checking git version..."
		local GITVERSION="$(git --version | cut -d' ' -f3)"
		if version_less_than "$GITVERSION" "$NEEDEDGIT"; then
			print_msg_new ""
			print_msg_new ""
			printf '%s\t%s\n' "WARNING: Your git version is lower than the required!"
			printf '\t%s\n' "Your git version: $GITVERSION"
			printf '\t%s\n' "Required git version: $NEEDEDGIT"
			printf '\t%s\n' "Auto-update feature has been disabled, please update your git to latest version"
			press_enter
			return 0
		fi
		print_done
		print_msg " - Checking network connection..."
		if [[ "$(wget --spider github.com >/dev/null 2>&1; echo $?)" -ne 0 ]]; then
			print_msg_new ""
			print_msg_new ""
			printf '%s\t%s\n' "WARNING: Could not connect to github.com, probably your network is down"
			printf '\t%s\n' "Auto-update feature has been disabled"
			press_enter
			return 0
		else
			print_done
		fi
		
		local REPO="origin"
		local OLDHEAD="$(git rev-parse HEAD)"
		local CURBRANCH="$(git rev-parse --abbrev-ref HEAD)"
		print_msg " - Checking branch..."
		if [[ "$CURBRANCH" != "$GITHUBBRANCH" ]]; then
			print_msg_new ""
			print_msg_new ""
			printf '%s\t%s\n' "WARNING: You're currently using $CURBRANCH branch, and this is not the default $GITHUBBRANCH branch."
			printf '\t%s\n' "Auto-update feature has been disabled"
			print_msg_new ""
			press_enter
			return 0
		fi
		print_done
		if [[ "$(git remote | grep -qi "$REPO"; echo $?)" -ne 0 ]]; then
			git remote add -t "$GITHUBBRANCH" -m "$GITHUBBRANCH" "$REPO" "$GITHUBLINK"
		fi
		print_msg " - Fetching current version..."
		git fetch -q "$REPO" "$GITHUBBRANCH"
		local HEAD="$(git rev-parse "$REPO/$GITHUBBRANCH")"
		if [[ ! -z "$HEAD" && "$OLDHEAD" != "$HEAD" ]]; then
			print_msg_new ""
			print_msg_new ""
			print_msg_new "Found new version!"
			print_msg_new "Changelog:"
			print_msg_new "=========="
			git --no-pager log --abbrev-commit --decorate --date=relative --pretty=format:'%C(bold red)%h%Creset %C(bold green)(%cr)%Creset - %C(bold yellow)%s%Creset %C(bold blue)commited by%Creset %C(bold cyan)%an%Creset' "$OLDHEAD..$HEAD"
			print_msg_new "" # Because git log doesn't finish with newline
			print_msg_new "=========="
			git pull -q "$REPO" "$GITHUBBRANCH" >/dev/null 2>&1 || (echo; echo "WARNING: PokemonGo-Bot_wrapper_osx could not apply update due to conflicts, forced update mode will be used now. Please make proper backups if you need any of your past projects before going to the next step"; press_enter; git reset -q --hard; git clean -qfd; git pull -q "$REPO" "$GITHUBBRANCH")
			print_msg_new "PokemonGo-Bot_wrapper_osx has been updated, it will now restart itself"
			press_enter
			exec ./start.sh
		else
			print_msg_new ""
			print_msg_new ""
			print_msg_new "No new updates found"
			sleep 1
		fi
	fi
}

# Compare two versions
version_less_than() {
	# $1 - Input version
	# $2 - Compared version
	# Returns true if $1 < $2, false otherwise
	if [[ "$1" != "$2" && "$(echo -e "$1\n$2" | sort | head -n 1)" = "$1" ]]; then
		return 0
	else
		return 1
	fi
}

# check for updates
if [[ "$AUTOUPDATE" -eq 1 ]]; then
	check_update
fi

# core app
while true ; do
	display_menu
done