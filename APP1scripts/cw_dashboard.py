import boto3
import json
import copy
import os
import logging

from datetime import datetime


def lambda_handler(context, event):
    # EVENT TAGS AND REGIONS
    key = 'event'
    value = 'cloudwatch_dashboard'
    regions = ['ap-southeast-2']
    
    # DASHBOARDS WIDGET TEMPLATES

    
    scafolding_json = {
        "type": "metric",
        "width": 6,
        "height": 6,
        "properties": {
            "view": "timeSeries",
            "stacked": False,
            "metrics": [],
            "region": "ap-southeast-2",
            "period": 300,
            "title": ""
        }
    }
    
    # LOGGER
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    logger.info('## ENVIRONMENT VARIABLES')
    logger.info(os.environ)

    # Load environment variables
    app = os.environ['app']
    env = os.environ['env']
    dashboards = []
    unsorted_tagged_arn_list = []
    sorted_tagged_arn_list = []
        # DASHBOARDS & WIDGET TEMPLATES
    widget_json = {
            "widgets": []
    }

   
    for region in regions:
        unsorted_tagged_arn_list.append(iterate_regions(region,key,value,logger,env))
    sorted_tagged_arn_list = sort_list(unsorted_tagged_arn_list)
    create_widgets(sorted_tagged_arn_list,widget_json,scafolding_json,logger,app,env.upper())
    dashboard_title = f"{app}-{env}-testing"
    dashboards.append(create_dashboard(dashboard_title,json.dumps(widget_json)))
    return True

# get instance 'Name' tag
def get_instance_info(fid):
    # When given an instance ID as str e.g. 'i-1234567', return the instance 'Name' from the name tag.
    ec2 = boto3.resource('ec2')
    ec2instance = ec2.Instance(fid)
    instancename = ''
    env = ''
    asg = ''
    if ec2instance :
        for tags in ec2instance.tags:
            if tags["Key"] == 'Name':
                instancename = tags["Value"]
            if tags["Key"] == 'Environment':
                env = tags["Value"]
            if tags["Key"] == 'aws:autoscaling:groupName':
                asg = tags["Value"]
    ec2_info = {}
    ec2_info.update({"instancename": instancename})
    ec2_info.update({"Environment": env})
    ec2_info.update({"groupName": asg})

    
    return ec2_info
#LAMBDA HANDLER RETURN

def iterate_regions(region,key,value,logger,env):
    region_arn_list = []
    try: #Local Account Resources
        request = local_client(region)
        region_arn_list.append(get_tagged_resources(request,key,value,logger,env))
    except Exception as e:
        logger.info('### EXCEPTION')
        logger.info(e)
    
    return region_arn_list

def get_tagged_resources(request,key,value,logger,env):
    response = request.get_resources(TagFilters=[
        {
            'Key': key,
            'Values': [
                value,
            ]
        }
    ])
    
    account_arn_list = []
    for item in response['ResourceTagMappingList']:
        account_arn_list.append(item['ResourceARN'].split(':'))
    return account_arn_list

def local_client(region):
    request = boto3.client(
        'resourcegroupstaggingapi',
        region_name=region
    )
    return request
    
    
def create_dashboard(title,dashboard_body):
    cloudwatch = boto3.client('cloudwatch')
    response = cloudwatch.put_dashboard(DashboardName=title, DashboardBody=dashboard_body)
    return response
    
