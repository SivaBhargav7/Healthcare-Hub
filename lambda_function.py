import json
import pymysql
import os

def lambda_handler(event, context):
    connection = pymysql.connect(
        host=os.environ['DB_HOST'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD'],
        database=os.environ['DB_NAME']
    )

    body = json.loads(event['body'])
    name = body['name']
    age = body['age']
    hospital = body['hospital']
    date = body['date']

    with connection.cursor() as cursor:
        sql = "INSERT INTO appointments (name, age, hospital, date) VALUES (%s, %s, %s, %s)"
        cursor.execute(sql, (name, age, hospital, date))
        connection.commit()

    connection.close()

    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Appointment booked successfully!'})
    }
