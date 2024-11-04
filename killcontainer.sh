for m in $(mount | grep containers | awk '{print $3}'); do umount -f $m; done

