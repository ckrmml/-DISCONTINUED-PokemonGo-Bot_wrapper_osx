#!/bin/bash

#
#
#
#

export BRANCH=""
export ACTIVE_CONFIG=""

## check for requirements
TOOLS=(python pip git virtualenv brew)
## check for tools
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

# text messages etc pp
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
	if [[ -d ./PokemonGo-Bot ]] ; then
		if [[ ! -n "$(find ./PokemonGo-Bot/configs -maxdepth 1 -name '*.json' -not -iname '*example*' -print -quit)" ]] ; then
		print_msg_new ""
		print_msg_new "Please go to "
		print_msg_new ""
		print_msg_new "$PWD/PokemonGo-Bot/configs"
		print_msg_new ""
		print_msg_new "and create a configuration file to continue."
		print_msg_new "After you have done this, please enter 'r' "
		print_msg_new "or 'R' as choice or restart the wrapper."
		print_msg_new ""
		fi
	fi
	if [[ -d ./PokemonGo-Bot ]] ; then
		if [[ -n "$(find ./PokemonGo-Bot/configs -maxdepth 1 -name '*.json' -not -iname '*example*' -print -quit)" ]] ; then
			print_command s "Start PokemonGo-Bot"
			print_command u "Update Bot"
		fi
	fi
	print_command x "Quit"
	print_msg_new ""
	read -p "Please choose: " CHOICE
    case "$CHOICE" in
        i|I) branch_menu ;;
        s|S) start_menu ;;
        u|U) update_bot ;;
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
	#read -p "Please enter path to bot: " BOT_PATH
	print_msg " - Moving to bot directory..."
	cd ./PokemonGo-Bot
	print_done
}

new_window() 
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

# subroutines for cloning, installation and updating
clone_bot_git()
{
	clear
	branch=$1
	print_banner "Installing PokemonGo-Bot"
	print_msg " - Cloning $branch branch..."
	git clone -q -b $branch https://github.com/PokemonGoF/PokemonGo-Bot 2>/dev/null
	OUT=$?
	if [ $OUT -eq 0 ] ; then
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
	print_banner "Update Bot"
	move_to_dir
	printf '%s' " - Updating bot..."
	git pull -q 2>/dev/null
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
    local LASTFOUND=""
	print_banner "Start bot(s)"
    print_msg_new "Searching for configuration files you've created in the past..."
    print_msg_new "=-=-=-=-=-=-=-=-=-==-=-=-="
    while read line; do
        ((COUNT++))
        LASTFOUND="$line"
        basename "$LASTFOUND"
    done < <(find ./PokemonGo-Bot/configs -type f -iname "*.json" -not -iname "*example*" -maxdepth 1) # Avoid a subshell, because we must remember variables
    print_msg_new "=-=-=-=-=-=-=-=-=-==-=-=-="
    print_msg_new "$COUNT config files were found"
	print_msg_new ""
    if [[ "$COUNT" -eq 1 ]]; then
        ACTIVE_CONFIG="$(basename "$LASTFOUND")" # If we have only one config file, there's nothing to choose from, so we can save some precious seconds
        new_window
    fi
    read -p "Please choose: " CHOICE
    case "$CHOICE" in
        x|X) return 0 ;;
        *)
        CHOICE="$(basename "$CHOICE")"
        if [[ -f "./PokemonGo-Bot/configs/$CHOICE" ]] ; then
            ACTIVE_CONFIG="$CHOICE"
            new_window
		else
            print_msg_new "Invalid selection"
            read -p "Press [Enter] key to continue..."
        fi
        ;;
    esac
}

while true ; do
	display_menu
done