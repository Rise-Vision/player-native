#!/bin/sh
# Rise Vision Player installation script

set -e

DISPLAY_ID="" 
CLAIM_ID="#CLAIM_ID#" 

VERSION="2.3.0000lnx" 

RVPLAYER="rvplayer"
CHROMIUM="chrome"

CHROME_LINUX="chrome-linux"
RISE_PLAYER_LINUX="RisePlayer"
RISE_CACHE_LINUX="RiseCache"
JAVA_LINUX="jre"

CORE_URL="https://rvaserver2.appspot.com" 
SHOW_URL="http://rvashow.appspot.com"

OS=$(lsb_release -si)
ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')

TYPE_CHROMIUM="chromium"
TYPE_INSTALLER="installer"
TYPE_JAVA="java"
TYPE_RISE_PLAYER="RisePlayer"
TYPE_RISE_CACHE="RiseCache"

VIEWER_URL="$SHOW_URL/Viewer.html"

RISE_CACHE_URL="http://localhost:9494"
RISE_CACHE_PING_URL="$RISE_CACHE_URL/ping?callback=test"
RISE_CACHE_SHUTDOWN_URL="$RISE_CACHE_URL/shutdown"

RISE_PLAYER_URL="http://localhost:9449"
RISE_PLAYER_PING_URL="$RISE_PLAYER_URL/ping?callback=test"
RISE_PLAYER_SHUTDOWN_URL="$RISE_PLAYER_URL/shutdown"

PREFERENCES="{\"countryid_at_install\":0,\"default_search_provider\":{\"enabled\":false},\"geolocation\":{\"default_content_setting\":1},\"profile\":{\"content_settings\":{\"pref_version\":1},\"default_content_settings\": {\"geolocation\": 1},\"exited_cleanly\":true}}"

CONFIG_PATH=".config/$RVPLAYER"
CACHE_PATH=".cache/$RVPLAYER"
PREFERENCES_PATH=".config/$RVPLAYER/Default"
FIRST_RUN_FILE="First Run"
PREFERENCES_FILE="Preferences"
RDNII_FILE="RiseDisplayNetworkII.ini"

TEMP_PATH="$HOME/$RVPLAYER/temp"
INSTALL_PATH="$HOME/$RVPLAYER"
STARTUP_SCRIPT_FILE="$HOME/$RVPLAYER/$RVPLAYER"

TERMS_FILE="$INSTALL_PATH/$RDNII_FILE"

AUTOSTART_PATH="$HOME/.config/autostart"
AUTOSTART_FILE="$RVPLAYER.desktop"

PARAM_INSTALLER_VERSION="InstallerVersion"
PARAM_INSTALLER_URL="InstallerURL"
PARAM_CHROMIUM_VERSION="BrowserVersion"
PARAM_CHROMIUM_URL="BrowserURL"
PARAM_JAVA_VERSION="JavaVersion"
PARAM_JAVA_URL="JavaURL"
PARAM_RISE_PLAYER_VERSION="PlayerVersion"
PARAM_RISE_PLAYER_URL="PlayerURL"
PARAM_RISE_CACHE_VERSION="CacheVersion"
PARAM_RISE_CACHE_URL="CacheURL"

SILENT=false
CLEAR_CACHE=false

VALUE_NO="0"
VALUE_YES="1"

VALUE_INSTALLER_VERSION=""
VALUE_INSTALLER_URL=""
VALUE_CHROMIUM_VERSION=""
VALUE_CHROMIUM_URL=""
VALUE_JAVA_VERSION=""
VALUE_JAVA_URL=""
VALUE_RISE_CACHE_VERSION=""
VALUE_RISE_CACHE_URL=""
VALUE_RISE_PLAYER_VERSION=""
VALUE_RISE_PLAYER_URL=""

CURRENT_CHROMIUM_VERSION=""
CURRENT_JAVA_VERSION=""
CURRENT_RISE_PLAYER_VERSION=""
CURRENT_RISE_CACHE_VERSION=""


rvp_exit_with_error() {

	rm -rf $TEMP_PATH

	echo $1
	echo "Rise Vision Player is NOT installed."
	exit 0
}

rvp_fix_display_id() {
	
	# empty $DISPLAY_ID if it starts with #
	if [ "$(echo $DISPLAY_ID | head -c 1)" = "#" ]
	then
		DISPLAY_ID=""
		echo 'reset DISPLAY_ID'
	fi
	
	# empty $CLAIM_ID if it starts with #
	if [ "$(echo $CLAIM_ID | head -c 1)" = "#" ]
	then
		CLAIM_ID=""
		echo 'reset CLAIM_ID'
	fi
	
}

