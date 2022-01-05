#!/usr/bin/env bash

# set initial values
skip_intro=false
remove_delay=false
plex_dir=

function usage() {
	echo "Usage: $0 --plex-dir=<plex_base_directory> [--skip-intro] [--remove-delay]"
	echo "Usage: $0 -p <plex_base_directory> [-s] [-r]"
	exit 1
}

function parse_args() {
	# Option strings
	SHORT=p:s,r
	LONG=plex-dir:,skip-intro,remove-delay

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

	client_file=$(du -a "$web_client_path" | sort -hr | sed -n '2{p;q}' | awk '{print $2}')
}

function skip_intro() {
	echo "Adding Auto Skip Intro"
	perl -pi -e 's/onTouchStart:(.*?)}/onTouchStart:\1,onFocus:y}/g' "$client_file"
}

function remove_delay() {
	echo "Removing Autoplay Delay"
	sed -i 's/secondsLeft:10/secondsLeft:0/g' "$client_file"
}

function main() {
	echo "base plex directory: $plex_base_directory"
	echo "skip-intro: $skip_intro"
	echo "remove-delay: $remove_delay"

	if [ -z "$plex_base_directory" ]; then
		echo "Plex directory is required"
		exit 1
	fi

	if [ ! -d "$plex_base_directory" ]; then
		echo "\"$plex_base_directory\" does not exist"
		exit 1
	fi

	get_client_file

	if $skip_intro; then skip_intro; fi
	if $remove_delay; then remove_delay; fi

	echo "Finished"
}

parse_args "$@"
main
