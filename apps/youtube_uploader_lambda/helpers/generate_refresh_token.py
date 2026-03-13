#!/usr/bin/env python3
import sys
from google_auth_oauthlib.flow import InstalledAppFlow

SCOPES = ['https://www.googleapis.com/auth/youtube.upload']

def main():
    if len(sys.argv) != 3:
        print("Usage: python3 generate_refresh_token.py <client_id> <client_secret>")
        sys.exit(1)
    
    client_id = sys.argv[1]
    client_secret = sys.argv[2]
    
    client_config = {
        "installed": {
            "client_id": client_id,
            "client_secret": client_secret,
            "auth_uri": "https://accounts.google.com/o/oauth2/auth",
            "token_uri": "https://oauth2.googleapis.com/token",
            "redirect_uris": ["http://localhost"]
        }
    }
    
    flow = InstalledAppFlow.from_client_config(client_config, SCOPES)
    credentials = flow.run_local_server(port=8080)
    
    print("\n" + "="*50)
    print("REFRESH TOKEN:")
    print("="*50)
    print(credentials.refresh_token)
    print("="*50)
    print("\nStore this in SSM Parameter Store as:")
    print(f"  /youtube/<topic>/refresh_token")

if __name__ == '__main__':
    main()
