diskutil mount $(diskutil list|grep EFI|head -n 1|cut -d 'B' -f 2)
