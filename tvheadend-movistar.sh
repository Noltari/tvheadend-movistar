#!/bin/bash

WORK_DIR="$(dirname ${BASH_SOURCE[0]})"
LOG_FILE="$WORK_DIR/log-$(basename ${BASH_SOURCE[0]} .sh).txt"

. $WORK_DIR/tvheadend-movistar-config

log()
{
	echo -e $@ >> $LOG_FILE;
}

print()
{
	echo -e $@;
	log $@;
}

error()
{
	echo -e "Error: $@" 1>&2;
	log "Error: $@";
}

tvheadend_backup()
{
	print "TODO: tvheadend_backup"
}

tvheadend_get_permissions()
{
	for dir in $TVHEADEND_DIR_LIST; do
		local dst_dir="$TVHEADEND_DIR/$dir"

		if [ -d "$dst_dir" ]; then
			TVHEADEND_CFG_USER["$dir"]=$(stat -c %U "$dst_dir")
			TVHEADEND_CFG_GROUP["$dir"]=$(stat -c %G "$dst_dir")
			TVHEADEND_CFG_PERM["$dir"]=$(stat -c %a "$dst_dir")
		else
			TVHEADEND_CFG_USER["$dir"]=$TVHEADEND_USER
			TVHEADEND_CFG_GROUP["$dir"]=$TVHEADEND_GROUP
			TVHEADEND_CFG_PERM["$dir"]=$TVHEADEND_PERM
		fi
	done
}

tvheadend_install()
{
	for dir in $TVHEADEND_DIR_LIST; do
		local src_dir="$FILES_DIR/$dir"
		local dst_dir="$TVHEADEND_DIR/$dir"

		if [ -d "$dst_dir" ]; then
			rm -rf $dst_dir
		fi

		print "Installing TVHeadEnd $dir..."
		cp -r $src_dir $dst_dir

		chown TVHEADEND_CFG_USER["$dir"]:TVHEADEND_CFG_GROUP["$dir"] $dst_dir
		chmod TVHEADEND_CFG_PERM["$dir"] $dst_dir
	done
}

tvheadend_save()
{
	if [ ! -d $TVHEADEND_DIR ]; then
		error "Unable to find TVHeadEnd directory: $TVHEADEND_DIR"
		exit 1
	fi

	if [ ! -d $FILES_DIR ]; then
		print "Creating FILES_DIR=$FILES_DIR"
		mkdir -p $FILES_DIR
	fi

	if [ ! -d $FILES_DIR ]; then
		error "Unable to create FILES_DIR=$FILES_DIR"
		exit 1
	fi

	FILES_USER=$(stat -c %U "${BASH_SOURCE[0]}")
	FILES_GROUP=$(stat -c %G "${BASH_SOURCE[0]}")

	for dir in $TVHEADEND_DIR_LIST; do
		local src_dir="$TVHEADEND_DIR/$dir"
		local dst_dir="$FILES_DIR/$dir"

		if [ -d "$dst_dir" ]; then
			rm -rf $dst_dir
		fi

		print "Saving TVHeadEnd $dir..."
		cp -r $src_dir $dst_dir

		chown $FILES_USER:$FILES_GROUP $dst_dir
		find $dst_dir -type d -exec chmod $FILES_PERM_D {} +
		find $dst_dir -type f -exec chmod $FILES_PERM_F {} +
	done
}

tvheadend_start()
{
	print "Starting TVHeadEnd..."
	systemctl start $TVHEADEND_SERVICE 2>&1 | tee -a $LOG_FILE
}

tvheadend_stop()
{
	print "Stopping TVHeadEnd..."
	systemctl stop $TVHEADEND_SERVICE 2>&1 | tee -a $LOG_FILE
}

backup()
{
	tvheadend_backup
}

help()
{
	print "Usage: $(basename "$0") [OPTION]...\n"
	print "  -b\tCreate a backup with current TVHeadEnd config"
	print "  -h\tPrints helpful information"
	print "  -i\tInstall custom TVHeadEnd config"
	print "  -s\tSave current TVHeadEnd config"
	print ""
}

install()
{
	tvheadend_stop
	tvheadend_get_permissions
	tvheadend_install
	tvheadend_start
}

save()
{
	tvheadend_save
}

main()
{
	local opt_backup=0
	local opt_help=0
	local opt_install=0
	local opt_save=0

	rm -f $LOG_FILE
	touch $LOG_FILE
	chmod 777 $LOG_FILE

	while getopts ":bhis" opt; do
		case $opt in
			b)
				opt_backup=1
				;;
			h)
				opt_help=1
				;;
			i)
				opt_install=1
				;;
			s)
				opt_save=1
				;;
		esac
	done

	if [ $opt_help -ne 0 ]; then
		help
	fi

	if [ $(id -u) -ne 0 ]; then
		error "This script must be run as root\n"
		exit 1
	fi

	if [ $opt_backup -ne 0 ]; then
		backup
	fi

	if [ $opt_install -ne 0 ]; then
		install
	fi

	if [ $opt_save -ne 0 ]; then
		save
	fi
}

main $@
