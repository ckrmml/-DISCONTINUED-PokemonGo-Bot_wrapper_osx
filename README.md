#PokemonGo-Bot_wrapper_osx

##A wrapper file for [PokemonGo-Bot](https://github.com/PokemonGoF/PokemonGo-Bot) for OSX
This wrapper script will allow you to install the PokemonGo-Bot on Mac OSX and execute as many instances as you like.

**This script will download the bot inside the folder it resides in**

**As of now you have to edit the configuration file yourself or copy yours over there**

**The update functions may be broken, please file an issue if you have problems**

This script will (at least try to):

- [x] clone desired branch 
- [x] install and update requirements (from requirements.txt)
- [x] install and update submodule 
- [x] install libencrypt.so
- [x] install unmet requirements (Python, Homebrew, virtualenv, pip, git, protobuf, tor, coreutils, proxychains)
- [x] initialise and activate Python virtualenv 
- [x] start a single account (if there is only one, it will get startet automatically)
- [x] start selection of accounts
- [x] start all accounts
- [x] start web server
- [x] create a config file for every account you have so you have to configure tor only once
- [x] allow you to change the config file
- [x] create proxychains config file (tor controlport and subnet)
- [x] create tor config file (random socksport and controlport, every tor instance gets it's own data dir)
- [x] proxy your bot over tor
- [x] leave all configuration except exit country to tor
- [x] force tor to use given exit nodes (you can choose how many)
- [x] update bot
- [x] update itself

Edit your configuration files and simply choose which accounts the bot should be playing.

As this script will always download the latest commit, your old configuration files might no longer work. 
If you want an older commit of the bot, or already have one installed, just copy it over there. 
It should probably work.

###**USAGE**
- download zip or clone
- open Terminal and cd to directory
- chmod +x start.sh
- ./start.sh

**batch start all accounts**
	- enter ```[a]``` or ```[A]``` as choice,
**batch start a selection**
	- enter the names of the accounts separated by a space like this 
	```ACCOUNT_1_config.json ACCOUNT_2_config.json ...```


**see wiki for an usage example**

###**ChangeLog**
####**v0.6**
- script can proxy your bot over tor with proxychains
- automated tor configuration
- automated proxychains configuration
- tor usage config file for every account (changeable from the menu)
- broken batch start and star menu fixed
- fancy colors
- much more

####**v0.5**
- script installs requirements if not met (Python, Homebrew, virtualenv, pip, git)
- script installs libencrypt.so
- some code fixes

####**v0.4**
- removed some functions (online-check, needed git version etc.pp)
- summed up code needed more than one time
- changes to logging
- some code fixes

####**v0.3**
- batch start all accounts
- batch start selection of accounts
- auto-update wrapper at startup
- some code fixes
- changes to formatting

####**v0.2**
- check for requirements (Python, Homebrew, virtualenv, pip, git)
- start the web server
- minor code fixes

####**v0.1**
- install/update bot (master or dev branch)
- install/update requirements
- init/update submodule
- install/init Python virtualenv
- start as many bots as you like (in new Terminal windows)
- exiting a running bot by pressing [ctrl]+[c] -> the bot will restart after 5 seconds. it's pretty handy sometimes. If you want to exit the bot completely, hit [ctrl]+[c] twice

###**TO-DO**
- [ ] edit configuration files
- [ ] check for protobuf
- [ ] had one thing i can't remember now, it will come anyway
- [ ] you tell me


