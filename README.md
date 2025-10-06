🏥 Healthcare Hub Web Application
📖 Overview

<img width="1920" height="1080" alt="2" src="https://github.com/user-attachments/assets/59c53ef2-415a-4079-a53a-2e751c501c84" />


The Healthcare Hub web application is a cloud-native hospital appointment booking system built on AWS using a serverless and highly available architecture.

It allows users to schedule hospital appointments through a simple frontend, which connects to a backend powered by AWS Lambda, API Gateway, and a MySQL database hosted in Amazon RDS.
The frontend is hosted in an S3 bucket configured for static website hosting.

This project was designed to demonstrate an end-to-end full-stack cloud application with infrastructure automated via Terraform.

🏗️ Architecture
🔹 Components:
Layer	Service	Purpose
Frontend	Amazon S3	Hosts static website (HTML/CSS/JS) for hospital appointment booking.
Backend	AWS Lambda	Processes appointment submissions and inserts them into RDS.
API Layer	API Gateway	Provides REST endpoint for the frontend to send appointment data.
Database	Amazon RDS (MySQL)	Stores appointment details securely.
Networking	VPC, Subnets, Security Groups	Ensures isolation, routing, and controlled access.
Infrastructure as Code	Terraform	Automates provisioning of all resources.
🧩 Architecture Diagram
 ┌────────────────────────────────────────┐
 │          User (Frontend UI)            │
 │   [HTML/CSS/JS hosted on S3 Website]   │
 └────────────────────────────────────────┘
                   │
                   ▼
 ┌────────────────────────────────────────┐
 │        Amazon API Gateway (REST)       │
 │   Endpoint: POST /appointments         │
 └────────────────────────────────────────┘
                   │
                   ▼
 ┌────────────────────────────────────────┐
 │          AWS Lambda Function           │
 │ (Processes request, connects to RDS)   │
 └────────────────────────────────────────┘
                   │
                   ▼
 ┌────────────────────────────────────────┐
 │       Amazon RDS (MySQL Database)      │
 │  Stores appointment and patient data   │
 └────────────────────────────────────────┘

⚙️ Features

🩺 Book hospital appointments via a user-friendly web form

☁️ 100% AWS Serverless Backend

🧾 Appointment data stored securely in Amazon RDS (MySQL)

🚀 Frontend hosted using Amazon S3 Static Website Hosting

🔐 Secure communication via API Gateway

🧠 Infrastructure fully automated using Terraform

🧰 Tech Stack
Category	Technology
Frontend	HTML, CSS, JavaScript
Backend	Python (AWS Lambda)
Database	Amazon RDS – MySQL
Infrastructure	Terraform
Cloud Provider	AWS (S3, API Gateway, Lambda, RDS, IAM, VPC)

🚀 Deployment Guide
1️⃣ Prerequisites

AWS Account

AWS CLI configured with your credentials

Terraform installed (v1.5+ recommended)

Python 3.9+

2️⃣ Setup and Initialize Terraform
cd healthcare-hub/
terraform init
terraform plan
terraform apply


This will create:

A new VPC with public and private subnets

An RDS MySQL database

A Lambda function connected to RDS

An API Gateway endpoint

An S3 bucket for frontend hosting

3️⃣ Prepare and Upload Lambda Function

Create a Python file lambda_function.py:

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


Install dependencies (if using external libraries like pymysql):

pip install pymysql -t .
zip -r lambda_function.zip .


Replace the existing ZIP file in your project directory.

4️⃣ Connect Frontend with Backend

In your frontend/script.js:

const apiUrl = "https://<your-api-gateway-id>.execute-api.ap-southeast-2.amazonaws.com/appointments";

async function bookAppointment(event) {
  event.preventDefault();

  const appointment = {
    name: document.getElementById("name").value,
    age: document.getElementById("age").value,
    hospital: document.getElementById("hospital").value,
    date: document.getElementById("date").value
  };

  const response = await fetch(apiUrl, {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify(appointment)
  });

  const result = await response.json();
  alert(result.message);
}

5️⃣ Deploy Frontend to S3
aws s3 sync ./frontend s3://<your-s3-bucket-name> --acl public-read


Then open your S3 Website URL (from Terraform output):

http://healthcare-frontend-xxxxxx.s3-website-ap-southeast-2.amazonaws.com

🧩 Terraform Outputs

After successful deployment, you’ll see:

api_gateway_url = https://xxxxxx.execute-api.ap-southeast-2.amazonaws.com
rds_endpoint    = healthcare-db.xxxxxx.ap-southeast-2.rds.amazonaws.com
s3_website_url  = http://healthcare-frontend-xxxxxx.s3-website-ap-southeast-2.amazonaws.com


Use these values to connect your system.

🔐 Security Notes

The RDS instance is deployed in a private subnet (not publicly accessible).

Lambda has IAM permissions to log to CloudWatch and connect securely to RDS.

Only API Gateway can trigger the Lambda function.

You can add SSL certificates (ACM + CloudFront) for HTTPS support later.

📊 Future Enhancements

Add Cognito authentication for user login.

Send email confirmations using AWS SES.

Add CloudFront CDN for frontend performance optimization.

Integrate monitoring dashboards with CloudWatch and SNS alerts.

👨‍💻 Author

Siva Bhargav Bachala
AWS Certified Solutions Architect – Associate
Passionate about Cloud, DevOps, and Serverless Application Design.

📧 Email: sivabhargav783@gmail.com

🌐 Portfolio: https://my-3d-portfolio-rose.vercel.app/#projects
