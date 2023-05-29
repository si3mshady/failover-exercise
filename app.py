import streamlit as st
from dotenv import load_dotenv
import boto3
import logging
from datetime import datetime
import time
import os

load_dotenv()

# Configure logging
logging.basicConfig(filename='ec2_health.log', level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')

# Function to retrieve available regions
def get_regions():
    return ['us-east-1', 'us-east-2']

# Function to check the health status of EC2 machines
def check_health(region, ec2_instance_ids):
    ec2 = boto3.client('ec2', region_name=region, aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'), aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'))
    health_status = []
    for instance_id in ec2_instance_ids:
        response = ec2.describe_instance_status(InstanceIds=[instance_id])
        if len(response['InstanceStatuses']) > 0:
            instance_status = response['InstanceStatuses'][0]['InstanceStatus']['Status']
            health_status.append(instance_status)
            logging.info(f'[ECS] Health Status: Instance ID: {instance_id}, Status: {instance_status}')
    return health_status

# Function to get the number of instances and their states in a region
def get_instance_states(region):
    ec2 = boto3.client('ec2', region_name=region, aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'), aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'))
    response = ec2.describe_instances()
    instance_states = {}
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']
            state = instance['State']['Name']
            instance_states[instance_id] = state
    return instance_states

# Function to start an EC2 machine
def start_instance(instance_id, region):
    ec2 = boto3.client('ec2', region_name=region, aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'), aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'))
    response = ec2.start_instances(InstanceIds=[instance_id])
    logging.info(f'[ECS] Start: Instance ID: {instance_id}, Response: {response}')
    return response

# Function to stop an EC2 machine
def stop_instance(instance_id, region):
    ec2 = boto3.client('ec2', region_name=region, aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'), aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'))
    response = ec2.stop_instances(InstanceIds=[instance_id])
    logging.info(f'[ECS] Stop: Instance ID: {instance_id}, Response: {response}')
    return response

# Function to check if the instance has reached the desired state
def check_instance_state(instance_id, region, desired_state):
    ec2 = boto3.client('ec2', region_name=region, aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'), aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'))
    while True:
        response = ec2.describe_instances(InstanceIds=[instance_id])
        if len(response['Reservations']) > 0:
            instance_state = response['Reservations'][0]['Instances'][0]['State']['Name']
            if instance_state == desired_state:
                break
        time.sleep(5)

# Function to generate cards for each region
def generate_cards(ec2_instance_ids):
    regions = get_regions()
    for region in regions:
        st.subheader(f'Region: {region}')
        instance_states = get_instance_states(region)
        st.write(f'Total instances: {len(instance_states)}')
        for instance_id, state in instance_states.items():
            st.write(f'Instance ID: {instance_id}')
            if state == 'running':
                st.success(f'State: {state}')
            else:
                st.error(f'State: {state}')
        st.write('---')

# Streamlit app
def main():
    st.title('EC2 Health Status')

    st.subheader('AWS Credentials')

    # Check if environment variables for access keys are set
    if 'AWS_ACCESS_KEY_ID' in os.environ and 'AWS_SECRET_ACCESS_KEY' in os.environ:
        access_key = os.environ['AWS_ACCESS_KEY_ID']
        secret_key = os.environ['AWS_SECRET_ACCESS_KEY']
    else:
        access_key = st.text_input('Access Key')
        secret_key = st.text_input('Secret Key', type='password')

    # EC2 instance IDs input
    instance_ids_input = st.text_input('EC2 Instance IDs (comma-separated)', help='Enter the EC2 instance IDs separated by commas')
    ec2_instance_ids = [instance.strip() for instance in instance_ids_input.split(',')] if instance_ids_input else []

    # Check the health status of EC2 machines
    generate_cards(ec2_instance_ids)

    # Columns to start and stop EC2 machines
    col1, col2 = st.columns(2)
    with col1:
        if st.button('Start EC2 Machines'):
            for instance_id in ec2_instance_ids:
                st.write(f'Starting instance {instance_id}')
                start_instance(instance_id, 'us-east-1')
                with st.spinner('Waiting for instance to start...'):
                    check_instance_state(instance_id, 'us-east-1', 'running')
                st.success(f'Instance {instance_id} started successfully!')
    with col2:
        if st.button('Stop EC2 Machines'):
            for instance_id in ec2_instance_ids:
                st.write(f'Stopping instance {instance_id}')
                stop_instance(instance_id, 'us-east-1')
                with st.spinner('Waiting for instance to stop...'):
                    check_instance_state(instance_id, 'us-east-1', 'stopped')
                st.error(f'Instance {instance_id} stopped successfully!')

if __name__ == '__main__':
    main()