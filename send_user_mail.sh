#!/bin/bash

CC_DIVISIONS_DIRECTORS=${14:-"0"}
SEND_TO_REAL_EMAIL=${15:-"0"} #"1"}
DEBUG_MODE=${16:-"0"} #"1"}
USERSIDM_SERVER=${17:-"127.0.0.1"}
USERSIDM_USER=${18:-"root"}
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

mail_domain="$(echo "$email" | cut -d'@' -f2 | cut -d'.' -f1)"
is_cmcc=$(if [[ "$mail_domain" == "cmcc" ]] || [[ "$mail_domain" == "gmail" ]]; then echo "true"; elif [[ "$mail_domain" == "eiee" ]]; then echo "true"; else "false"; fi)

link="$6"

if [[ -z "$link" ]];
then
	echo "ERROR: Invalid link. The Google Drive shared folder link has to be provided in any case (both CMCC/Gmail mail or external)." >&2
	echo "Cannot proceed to send mail to the user." >&2
	exit 1
fi

pdf_file="$7"

if [[ ! "$is_cmcc" ]] && [[ -z "$pdf_file" ]];
then
       	echo "ERROR: Invalid PDF file path. If the user has not a CMCC/Gmail mail, the PDF file path has to be provided." >&2
	echo "Cannot proceed to send mail to the user." >&2
        exit 1
fi

HSM_MAIL="hsm@cmcc.it"
DEBUG_MAIL="marco_chiarelli@yahoo.it" #"marcochiarelli.nextgenlab@gmail.com"
MAIL_CMD=${11:-"/usr/sbin/sendmail"}
#it doesn't work with the current SMTP relay
MAIL_FROM=${12:-"$HSM_MAIL"} #"marco_chiarelli@yahoo.it"} #"marcochiarelli.nextgenlab@gmail.com"} #"monitoring-scc@cmcc.it"}
#HSM_MAIL_CC=${12:-"$HSM_MAIL"}

mach="${10}"
notify="$8"
vpn_notification="$9"

if [[ "$SEND_TO_REAL_EMAIL" -eq 0 ]];
then
	if [[ "$DEBUG_MODE" -eq 0 ]];
	then
		email="$HSM_MAIL" #"marco_chiarelli@yahoo.it"
		HSM_MAIL_CC=${13:-"$HSM_MAIL"}
	else
		email="$DEBUG_MAIL"
		HSM_MAIL_CC=${13:-"$DEBUG_MAIL"}
	fi
fi

if [[ -z "$mach" ]];
then
	if [[ "$notify" -eq 1 ]];
	then
		smg_mail="smg@cmcc.it"
		vpn_user_guides_link="https://drive.google.com/drive/folders/1JRYv7nX2fW94hVr8SWal27aGl80GPF1o"
        	#echo "ERROR: Invalid machine. Cannot proceed to send mail to the user." >&2
        	#exit 1
		(
                	echo "Subject: Notifica attivazione account VPN CMCC";
                	echo "From: $MAIL_FROM";
                	echo "To: $email";
			#if [[ "$CC_DIVISIONS_DIRECTORS" -ne 0 ]];
			#then
                		echo "Cc: $smg_mail, $HSM_MAIL_CC";
			#fi
			#echo "Cc: $HSM_MAIL_CC";
                	
			#echo "Mime-Version: 1.0";
                	echo "Content-Type: multipart/related; boundary=\"boundary-example\"; type=\"text/html\"";
                	echo "";
                	echo "--boundary-example";
                	echo "Content-Type: text/html; charset=utf-8"; #ISO-8859-15";
                	echo "Content-Transfer-Encoding: 7bit";
                	echo ""; 
			echo -e "<html><body>Car$(echo ${name:$((${#name}-1)):${#name}}) $name,<br><br>Ti informo che abbiamo attivato il tuo account per accedere al servizio <b>VPN</b> del CMCC.<br><br>Tale servizio ti consentirà di accedere all’applicazione SAP da qualsiasi luogo di lavoro (in sede o fuori sede in smart-working o missione).<br><br>";
	        	echo -e "<b>N.B. per gli utenti della sede di Lecce</b><br>l'accesso alla VPN è consentito solo tramite la Wi-Fi “CMCC” (n.b. la rete wi-fi “CMCC-Guest” <u>non è abilitata</u> per accedere a SAP).<br><br>";
			echo -e "Per accedere al servizio VPN, è necessario installare sul tuo computer un client VPN (client VPN Forcepoint) e disporre delle tue credenziali personali.<br><br>";
			echo "Per scaricare il file PDF con le tue credenziali personali, accedi alla seguente cartella <u>personale</u> (per l’accesso devi usare le credenziali mail CMCC):<br><br><a href=\"$link\">$link</a><br><br>";
			echo "Le istruzioni per installare e configurare il client VPN sono disponibili nella cartella condivisa al seguente link:<br><br><a href=\"$vpn_user_guides_link\">$vpn_user_guides_link</a><br><br>";
			echo "Per qualsiasi problema di connettività al servizio VPN, contatta <a href=\"mailto:$HSM_MAIL_CC\">$HSM_MAIL_CC</a><br><br>Un caro saluto,<br>$issuer<br>HSM Team<br><br><br></body></html>";
		) | "$MAIL_CMD" -t "$email"
	fi
