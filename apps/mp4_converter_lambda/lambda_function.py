import boto3
import json
import subprocess
import os
from datetime import date

s3 = boto3.client('s3')

def lambda_handler(event, context):
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    
    topic = key.split('/')[0]
    
    audio_file = f'/tmp/audio.mp3'
    image_file = f'/tmp/image.png'
    output_file = f'/tmp/output.mp4'
    
    s3.download_file(bucket, key, audio_file)
    
    image_key = f'{topic}/image/{date.today()}.png'
    try:
        s3.head_object(Bucket=bucket, Key=image_key)
        s3.download_file(bucket, image_key, image_file)
    except s3.exceptions.ClientError:
        s3.download_file(bucket, f'{topic}/image/image.png', image_file)
    
    subprocess.run([
        'ffmpeg', '-y',
        '-loop', '1', '-i', image_file,
        '-i', audio_file,
        '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '23',
        '-maxrate', '5M', '-bufsize', '10M',
        '-r', '30',
        '-c:a', 'aac', '-b:a', '192k', '-ar', '48000',
        '-vf', 'scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2',
        '-shortest',
        '-movflags', '+faststart',
        output_file
    ], check=True)
    
    output_key = key.replace('.mp3', '.mp4')
    s3.upload_file(output_file, bucket, output_key)
    
    return {'statusCode': 200, 'body': json.dumps({'outputKey': output_key})}
