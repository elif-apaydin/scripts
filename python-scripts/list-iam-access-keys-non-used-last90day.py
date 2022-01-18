#list iam user access keys last used 90 days

from re import A
import boto3
import datetime
from dateutil.tz import tzutc

resource = boto3.resource('iam')
client = boto3.client('iam')

today = datetime.datetime.now()
final_report = ''
number = 1

# For every user
for user in resource.users.all():

    # Get Access Keys for the User
    keys_response = client.list_access_keys(UserName=user.user_name)
    last_access = None

    # For every Access Key associate with the user
    for key in keys_response['AccessKeyMetadata']:

        last_used_response = client.get_access_key_last_used(AccessKeyId=key['AccessKeyId'])
        if 'LastUsedDate' in last_used_response['AccessKeyLastUsed']:
            accesskey_last_used = last_used_response['AccessKeyLastUsed']['LastUsedDate']
            if last_access is None or accesskey_last_used < last_access:
                last_access = accesskey_last_used

    # More than x days since last access?
    if last_access is not None:
        delta = (today - last_access.replace(tzinfo=None)).days
        if delta >= 90:
            final_report += str(number) + " username: " + [user.user_name][0] + " - " + str(delta) + " days\n" 
            number += 1

print(final_report)
