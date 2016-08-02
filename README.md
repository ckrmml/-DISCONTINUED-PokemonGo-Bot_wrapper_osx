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


####EXAMPLE
```
MacBook-Pro:~ YOUR-NAME$ cd PokemonGo-Bot_wrapper_osx
MacBook-Pro:PokemonGo-Bot_wrapper_osx YOUR-NAME$ chmod +x start.sh
MacBook-Pro:PokemonGo-Bot_wrapper_osx YOUR-NAME$ ./start.sh
```
Now this screen should appear
```
----------------------------------------------------------------------------------------------
                                   PokemonGo-Bot Wrapper OSX
----------------------------------------------------------------------------------------------

i - Choose and install PokemonGo-Bot branch
x - Quit

Please choose: 
```
if you now enter ```i``` or ```I``` and hit [Enter], you should be here
```
----------------------------------------------------------------------------------------------
                              PokemonGo-Bot installer and starter
----------------------------------------------------------------------------------------------

m - Choose master branch
d - Choose dev branch
x - Return

Please choose: 
```
by entering ```m```/```M``` or ```d```/```D``` the script will clone the chosen branch inside it's folder which
looks like this
```
----------------------------------------------------------------------------------------------
                                   Installing PokemonGo-Bot
----------------------------------------------------------------------------------------------
 - Cloning dev branch...[DONE]
 - Moving to bot directory...[DONE]
 - Setting up Python virtualenv...[DONE]
 - Activating Python virtualenv...[DONE]
 - Install requirements...[DONE]
 - Moving to submodule dir...[DONE]
 - Initializing submodule...[DONE]
 - Updating submodule...[DONE]
```
after this is done you will get back to the menu which now looks like this (if you have no config file)
```
----------------------------------------------------------------------------------------------
                                   PokemonGo-Bot Wrapper OSX
----------------------------------------------------------------------------------------------


Please go to 

/PATH/TO/PokemonGo-Bot_wrapper_osx/PokemonGo-Bot/configs

and create a configuration file to continue.
After you have done this, please enter 'r' 
or 'R' as choice or restart the wrapper.

x - Quit

Please choose: 
```
if you have done this, or simply copied over your old configuration files from another instance of the bot, simply enter
```r``` / ```R``` and hit [Enter] or restart the script to get to this menu
```
----------------------------------------------------------------------------------------------
                                   PokemonGo-Bot Wrapper OSX
----------------------------------------------------------------------------------------------

s - Start PokemonGo-Bot
u - Update Bot
x - Quit

Please choose: 
```
entering ```s```or ```S```will show this menu
```
----------------------------------------------------------------------------------------------
                                         Start bot(s)
----------------------------------------------------------------------------------------------
Searching for configuration files you've created in the past...
=-=-=-=-=-=-=-=-=-==-=-=-=
YOUR_OWN_config.json
=-=-=-=-=-=-=-=-=-==-=-=-=
1 config files were found

Please choose: 
```
if you only have one config file, a new window will pop up and the bot will be started, if you got two or more, enter the name of any
config file and a new window will pop up and the bot will start inside it with the desired configuration
```
Last login: Wed Aug  3 01:12:51 on ttys001
/PATH/TO/PokemonGo-Bot_wrapper_osx/YOUR_OWN_config.json.command ; exit;
MacBook-Pro:~ YOUR_NAME$ /PATH/TO//PokemonGo-Bot_wrapper_osx/YOUR_OWN_config.json.command ; exit;
Executing PokemonGo-Bot with config YOU_OWN_config.json...
 - Moving to bot directory...[DONE]
 - Activating Python virtualenv...[DONE]
[01:18:09]  PokemonGO Bot v1.0
[01:18:09]  Configuration initialized 
[01:18:09] [x] Coordinates found in passed in location, not geocoding.
[01:18:09] 
[01:18:09] Location Found: xx.xxxxxxx, y.yyyyyyy,yy
[01:18:09] GeoPosition: (xx.xxxxxxx, y.yyyyyyy ,z)
[01:18:09] 
[01:18:09] [x] Parsing cached location...
[01:18:09] [x] Parsing cached location failed, try to use the initial location...
[01:18:09] Attempting login to Pokemon Go.
 [01:18:12]  Login to Pokemon Go successful. 
[01:18:13] Server is throttling, let's slow down a bit
[01:18:14] 
[01:18:14]  --- YOUR_NAME --- 
[01:18:14]  Level: 22 (Next Level: 49155 XP) (Total: 385845 XP) 
[01:18:14]  Pokemon Captured: 1194 | Pokestops Visited: 636 
[01:18:14]  Pokemon Bag: 21/250 
[01:18:14]  Items: 345/350 
[01:18:14]  Stardust: 149683 | Pokecoins: 0 
[01:18:14]  PokeBalls: 125 | GreatBalls: 83 | UltraBalls: 58 
[01:18:14]  RazzBerries: 65 | BlukBerries: 0 | NanabBerries: 0 
[01:18:14]  LuckyEgg: 0 | Incubator: 0 | TroyDisk: 5 
[01:18:14]  Potion: 0 | SuperPotion: 0 | HyperPotion: 0 
[01:18:14]  Incense: 7 | IncenseSpicy: 0 | IncenseCool: 0 
[01:18:14]  Revive: 0 | MaxRevive: 0 
[01:18:14] 
[01:18:14] 
[01:18:18] Server is throttling, let's slow down a bit
[01:18:19]  Starting PokemonGo Bot.... 
...
```



