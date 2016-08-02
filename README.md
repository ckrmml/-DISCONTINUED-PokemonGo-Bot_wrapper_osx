#PokemonGo-Bot_wrapper_osx

##A wrapper file for [PokemonGo-Bot](https://github.com/PokemonGoF/PokemonGo-Bot) for OSX
This wrapper script will allow you to install the PokemonGo-Bot on Mac OSX and execute as many instances as you like.

**This script will download the bot inside the folder it resides in**

**As of now you have to edit the configuration file yourself or copy yours over there**

Everything beside that, like cloning desired branch, installing and updating requirements and submodule, initializing and activating 
Python virtualenv will be done by the script. Edit your configuration files and simply choose which accounts the bot should be playing.

As this script will always download the latest commit, your old configuration files might no longer work. If you want an older commit of the 
bot, or already have one installed, just copy it over there and it should probably work.

###**Requirements for PokemonGo-Bot you have to install by yourself**

- [Python 2.7.x](http://docs.python-guide.org/en/latest/starting/installation/)
- [pip](https://pip.pypa.io/en/stable/installing/)
- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [virtualenv](https://virtualenv.pypa.io/en/stable/installation/) (Recommended for the bot, definitely needed for the wrapper)
- protobuf 3 -> brew update && brew install --devel protobuf

**-> protobuf 3 installation needs [Homebrew](http://brew.sh).**

Follow link and install or execute the command

```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

in your terminal.

###**USAGE**
- download zip or clone
- open Terminal and cd to directory
- chmod +x start.sh
- ./start.sh

**scroll down for an usage example***

###**ChangeLog**
####**v0.1**
- install/update bot (master or dev branch)
- install/update requirements
- init/update submodule
- install/init Python virtualenv
- start as many bots as you like (in new Terminal windows)
- exiting a running bot by pressing [ctrl]+[c] -> the bot will restart after 5 seconds. it's pretty handy sometimes. If you want to exit the bot completely, hit [ctrl]+[c] twice

###**TO-DO**
- edit configuration files
- check for requirements (Python, Homebrew etc pp.)
- had one thing i can't remember now, it will come anyway
- you tell me


