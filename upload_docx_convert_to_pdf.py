import os.path
import sys
import io

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaFileUpload
from googleapiclient.http import MediaIoBaseDownload


import google.auth
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

# If modifying these scopes, delete the file token.json.
SCOPES = ["https://www.googleapis.com/auth/drive", "https://www.googleapis.com/auth/drive.metadata.readonly"]

real_file_name = sys.argv[1]
real_folder_name = sys.argv[2]
real_email = sys.argv[3]
real_parent_id = "10N_pqAKbry-xwOmjWvljKbIXR8KyosEL" # SCC-HSM/CMCC_IDM_users_credentials
real_token = sys.argv[4] #"marco_chiarelli"

print("-------------------------------------------")
print("Real file name: {}".format(real_file_name))
print("Real folder name: {}, Real email: {}".format(real_folder_name, real_email))
print("Real parent ID: {}".format(real_parent_id))
print("Real token: {}".format(real_token))

def manage_creds():
    creds = None
    # The file token.json stores the user's access and refresh tokens, and is
    # created automatically when the authorization flow completes for the first
    # time.
    real_token_file="tokens/token_{}.json".format(real_token)
    if os.path.exists(real_token_file):
        creds = Credentials.from_authorized_user_file(real_token_file, SCOPES)
    # If there are no (valid) credentials available, let the user log in.
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
            "credentials.json", SCOPES
            )
            creds = flow.run_local_server(port=0)
    # Save the credentials for the next run
    with open(real_token_file, "w") as token:
        token.write(creds.to_json())
    
    return creds
      
#creds, _ = google.auth.default()
creds = manage_creds()

def create_folder(folder_name, parent):
  """Create a folder and prints the folder ID
  Returns : Folder Id

  Load pre-authorized user credentials from the environment.
  TODO(developer) - See https://developers.google.com/identity
  for guides on implementing OAuth2 for the application.
  """
  #creds, _ = google.auth.default()

  try:
    # create drive api client
    #service = build("drive", "v3", credentials=creds)
    file_metadata = {
        "name": folder_name,
        "mimeType": "application/vnd.google-apps.folder",
        "parents": [parent]
    }

    # pylint: disable=maybe-no-member
    file = service.files().create(body=file_metadata, fields="id, webViewLink").execute()
    print(f'Folder ID: "{file.get("id")}".')
    return file #.get("id"), file

  except HttpError as error:
    print(f"An error occurred: {error}")
    return None

def upload_to_folder(folder_id, file_name, mimeType):
  """Upload a file to the specified folder and prints file ID, folder ID
  Args: Id of the folder
  Returns: ID of the file uploaded

  Load pre-authorized user credentials from the environment.
  TODO(developer) - See https://developers.google.com/identity
  for guides on implementing OAuth2 for the application.
  """
  #creds, _ = google.auth.default()
  out_file_name = file_name.split("/")[-1]
  
  try:
    # create drive api client
    #service = build("drive", "v3", credentials=creds)

    file_metadata = {"name": out_file_name, "mimeType": mimeType, "parents": [folder_id]}
    media = MediaFileUpload(
        file_name, mimetype="application/vnd.openxmlformats-officedocument.wordprocessingml.document", resumable=True
    )
    # pylint: disable=maybe-no-member
    file = (
        service.files()
        .create(body=file_metadata, media_body=media, fields="id")
        .execute()
    )
    print(f'File ID: "{file.get("id")}".')
    return file.get("id"), file_name

  except HttpError as error:
    print(f"An error occurred: {error}")
    return None
    
def download_file(real_file_id, file_name):
  """Downloads a file
  Args:
      real_file_id: ID of the file to download
  Returns : IO object with location.

  Load pre-authorized user credentials from the environment.
  TODO(developer) - See https://developers.google.com/identity
  for guides on implementing OAuth2 for the application.
  """
  #creds, _ = google.auth.default()

  try:
    # create drive api client
    #service = build("drive", "v3", credentials=creds)

    file_id = real_file_id

    # pylint: disable=maybe-no-member
    request = service.files().export_media(
        fileId=file_id, mimeType="application/pdf"
    )

    file = io.BytesIO()
    downloader = MediaIoBaseDownload(file, request)
    done = False
    while done is False:
      status, done = downloader.next_chunk()
      print(f"Download {int(status.progress() * 100)}.")

  except HttpError as error:
    print(f"An error occurred: {error}")
    file = None

  return file, file_name  #.getvalue()


if __name__ == "__main__":
    try:
        service = build("drive", "v3", credentials=creds)
        folder = create_folder(real_folder_name, parent=real_parent_id)
        folder_id = folder.get("id")
        folder_link = folder.get("webViewLink")
        print("Folder link {}".format(folder_link))
        file_id, file_name = upload_to_folder(folder_id=folder_id, file_name=real_file_name, mimeType="application/vnd.google-apps.document")
        bytesio_object, file_name = download_file(file_id, file_name)
        # Write the stuff
        out_file_name = file_name.split(".")[0]+".pdf"
        
        with open(out_file_name, "wb") as f:
            f.write(bytesio_object.getbuffer())
            
        service.files().delete(fileId=file_id).execute()
        upload_to_folder(folder_id=folder_id,file_name=out_file_name, mimeType="application/pdf")
        
        if(real_email and real_email.split("@")[1] == "cmcc.it"):
            user_permission = {
                "type": "user",
                "role": "reader",
                "emailAddress": real_email,
            }
            
            perm = (service.permissions().create(fileId=folder_id, sendNotificationEmail = False, body = user_permission, fields="id").execute())
            print(f'Permission ID: "{perm.get("id")}".')
            
    except HttpError as error:
        print(f"An error occurred: {error}")
  
print("-------------------------------------------")
