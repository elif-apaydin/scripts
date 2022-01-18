import boto3

s3_client   = boto3.client('s3')
bucket_list = s3_client.list_buckets()

for bucket in bucket_list['Buckets']:

    try:
        lifecycle = s3_client.get_bucket_lifecycle(Bucket=bucket['Name'])
        rules = lifecycle['Rules']
    except:
        rules = 'No Policy'
        
    print(bucket['Name'], rules)
