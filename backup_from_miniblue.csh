#!/bin/bash

# exit script upon error
set -e

backup_reg_files="true"
backup_camera_others="true"
backup_camera_processed="true"
backup_camera_unprocessed="true"
backup_this_time_only="false"

backup_dirs=()

if [[ "$backup_reg_files" = "true" ]]; then
    backup_dirs+=( "MyFiles" "bin" )
fi

if [[ "$backup_camera_others" = "true" ]]; then
    backup_dirs+=( "Camera/Others" )
fi

if [[ "$backup_camera_processed" = "true" ]]; then
    backup_dirs+=( "Camera/Processed" )
fi

if [[ "$backup_camera_unprocessed" = "true" ]]; then
    backup_dirs+=( "Camera/Unprocessed" )
fi

if [[ "$backup_this_time_only" = "true" ]]; then
    backup_dirs+=( "foo/bar" )
fi

update_timestamps=0
rsync_args=""

for arg in "$@"; do
    if [[ "$arg" = "--update-timestamps" ]] || [[ "$arg" = "--ut" ]]; then
        update_timestamps=1
    else
        rsync_args+=" $arg"
    fi
done

echo ""
echo ""
echo ""
echo "*********************************************************"
zdump EST
echo "*********************************************************"

for i_dir in "${backup_dirs[@]}"; do
    source_dir="/Applications/nobackup/miniblue/$i_dir"
    dest_dir_rudolph="/Volumes/RUDOLPH/backup_miniblue/$i_dir"
    dest_dir_whistle="/Volumes/WHISTLE/backup_miniblue/$i_dir"
    dest_dir_even="/Volumes/MYFILESEVEN/BackupEvenYears/2022/$i_dir"
    dest_dir_odd="/Volumes/MYFILESODD/BackupOddYears/2023/$i_dir"

    if [ -d "$dest_dir_rudolph" ]; then
        dest_dir="$dest_dir_rudolph"
    elif [ -d "$dest_dir_whistle" ]; then
        dest_dir="$dest_dir_whistle"
    elif [ -d "$dest_dir_even" ]; then
        dest_dir="$dest_dir_even"
    elif [ -d "$dest_dir_odd" ]; then
        dest_dir="$dest_dir_odd"
    else
        echo "Destination not found"
        exit 1
    fi

    # strip off the last dir in the $dest_dir
    dest_dir_up1dir="$(echo "$dest_dir" | sed 's|\/[^\/]*$||')"

    echo "---------------------------------------------------------"
    echo "[$i_dir]"
    echo "---------------------------------------------------------"

    # -rltDv is equivalent to --archive --verbose
    # except it doesn't include --owner --group --partial
    # which I don't care about anyway
    # switched to -rltDv because it works with exfat file systems (like my 64G SD card)
    # added --modify-window=1 because timestamps can be slightly different between mac and FAT32 and 3600 because can be 1 hour different due to DST
    rsync $rsync_args \
        -rltDv \
        --modify-window=3601 \
        --exclude=".DS_Store" \
        --exclude="._*" \
        "$source_dir" "$dest_dir_up1dir"

    # update timestamps
    # for some reason the rsync -t option stopped working when rsyncing to USB drive, so this is workaround
    if [[ $update_timestamps -eq 1 ]]; then
        echo "Update timestamps of files and directories - begin"

        # find source dir files and directories recursively and iterate through them
        # the -r option is used so that backslashes are not treated as escape characters
        find "$source_dir" -type f -or -type d | while read -r source_item; do

            # get path of dest item by replacing the source dir with the dest dir
            dest_item="$(echo "$source_item" | sed "s|$source_dir|$dest_dir|")"

            # update timestamp of destination file to match source file
            touch -c -r "$source_item" "$dest_item"

        done

        echo "Update timestamps of files and directories - end"
    else
        echo "Update timestamps of files and directories - skip"
    fi
done

echo "*********************************************************"
zdump EST
echo "*********************************************************"

