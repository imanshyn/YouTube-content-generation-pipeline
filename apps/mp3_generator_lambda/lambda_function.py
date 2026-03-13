import boto3
import json
import os
from datetime import datetime
from botocore.config import Config

s3 = boto3.client('s3')
bedrock = boto3.client('bedrock-runtime', config=Config(read_timeout=120))
polly = boto3.client('polly')

def lambda_handler(event, context):
    prompts_bucket = event['prompts_bucket']
    topic = event.get('topic')
    voice = event.get('voice', 'Stephen')
    output_bucket = os.environ['OUTPUT_BUCKET']
    model_id = os.environ.get('BEDROCK_MODEL_ID', 'us.anthropic.claude-sonnet-4-20250514-v1:0')
    
    current_date = datetime.now().strftime('%Y-%m-%d')
    
    # List objects in video-gen-prompts folder
    response = s3.list_objects_v2(Bucket=prompts_bucket, Prefix=f'video-gen-prompts/{topic}/')
    
    # Find prompt with current date
    prompt_key = None
    for obj in response.get('Contents', []):
        if current_date in obj['Key']:
            prompt_key = obj['Key']
            break
    
    if not prompt_key:
        return {'statusCode': 404, 'body': f'No prompt found for {current_date}'}
    
    # Read prompt
    prompt_obj = s3.get_object(Bucket=prompts_bucket, Key=prompt_key)
    prompt_text = prompt_obj['Body'].read().decode('utf-8')
    
    # Send to Claude 4.6
    bedrock_request = {
        'anthropic_version': 'bedrock-2023-05-31',
        'max_tokens': 20000,
        'messages': [{'role': 'user', 'content': prompt_text}]
    }
    
    bedrock_response = bedrock.invoke_model(
        modelId=model_id,
        body=json.dumps(bedrock_request)
    )
    
    response_body = json.loads(bedrock_response['body'].read())
    ssml_text = response_body['content'][0]['text']

    # Generate speech with Polly async task
    output_key_prefix = f'{topic}/{current_date}/'
    
    polly_response = polly.start_speech_synthesis_task(
        Engine='generative',
        VoiceId=voice,
        LanguageCode='en-US',
        OutputFormat='mp3',
        Text=ssml_text,
        TextType='ssml',
        OutputS3BucketName=output_bucket,
        OutputS3KeyPrefix=output_key_prefix
    )
    
    # Get metadata generation prompt
    metadata_prompt_obj = s3.get_object(Bucket=prompts_bucket, Key=f'title/{topic}/metadata_generation_prompt.md')
    metadata_prompt = metadata_prompt_obj['Body'].read().decode('utf-8')
    
    # Get title and description from Bedrock
    metadata_request = {
        'anthropic_version': 'bedrock-2023-05-31',
        'max_tokens': 2000,
        'messages': [{
            'role': 'user',
            'content': f'{metadata_prompt}\n\n{ssml_text[:5000]}'
        }]
    }
    
    metadata_response = bedrock.invoke_model(
        modelId=model_id,
        body=json.dumps(metadata_request)
    )
    
    metadata_body = json.loads(metadata_response['body'].read())
    metadata_text = metadata_body['content'][0]['text'].strip()
    if metadata_text.startswith('```'):
        metadata_text = metadata_text.split('\n', 1)[1].rsplit('```', 1)[0].strip()
    
    # Save metadata to S3
    metadata_key = f'{topic}/{current_date}/metadata.json'
    s3.put_object(
        Bucket=output_bucket,
        Key=metadata_key,
        Body=metadata_text,
        ContentType='application/json'
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps(f'Audio saved to s3://{output_bucket}/{output_key_prefix}')
    }