def create_widgets(sorted_tagged_arn_list,widget_json,scafolding_json,logger,app,env):
    
    asg = f"{app}-{env}-cloudwatch"
    
    #ARN KEY MAPPING
    arn_keys = ['arn','segment','service','region','account','resource','item']
    # EC2
    
    header_json = {
            "height": 1,
            "width": 24,
            "type": "text",
            "properties": {
                "markdown": "# app1 App Instances"
            }
        }
    widget_json['widgets'].append(create_widget_text('app1',header_json))
    
    ec2_metric_dimensions = get_ec2_metric_dimensions(arn_keys,sorted_tagged_arn_list,logger)
    
    widget_json['widgets'].append(create_widget('EC2 CPU Utilization', scafolding_json, 'AWS/EC2',
                                                'CPUUtilization', 'InstanceId',ec2_metric_dimensions))
    widget_json['widgets'].append(create_widget('EC2 Network In', scafolding_json, 'AWS/EC2',
                                                'NetworkIn', 'InstanceId', ec2_metric_dimensions))
    widget_json['widgets'].append(create_widget('EC2 Network Out', scafolding_json, 'AWS/EC2',
                                                'NetworkOut', 'InstanceId', ec2_metric_dimensions))
    widget_json['widgets'].append(create_widget('EC2 Status Check', scafolding_json, 'AWS/EC2',
                                                'StatusCheckFailed', 'InstanceId', ec2_metric_dimensions))
                                                
    header_json = {
            "height": 1,
            "width": 24,
            "type": "text",
            "properties": {
                "markdown": "# RDS Instances"
            }
        }
        
    widget_json['widgets'].append(create_widget_text('app1',header_json))
    rds_metric_dimensions = get_rds_metric_dimensions(arn_keys,sorted_tagged_arn_list)
    
    widget_json['widgets'].append(create_widget('RDS CPU Utilization', scafolding_json, 'AWS/RDS',
                                                'CPUUtilization', 'DBInstanceIdentifier', rds_metric_dimensions))
    widget_json['widgets'].append(create_widget('RDS DB Connections', scafolding_json, 'AWS/RDS',
                                                'DatabaseConnections', 'DBInstanceIdentifier', rds_metric_dimensions))
    widget_json['widgets'].append(create_widget('RDS Read IOPS', scafolding_json, 'AWS/RDS',
                                                'ReadIOPS', 'DBInstanceIdentifier', rds_metric_dimensions))
    widget_json['widgets'].append(create_widget('RDS FreeableMemory', scafolding_json, 'AWS/RDS',
                                                'FreeableMemory', 'DBInstanceIdentifier', rds_metric_dimensions))
    widget_json['widgets'].append(create_widget('RDS Write IOPS', scafolding_json,'AWS/RDS',
                                                'WriteIOPS', 'DBInstanceIdentifier', rds_metric_dimensions))
    
    header_json = {
            "height": 1,
            "width": 24,
            "type": "text",
            "properties": {
                "markdown": "# Load Balancer Instances"
            }
        }
        
    widget_json['widgets'].append(create_widget_text('Traapp1kgene',header_json))
                                                
    nlb_metric_dimensions = get_nlb_metric_dimensions(arn_keys,sorted_tagged_arn_list)

    widget_json['widgets'].append(create_widget('NLB Consumed LCUs', scafolding_json, 'AWS/NetworkELB',
                                                'ConsumedLCUs', 'LoadBalancer', nlb_metric_dimensions))
    widget_json['widgets'].append(create_widget('NLB Processed Bytes', scafolding_json, 'AWS/NetworkELB',
                                                'ProcessedBytes', 'LoadBalancer', nlb_metric_dimensions))
    widget_json['widgets'].append(create_widget('NLB Active Flow Count', scafolding_json, 'AWS/NetworkELB',
                                                'ActiveFlowCount', 'LoadBalancer', nlb_metric_dimensions))
    widget_json['widgets'].append(create_widget('NLB New Flow Count', scafolding_json, 'AWS/NetworkELB',
                                                'NewFlowCount', 'LoadBalancer', nlb_metric_dimensions))
    widget_json['widgets'].append(create_widget('NLB TCP Client Reset Count', scafolding_json, 'AWS/NetworkELB',
                                                'TCP_Client_Reset_Count', 'LoadBalancer', nlb_metric_dimensions))
    
    return True
    
def create_widget(title, scaffolding_json, namespace, metric, metric_dimension_name, metric_dimensions):
    widget = copy.deepcopy(scaffolding_json)
    for metric_dimension in metric_dimensions:
        widget['properties']['metrics'].append([namespace, metric,
                                                metric_dimension_name, metric_dimension['id'] ,
                                                { "region": metric_dimension['region'], "accountId": metric_dimension['account']}])
    widget['properties']['title'] = title
    return widget

