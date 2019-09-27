#!/bin/bash

WORK_DIR="$(dirname ${BASH_SOURCE[0]})"

. $WORK_DIR/../tvheadend-movistar-config

TMP_LIST=$(mktemp -q)

main()
{
	local imagecache="$TVHEADEND_DIR/imagecache/meta"

	if [ ! -d $imagecache ]; then
		echo "$imagecache doesn't exist"
		exit 1
	fi

	for file in $imagecache/*; do
		local url=$(cat $file | python3 -c "import sys, json; print(json.load(sys.stdin)['url'])")
		local path=${url#"file://"}

		if [ ! -f $path ]; then
			echo "Picon $path not found!"
		fi

		echo $path >> $TMP_LIST
	done

	sort $TMP_LIST | uniq -d -c

	rm -f $TMP_LIST
}

main $@
