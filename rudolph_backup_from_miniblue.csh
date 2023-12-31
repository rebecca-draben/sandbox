#!/bin/csh

set backup_reg_files = yes
set backup_camera_others = yes 
set backup_camera_processed = yes
set backup_camera_unprocessed = yes
set backup_this_time_only = no 

set backup_dirs = ""

if ($backup_reg_files == yes) then
   set backup_dirs = ( \
       $backup_dirs \
       MyFiles \
       bin \
   )
endif
if ($backup_camera_others == yes) then
   set backup_dirs = ( \
       $backup_dirs \
       Camera/Others \
   )
endif
if ($backup_camera_processed == yes) then
   set backup_dirs = ( \
       $backup_dirs \
       Camera/Processed \
   )
endif
if ($backup_camera_unprocessed == yes) then
   set backup_dirs = ( \
       $backup_dirs \
       Camera/Unprocessed \
   )
endif
if ($backup_this_time_only == yes) then
   set backup_dirs = ( \
       $backup_dirs \
       foo/bar \
   )
endif

echo ""
echo ""
echo ""
echo "*********************************************************"
zdump EST
echo "*********************************************************"

foreach i_dir ( $backup_dirs ) 
   set source_dir = "/Applications/nobackup/miniblue/$i_dir"
   set dest_dir = "/Volumes/RUDOLPH/backup_miniblue/$i_dir"

   # strip off the last dir in the $dest_dir
   set dest_dir_up1dir = `echo $dest_dir | sed 's/\/[^\/]*$//'`

   echo "---------------------------------------------------------"
   echo "[$i_dir]"
   echo "---------------------------------------------------------"
  
   # -rltDv is equivalent to --archive --verbose 
   # except it doesn't include --owner --group --partial 
   # which I don't care about anyway
   # switched to -rltDv because it works with exfat file systems (like my 64G SD card)
   # http://blog.marcelotmelo.com/linux/ubuntu/rsync-to-an-exfat-partition/
   # added --modify-window=1 because timestamps can be slightly different between mac and FAT32 and 3600 because can be 1 hour different due to DST 
   rsync $* \
       -rltDv \
       --modify-window=3601 \
       --exclude=".DS_Store" \
       "$source_dir" "$dest_dir_up1dir"

end

echo "*********************************************************"
zdump EST
echo "*********************************************************"

