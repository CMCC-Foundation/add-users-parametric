#!/bin/bash
IFS=$'\n'
SEP=';'
SEP_GROUPS=','

date_keyword="date"
pwd_keyword="password"
pwd_len=10
docx_filename="CMCC_VPN_account_username_GROUP_script.docx" #"Juno_account_username_DIVISION_script.docx"
in_file="$1"
stage_file="$in_file""_stage"

out_dir_name="users_""$(date '+%Y-%m-%d')""_$(od -vAn -N1 -td1 < /dev/urandom | tr '-' ' ' | tr -d ' ')"
mkdir -p "$out_dir_name"

stage_file_loc="$out_dir_name""/""$stage_file"

#sed -i "s/,$date_keyword,/,$(date '+%Y-%m-%d'),/g" "$in_file"
sed "s/;$date_keyword;/;$(date '+%Y-%m-%d');/g" "$in_file" > "$stage_file_loc"
sed -i "s/;;;;/;$(date '+%Y-%m-%d');None;None;/g" "$stage_file_loc"
sed -i "s/;;;/;None;None;/g" "$stage_file_loc"
sed -i "s/;;/;None;/g" "$stage_file_loc"

cnt_file=0

IDMTODB_PROMPT_ON_INSERT=${2:-"1"}
IDMTODB_PROMPT_ON_UPDATE=${3:-"1"}
IDMTODB_PROMPT_ON_DELETE=${4:-"2"} #${3:-"1"} # insert a number > 1 (i.e. 2) in order to permanently disable delete synchronization
IDMTODB_IGNORE_GROUPS=${5:-"0"} #1"} 
IDMTODB_MAX_USERS=${6:-"1000"}

