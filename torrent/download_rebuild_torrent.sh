#!/bin/bash

RASPI_TORRENT_SOURCE_PATH="/mnt/rasPiTorrent/torrent"
RASPI_TORRENT_TARGET_PATH="/mnt/rasPiTorrent/torrent/동영상"
RASPI_TORRENT_DROPBOX_PATH="/mnt/rasPiTorrent/torrent/떨굼상자"
MCM_TORRENT_SOURCE_PATH="/Share/rasPiTorrent/torrent"
MCM_TORRENT_TARGET_PATH="/Share/rasPiTorrent/torrent/동영상"
MCM_TORRENT_DROPBOX_PATH="/Share/rasPiTorrent/torrent/떨굼상자"

RASPI_MUSIC_SOURCE_PATH="/mnt/rasPiMusic/torrent"
RASPI_MUSIC_TARGET_PATH="/mnt/rasPiMusic/torrent/동영상"
MCM_MUSIC_SOURCE_PATH="/Share/rasPiMusic/torrent"
MCM_MUSIC_TARGET_PATH="/Share/rasPiMusic/torrent/동영상"

MCM_IMAC_SOURCE_PATH="$HOME/Movies"
MCM_IMAC_TARGET_PATH="$HOME/Movies"

[ "$(hostname -s |cut -c 1-4)" == "iMac" ] && SAY_MODE=ON

function rmdir_sub() {
	if [ -d "$1" ]; then
		cd "$1"
		for FILE in *; do
			if [ -d "$FILE" ] && [ "$(echo ${FILE}|cut -c 1)" != "[" ]; then
				find "$FILE" \( -name ".DS_Store" -or -name ".Parent" -or -name ".AppleDouble" \) -delete
				rmdir "$FILE" 2> /dev/null && echo "-[${FILE}]"
			fi
		done
		cd ..
		rmdir "$1" 2> /dev/null
	fi
}

function mv_file() {
	[ -f "$1" ] && mv "$1" "$2"
}

function cleanup() {
	# cleanup target to source
	SRC_PATH=$1
	if [ "$2" != "" ]; then
		TAR_PATH=$2
	else
		TAR_PATH=$1
	fi

	cd "$TAR_PATH"
	echo "[Cleanup ${TAR_PATH}]"
	[ "$SAY_MODE" == "ON" ] && say "정리"

	# move target to source
	if [ "$(uname)" == "Darwin" ]; then
		find "$TAR_PATH" \( -name "*.mp4" -or -name "*.mkv" -or -name "*.avi" -or -name "*.smi" -or -name "*.sup" \) -print0 | xargs -0 -J % echo "[ -f \"%\" ] && mv \"%\" \"$SRC_PATH\"" | bash
	else
		find "$TAR_PATH" \( -name "*.mp4" -or -name "*.mkv" -or -name "*.avi" -or -name "*.smi" -or -name "*.sup" \) -print0 | xargs -0 -I % echo "[ -f \"%\" ] && mv \"%\" \"$SRC_PATH\"" | bash
	fi

	# cleanup target's sub directories
	for FILE in *; do
		if [ -d "$FILE" ] && [ "$(echo ${FILE}|cut -c 1)" != "[" ]; then
			find "$FILE" \( -name ".DS_Store" -or -name ".Parent" -or -name ".AppleDouble" \) -delete
			rmdir "$FILE" 2> /dev/null && echo "-[${FILE}]" || rmdir_sub "$FILE"
		fi
	done

	echo
}

function get_target_name() {
	GET_TARGET_NAME=$(echo -n "$@"|sed -e 's/[[:space:]]*\[.*\][[:space:]]*//' -e 's/[[:space:]]*\「.*\」[[:space:]]*//' -e 's/[[:space:]]*\\(.*\\)[[:space:]]*//')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/....[pP]-[nN][eE][xX][tT]//' -e 's/....[pP]-[wW][iI][tT][hH]//' -e 's/....[pP]-[cC][iI][nN][eE][bB][uU][sS]//')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/\.[aA][aA][cC]//' -e 's/\.[hH][dD][tT][vV]//' -e 's/\.[hH]26[45]//' -e 's/\.[eE][nN][dD]//')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/\.[hH][eE][vV][cC]//' -e 's/\.10[bB][iI][tT]//' -e 's/\.[xX]26[45]//' -e 's/\.[bB][lL][uU][rR][aA][yY]//')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/\.[wW][eE][bB]-[dD][lL]//' -e 's/\.5\.1//' -e 's/\.[xX]26[45]//' -e 's/\.[bB][lL][uU][rR][aA][yY]//')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/\.\.\./\./' -e 's/\.\./\./' -e 's/알\.쓸\.신\./알쓸신/' -e 's/AMZN//' -e 's/Game.of.Thrones/Game of Thrones/')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/ .부\././' -e 's/\.[wW][eE][bB][rR][iI][pP]//')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/\.1440[pP]//' -e 's/\.1080[pP]//' -e 's/\.720[pP]//' -e 's/\.360[pP]//')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/\(^[0-9]*\)\.\([^\.]*\.\)/\2\1./')
	#GET_TARGET_NAME=$(echo -n "${GET_TARGET_NAME}" | sed -e 's/-.*\././')
	echo -n "$GET_TARGET_NAME"|sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/[[:space:]]*\.E/\.E/'
}

