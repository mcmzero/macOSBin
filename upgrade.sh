diskutil mount $(diskutil list|grep EFI|head -n 1|cut -d 'B' -f 2)
audio_cloverALC-130_v0.3.command << __EOF__
y
y
y
__EOF__
apfs_efi.sh
