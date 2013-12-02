#!/bin/bash
###########################################################
## Title: langtool
## Abstact: A Script that manage LanguageTool
## Author:  Fabian Raab <fabian@4raab.de>
## Dependencies: bash, wget
## Creation Date: 2013-12-02
## Last Edit: 2013-12-02 17:20
###########################################################

SCRIPTNAME=$(basename $0)
SCRIPTPATH="$0"
EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_ERROR=2
EXIT_BUG=10

INSTALL_WITH_ROOT=true # need root privilegues for install?
INSTALL_PATH_PREFIX="/opt/"
INSTALL_DIR="languagetool"
INSTALL_PATH="${INSTALL_PATH_PREFIX}${INSTALL_DIR}"

BIN_PATH="/usr/local/bin"
ICON_PATH="/usr/share/pixmaps/"
MENU_PATH="/usr/share/applications/"

LANGTOOL_CMD="java -jar $INSTALL_PATH/languagetool-commandline.jar"
LANGTOOL_SERVER="java -jar $INSTALL_PATH/languagetool-server.jar"
LANGTOOL_GUI="java -jar $INSTALL_PATH/languagetool-standalone.jar"

DOWNLOAD_URL_LAST_STABLE="http://www.languagetool.org/download/LanguageTool-stable.zip"
DOWNLOAD_URL_VERSION="http://www.languagetool.org/download/LanguageTool-"
DOWNLOAD_LOGO="http://www.languagetool.org/images/LanguageToolBig.png"

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


function exit_error() {
	echo -e "${Red}${1}${RCol}">&2
	exit $EXIT_ERROR
}

function exit_failure() {
	echo -e "${Blu}${1}${RCol} ... [${Red}FAILED${RCol}]">&2
	exit $EXIT_FAILURE
}

function action_ok() {
	echo -e "${Blu}${1}${RCol} ... [${Gre}DONE${RCol}]"
}

function action() {
	echo -e "${Blu}${1}${RCol} ..."
}

