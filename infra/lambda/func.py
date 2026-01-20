import json
import boto3
import time
from decimal import Decimal
from botocore.exceptions import ClientError

dynamodb = boto3.resource('dynamodb')
# Tablo isimleri
stats_table = dynamodb.Table('cloud-resume-stats-v2')
ip_table = dynamodb.Table('cloud-resume-ips-v2')

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return int(obj)
        return super(DecimalEncoder, self).default(obj)

def lambda_handler(event, context):
    # 1. IP BULMA
    try:
        if 'http' in event['requestContext']:
            visitor_ip = event['requestContext']['http']['sourceIp']
        elif 'identity' in event['requestContext']:
            visitor_ip = event['requestContext']['identity']['sourceIp']
        else:
            visitor_ip = "Unknown"
    except Exception as e:
        print(f"IP Hata: {e}")
        visitor_ip = "Unknown"

    print(f"Ziyaretci IP: {visitor_ip}")

    # 2. LOGIC
    ttl_value = int(time.time() + 86400)
    should_increment = False
    
    try:
        ip_table.put_item(
            Item={'ip_address': visitor_ip, 'ttl': ttl_value},
            ConditionExpression='attribute_not_exists(ip_address)'
        )
        should_increment = True
    except ClientError as e:
        if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
            should_increment = False
        else:
            pass

    # 3. SAYAÇ GÜNCELLEME (Düzeltilen Kısım)
    if should_increment:
        response = stats_table.update_item(
            Key={'id': 'stats'},
            # DÜZELTME: if_not_exists fonksiyonu eklendi
            # Eğer views yoksa 0 kabul et ve :inc ekle
            UpdateExpression='SET #v = if_not_exists(#v, :start) + :inc',
            ExpressionAttributeNames={'#v': 'views'},
            ExpressionAttributeValues={
                ':inc': 1,
                ':start': 0  # Başlangıç değeri
            },
            ReturnValues='UPDATED_NEW'
        )
        view_count = response['Attributes']['views']
    else:
        # Sadece okuma
        response = stats_table.get_item(Key={'id': 'stats'})
        if 'Item' in response:
            view_count = response['Item']['views']
        else:
            view_count = 0

    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        },
        'body': json.dumps(view_count, cls=DecimalEncoder)
    }