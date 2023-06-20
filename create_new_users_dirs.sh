#!/bin/bash

for i in $(tail -n+2 "$1" | cut -d',' -f1,7);
do
        echo "################################################"
        this_user=$(echo "$i" | cut -d',' -f1)
        this_div=$(echo "$i" | cut -d',' -f2)
        echo "This user: ""$this_user"", div: ""$this_div"
        #su - "$this_user" -c "exit" # decomment this in order to create /users_home/division/user
        ls -lah "/users_home/""$this_div""/""$this_user"
        echo "Back to parent shell."
        work_dir="/work/""$this_div""/""$this_user"
        echo "Creating /work dir: ""$work_dir"
        mkdir -p "$work_dir"
        echo "Setting UNIX ownerships.."
        chown "$this_user":"$this_div" "$work_dir"
        echo "Done."
        echo "Setting UNIX permissions.."
        chmod 750 "$work_dir"
        ls -lah "$work_dir"
        echo "Done."
        data_dir="/data/""$this_div""/""$this_user"
        echo "Creating /data dir: ""$work_dir"
        mkdir -p "$data_dir"
        echo "Setting UNIX ownerships.."
        chown "$this_user":"$this_div" "$data_dir"
        echo "Done."
        echo "Setting UNIX permissions.."
        chmod 700 "$data_dir"
        ls -lah "$data_dir"
        echo "Done."
        echo "################################################"
done
