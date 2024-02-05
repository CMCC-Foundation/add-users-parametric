#!/bin/bash
IFS=$'\n'
SEP=';'
SEP_GROUPS=','
SEP_MACHINES=','

parent_folder="cmcc"
pwd_keyword="password"
none_keyword="None" # just like Python
pwd_len=10
docx_filename="CMCC_VPN_account_username_GROUP_script.docx" #"Juno_account_username_DIVISION_script.docx"
in_file="$1"
issuer="$2"
stage_file="$in_file""_stage"

out_dir_name="users_""$(date '+%Y-%m-%d')""_$(od -vAn -N1 -td1 < /dev/urandom | tr '-' ' ' | tr -d ' ')"
mkdir -p "$out_dir_name"

stage_file_loc="$out_dir_name""/""$stage_file"

cnt_file=0

IDMTODB_PROMPT_ON_INSERT=${2:-"1"}
IDMTODB_PROMPT_ON_UPDATE=${3:-"1"}
IDMTODB_PROMPT_ON_DELETE=${4:-"2"} #${3:-"1"} # insert a number > 1 (i.e. 2) in order to permanently disable delete synchronization
IDMTODB_IGNORE_GROUPS=${5:-"0"} #1"} 
IDMTODB_IGNORE_DIVISION_GROUP_NAME=${6:-"0"}
IDMTODB_MAX_USERS=${7:-"1000"}

SCCDB_HOST="sccdb.cmcc.scc"

cat "$in_file" | head -n1 > "$stage_file_loc"

