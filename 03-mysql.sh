#!/bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $user_id -ne 0 ]; then
    echo "Please run this script with sudo access"
    exit 1
fi
mkdir -p $logs_folder
timestamp()
{
    date +"%F %T"
}
validate(){
    if [ $? -ne 0 ]; then
        echo -e "$(timestamp) [ERROR] ${2} ${R}Failed${N}"  | tee -a $logs_file
    else
        echo -e "$(timestamp) [INFO] ${2} ${G}Success${N}" | tee -a $logs_file
    fi
}

echo "$(timestamp) [INFO] === Script started Execution ===" | tee -a $logs_file
dnf module enable mysql:8.4 -y &>>$logs_file
dnf install mysql-server -y &>>$logs_file
validate $? "Installing mysql server"

systemctl enable mysqld &>>$logs_file
systemctl start mysqld &>>$logs_file
validate $? " Start and enable MySQL"

mysql_secure_installation --set-root-pass RoboShop@1
validate $? "Set up MySQL root password"