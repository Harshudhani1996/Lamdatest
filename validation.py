import boto3
import re
import os
import json

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    print("Received event:", json.dumps(event, indent=2))  # Debugging

    if 'Records' not in event:
        print("❌ Error: 'Records' key missing from event")
        return {"status": "error", "message": "'Records' key not found"}
    
    bucket_name = os.environ.get("BUCKET_NAME")
    validated_folder = os.environ.get("VALIDATED_FOLDER")

    for record in event['Records']:
        s3_object = record['s3']
        source_key = s3_object['object']['key']
        
        filename = os.path.basename(source_key)
        
        if re.match("^[a-zA-Z]+$", filename.split('.')[0]):
            destination_key = f"{validated_folder}/{filename}"
            s3_client.copy_object(
                Bucket=bucket_name,
                CopySource={'Bucket': bucket_name, 'Key': source_key},
                Key=destination_key
            )
            s3_client.delete_object(Bucket=bucket_name, Key=source_key)
            print(f"✅ Moved {filename} to {validated_folder}/")
        else:
            print(f"🚫 Invalid filename {filename}, keeping in allfiles/")

    return {"status": "success"}
