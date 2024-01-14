#!/bin/bash

USERSIDM_SERVER=${8:-"127.0.0.1"}
USERSIDM_USER=${9:-"root"}
USERSIDM_PASSWORD="root" #"root"
USERSIDM_DATABASE="idmdb"

issuer="$1"

if [[ -z "$issuer" ]];
then
        echo "ERROR: Invalid issuer name. Cannot proceed to send mail to the user." >&2
        exit 1
fi

name="$2"

if [[ -z "$name" ]];
then
	echo "ERROR: Invalid name. Cannot proceed to send mail to the user." >&2
	exit 1
fi

username="$3"

if [[ -z "$username" ]];
then
	echo "ERROR: Invalid username. Cannot proceed to send mail to the user." >&2
	exit 1
fi

email="$4"

if [[ -z "$email" ]];
then
	echo "ERROR: Invalid email. Cannot proceed to send mail to the user." >&2
fi

division="$5"

if [[ -z "$division" ]];
then
	echo "ERROR: Invalid division. Cannot determine director division to be added in Cc." >&2
	echo "Cannot proceed to send mail to the user." >&2
	exit 1
fi

division_director_mail=$(mysql "$USERSIDM_DATABASE" --raw -h "$USERSIDM_SERVER" -u "$USERSIDM_USER" -p"$USERSIDM_PASSWORD" <<<$(echo "SELECT select_division_director_mail(\"""$(echo $division | tr '[:upper:]' '[:lower:]')""\");"))

if [[ -z "$division_director_mail" ]];
then
	echo "ERROR: Invalid division_director_mail." >&2
	echo "Cannot fetch director division mail field from the $USERSIDM_USER@$USERSIDM_SERVER:$USERSIDM_DATABASE.idmdb server:db.table." >&2
        echo "Cannot proceed to send mail to the user." >&2
        exit 1
fi

is_cmcc=$(if [[ $(echo "$email" | cut -d'@' -f2) == "cmcc.it" ]]; then echo "true" else "false"; fi)

if [[ "$is_cmcc" ]];
then
	link="$6"

	if [[ -z "$link" ]];
	then
		echo "ERROR: Invalid link. If the user has a CMCC mail, the Google Drive shared folder link has to be provided." >&2
		echo "Cannot proceed to send mail to the user." >&2
		exit 1
	fi
else
	pdf_file="$6"

	if [[ -z "$pdf_file" ]];
        then
                echo "ERROR: Invalid PDF file path. If the user has not a CMCC mail, the PDF file path has to be provided." >&2
                echo "Cannot proceed to send mail to the user." >&2
                exit 1
        fi
fi

MAIL_CMD=${8:-"/usr/sbin/sendmail"}
#it doesn't work with the current SMTP relay
MAIL_FROM=${9:-"hsm@cmcc.it"} #"marco_chiarelli@yahoo.it"} #"marcochiarelli.nextgenlab@gmail.com"} #"monitoring-scc@cmcc.it"}
HSM_MAIL_CC=${10:-"hsm@cmcc.it"}

mach="$7"

if [[ -z "$mach" ]];
then
	smg_mail="smg@cmcc.it"
	vpn_user_guides_link="https://drive.google.com/drive/folders/1JRYv7nX2fW94hVr8SWal27aGl80GPF1o"
        #echo "ERROR: Invalid machine. Cannot proceed to send mail to the user." >&2
        #exit 1
	(
                echo "Subject: Notifica attivazione account VPN CMCC";
                echo "From: $MAIL_FROM";
                echo "To: $email";
                #echo "Cc: $smg_mail, $HSM_MAIL_CC";
		#echo "Cc: $HSM_MAIL_CC";
                #echo "Mime-Version: 1.0";
                echo "Content-Type: multipart/related; boundary=\"boundary-example\"; type=\"text/html\"";
                echo "";
                echo "--boundary-example";
                echo "Content-Type: text/html; charset=ISO-8859-15";
                echo "Content-Transfer-Encoding: 7bit";
                echo ""; 
                echo -e "<html><body>work in progress waiting for ITA-EN translation</body></html>";
	) | "$MAIL_CMD" -t "$email"
else
	#mach_lower="$(echo ${mach:0:1} | tr '[:lower:]' '[:upper:]')""$(echo ${mach:1:${#mach}})"
	mach_upper="$(echo $mach | tr '[:lower:]' '[:upper:]')"
	mach_user_guides_link="https://drive.google.com/drive/folders/1a0MCtDAHjH7gGh9GPLuyVevD8wMLQiGg"
	(
		echo "Subject: $mach_upper account activation notification (username $username)";
       		echo "From: $MAIL_FROM";
       		echo "To: $email";
		#echo "Cc: marco_chiarelli@yahoo.it";
		#echo "Cc: $division_director_mail, $HSM_MAIL_CC";
		#echo "Cc: $HSM_MAIL_CC";
		echo "Mime-Version: 1.0";
       		echo "Content-Type: multipart/related; boundary=\"boundary-example\"; type=\"text/html\"";
       		echo "";
       		echo "--boundary-example";
       		echo "Content-Type: text/html; charset=ISO-8859-15";
       		echo "Content-Transfer-Encoding: 7bit";
       		echo "";
		if [[ "$is_cmcc" ]]; #[[ "$is_cmcc" ]];
		then 
			echo -e "<html><body>Dear $name,<br><br>you have been issued an account (username $username) in order to access the $mach_upper supercomputer.<br><br>In order to access $mach_upper, you will need to download your credentials from the following link:<br><br><a href=\"$link\">$link</a><br><br>N.B.: you must use your CMCC mail account in order to access the shared folders.<br><br>$mach_upper User Guides are available at this link:<br><br><a href=\"$mach_user_guides_link\">$mach_user_guides_link</a><br><br>Instructions for accessing $mach_upper are available in the '$mach_upper Getting Started' guide.<br><br>Best Regards,<br>$issuer<br>HSM Staff<br><br><br></body></html>";
		else
			pdf_file_tag="CMCC_VPN_account_""$username""_""$(echo $division | tr '[:lower:]' '[:upper:]')"
			echo -e "<html><body>Dear $name,<br><br>you have been issued an account (username $username) in order to access the $mach_upper supercomputer.<br><br>Your account information is available in the pdf file in attachment.<br><br>$mach_upper User Guides are available at this link:<br><br><a href=\"$mach_user_guides_link\">$mach_user_guides_link</a><br><br>Instructions for accessing $mach_upper are available in the '$mach_upper Getting Started' guide.<br><br>Best Regards,<br>$issuer<br>HSM Staff<br><br><br></body></html>";
			echo "--boundary-example";
			echo "Content-Type: application/pdf;name=\"""$pdf_file_tag"".pdf\"";
			echo "Content-Transfer-Encoding: BASE64";
			echo "Content-ID: <""$pdf_file_tag"">";
			echo "Content-Disposition: inline;"
			echo "";
			base64 "$pdf_file"
			echo "--boundary-example";
			echo "";
			echo "";
		fi
	) | "$MAIL_CMD" -t "$email"
fi
