#!/bin/bash
###########################################################
## Title: langtool
## Abstact: A Script that manage LanguageTool
## Author:  Fabian Raab <fabian@4raab.de>
## Dependencies: bash, wget
## Creation Date: 2013-12-02
## Last Edit: 2014-05-15 22:20
###########################################################

SCRIPTNAME=$(basename $0)
SCRIPTPATH="$0"
EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_ERROR=2
EXIT_BUG=10

INSTALL_WITH_ROOT=true # need root privilegues for install?
STD_INSTALL_PATH_PREFIX="/opt/"
INSTALL_DIR="languagetool"

BIN_PATH="/usr/local/bin"
ICON_PATH="/usr/share/pixmaps/"
MENU_PATH="/usr/share/applications/"

DOWNLOAD_URL_LAST_STABLE="http://www.languagetool.org/download/LanguageTool-stable.zip"
DOWNLOAD_URL_VERSION="http://www.languagetool.org/download/LanguageTool-"
DOWNLOAD_LOGO="http://www.languagetool.org/images/LanguageToolBig.png"

JAVA_BIN="java -jar"

## Colors
RCol='\e[0m'    # Text Reset

# Regular           Bold                Underline           High Intensity      BoldHigh Intens     Background          High Intensity Backgrounds
Bla='\e[0;30m';     BBla='\e[1;30m';    UBla='\e[4;30m';    IBla='\e[0;90m';    BIBla='\e[1;90m';   On_Bla='\e[40m';    On_IBla='\e[0;100m';
Red='\e[0;31m';     BRed='\e[1;31m';    URed='\e[4;31m';    IRed='\e[0;91m';    BIRed='\e[1;91m';   On_Red='\e[41m';    On_IRed='\e[0;101m';
Gre='\e[0;32m';     BGre='\e[1;32m';    UGre='\e[4;32m';    IGre='\e[0;92m';    BIGre='\e[1;92m';   On_Gre='\e[42m';    On_IGre='\e[0;102m';
Yel='\e[0;33m';     BYel='\e[1;33m';    UYel='\e[4;33m';    IYel='\e[0;93m';    BIYel='\e[1;93m';   On_Yel='\e[43m';    On_IYel='\e[0;103m';
Blu='\e[0;34m';     BBlu='\e[1;34m';    UBlu='\e[4;34m';    IBlu='\e[0;94m';    BIBlu='\e[1;94m';   On_Blu='\e[44m';    On_IBlu='\e[0;104m';
Pur='\e[0;35m';     BPur='\e[1;35m';    UPur='\e[4;35m';    IPur='\e[0;95m';    BIPur='\e[1;95m';   On_Pur='\e[45m';    On_IPur='\e[0;105m';
Cya='\e[0;36m';     BCya='\e[1;36m';    UCya='\e[4;36m';    ICya='\e[0;96m';    BICya='\e[1;96m';   On_Cya='\e[46m';    On_ICya='\e[0;106m';
Whi='\e[0;37m';     BWhi='\e[1;37m';    UWhi='\e[4;37m';    IWhi='\e[0;97m';    BIWhi='\e[1;97m';   On_Whi='\e[47m';    On_IWhi='\e[0;107m';

### Dynamic variables ###

installPathPrefix=$STD_INSTALL_PATH_PREFIX
installPath="${installPathPrefix}${INSTALL_DIR}"

langtoolCmd="$installPath/languagetool-commandline.jar"
langtoolServer="$installPath/languagetool-server.jar"
langtoolGUIUntil24="$installPath/languagetool-standalone.jar"
langtoolGUI="$installPath/languagetool.jar" # sice version 2.5 of langtool

### Exit Functions ###