rvp_load_display_id() {
	
	# load $DISPLAY_ID if empty
	if [ -z "$DISPLAY_ID" ] && [ -f "$INSTALL_PATH/$RDNII_FILE" ]
	then
		set +e
		line="$(grep -F -m 1 'displayid=' $INSTALL_PATH/$RDNII_FILE)"
		DISPLAY_ID="$(echo $line | cut -d = -f 2-)"
		#remove carriage return
		DISPLAY_ID="$(echo $DISPLAY_ID | tr -d '\r')" 
		set -e
	fi
		
}

rvp_save_display_id() {
	if [ ! -f "$INSTALL_PATH/$RDNII_FILE" ] 
	then		
		echo "[RDNII]
displayid=$DISPLAY_ID
claimid=$CLAIM_ID
viewerurl=$VIEWER_URL
" > $INSTALL_PATH/$RDNII_FILE
	fi
}

rvp_install_script() {

	mkdir -p $INSTALL_PATH

	abspath=$(cd ${0%/*} && echo $PWD/${0##*/})

	if [ $abspath != $STARTUP_SCRIPT_FILE ]; then

		cp $abspath $STARTUP_SCRIPT_FILE
		chmod 755 $STARTUP_SCRIPT_FILE
		echo "Startup script updated."
	fi
	
	echo $VERSION > $INSTALL_PATH/$TYPE_INSTALLER".ver"

}

rvp_get_response_code() {
	
	local URL=$1
	
	set +e
	
	response_code=$(wget --spider --server-response $URL 2>&1 | awk '/^  HTTP/{print $2}')
	
	set -e
}

rvp_get_update() {

	#rename cromium_version if exists to make it compatible with Player 1.
	if [ -f "$INSTALL_PATH/${TYPE_CHROMIUM}_version" ]
	then
		mv -u $INSTALL_PATH/$TYPE_CHROMIUM"_version" $INSTALL_PATH/$TYPE_CHROMIUM".ver"
	fi	

	CURRENT_CHROMIUM_VERSION=`cat $INSTALL_PATH/$TYPE_CHROMIUM".ver" 2>&1` || CURRENT_CHROMIUM_VERSION=""
	CURRENT_JAVA_VERSION=`cat $INSTALL_PATH/$TYPE_JAVA".ver" 2>&1` || CURRENT_JAVA_VERSION=""
	CURRENT_RISE_PLAYER_VERSION=`cat $INSTALL_PATH/$TYPE_RISE_PLAYER".ver" 2>&1` || CURRENT_RISE_PLAYER_VERSION=""
	CURRENT_RISE_CACHE_VERSION=`cat $INSTALL_PATH/$TYPE_RISE_CACHE".ver" 2>&1` || CURRENT_RISE_CACHE_VERSION=""

	if [ "$ARCH" = "64" ]
	then
		update_url="https://install-versions.risevision.com/remote-components-lnx-64.cfg"
	else
		update_url="https://install-versions.risevision.com/remote-components-lnx-32.cfg"
	fi

	echo "Checking for updates..."
	echo $update_url
	echo $DISPLAY_ID

	set +e

	update_content=`wget -O - $update_url` || update_content="" # rvp_exit_with_error "Update check failed"

	set -e

	upgrade_needed=$VALUE_NO

	for line in $update_content ; do

		echo $line

	 	p_name="$(echo "$line" | cut -d = -f 1)"
		p_value="$(echo "$line" | cut -d = -f 2-)"
		   	
		case $p_name in

			$PARAM_INSTALLER_VERSION ) VALUE_INSTALLER_VERSION=$p_value ;;
			$PARAM_INSTALLER_URL ) VALUE_INSTALLER_URL=$p_value ;;
			$PARAM_CHROMIUM_VERSION ) VALUE_CHROMIUM_VERSION=$p_value ;;
			$PARAM_CHROMIUM_URL ) VALUE_CHROMIUM_URL=$p_value ;;
			$PARAM_JAVA_VERSION ) VALUE_JAVA_VERSION=$p_value ;;
			$PARAM_JAVA_URL ) VALUE_JAVA_URL=$p_value ;;
			$PARAM_RISE_PLAYER_VERSION ) VALUE_RISE_PLAYER_VERSION=$p_value ;;
			$PARAM_RISE_PLAYER_URL ) VALUE_RISE_PLAYER_URL=$p_value ;;
			$PARAM_RISE_CACHE_VERSION ) VALUE_RISE_CACHE_VERSION=$p_value ;;
			$PARAM_RISE_CACHE_URL ) VALUE_RISE_CACHE_URL=$p_value ;;
			
		esac
	   
	done

}

