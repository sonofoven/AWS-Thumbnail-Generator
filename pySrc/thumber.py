from PIL import Image
from io import BytesIO
import json
import boto3
import os

destBucket = "novesen-s3-thumb-gen-output"

size = (128, 128)
s3Client = boto3.client('s3')

def lambda_handler(event, context):

    try:
        # Get trigger info
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
    except Exception as e:
        return {'statusCode': 400,
                'body': json.dumps(f'Invalid S3 trigger event. {e}')}

    try:
        # Grab new object and get its bytes
        response = s3Client.get_object(Bucket=bucket, Key=key)
        imageBytes = response['Body'].read()
    except Exception as e:
        return {'statusCode': 400,
                'body': json.dumps(f'Could not grab image bytes. {e}')}

    try:
        # Make open up a byte buffer and modify the bytes
        image = Image.open(BytesIO(imageBytes))
        image.thumbnail(size)

        # Save the image to a new buffer
        buffer = BytesIO()
        image.save(buffer, "JPEG")
        buffer.seek(0)
    except Exception as e:
        return {'statusCode': 400,
                'body': json.dumps(f'Failed to process image. {e}')}

        # Create output name
        destKey = os.path.splitext(key)[0] + "_thumb.jpg"

    try:
        # Save converted buffer to the s3 bucket
        s3Client.put_object(
            Bucket=destBucket,
            Key=destKey,
            Body=buffer,
            ContentType="image/jpeg"
        )
    except Exception as e:
        return {'statusCode': 400,
                'body': json.dumps(f'Failed to put object. {e}')}

    return {
        'statusCode': 200,
        'body': json.dumps('File successfully thumbnailed')
    }
