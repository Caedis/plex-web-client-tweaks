#!/usr/bin/env bash

# set initial values
skip_intro=false
remove_delay=false
restore=false
plex_base_directory=
original_file=

function usage() {
	echo "Usage: $0 --plex-dir=<plex_base_directory> [--skip-intro] [--remove-delay]"
	echo "Usage: $0 -p <plex_base_directory> [-s] [-r]"
	exit 1
}

function parse_args() {
	# Option strings
	SHORT=p:s,r
	LONG=plex-dir:,skip-intro,remove-delay,restore

	# read the options
	if ! OPTS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@"); then
		usage
	fi

	eval set -- "$OPTS"

	# extract options and their arguments into variables.
	while true; do
		case "$1" in
		-p | --plex-dir)
			plex_base_directory="$2"
			shift 2
			;;
		-s | --skip-intro)
			skip_intro=true
			shift
			;;
		-r | --remove-delay)
			remove_delay=true
			shift
			;;
		--restore)
			restore=true
			shift
			;;
		--)
			shift
			break
			;;
		*)
			echo "Internal error"
			exit 1
			;;
		esac
	done

}

client_file=
function get_client_file() {
	local web_client_path
	web_client_path="$(find "$plex_base_directory" -name WebClient.bundle)/Contents/Resources/js"
	client_file=$(find "$web_client_path" -name "main*.js")
}

function skip_intro() {
	echo "Adding Auto Skip Intro"
	sed -i 's/autoFocus:"autofocus",/autoFocus:"autofocus",onFocus:y,/g' "$client_file"
}

function remove_delay() {
	echo "Removing Autoplay Delay"
	sed -i 's/secondsLeft:10/secondsLeft:0/g' "$client_file"
}

function backup_original() {
	echo "Backing up original"
	cp "$client_file" "$client_file.bak"
}

function restore_original() {
	if [ ! -f "$original_file" ]; then
		echo "No original file found"
		return
	fi

	echo "Restoring original file"
	cp "$original_file" "$client_file"
	rm "$original_file"
}

function main() {
	if [ -z "$plex_base_directory" ]; then
		echo "Plex directory is required"
		usage
	fi

	if [ ! -d "$plex_base_directory" ]; then
		echo "\"$plex_base_directory\" does not exist"
		exit 1
	fi

	get_client_file
	original_file="$client_file.bak"
	if $restore; then
		restore_original
	else
		# backup the original if it is not found (script has not been ran)
		if [ ! -f "$original_file" ]; then backup_original; fi

		if $skip_intro; then skip_intro; fi
		if $remove_delay; then remove_delay; fi
	fi

	echo "Finished"
}

parse_args "$@"
main