rvp_kill_rise_player() {

	set +e

	wget --spider --tries=1 $RISE_PLAYER_SHUTDOWN_URL >/dev/null 2>&1

	set -e

	sleep 3

}

rvp_kill_rise_cache() {

	set +e

	wget --spider --tries=1 $RISE_CACHE_SHUTDOWN_URL >/dev/null 2>&1

	set -e
	
	sleep 3

}

rvp_kill_chromium() {

	killall "$CHROMIUM" || echo "no Chromiums to kill"
	sleep 3

	if ps ax | grep -v grep | grep $CHROMIUM > /dev/null
	then
		sleep 10

		if ps ax | grep -v grep | grep $CHROMIUM > /dev/null
		then
			killall "$CHROMIUM" || echo "no Chromiums to kill"
			sleep 3
		fi	
	fi
}

rvp_reset_chromium() {

	echo "Closing Chromium and clearing its cache..."

	rvp_kill_chromium
	rm -rf $HOME/$CACHE_PATH
	rm -rf $HOME/$CONFIG_PATH
}

rvp_download_and_run_installer() {

	# begin support for rollback to Player 1
	# check if installer version begins with 1
	if [ "$(echo $VALUE_INSTALLER_VERSION | head -c 2)" = "1." ] 
	then
		VALUE_INSTALLER_URL="$CORE_URL/player/download?os=lnx&displayId=$DISPLAY_ID" 
	fi
	# end support for rollback to Player 1
	
	abspath=$(cd ${0%/*} && echo $PWD/${0##*/})
	
	echo $abspath
	
	# setting wget options
	:> wgetrc
	echo "noclobber = off" >> wgetrc
	echo "dir_prefix = ." >> wgetrc
	echo "dirstruct = off" >> wgetrc
	echo "verbose = on" >> wgetrc
	echo "progress = dot:default" >> wgetrc
	echo "output-document = $abspath" >> wgetrc
	# downloading zip
	echo "Downloading..."
	WGETRC=wgetrc wget $VALUE_INSTALLER_URL || rvp_exit_with_error "Installer download failed"
	rm -f wgetrc
	echo "Download complete."
	
	chmod 755 $abspath
	$abspath

	# exit this version and let new version take over
	exit 0

}

rvp_download_and_unpack() {

	# $1 - download URL
	# $2 - file name
	# $3 - temp path

	mkdir -p $3
	cd $3
	
	# setting wget options
	:> wgetrc
	echo "noclobber = off" >> wgetrc
	echo "dir_prefix = ." >> wgetrc
	echo "dirstruct = off" >> wgetrc
	echo "verbose = on" >> wgetrc
	echo "progress = dot:default" >> wgetrc
	echo "output-document = $2.zip" >> wgetrc 

	# downloading zip
	echo "Downloading..."
	rm -f "$2.zip"
	WGETRC=wgetrc wget $1 || rvp_exit_with_error "Download failed"
	rm -f wgetrc
	echo "Download complete."

	rm -rf $2*/

	# unzipping
	unzip -bo "$2.zip" || rvp_exit_with_error "Cannot unzip $2.zip"
	
	rm -f "$2.zip"
}