for line in $(tail "$in_file" -n+2); do
  
    echo "*************************************************"
    IFS=' '
    cnt_file=$(($cnt_file+1))
    username=$(echo $line|cut -f1 -d"$SEP")
    first=$(echo $line|cut -f2 -d"$SEP")
    last=$(echo $line|cut -f3 -d"$SEP")

    if [[ -z "$last" ]];
    then
	last="project account"
    fi

    if [[ -z "$username" ]] || [[ "$username" = "None" ]];
    then
    	if [[ "$last" != "project account" ]];
	then
		username=$(echo "${first:0:1}""${last:0:1}""$(date +%j%y)" | tr '[:upper:]' '[:lower:]' )
	elif [[ ! -z "$first" ]];
	then
		username="$first"
	else
		echo "ERROR project account cannot have blank username." >&2
	fi
    fi

    # Not collecting encrypted password because we need cleartext password to create kerberos key
    uid=$(echo $line|cut -f4 -d"$SEP")
    gid=$(echo $line|cut -f5 -d"$SEP")

    no_group_signal=0
    group_names=$(echo $line|cut -f6 -d"$SEP")
    groups=($(echo "$group_names" | tr "$SEP_GROUPS" ' '))

    for group_name in ${groups[@]};
    do

        ipa group-show "$group_name" 1>/dev/null 2>/dev/null
    
        if [[ "$?" == "2" ]];
        then
            echo "ERROR [""$username"", line ""$(($cnt_file+1))""]: The specified group: ""$group_name"" does not exist into IDM groups." >&2
            no_group_signal=1
	    break
            #exit "$?"
        fi

        echo "GROUP_NAME: ""$group_name"

    done

    if [[ "$no_group_signal" -eq 1 ]];
    then
	    continue
    fi

    tmp_exp_date=$(echo $line|cut -f7 -d"$SEP")
    #vpn_exp_date=$(echo $line|cut -f8 -d"$SEP")

    if [[ "$tmp_exp_date" = "None" ]] || [[ "$tmp_exp_date" = "" ]];
    then
        exp_date=""
    else
        exp_date="$tmp_exp_date"'T00:00Z'
    fi

    #echo $exp_date

    email=$(echo $line|cut -f8 -d"$SEP")
    
    name_dot_surname="$(echo "$first" | tr -d ' ' | tr '[:upper:]' '[:lower:]')"".""$(echo "$last" | tr -d ' ' | tr '[:upper:]' '[:lower:]')"

    if [[ -z "$email" ]];
    then
	    email="$name_dot_surname""@cmcc.it"
    fi
    
    shell="/bin/bash"
    gecos=$(echo $first" "$last )
 
    pwd=$(echo $(export AUP_PWD_LEN=$pwd_len; python3 -c 'import os; import random; import string; print("".join(random.choice(string.ascii_lowercase + string.ascii_uppercase + string.digits[1:] + string.digits[1:]) for _ in range(int(os.getenv("AUP_PWD_LEN")))))'))
    
    mach_names=$(echo $line|cut -f9 -d"$SEP")
    machs=($(echo $mach_names | tr "$SEP_MACHINES" ' ')) 
    mach="${machs[0]}"

    notify=$(echo $line| cut -f10 -d"$SEP")
    vpn_notify=$(echo $line| cut -f11 -d"$SEP")

    echo "USERNAME: ""$username"
    echo "FIRST: ""$first"
    echo "LAST: ""$last"
    echo "UID: ""$uid"
    echo "GID: ""$gid"
    #echo "GROUP_NAME: ""$group_name"
    if [[ "$mach" != "" ]]; then
        div="${groups[0]}"
	echo "DIVISION: ""$div"
    fi
    echo "GROUPS: ""$groups"
    echo "CREATION_DATE: ""$creation_date"
    echo "EXPIRATION_DATE: ""$exp_date"
    #echo "VPN_EXPIRATION_DATE: ""$vpn_exp_date"
    echo "EMAIL: ""$email"
    echo "GECOS: ""$gecos"
    echo "PSW: ""$pwd" 
    echo "MACH: ""$mach"
    echo "NOTIFY: ""$notify"
    echo "VPN NOTIFY: ""$vpn_notify"

    ipa user-find --uid="$uid" 1>/dev/null

    if [[ "$?" == "0" ]];
    then
	    echo "Error [""$?""], uid: ""$uid"" already in use!"
	    continue
    fi

     #### BEGIN
    #echo $pwd | ipa user-add $username --first="$first" --last="$last" --password --gidnumber=$gid --uid=$uid --gecos="$gecos" --homedir="/users_home/$div/$username" --shell="$shell" --email=$email --user-auth-type=otp --principal-expiration=$exp_date >> "$out_dir_name"/"$in_file""_logs"
    if [[ "$mach" != "" ]]; then
	echo $pwd | ipa user-add $username --first="$first" --last="$last" --password --gidnumber=$gid --uid=$uid --gecos="$gecos" --homedir="/users_home/$parent_folder/$username" --shell="$shell" --email=$email --user-auth-type=otp --principal-expiration=$exp_date >> "$out_dir_name"/"$in_file""_logs"
    else
        echo $pwd | ipa user-add $username --first="$first" --last="$last" --password --gidnumber=$gid --uid=$uid --gecos="$gecos" --email=$email --user-auth-type=otp --principal-expiration=$exp_date >> "$out_dir_name"/"$in_file""_logs"
    fi
    if (( $? == 0 ));then
        echo "  Password for $username is: $pwd" >> "$out_dir_name"/"$in_file""_logs"
        otptoken_text=$(ipa otptoken-add --type=totp --owner=$username)
        echo "$otptoken_text" >> "$out_dir_name"/"$in_file""_logs"
        otptoken_uri=$(echo "$otptoken_text" | grep URI | sed 's/  URI: //g')
        echo "URI: ""$otptoken_uri"
        qrencode -t PNG -o "$out_dir_name"/"$username"".png" "$otptoken_uri"
        otptoken_secret=$(echo "$otptoken_uri" | cut -d'=' -f3 | cut -d'&' -f1)
        packed_docx_args="$(echo $first | tr ' ' '@') $(echo $last | tr ' ' '@') $username $pwd $otptoken_secret"
        div=${groups[0]}
	docx_filename_out="$out_dir_name"/"CMCC_VPN_account_""$username""_""$(echo $div | tr '[:lower:]' '[:upper:]')"".docx"
        #docx_filename_out="$out_dir_name"/"CMCC_VPN_account_""$username"".docx"
	./find_and_replace_docx.sh "$docx_filename" "$docx_filename_out" '%NAME% %SURNAME% %USERNAME% %PASSWORD% %SECRET%' "$packed_docx_args"
       
	if [[ ! -z "$issuer" ]];
	then
        	scp "$docx_filename_out" "root@""$SCCDB_HOST":"/root/gdrive_API/files/"
		ssh -l root "$SCCDB_HOST" "cd /root/gdrive_API ; ./dexter_fan_in.sh $out_dir_name $docx_filename_out $name_dot_surname $email $issuer $first $username $div $notify $vpn_notify $mach"
	fi

        #ipa otptoken-add --type=totp --owner=sysm07 | grep URI | sed 's/  URI: //g'
    else
        echo "Error [""$?""] while creating the user!"
        continue
    fi
    
    #### END

    #echo $pwd
    #echo $exp_date


    #### BEGIN
    echo "*************************************************" >> "$out_dir_name"/"$in_file""_logs"
    #### END


    for mach in ${machs[@]};
    do
    	if [[ "$mach" != "" ]];
    	then
    		mach_users="$mach""-users"

     		#continue
    		#### PARTE INSERIMENTO GRUPPI
    		ipa group-add-member "$mach_users" --users="$username" 1>/dev/null

    		if [[ "$?" != "0" ]];
    		then
        		echo "ERROR: [""$username"", line ""$(($cnt_file+1))""]: Failed to add ""$username"" user to the \"""$mach_users""\" group." >&2
        		continue
    		fi

    		mach_ext="$mach""-ext"
    		mach_cmcc="$mach""-cmcc"

		group_name="${group_name[1]}"
		division="$div"

    		if [[ "$group_name" != "$mach_ext" ]] && [[ "$division" != "$mach_ext" ]]; # decidere se "mach-ext" sarà indicato su division o group_name
    		then
        		ipa group-add-member "$mach_cmcc" --users="$username" 1>/dev/null
     			if [[ "$?" != "0" ]];
     			then
            			echo "ERROR: [""$username"", line ""$(($cnt_file+1))""]: Failed to add ""$username"" user to the \"""$mach_cmcc""\" group." >&2
            			continue
    			fi
    		else
        		ipa group-add-member "$mach_ext" --users="$username" 1>/dev/null
        		if [[ "$?" != "0" ]];
        		then
            			echo "ERROR: [""$username"", line ""$(($cnt_file+1))""]: Failed to add ""$username"" user to the \"""$mach_ext""\" group." >&2
            			continue
        		fi
    		fi
    	fi
    done

    cnt=0

    for group_name in ${groups[@]};
    do
	cnt=$(($cnt+1))

	if [[ "$group_name" == "$mach""-users" ]] || [[ "$group_name" == "$mach_cmcc" ]];
	then
		continue
	fi

	if [[ "${groups[$cnt]}" != "${groups[$(($cnt-1))]}" ]];
	then
        	ipa group-add-member "$group_name" --users="$username" 1>/dev/null
	fi

        if [[ "$?" != "0" ]];
        then
            echo "ERROR: [""$username"", line ""$(($cnt_file+1))""]: Failed to add ""$username"" user to the \"""$group_name""\" group." >&2 
            continue
	    #exit "$?"
        fi

        echo "GROUP_NAME: ""$group_name"

    done

    ipa group-add-member "registry" --users="$username" 1>/dev/null

    echo "*************************************************"

    if [[ -z "$(echo $group_names | grep registry)" ]];
    then
	    group_names="$group_names"",registry"
    fi

    if [[ -z "$(echo $group_names | grep ipausers)" ]];
    then
    	    group_names="$group_names"",ipausers"
    fi

    curdate="$(date '+%Y-%m-%d')"

    echo "$username""$SEP""$first""$SEP""$last""$SEP""$uid""$SEP""$gid""$SEP""$group_names""$SEP""$curdate""$SEP""$tmp_exp_date""$SEP""$none_keyword""$SEP""$curdate""$SEP"$(if [[ "$notify" -eq 1 ]]; then echo $(date '+%Y-%m-%d'); else echo "$none_keyword"; fi )"$SEP""$email""$SEP""$none_keyword""$SEP""0""$SEP""$pwd_keyword""$SEP""$mach" >> "$stage_file_loc"

done

#mv "$stage_file_loc_2" "$stage_file_loc"

# IDMTODB Consistency
#../idmtodb/idmtodb_launcher_users.sh "$IDMTODB_PROMPT_ON_INSERT" "$IDMTODB_PROMPT_ON_UPDATE" "$IDMTODB_PROMPT_ON_DELETE" "$IDMTODB_IGNORE_GROUPS" "$IDMTODB_IGNORE_DIVISION_GROUP_NAME" "$IDMTODB_MAX_USERS" "$stage_file_loc"