function get_target_path_name() {
	echo $@ | cut -d . -f 1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/[[:space:]]*스페셜$//'
}

function rebuild_mp4_catagory() {
	SRC_PATH=$1
	if [ "${2}" != "" ]; then
		TAR_PATH=$2
	else
		TAR_PATH=$1
	fi

	cd ${SRC_PATH}
	echo "[Rebuild ${SRC_PATH}]"
	[ "${SAY_MODE}" == "ON" ] && say "재생성"

	for FILE in *.{mp4,mkv,avi,smi,sup}; do
		if [ -f "$FILE" ] && [ "$FILE" != "*.mp4" ] && [ "$FILE" != "*.mkv" ] && [ "$FILE" != "*.avi" ] && [ "$FILE" != "*.smi" ] && [ "$FILE" != "*.sup" ]; then
			TARGET_NAME=$(get_target_name "$FILE")
			DIR_NAME="$TAR_PATH"/$(get_target_path_name "$TARGET_NAME")
			if [ ! -d "$DIR_NAME" ]; then
				echo "+[${DIR_NAME}]"
				mkdir -p "$DIR_NAME"
			fi
			mv "${SRC_PATH}/$FILE" "${DIR_NAME}/$TARGET_NAME" 2> /dev/null
		fi
	done
	echo
}

function rebuild_raspi_music() {
	echo "[Rebuild `hostname -s`]"
	case "${1}" in
	c*)
		cleanup ${RASPI_MUSIC_SOURCE_PATH} ${RASPI_MUSIC_TARGET_PATH}
		rebuild_mp4_catagory ${RASPI_MUSIC_SOURCE_PATH} ${RASPI_MUSIC_TARGET_PATH}
	;;
	*)
		rebuild_mp4_catagory ${RASPI_MUSIC_SOURCE_PATH} ${RASPI_MUSIC_TARGET_PATH}
	;;
	esac
}

function rebuild_raspi_dropbox() {
	echo "[Rebuild `hostname -s`: dropbox]"
	cleanup "$RASPI_TORRENT_DROPBOX_PATH" "$RASPI_TORRENT_DROBOX_PATH"
	rebuild_mp4_catagory "$RASPI_TORRENT_DROPBOX_PATH" "$RASPI_TORRENT_TARGET_PATH"
}

function rebuild_raspi_torrent() {
	echo "[Rebuild `hostname -s`: torrent]"
	case "$1" in
	c*)
		cleanup "$RASPI_TORRENT_SOURCE_PATH" "$RASPI_TORRENT_TARGET_PATH"
		rebuild_mp4_catagory "$RASPI_TORRENT_SOURCE_PATH" "$RASPI_TORRENT_TARGET_PATH"
	;;
	*)
		rebuild_mp4_catagory "$RASPI_TORRENT_SOURCE_PATH" "$RASPI_TORRENT_TARGET_PATH"
	;;
	esac
}

function rebuild_mcm_dropbox() {
	echo "[Rebuild `hostname -s`: dropbox]"
	cleanup "$MCM_TORRENT_DROPBOX_PATH" "$MCM_TORRENT_DROBOX_PATH"
	rebuild_mp4_catagory "$MCM_TORRENT_DROPBOX_PATH" "$MCM_TORRENT_TARGET_PATH"
}

function rebuild_mcm_imac() {
	echo "[Rebuild `hostname -s`]"
	case "${1}" in
	r1c*)
			cleanup "$MCM_MUSIC_SOURCE_PATH" "$MCM_MUSIC_TARGET_PATH"
			rebuild_mp4_catagory "$MCM_MUSIC_SOURCE_PATH" "$MCM_MUSIC_TARGET_PATH"

			cleanup "$MCM_TORRENT_SOURCE_PATH" "$MCM_TORRENT_TARGET_PATH"
			rebuild_mp4_catagory "$MCM_TORRENT_SOURCE_PATH" "$MCM_TORRENT_TARGET_PATH"
	;;
	r1)
			rebuild_mp4_catagory "$MCM_MUSIC_SOURCE_PATH" "$MCM_MUSIC_TARGET_PATH"
			rebuild_mp4_catagory "$MCM_TORRENT_SOURCE_PATH" "$MCM_TORRENT_TARGET_PATH"
	;;

	c*)
			cleanup "$MCM_IMAC_SOURCE_PATH" "$MCM_IMAC_TARGET_PATH"
			rebuild_mp4_catagory "$MCM_IMAC_SOURCE_PATH" "$MCM_IMAC_TARGET_PATH"
	;;
	*)
			rebuild_mp4_catagory "$MCM_IMAC_SOURCE_PATH" "$MCM_IMAC_TARGET_PATH"
	;;
	esac
}

HOSTNAME=$(hostname -s | cut -c 1-3)
if [ "${HOSTNAME}" == "ras" ]; then
	#[ "$(basename $0 | cut -d_ -f 1)" == "local" ] && rebuild_raspi_music $@ || rebuild_raspi_torrent $@
	#rebuild_raspi_music $@
	rebuild_raspi_torrent $@
	rebuild_raspi_dropbox
else
	rebuild_mcm_imac $@
	rebuild_mcm_dropbox
fi