def create_widget_text(title, scaffolding_json):
    widget = copy.deepcopy(scaffolding_json)
    widget['properties']['title'] = title
    return widget

def create_mem_widget(title, scaffolding_json, namespace, metric, metric_dimension_name, metric_dimension, ec2_info):
    widget = copy.deepcopy(scaffolding_json)
#    for metric_dimension in metric_dimensions:
    widget['properties']['metrics'].append([namespace, metric, 
                                                metric_dimension_name, metric_dimension['id'], "AutoScalingGroupName", ec2_info['groupName'],
                                                "Environment", ec2_info['Environment'],
                                                { "region": metric_dimension['region'], "accountId": metric_dimension['account']}])
    widget['properties']['title'] = title
    return widget

def get_ec2_metric_dimensions(arn_keys,sorted_tagged_arn_list,logger):
    ec2_metric_dimensions = []
    for arn_item in sorted_tagged_arn_list:
        arn_item_value = dict(zip(arn_keys, arn_item))
        if arn_item_value['service'] == 'ec2':
            if arn_item_value['resource'].split('/')[0] == 'instance':
                resource = arn_item_value['resource'].split('/')[1]
                print(resource)
                ec2_metric_dimensions.append(dict(
                    id=resource,
                    region=arn_item_value['region'],
                    account=arn_item_value['account']
                ))
    return ec2_metric_dimensions

def get_rds_metric_dimensions(arn_keys,sorted_tagged_arn_list):
    rds_metric_dimensions = []
    for arn_item in sorted_tagged_arn_list:
        arn_item_value = dict(zip(arn_keys, arn_item))
        if arn_item_value['service'] == 'rds':
            if arn_item_value['resource'] == 'db':
                resource = arn_item_value['item']
                rds_metric_dimensions.append(dict(
                    id=resource,
                    region=arn_item_value['region'],
                    account=arn_item_value['account']
                ))
    return rds_metric_dimensions
    
    
def get_alb_metric_dimensions(arn_keys,sorted_tagged_arn_list):
    alb_metric_dimensions = []
    for arn_item in sorted_tagged_arn_list:
        arn_item_value = dict(zip(arn_keys, arn_item))
        if arn_item_value['service'] == 'elasticloadbalancing':
            if arn_item_value['resource'].split('/')[0] == 'loadbalancer':
                if arn_item_value['resource'].split('/')[1] == 'app':
                    resource = arn_item_value['resource'].split('/')[1] + '/' + arn_item_value['resource'].split('/')[2] + '/' + arn_item_value['resource'].split('/')[3] 
                    #resource = arn_item_value['resource'].split('/')[2]
                    alb_metric_dimensions.append(dict(
                        id=resource,
                        region=arn_item_value['region'],
                        account=arn_item_value['account']
                    ))
                    
    return alb_metric_dimensions

def get_nlb_metric_dimensions(arn_keys,sorted_tagged_arn_list):
    nlb_metric_dimensions = []
    for arn_item in sorted_tagged_arn_list:
        arn_item_value = dict(zip(arn_keys, arn_item))
        if arn_item_value['service'] == 'elasticloadbalancing':
            if arn_item_value['resource'].split('/')[0] == 'loadbalancer':
                if arn_item_value['resource'].split('/')[1] == 'net':
                    resource = arn_item_value['resource'].split('/')[1] + '/' + arn_item_value['resource'].split('/')[2] + '/' + arn_item_value['resource'].split('/')[3]
                    nlb_metric_dimensions.append(dict(
                        id=resource,
                        region=arn_item_value['region'],
                        account=arn_item_value['account']
                    ))
    return nlb_metric_dimensions

    
    
def sort_list(unsorted_tagged_arn_list):
    temp_list = []
    for arn_item_per_region in unsorted_tagged_arn_list:
        for arn_item_per_account in arn_item_per_region:
            for arn_item in arn_item_per_account:
                if arn_item:
                    temp_list.append(arn_item)
    return temp_list