else

	if [[ "$vpn_notification" -ne 0 ]];
	then
		vpn_user_guides_link="https://drive.google.com/drive/folders/1JRYv7nX2fW94hVr8SWal27aGl80GPF1o"
		(
               		echo "Subject: New CMCC VPN service announcement and account activation notification";
                	echo "From: $MAIL_FROM";
                	echo "To: $email";
                	if [[ "$CC_DIVISIONS_DIRECTORS" -ne 0 ]];
                	then
                        	echo "Cc: $division_director_mail, $HSM_MAIL_CC";
                	fi
                	echo "Cc: $HSM_MAIL_CC";
                	#echo "Mime-Version: 1.0";
                	echo "Content-Type: multipart/related; boundary=\"boundary-example\"; type=\"text/html\"";
                	echo "";
                	echo "--boundary-example";
                	echo "Content-Type: text/html; charset=utf-8"; #ISO-8859-15";
                	echo "Content-Transfer-Encoding: 7bit";
                	echo "";
			if [[ "$vpn_notification" -ne 1 ]];
			then
                		echo -e "<html><body>Dear $name,<br><br>We are glad to inform you that there is a <b>new VPN service available at CMCC</b>. This service will replace the old one that will soon be discontinued.<br><br>In order to grant you access to the new VPN service, you should follow the steps below:<br><br>";
                		echo -e "1) Install and configure the Forcepoint VPN client on your computer, you may follow the guide available at the following link:<br><br><a href=\"$vpn_user_guides_link\">$vpn_user_guides_link</a><br><br>2) Once you have completed the installation of the VPN client, you will be able to activate a VPN connection using your <b>personal credentials</b>:<br><br>";
				echo -e "<a href=\"""$link""\">""$link""</a><br><br>";
                		echo -e "<b>IMPORTANT:</b><br>With the new Identity Management system (IdM) running at SCC, users credentials are centrally managed. <br>IdM allows users to access many different services and hosts using the same credentials.<br>For this reason, to access the new VPN service, <b>you must provide the same credentials that you are using for your IDM account (password+OTP)</b>.<br><br>";
                		echo -e "N.B.<br>1) With the new VPN service, <u>you will be able to login on ZEUS but, in this case, you must use your ZEUS credentials</u> (the new IDM is not connected with ZEUS and therefore ZEUS credentials are not centrally managed).<br><br>";
				echo -e "2) Don’t forget to close the old VPN client (OpenVPN) before using the new one.<br><br>";
				echo -e "Contact <a href=\"mailto:$HSM_MAIL_CC\">$HSM_MAIL_CC</a> in case you need support.<br><br>Best Regards,<br>$issuer<br>HSM Team<br><br><br></body></html>";
			else
				if [[ "$is_cmcc" ]];
				then
					echo -e "<html><body>Dear $name,<br><br>you have been issued a VPN account.<br><br>To install and configure the Forcepoint VPN client on your computer, you may follow the guide available at the following link:<br><br>";
					echo -e "<a href=\"$vpn_user_guides_link\">$vpn_user_guides_link</a><br><br>Once you have completed the installation of the VPN client, you will be able to activate a VPN connection using <b>your personal credentials</b> that are available at the following link:<br><br>";
					echo -e "<a href=\"""$link""\">""$link""</a><br><br>N.B. you must use your CMCC mail account in order to access this shared folder.<br><br>Contact <a href=\"mailto:$HSM_MAIL_CC\">$HSM_MAIL_CC</a> in case you need support.<br><br>Best Regards,<br>$issuer<br>HSM Team<br><br><br></body></html>";
				else
					pdf_file_tag="CMCC_VPN_account_""$username""_""$(echo $division | tr '[:lower:]' '[:upper:]')"
					echo -e "<html><body>Dear $name,<br><br>you have been issued a VPN account.<br><br>To install and configure the Forcepoint VPN client on your computer, you may follow the guide available at the following link:<br><br>";
                                        echo -e "<a href=\"$vpn_user_guides_link\">$vpn_user_guides_link</a><br><br>Once you have completed the installation of the VPN client, you will be able to activate a VPN connection using <b>your personal credentials</b> that are available in the PDF file in attachment.<br><br>";
                                        echo -e "Contact <a href=\"mailto:$HSM_MAIL_CC\">$HSM_MAIL_CC</a> in case you need support.<br><br>Best Regards,<br>$issuer<br>HSM Team<br><br><br></body></html>";
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
			fi

        ) | "$MAIL_CMD" -t "$email"

	fi

	if [[ "$notify" -eq 1 ]];
	then
		#mach_lower="$(echo ${mach:0:1} | tr '[:lower:]' '[:upper:]')""$(echo ${mach:1:${#mach}})"
		mach_upper="$(echo $mach | tr '[:lower:]' '[:upper:]')"
		mach_user_guides_link="https://drive.google.com/drive/folders/1a0MCtDAHjH7gGh9GPLuyVevD8wMLQiGg"
		(
			echo "Subject: $mach_upper account activation notification (username $username)";
       			echo "From: $MAIL_FROM";
       			echo "To: $email";
			if [[ "$CC_DIVISIONS_DIRECTORS" -ne 0 ]];
                	then	
				echo "Cc: $division_director_mail, $HSM_MAIL_CC";
			fi
			echo "Cc: $HSM_MAIL_CC";
			echo "Mime-Version: 1.0";
       			echo "Content-Type: multipart/related; boundary=\"boundary-example\"; type=\"text/html\"";
       			echo "";
       			echo "--boundary-example";
       			echo "Content-Type: text/html; charset=utf-8"; #ISO-8859-15";
       			echo "Content-Transfer-Encoding: 7bit";
       			echo "";
			if [[ "$is_cmcc" ]]; #[[ "$is_cmcc" ]];
			then 
				echo -e "<html><body>Dear $name,<br><br>you have been issued an account (username $username) in order to access the $mach_upper supercomputer.<br><br>In order to access $mach_upper, you will need to download your credentials from the following link:<br><br><a href=\"""$link""\">""$link""</a><br><br>N.B.: you must use your CMCC mail account in order to access the shared folders.<br><br>$mach_upper User Guides are available at this link:<br><br><a href=\"$mach_user_guides_link\">$mach_user_guides_link</a><br><br>Instructions for accessing $mach_upper are available in the '$mach_upper Getting Started' guide.<br><br>Best Regards,<br>$issuer<br>HSM Team<br><br><br></body></html>";
			else
				pdf_file_tag="CMCC_VPN_account_""$username""_""$(echo $division | tr '[:lower:]' '[:upper:]')"
				echo -e "<html><body>Dear $name,<br><br>you have been issued an account (username $username) in order to access the $mach_upper supercomputer.<br><br>Your account information is available in the PDF file in attachment.<br><br>$mach_upper User Guides are available at this link:<br><br><a href=\"$mach_user_guides_link\">$mach_user_guides_link</a><br><br>Instructions for accessing $mach_upper are available in the '$mach_upper Getting Started' guide.<br><br>Best Regards,<br>$issuer<br>HSM Team<br><br><br></body></html>";
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
fi