rvp_install_updates() {
	
	cd $TEMP_PATH
	find * -print | cpio -pvdmu $INSTALL_PATH
	
	chmod -R g+r,a+r,a+X $INSTALL_PATH/*
	
	cd $INSTALL_PATH
	rm -rf $TEMP_PATH*
		
} 

rvp_confirm_add_player_to_autostart() {

	if ! $SILENT
	then
		echo ''
		read -p 'run Rise Vision Player on OS startup (y/n)?' choice
		case "$choice" in
			y|Y) rvp_add_player_to_autostart;;
			*) rm -f $AUTOSTART_PATH/$AUTOSTART_FILE;;
		esac
	fi

}

rvp_add_player_to_autostart() {

	mkdir -p $AUTOSTART_PATH
	:> $AUTOSTART_PATH/$AUTOSTART_FILE
	echo "[Desktop Entry]" >> $AUTOSTART_PATH/$AUTOSTART_FILE
	echo "Encoding=UTF-8" >> $AUTOSTART_PATH/$AUTOSTART_FILE
	echo "Name=Rise Vision Player" >> $AUTOSTART_PATH/$AUTOSTART_FILE
	echo "Comment=" >> $AUTOSTART_PATH/$AUTOSTART_FILE
	echo "Icon=" >> $AUTOSTART_PATH/$AUTOSTART_FILE
	echo "Exec=$STARTUP_SCRIPT_FILE /S" >> $AUTOSTART_PATH/$AUTOSTART_FILE
	echo "Terminal=false" >> $AUTOSTART_PATH/$AUTOSTART_FILE
	echo "Type=Application" >> $AUTOSTART_PATH/$AUTOSTART_FILE
	echo "Categories=" >> $AUTOSTART_PATH/$AUTOSTART_FILE
	echo "NotShowIn=KDE;" >> $AUTOSTART_PATH/$AUTOSTART_FILE
	echo "X-GNOME-Autostart-Delay=10" >> $AUTOSTART_PATH/$AUTOSTART_FILE
	echo "X-Ubuntu-Gettext-Domain=$RVPLAYER" >> $AUTOSTART_PATH/$AUTOSTART_FILE

	chmod 755 $AUTOSTART_PATH/$AUTOSTART_FILE

}

rvp_update_crontab() {

	# remove crontab if it has 'rvplayer' in it
	if [ $(expr index "$(crontab -l)" "$RVPLAYER") -gt 0 ]
	then
		crontab -r
	fi

}

rvp_start_player() {

	if ps ax | grep -v grep | grep $CHROMIUM > /dev/null
	then
		echo "Chromium is already running"
	else
		#set up Chromium preferences
		cd
		mkdir -p $HOME/$CONFIG_PATH
		mkdir -p $HOME/$PREFERENCES_PATH
		:>"$HOME/$CONFIG_PATH/$FIRST_RUN_FILE"
		:>$HOME/$PREFERENCES_PATH/$PREFERENCES_FILE
		echo "$PREFERENCES" >> $HOME/$PREFERENCES_PATH/$PREFERENCES_FILE
	fi

	#check if cache is running
	rvp_get_response_code $RISE_CACHE_PING_URL
	if [ "$response_code" = "200" ]
	then	
		echo "RiseCache is already running"
	else
		#run RiseCache in non-blocking mode (background) and hide output
		#also run it as job, so it won't be killed when terminal is closed 
		nohup sh -c "export PATH=$INSTALL_PATH/jre/bin:$PATH; java -jar '$INSTALL_PATH/$RISE_CACHE_LINUX/$RISE_CACHE_LINUX.jar' >/dev/null 2>&1 &"
	fi

	#check if player is running
	rvp_get_response_code $RISE_PLAYER_PING_URL
	if [ "$response_code" = "200" ]
	then	
		echo "RisePlayer is already running"
	else
		echo "Starting Rise Player..."
		rvp_save_display_id
		#run RisePlayer in non-blocking mode (background) and hide output
		#also run it as job, so it won't be killed when terminal is closed 
		nohup sh -c "export DISPLAY=:0; export PATH=$INSTALL_PATH/jre/bin:$PATH; java -jar '$INSTALL_PATH/$RISE_PLAYER_LINUX.jar' >/dev/null 2>&1 &"
	fi

}

rvp_accept_terms() {

	if [ ! -f $TERMS_FILE ]
	then
		echo ''
		echo '***************************************************************************'
		echo '** Warning ****************************************************************'
		echo '***************************************************************************'
		echo 'The Rise Vision Player is best run on a dedicated digital signage appliance.'
		echo 'Every time you start the computer it is installed on it will automatically'
		echo 'begin showing it'\''s assigned Presentations, which will drive you nuts if'
		echo 'this is your personal computer. If you just want to check out Presentations,'
		echo 'the best way to do that is to Preview them in your browser from the'
		echo 'Presentation editor. Otherwise if you still want to install on this computer'
		echo 'please read and accept our Terms of Service and Privacy'
		echo '(http://rvauser.appspot.com/RiseVisionTermsofServiceandPrivacy.html)'
		echo 'and proceed with your installation. Please note that if you are running the'
		echo 'Chrome browser it will be closed to complete the installation.'
		echo '***************************************************************************'
		echo ''

		read -p 'Do you agree with the Terms of Service and Privacy (y/n)?' choice
		case "$choice" in 
		y|Y ) echo "Terms accepted.";; #echo -n "" > $TERMS_FILE;;
		* ) exit;;
		esac

	fi

}

echo "Rise Vision Player Installer ver.$VERSION"

rvp_fix_display_id

rvp_load_display_id

# check if silent
for i
do 
	if [ "$i" = "/S" ]; then SILENT=true; fi
	if [ "$i" = "/C" ]; then CLEAR_CACHE=true; fi
done

# set to silent if script is not running in terminal (cron in our case)
# this is required for Player 1 upgrade
if [ ! -t 1 ]; then SILENT=true; fi

if [ -f "$INSTALL_PATH/clear_cache" ]
then 
	CLEAR_CACHE=true
	rm -f "$INSTALL_PATH/clear_cache"
fi

if ! $SILENT; then rvp_accept_terms; fi

rvp_get_update

# check for installer upgrade

if [ -n "$VALUE_INSTALLER_VERSION" ] && [ -n "$VALUE_INSTALLER_URL" ] && [ "$VALUE_INSTALLER_VERSION" != "$VERSION" ]
then 
	rvp_download_and_run_installer
else
	echo "Installer is up to date."
fi

rvp_install_script

rm -rf $TEMP_PATH/$CHROME_LINUX

upgrade_needed=$VALUE_NO

# check for Chromium upgrade

if [ -n "$VALUE_CHROMIUM_VERSION" ] && [ -n "$VALUE_CHROMIUM_URL" ] && [ "$VALUE_CHROMIUM_VERSION" != "$CURRENT_CHROMIUM_VERSION" ]
then

	rvp_download_and_unpack $VALUE_CHROMIUM_URL $CHROME_LINUX $TEMP_PATH
	echo $VALUE_CHROMIUM_VERSION > $INSTALL_PATH/$TYPE_CHROMIUM".ver"
	upgrade_needed=$VALUE_YES
	rvp_reset_chromium

elif $CLEAR_CACHE
then

	rvp_reset_chromium
else

	echo "Chromium is up to date."
fi

# check for Java upgrade

if [ -n "$VALUE_JAVA_VERSION" ] && [ -n "$VALUE_JAVA_URL" ] && [ "$VALUE_JAVA_VERSION" != "$CURRENT_JAVA_VERSION" ]
then

	rvp_download_and_unpack $VALUE_JAVA_URL $JAVA_LINUX $TEMP_PATH
	echo $VALUE_JAVA_VERSION > $INSTALL_PATH/$TYPE_JAVA".ver"
	upgrade_needed=$VALUE_YES
else

	echo "Java is up to date."
fi

# check for RisePlayer upgrade

if [ -n "$VALUE_RISE_PLAYER_VERSION" ] && [ -n "$VALUE_RISE_PLAYER_URL" ] && [ "$VALUE_RISE_PLAYER_VERSION" != "$CURRENT_RISE_PLAYER_VERSION" ]
then

	rvp_download_and_unpack $VALUE_RISE_PLAYER_URL $RISE_PLAYER_LINUX $TEMP_PATH
	echo $VALUE_RISE_PLAYER_VERSION > $INSTALL_PATH/$TYPE_RISE_PLAYER".ver"
	upgrade_needed=$VALUE_YES
else

	echo "RisePlayer is up to date."
fi

# check for RiseCache upgrade

if [ -n "$VALUE_RISE_CACHE_VERSION" ] && [ -n "$VALUE_RISE_CACHE_URL" ] && [ "$VALUE_RISE_CACHE_VERSION" != "$CURRENT_RISE_CACHE_VERSION" ]
then

	rvp_download_and_unpack $VALUE_RISE_CACHE_URL $RISE_CACHE_LINUX $TEMP_PATH/$RISE_CACHE_LINUX
	echo $VALUE_RISE_CACHE_VERSION > $INSTALL_PATH/$TYPE_RISE_CACHE".ver"
	upgrade_needed=$VALUE_YES
else

	echo "RiseCache is up to date."
fi

# always close Player

	rvp_kill_rise_player
	rvp_kill_chromium
	rvp_kill_rise_cache
	sleep 3

# install upgrades if necessary

if [ $upgrade_needed = $VALUE_YES ] && ([ -d $TEMP_PATH/$CHROME_LINUX ] || [ -d $TEMP_PATH/$JAVA_LINUX ] || [ -f "$TEMP_PATH/$RISE_PLAYER_LINUX.jar" ] || [ -d $TEMP_PATH/$RISE_CACHE_LINUX ])
then 
	
	echo "Installing updates..."

	rvp_install_updates

	echo "Updates installed."
fi

rvp_confirm_add_player_to_autostart

rvp_update_crontab

rvp_start_player

