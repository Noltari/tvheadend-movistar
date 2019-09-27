#!/bin/bash

WORK_DIR="$(dirname ${BASH_SOURCE[0]})"

. $WORK_DIR/../tvheadend-movistar-config

TMP_LIST=$(mktemp -q)

main()
{
	local tvh_cfg="$TVHEADEND_DIR/config"
	local channel_cfg="$TVHEADEND_DIR/channel/config"

	if [ ! -f $tvh_cfg ]; then
		echo "$tvh_cfg doesn't exist"
		exit 1
	fi

	if [ ! -d $channel_cfg ]; then
		echo "$channel_cfg doesn't exist"
		exit 1
	fi

	local piconpath=$(cat $tvh_cfg | python3 -c "import sys, json; print(json.load(sys.stdin)['piconpath'])")
	local picons=${piconpath#"file://"}

	for file in $channel_cfg/*; do
		local icon=$(cat $file | python3 -c "import sys, json; print(json.load(sys.stdin)['icon'])")
		local path=${icon#"picon://"}

		if [ ! -f $picons/$path ]; then
			echo "Picon $path not found"
		else
			echo $path >> $TMP_LIST
		fi
	done

	sort $TMP_LIST | uniq -d -c

	rm -f $TMP_LIST
}

main $@
