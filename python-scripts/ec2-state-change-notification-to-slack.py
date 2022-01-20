import boto3
import json, requests
from requests.structures import CaseInsensitiveDict
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    webhook_url     = "<SLACK-WEBHOOK-URL>"
    alertUrl        = "<OPSGENIE-URL>"
    eventName       = event['detail']['eventName']
    ip              = event['detail']['sourceIPAddress']
    region          = event['detail']['awsRegion']
    user            = event['detail']['userIdentity']['userName']
    instanceId      = event['detail']['requestParameters']['instancesSet']['items']
    listInst        = []
    
    for i in instanceId:
        listInst.append(i['instanceId'])
    strInst = ' , '.join(listInst)
    
    if event['detail']['userIdentity']['type'] == 'IAMUser'  and event['detail']['userIdentity']['userName']!= <USERNAME> and ip != '<IP-ADDRESS>':
        slack_data = { 'text': "\n*EC2 EVENT :alert_: * " + "\n*`Event Name:`*  " + eventName + "\n*`Instance Id:`*  " + strInst + "\n*`User:`* " + user + "\n*`IP:`* " + ip + "\n*`Region:`* " + region}
        response = requests.post(
            webhook_url, data=json.dumps(slack_data),
            headers={'Content-Type': 'application/json'}
        )

        headers = CaseInsensitiveDict()
        headers["Content-Type"] = "application/json"
        headers["Authorization"] = "GenieKey 8e334dc4-0339-437b-a265-ccf56ac96dba"

        data = """
        {
            "message": "EC2 Change Event",
            "alias": "An unauthorized user has taken action.",
            "description":"Please check the EC2 Console"
        }
        """

        resp = requests.post(alertUrl, headers=headers, data=data)
        print(resp.status_code)
    
    
        if response.status_code != 200:
            raise ValueError(
                'Request to slack returned an error %s, the response is:\n%s'
                % (response.status_code, response.text)
        )

    return {"status": 200}
