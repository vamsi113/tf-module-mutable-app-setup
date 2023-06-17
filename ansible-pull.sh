#!/bin/bash
LOG=/opt/user-data-$$.log

yum install python39-devel -y &>>$LOG
pip3.9 install ansible botocore boto3 python-jenkins &>>$LOG
ansible-pull -i localhost, -U https://github.com/vamsi113/roboshop-ansible.git roboshop.yml -e ROLE_NAME=${COMPONENT} -e ENV=${ENV} &>>$LOG

