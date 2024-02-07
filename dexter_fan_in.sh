#!/bin/bash

out_dir_name="$1"
docx_filename_out="$2"
name_dot_surname="$3"
email="$4"
issuer="$5"
first="$6"
username="$7"
div="$8"
mach="${11}"
notify="${9}"
vpn_notify="${10}"

cd /root/gdrive_API
source gdrive_venv/bin/activate;
mkdir -p files/$out_dir_name ;
mv files/$(echo $docx_filename_out | cut -d'/' -f2) files/$docx_filename_out
python3 upload_docx_convert_to_pdf.py files/$docx_filename_out $name_dot_surname $email $issuer >> files/$out_dir_name/drive_api_log
cat files/$out_dir_name/drive_api_log

if [[ "$notify" -eq 1 ]] #|| [[ ! -z "$notify" ]];
then
	./send_user_mail.sh "$(echo ${issuer:0:1} | tr '[:lower:]' '[:upper:]')""$(echo ${issuer:1:${#issuer}} | cut -d'_' -f1)" "$first" "$username" "$email" "$(echo $div | tr '[:lower:]' '[:upper:]')" "$(cat files/$out_dir_name/drive_api_log | grep 'Folder link' | tail -n1 | cut -d' ' -f3 | tr -d '\n')" "files/$out_dir_name/$(echo $docx_filename_out | cut -d'/' -f2 | cut -d'.' -f1).pdf"	"$vpn_notify" "$mach"
fi