for line in $(tail "$stage_file_loc" -n+2); do
    
    echo "*************************************************"
    IFS=' '
    cnt_file=$(($cnt_file+1))
    username=$(echo $line|cut -f1 -d"$SEP")
    first=$(echo $line|cut -f2 -d"$SEP")
    last=$(echo $line|cut -f3 -d"$SEP")
    # Not collecting encrypted password because we need cleartext password to create kerberos key
    uid=$(echo $line|cut -f4 -d"$SEP")
    gid=$(echo $line|cut -f5 -d"$SEP")

    no_group_signal=0
    groups=($(echo $line|cut -f6 -d"$SEP" | tr "$SEP_GROUPS" ' '))

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

    creation_date=$(echo $line |cut -f7 -d"$SEP")

    if [[ "$creation_date" = "None" ]] || [[ "$creation_date" = "" ]];then
        creation_date=$(date '+%Y-%m-%d')
    fi

    tmp_expdate=$(echo $line|cut -f8 -d"$SEP")
    vpn_tmp_expdate=$(echo $line|cut -f9 -d"$SEP")

    if [[ "$tmp_expdate" = "None" ]] || [[ "$tmp_expdate" = "" ]];then
        expdate=""
    else
        expdate=$(echo $line|cut -f8 -d"$SEP")'T00:00Z'
    fi

    #echo $expdate

    email=$(echo $line|cut -f10 -d"$SEP")
    shell="/bin/bash"
    gecos=$(echo $first" "$last )

    pwd_tmp=$(echo $line|cut -f12 -d"$SEP")
    pwd=$(if [[ "$pwd_tmp" == "$pwd_keyword" ]]; then echo $(export AUP_PWD_LEN=$pwd_len; python3 -c 'import os; import random; import string; print("".join(random.choice(string.ascii_lowercase + string.ascii_uppercase + string.digits[1:] + string.digits[1:]) for _ in range(int(os.getenv("AUP_PWD_LEN")))))'); else echo "$pwd_tmp"; fi)
    #echo "PWD is: ""$pwd"
    #continue
    #exit
    
    
    mach=$(echo $line|cut -f13 -d"$SEP")

    #first=$(echo $gecos| cut -d' ' -f1 )
    #last=$(echo $gecos| cut -d' ' -f 2- )

    #pass=$( tr -cd '[:alnum:]' < /dev/urandom | fold -w8| head -1 )

    # Now create this entry

    #echo "ipa user-add $username --first=$first --last=$last --gidnumber=$gid --uid=$uid --gecos=\"$gecos\" --homedir=\"/users_home/$div/$username\" --shell=$shell --email=$email --user-auth-type=otp --random --principal-expiration=$expdate"
    #echo "ipa otptoken-add --type=totp --owner=$username"

    #echo $uid, $gid, $first, $last, $div, $email, $expadate

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
    echo "EXPIRATION_DATE: ""$tmp_expdate"
    echo "VPN_EXPIRATION_DATE: ""$vpn_tmp_expdate"
    echo "EMAIL: ""$email"
    echo "GECOS: ""$gecos"
    echo "PSW: ""$pwd" 
    echo "MACH: ""$mach"

    #echo "PASS PRE"
    
    #if [[ "$group_name" != "$div" ]];
    #then
    #    ipa group-add-member "$group_name" --users="$username" 1>/dev/null
    #
    #    if [[ "$?" != "0" ]];
    #    then
    #        echo "ERROR: [""$username"", line ""$(($cnt_file+1))""]: Failed to add ""$username"" user to the \"""$group_name""\" group." >&2
    #        continue
    #    fi
    #fi

    #echo "PASS POST"
    #continue

    ipa user-find --uid="$uid" 1>/dev/null

    if [[ "$?" == "0" ]];
    then
	    echo "Error [""$?""], uid: ""$uid"" already in use!"
	    continue
    fi

     #### BEGIN
    #echo $pwd | ipa user-add $username --first="$first" --last="$last" --password --gidnumber=$gid --uid=$uid --gecos="$gecos" --homedir="/users_home/$div/$username" --shell="$shell" --email=$email --user-auth-type=otp --principal-expiration=$expdate >> "$out_dir_name"/"$in_file""_logs"
    if [[ "$mach" != "" ]]; then
	echo $pwd | ipa user-add $username --first="$first" --last="$last" --password --gidnumber=$gid --uid=$uid --gecos="$gecos" --homedir="/users_home/$div/$username" --shell="$shell" --email=$email --user-auth-type=otp --principal-expiration=$expdate >> "$out_dir_name"/"$in_file""_logs"
    else
        echo $pwd | ipa user-add $username --first="$first" --last="$last" --password --gidnumber=$gid --uid=$uid --gecos="$gecos" --email=$email --user-auth-type=otp --principal-expiration=$expdate >> "$out_dir_name"/"$in_file""_logs"
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
        #ipa otptoken-add --type=totp --owner=sysm07 | grep URI | sed 's/  URI: //g'
    else
        echo "Error [""$?""] while creating the user!"
        continue
    fi
    #### END

    #echo $pwd
    #echo $expdate

    #### BEGIN
    echo "*************************************************" >> "$out_dir_name"/"$in_file""_logs"
    #### END


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

    cnt=0

    for group_name in ${groups[@]};
    do
	cnt=$(($cnt+1))
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

    #ipa group-add-member "$div" --users="$username" 1>/dev/null

    #if [[ "$?" != "0" ]];
    #then
    #    echo "ERROR: [""$username"", line ""$(($cnt_file+1))""]: Failed to add ""$username"" user to the \"""$div""\" group." >&2
    #    continue
    #fi

    #if [[ "$group_name" != "$div" ]];
    #then
    #    ipa group-add-member "$group_name" --users="$username" 1>/dev/null

    #    if [[ "$?" != "0" ]];
    #    then
    #        echo "ERROR: [""$username"", line ""$(($cnt_file+1))""]: Failed to add ""$username"" user to the \"""$group_name""\" group." >&2
    #        continue
    #    fi
    #fi

    ####

    echo "*************************************************"
	#ipa user-show $username
	#cnt_file=$(($cnt_file+1))
done

# IDMTODB Consistency
../idmtodb/idmtodb_launcher_ignore_groups.sh "$IDMTODB_PROMPT_ON_INSERT" "$IDMTODB_PROMPT_ON_UPDATE" "$IDMTODB_PROMPT_ON_DELETE" "$IDMTODB_IGNORE_GROUPS" "$IDMTODB_MAX_USERS" "$stage_file_loc"
