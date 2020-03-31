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

	for file in $channel_cfg/*; do
		local number=$(cat $file | python3 -c "import sys, json; print(json.load(sys.stdin)['number'])")

		echo $number >> $TMP_LIST
	done

	sort $TMP_LIST | uniq -d -c

	rm -f $TMP_LIST
}

main $@
