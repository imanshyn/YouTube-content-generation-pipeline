import boto3
import json
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

s3 = boto3.client('s3')
ssm = boto3.client('ssm')

def lambda_handler(event, context):
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    
    topic = key.split('/')[0]
    
    video_path = '/tmp/video.mp4'
    folder = key.rsplit('/', 1)[0]
    
    s3.download_file(bucket, key, video_path)
    
    metadata_obj = s3.get_object(Bucket=bucket, Key=f'{folder}/metadata.json')
    metadata = json.loads(metadata_obj['Body'].read().decode('utf-8'))
    
    client_id = ssm.get_parameter(Name=f'/youtube/{topic}/client_id', WithDecryption=True)['Parameter']['Value']
    client_secret = ssm.get_parameter(Name=f'/youtube/{topic}/client_secret', WithDecryption=True)['Parameter']['Value']
    
    try:
        refresh_token = ssm.get_parameter(Name=f'/youtube/{topic}/refresh_token', WithDecryption=True)['Parameter']['Value']
    except ssm.exceptions.ParameterNotFound:
        raise Exception(
            f"Missing refresh token for topic '{topic}'. "
            f"Run generate_refresh_token.py locally and store the token in SSM at /youtube/{topic}/refresh_token"
        )
    
    credentials = Credentials(
        token=None,
        refresh_token=refresh_token,
        token_uri='https://oauth2.googleapis.com/token',
        client_id=client_id,
        client_secret=client_secret
    )
    
    credentials.refresh(Request())
    
    title = metadata.get('viral_title', {}).get('text', 'Motivational Speech')
    desc = metadata.get('description', {})
    description = desc.get('full_text', '') if isinstance(desc, dict) else str(desc)
    tags = metadata.get('metadata', {}).get('suggested_tags', [])
    
    youtube = build('youtube', 'v3', credentials=credentials)
    
    request = youtube.videos().insert(
        part='snippet,status',
        body={
            'snippet': {
                'title': title,
                'description': description,
                'tags': tags,
                'categoryId': '22'
            },
            'status': {
                'privacyStatus': 'public',
            }
        },
        media_body=MediaFileUpload(video_path, chunksize=-1, resumable=True)
    )
    
    response = request.execute()
    
    return {'statusCode': 200, 'body': json.dumps(f"Video ID: {response['id']}")}