# @param exitCode Optional. If not specified it will exit with $EXIT_FAILURE
# @param message Optional. Message to display in red before exit
function exit_err #(int exitCode, String message)
{
	if [[ $# -ge 2 ]]; then
		echo -e "${Red}[$1] $2${RCol}" >&2
	elif [[ $# -eq 1 ]]; then
		echo -e "${Red}[$EXIT_FAILURE] $1${RCol}" >&2
	fi
	[[ $# -ge 2 ]] && exit $1 || exit $EXIT_FAILURE
}

# @param exitCode Optional. If not specified it will exit with $EXIT_FAILURE
# @param message Optional. Message to display in green before exit
function exit_ok #(int exitCode, String message)
{
	if [[ $# -ge 2 ]]; then
		echo -e "${Gre}[$1] $2${RCol}"
	elif [[ $# -eq 1 ]]; then
		echo -e "${Gre}[$EXIT_SUCCESS] $1${RCol}"
	fi
	[[ $# -ge 2 ]] && exit $1 || exit $EXIT_SUCCESS
}

function exit_error #(String message)
{
	exit_err $EXIT_ERROR "$@"
}

function exit_failure #(String message)
{
	exit_err $EXIT_FAILURE "$@"
}

###### Functions: Action ######

# @before action_step(), action_own()
# @param ExitCode. If there is neither parameter specified it will not exit.
# @param message Optional. Message to display in red before exit
# stops with a red "[FAIL]"
function action_fail #(int exitCode, String message)
{
	columns=$(tput cols)
	printf "\r${Blu}%s${RCol}%s${Red}%*s${RCol}\n" \
		"$action_name" "$action_dots" \
		"$(($columns-${#action_name}-${#action_dots}))" \
		"[FAIL]" >&2
	[[ $# -ge 1 ]] && exit_err "$@" "$action_name << has an error"
}

# @before action_step(), action_own()
# @param ExitCode. If there is neither parameter specified it will not exit.
# @param message Optional. Message to display in green before exit
# stops with a green "[OK]"
function action_ok #(int exitCode, String message)
{
	columns=$(tput cols)
	printf "\r${Blu}%s${RCol}%s${Gre}%*s${RCol}\n" \
		"$action_name" "$action_dots" \
		"$(($columns-${#action_name}-${#action_dots}))" \
		"[OK]"
	[[ $# -eq 1 ]] && exit_ok "$@" "$action_name << was successful"
}

# @before action_start()
# @after action_ok(), action_fail()
# adds a dot
function action_step() 
{
	action_dots="${action_dots}."
	ges="$action_name${action_dots}[PENDING]"
	columns=$(tput cols)
	
	if [ ${#ges} -ge $columns ]; then
		printf "\r${Blu}%s${RCol}%s${Yel}%*s${RCol}\n" \
			"$action_name" "$action_dots" \
			"$(($columns-${#action_name}-${#action_dots}))" \
			"         "
		action_dots="."
		action_name=""
	fi
	
	printf "\r${Blu}%s${RCol}%s${Yel}%*s${RCol}" \
		"$action_name" "$action_dots" \
		"$(($columns-${#action_name}-${#action_dots}))" \
		"[PENDING]"
}

# @after action_ok(), action_fail()
# Start the action. Use this if you want to use your own output to show the
# actual progress of your operation. You can't use action_step() when you start
# with this function
function action_own()
{
	action_dots=" ..."
	action_name=">> $1"
	columns=$(tput cols)

	printf "${Blu}%s${RCol}%s\n" \
		"$action_name" "$action_dots"
}

# @after action_step()
# Start the action. Use action_step() for an additional dot and end it with
# action_fail() or action_ok()
function action_start # (description) 
{
	action_dots=" ..."
	action_name=">> $1"
	columns=$(tput cols)
	
	printf "${Blu}%s${RCol}%s${Yel}%*s${RCol}" \
		"$action_name" "$action_dots" \
		"$(($columns-${#action_name}-${#action_dots}))" \
		"[PENDING]"
}

###### Functions: Percent ######

# @after percent_ok(), percent_fail(), percent_set()
# draws a bar with 0%
function percent_start # (description)
{
	percent_name=">> $1"
	percent_prefix=": ["
	percent_suffix="]"
	percent_bar_finish=""
	percent_bar_remain=""
	start=$((${#percent_name} + ${#percent_prefix}))
	end=$(($(tput cols)-${#percent_suffix}-6))
		# border + length "100%" + border = 6
	
	for (( i=$start; i<=$end; i++ )); do
		percent_bar_remain="${percent_bar_remain}-"
	done
	printf "${Blu}%s${RCol}%s${Yel}%s${RCol}%s%s%4s" \
		"$percent_name" "$percent_prefix" "$percent_bar_finish" \
		"$percent_bar_remain" "$percent_suffix" "0%" # length of "100%" = 4
}

# @before percent_start()
# @after percent_ok(), percent_fail()
# @param value {0..100} sets the bar to value %.
function percent_set # (Int value)
{
	value=$1
	end=$(($(tput cols)-${#percent_suffix}-6)) # border + length "100%" + border = 6
	difference=$(($end - $start))
	border=$((($difference * $value) / 100))
	percent_bar_finish=""
	percent_bar_remain=""
	
	for (( i=0; i<=$difference; i++ )); do
		if [ $i -le $border ]; then
			percent_bar_finish="${percent_bar_finish}#"
		else 
			percent_bar_remain="${percent_bar_remain}-"
		fi
	done
	printf "\r${Blu}%s${RCol}%s${Yel}%s${RCol}%s%s%4s" \
		"$percent_name" "$percent_prefix" "$percent_bar_finish" \
		"$percent_bar_remain" "$percent_suffix" "${value}%" # length "100%" = 4
}

# @before percent_set(), percent_start()
# @param ExitCode. If there is neither parameter specified it will not exit.
# @param message Optional. Message to display in red before exit
# stops with a red "[FAIL]"
function percent_fail # (int exitCode)
{
	columns=$(tput cols)
	printf "\r${Blu}%s${RCol}${Red}%*s${RCol}\n" \
		"$percent_name" \
		"$(($columns - ${#percent_name}))" \
		"[FAIL]" >&2
	[[ $# -ge 1 ]] && exit_err "$@" "$percent_name << has an error"
}

# @before percent_set(), percent_start()
# @param ExitCode. If there is neither parameter specified it will not exit.
# @param message Optional. Message to display in green before exit
# stops with a green "[OK]"
function percent_ok #(int exitCode)
{
	columns=$(tput cols)
	printf "\r${Blu}%s${RCol}${Gre}%*s${RCol}\n" \
		"$percent_name" \
		"$(($columns - ${#percent_name}))" \
		"[OK]"
	[[ $# -ge 1 ]] && exit_ok "$@" "$percent_name << was successful"
}



###### Functions ######

function usage {
echo -e "${Red}Usage: ${Blu}$SCRIPTNAME ${Gre}[server | gui | cmd] [LanguageTool Options]${RCol}"
echo -e "       ${Blu}$SCRIPTNAME ${Gre}[-h | --help]${RCol}"
echo -e "       ${Blu}$SCRIPTNAME ${Gre} install [version]${RCol}"
echo -e "       ${Blu}$SCRIPTNAME ${Gre}uninstall${RCol}"
cat <<- _EOF_


OPTIONS:
 -h | --help		Print this help and exit

COMMANDS:
[server | gui | cmd] [LanguageTool Options]
 Parse [LanguageTool Options] to either the server, the standalone (gui)
 or the comamndline java executable of LanguageTool. If you do not
 specify one, the cmd command is used. Use --help in the
 [LanguageTool Options] part to see the usage text of the
 individual executables.
		
install [version]
 Install LanguageTool to $installPathPrefix, add script
 to $BIN_PATH and make shortcuts. If you do not specify a special
 version (e.g 1.8, 1.9, 2.1, 2.2, 2.3, ...) the last stable version 
 is used.
		
uninstall
 Uninstall all files mentioned in the install command exept this
 script. Delete the script in $BIN_PATH yourself if you want.

upgrade [version]
 An uninstall with a following install. If you do not specify a special
 version (e.g 1.8, 1.9, 2.1, 2.2, 2.3, ...) the last stable
 version is used.
_EOF_
	[[ $# -eq 1 ]] && exit $1 || exit $EXIT_FAILURE
}

# @return 0 True. it is installed
# @return 1 False. It is not installed
function is_installed()
{
	if  [[ -d "$installPath/" ]] || [[ -f "$langtoolServer" ]]; then
		return 0
	else
		return 1
	fi
}

function install_download_extract # (versionToInstall)
{	
	versionToInstall=$1
	
	action_own "Downloading LanguageTool"
	
	if [ -z "$1" ]; then
		download_url="$DOWNLOAD_URL_LAST_STABLE"
	else
		download_url="${DOWNLOAD_URL_VERSION}${1}.zip"
	fi
	
	output="/tmp/languagetool.zip"
	
	wget --continue --no-check-certificate --output-document="$output" "$download_url" \
			|| action_fail $EXIT_FAILURE
				
	action_ok
	
	
	action_start "Extract LanguageTool"
	
	# multiple mv: the command should not copy from /tmp into 
	# the installPath, mv should replace it
	rc=0
	
	unzip -q -o "$output" -d "/tmp/install_LanguageTool/"; rc=$(($rc + $?))
	mv -f /tmp/install_LanguageTool/LanguageTool-* \
		"/tmp/install_LanguageTool/$INSTALL_DIR"; rc=$(($rc + $?))
	mv -f "/tmp/install_LanguageTool/$INSTALL_DIR" \
		"$installPathPrefix"; rc=$(($rc + $?))
	
	if  (( $rc != 0 )); then
		rm -r "/tmp/install_LanguageTool/$INSTALL_DIR"
		action_fail $EXIT_FAILURE
	fi
			
	action_ok
	
	
	action_own "Downloading LanguageTool Logo"
	
	output="$installPath/logo.png"
	
	wget --continue --no-check-certificate --output-document="$output" "$DOWNLOAD_LOGO" \
			|| action_fail $EXIT_FAILURE
				
	action_ok
}

function install_shortcut # ()
{
	action_start "Make shortcut"
	
	# copy icon
	cp "$installPath/logo.png" "$ICON_PATH/langtool.png" \
		|| action_fail $EXIT_FAILURE

	cd /tmp
	action_step

	cat > langtool.desktop <<- _EOF_
[Desktop Entry]
Encoding=UTF-8
Type=Application

Name=LanguageTool
Comment=LanguageTool ist a Tool to check the grammar of your text.

Exec=langtool gui
Terminal=false
X-MultipleArgs=false
StartupNotify=true
Icon=langtool
Categories=Utility;Office;

_EOF_

	desktop-file-install ./langtool.desktop \
		|| action_fail $EXIT_FAILURE
	action_step
	
	cat > langtooltray.desktop <<- _EOF_
[Desktop Entry]
Encoding=UTF-8
Type=Application

Name=LanguageTool (Tray)
Comment=LanguageTool ist a Tool to check the grammar of your text.

Exec=langtool gui --tray
Terminal=false
X-MultipleArgs=false
StartupNotify=true
Icon=langtool
Categories=Utility;Office;

_EOF_

	desktop-file-install ./langtooltray.desktop \
		|| action_fail $EXIT_FAILURE
	
	action_ok
}	


function install_full # (versionToInstall)
{
	versionToInstall=$1
	
	if is_installed; then
		echo -e "${Blu}LanguageTool seems to be already installed in${Rcol}"
		exit_failure "$installPath. Use \"$SCRIPTNAME uninstall\" first."
	fi
	
	if [ $INSTALL_WITH_ROOT = true ] && [ $(whoami) != "root" ]; then
		exit_failure "You need Administrator privileges! Run script as root again.">&2
	fi
	
	install_download_extract $versionToInstall
	
	if [ ! "$SCRIPTPATH" -ef "$BIN_PATH/$(basename $SCRIPTNAME .sh)" ]; then
		action_start "Copy files"
		cp "$SCRIPTPATH" "$BIN_PATH/$(basename $SCRIPTNAME .sh)" \
			|| action_fail $EXIT_FAILURE
		
		action_ok
		
		echo -e "${Pur}The script was added to the PATH directory \"$BIN_PATH\"${RCol}".
		echo -e "${Pur}You can now also type \"$(basename $SCRIPTNAME .sh) --help\" to use this${RCol}"
		echo -e "${Pur}script as an alias for the LanguageTool executables${RCol}"
		echo -e "${Pur}or for upgrading/uninstalling.${RCol}"
		echo -e "${Pur}Don't forget to activate the Server in the GUI Settings if you${RCol}"
		echo -e "${Pur}wish to use LanguageTool with another Programm.${RCol}"
	fi
	
	install_shortcut
	
	action_start "Install complete"
	
	# make a symlink if its an older version <= 2.3
	if [[ ! -z "$1" ]] && expr $1 \< 2.4 >/dev/null; then
		ln -s "$langtoolGUIUntil24" "$langtoolGUI"
	fi
	
	action_ok
}

function uninstall
{
	if [ $INSTALL_WITH_ROOT = true ] && [ $(whoami) != "root" ]; then
		exit_failure "You need Administrator privileges! Run script as root again.">&2
	fi
	
	while true; do
		read -p "Are You sure you want to uninstall? All files in $installPath will be deleted! (yes/no)" yn
		case $yn in
		[Yy]* ) break;;
		[Nn]* ) exit_err $EXIT_FAILURE "Aborted";;
		* ) echo "Please answer yes or no.";;
		esac
	done
	
	percent_start "Uninstall LanguageTool"
	rc=0
	
	percent_set 4
	
	rm -fr $installPath; rc=$(($rc + $?))
	
	percent_set 60
	rm -f "${MENU_PATH}/langtool.desktop"; rc=$(($rc + $?))
	rm -f "${MENU_PATH}/langtooltray.desktop"; rc=$(($rc + $?))
	rm -f "${ICON_PATH}/langtool.png"; rc=$(($rc + $?))
	
	percent_set 70
	update-desktop-database; rc=$(($rc + $?))
	
	percent_set 80
	# remove temp directories and files which used during install
	if [ -d "/tmp/install_LanguageTool" ]; then
		rm -fr "/tmp/install_LanguageTool"; rc=$(($rc + $?))
	fi
	
	percent_set 90
	
	if [ -f "/tmp/languagetool.zip" ]; then
		rm -f "/tmp/languagetool.zip"; rc=$(($rc + $?))
	fi
	
	if  (( $rc != 0 )); then
		exit_failure ">> Uninstall LanguageTool"
	fi
	
	percent_ok
}

####### Parse Options ######

# first ':' deletes getopts output
optspec=':o:vh-:'

while getopts "$optspec" OPTION ; do
	case $OPTION in
		-)
			case "${OPTARG}" in
				help)
					usage $EXIT_SUCCESS
				;;
				*)	# parsing arguments to langtoolCmd. remove break
					# and OPTIND increment if you do not want that
					OPTIND=$(( $OPTIND + 1 ))
				break
				if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
					echo "Unknown option --${OPTARG}" >&2
				fi
				;;
			esac
			;;
		h) 	usage $EXIT_SUCCESS
			;;
		\?)	# parsing arguments to langtoolCmd. remove break
			# if you do not want that
			break
			echo "Unknown option \"-$OPTARG\"." >&2
			usage $EXIT_ERROR
			;;
		:) 	echo "Option \"-$OPTARG\" needs an argument." >&2
			usage $EXIT_ERROR
			;;
		*) 	echo "${Red}ERROR: This should not happen ...${RCol}" >&2
			usage $EXIT_BUG
			;;
	esac
done

# jump over consumed arguments
shift $(( OPTIND - 1 ))

# Testing if there are enough arguments
if (( $# < 1 )) ; then

 echo -e "${Red}At least one argument is needed.${RCol}" >&2
 usage $EXIT_ERROR
fi

####### Parse Commands ######


# Loop over arguments
for ARG ; do
	
	OPTIND=$(( $OPTIND + 1 ))
	case "$ARG" in
		install) 		install_full "${!OPTIND}"
					break
					;;
		uninstall)		uninstall
					break
					;;
		upgrade)		uninstall
					install_full "${!OPTIND}"
					break
					;;
		server)
					shift 1 # remove server from $@
					if ! is_installed; then
						exit_failure "not installed"
					fi
					$JAVA_BIN "$langtoolServer" $@
					break
					;;
		gui)
					shift 1 # remove gui from $@
					if ! is_installed; then
						exit_failure "not installed"
					fi
					$JAVA_BIN "$langtoolGUI" $@
					break
					;;
		cmd)
					shift 1 # remove cmd from $@
					if ! is_installed; then
						exit_failure "not installed"
					fi
					$JAVA_BIN "$langtoolCmd" $@
					break
					;;
		*)			
					if ! is_installed; then
						usage
					fi
					$JAVA_BIN "$langtoolCmd" $@
					break
					;;
	esac
done

exit $EXIT_SUCCESS