### Functions ###
function usage {
echo -e "${Red}Usage: ${Blu}$SCRIPTNAME ${Gre}[server | gui | cmd] [LanguageTool Options]${RCol}"
echo -e "       ${Blu}$SCRIPTNAME ${Gre}[-h | --help]${RCol}"
echo -e "       ${Blu}$SCRIPTNAME ${Gre}install [version]${RCol}"
echo -e "       ${Blu}$SCRIPTNAME ${Gre}uninstall${RCol}"
cat <<- _EOF_

OPTIONS:
 -h | --help		Print this help and exit

COMMANDS:
[server | gui | cmd] [LanguageTool Options]
 Parse [LanguageTool Options] to either the server, the standalone
 or the comamndline java executable of LanguageTool. If you do not
 specify one, the cmd command is used. Use --help in the
 [LanguageTool Options] part to see the usage text of the
 individual executables.
		
install [version]
 Install LanguageTool to $INSTALL_PATH_PREFIX, add script to
 $BIN_PATH and make shortcuts. If you do not specify a special
 version (e.g 1.8, 1.9, 2.1, 2.2, 2.3, ...) the last stable
 version is used.
		
uninstall
 Uninstall all files mentioned in the install command exept this
 script. Delete the script in $BIN_PATH yourself if you want.

upgrade [version]
 An uninstall with a following install.
_EOF_
	[[ $# -eq 1 ]] && exit $1 || exit $EXIT_FAILURE
}

function install_download_extract # (version_to_install)
{	
	action "Downloading LanguageTool"
	
	if [ -z "$1" ]; then
		download_url="$DOWNLOAD_URL_LAST_STABLE"
	else
		download_url="${DOWNLOAD_URL_VERSION}${1}.zip"
	fi
	
	output="/tmp/languagetool.zip"
	
	wget --continue --no-check-certificate --output-document="$output" "$download_url" \
			|| exit_failure "Downloading LanguageTool"
				
	action_ok "Downloading LanguageTool"
	
	
	action "Extract LanguageTool"
	
	# multiple mv: the command should not copy from /tmp into 
	# the INSTALL_PATH, mv should replace it
	rc=0
	
	unzip -q -o "$output" -d "/tmp/install_LanguageTool/"; rc=$(($rc + $?))
	mv -f /tmp/install_LanguageTool/LanguageTool-* \
		"/tmp/install_LanguageTool/$INSTALL_DIR"; rc=$(($rc + $?))
	mv -f "/tmp/install_LanguageTool/$INSTALL_DIR" \
		"$INSTALL_PATH_PREFIX"; rc=$(($rc + $?))
	
	if  (( $rc != 0 )); then
		rm -r "/tmp/install_LanguageTool/$INSTALL_DIR"
		exit_failure "Extract LanguageTool"
	fi
			
	action_ok "Extract LanguageTool"
	
	
	action "Downloading LanguageTool Logo"
	
	output="$INSTALL_PATH/logo.png"
	
	wget --continue --no-check-certificate --output-document="$output" "$DOWNLOAD_LOGO" \
			|| exit_failure "Downloading LanguageTool Logo"
				
	action_ok "Downloading LanguageTool Logo"
}

function install_shortcut
{
	action "Make shortcut"
	
	# copy icon
	cp "$INSTALL_PATH/logo.png" "$ICON_PATH/langtool.png" \
		|| exit_failure "Make shortcut"

	cd /tmp

	cat > langtool.desktop <<- _EOF_
[Desktop Entry]
Encoding=UTF-8
Type=Application

Name=LanguageTool
Comment=LanguageTool ist a Tool to check the grammar of your texts.

Exec=langtool gui
Terminal=false
X-MultipleArgs=false
StartupNotify=true
Icon=langtool
Categories=Utility;Office;

_EOF_

	desktop-file-install ./langtool.desktop \
		|| exit_failure "Make shortcut"

	cat > langtooltray.desktop <<- _EOF_
[Desktop Entry]
Encoding=UTF-8
Type=Application

Name=LanguageTool (Tray)
Comment=LanguageTool ist a Tool to check the grammar of your texts.

Exec=langtool gui --tray
Terminal=false
X-MultipleArgs=false
StartupNotify=true
Icon=langtool
Categories=Utility;Office;

_EOF_

	desktop-file-install ./langtooltray.desktop \
		|| exit_failure "Make shortcut"
	
	action_ok "Make shortcut"
}	


function install_full # (version_to_install)
{
	if [ -d "$INSTALL_PATH/" ]; then
		echo -e "${Blu}LanguageTool seems to be already installed in${Rcol}"
		exit_failure "$INSTALL_PATH. Use \"$SCRIPTNAME uninstall\" first."
	fi
	
	if [ $INSTALL_WITH_ROOT = true ] && [ $(whoami) != "root" ]; then
		exit_failure "You need Administrator privileges! Run script as root again.">&2
	fi
	
	action ">> Installing LanguageTool"
	
	install_download_extract $1
	
	if [ ! "$SCRIPTPATH" -ef "$BIN_PATH/$(basename $SCRIPTNAME .sh)" ]; then
		action "Copy files"
		cp "$SCRIPTPATH" "$BIN_PATH/$(basename $SCRIPTNAME .sh)" \
			|| exit_failure "Copy files"
		
		echo -e "${Pur}The script was added to the PATH directory \"$BIN_PATH\"${RCol}".
		echo -e "${Pur}You can now also type \"$(basename $SCRIPTNAME .sh) --help\" to use this${RCol}"
		echo -e "${Pur}script as an alias for the LanguageTool executables${RCol}"
		echo -e "${Pur}or for upgrading/uninstalling.${RCol}"
		
		action_ok "Copy files"
	fi
	
	install_shortcut
	
	
	action_ok ">> Installing LanguageTool"
}

function uninstall
{
	if [ $INSTALL_WITH_ROOT = true ] && [ $(whoami) != "root" ]; then
		exit_failure "You need Administrator privileges! Run script as root again.">&2
	fi
	
	action ">> Uninstall LanguageTool"
	rc=0
	
	rm -r $INSTALL_PATH; rc=$(($rc + $?))
	rm "${MENU_PATH}/langtool.desktop"; rc=$(($rc + $?))
	rm "${MENU_PATH}/langtooltray.desktop"; rc=$(($rc + $?))
	rm "${ICON_PATH}/langtool.png"; rc=$(($rc + $?))
	update-desktop-database; rc=$(($rc + $?))
	
	# remove temp directories and files which used during install
	if [ -d "/tmp/install_LanguageTool" ]; then
		rm -r "/tmp/install_LanguageTool"; rc=$(($rc + $?))
	fi
	if [ -f "/tmp/languagetool.zip" ]; then
		rm "/tmp/languagetool.zip"; rc=$(($rc + $?))
	fi
	
	if  (( $rc != 0 )); then
		exit_failure ">> Uninstall LanguageTool"
	fi
	
	action_ok ">> Uninstall LanguageTool"
}

# first ':' deletes getopts output
optspec=':o:vh-:'

while getopts "$optspec" OPTION ; do
	case $OPTION in
		-)
            case "${OPTARG}" in
            	help)
                	usage $EXIT_SUCCESS
                	;;
                *)	# parsing arguments to LANGTOOL_CMD. remove break
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
		\?)	# parsing arguments to LANGTOOL_CMD. remove break
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
#if (( $# < 1 )) ; then
# echo "Mindestens ein Argument beim Aufruf übergeben." >&2
# usage $EXIT_ERROR
#fi


# Loop over arguments
for ARG ; do
	
	OPTIND=$(( $OPTIND + 1 ))
	case "$ARG" in
		install) 	install_full "${!OPTIND}"
					break
					;;
		uninstall)  uninstall
					break
					;;
		upgrade)	uninstall
					install_full "${!OPTIND}"
					break
					;;
		server)
					shift 1 # remove server from $@
					$LANGTOOL_SERVER $@
					break
					;;
		gui)
					shift 1 # remove gui from $@
					$LANGTOOL_GUI $@
					break
					;;
		cmd)
					shift 1 # remove cmd from $@
					$LANGTOOL_CMD $@
					break
					;;
		*)
					$LANGTOOL_CMD $@
					break
					;;
	esac
done

exit $EXIT_SUCCESS
