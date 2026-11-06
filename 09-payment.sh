#!/bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"
domain_name="paleminvest.online"
script_dir=$(dirname "$(realpath "$0")")
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

dnf install python3.14 python3.14-pip -y &>>$logs_file
validate $? "Installing Python 3.14"

id roboshop &>>$logs_file
if  [ $? -ne 0 ]; then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$logs_file
    validate $? "Creating system user"
else
    echo -e "System user roboshop already exist ...${Y} Skipping${N}"
fi

rm -rf /app
validate $? "Removing  old code"

mkdir -p /app
validate $? "Creating App Directory"

curl -L -o /tmp/payment.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/payment-v4.zip &>>$logs_file
validate $? "Downloading payment"

cd /app
unzip /tmp/payment.zip &>>$logs_file
validate $? "Unzipping payment"

cd /app
python3.14 -m venv /app/.venv
validate $? "Creating Virtual environment"

/app/.venv/bin/pip install -r requirements.txt &>>$logs_file
validate $? "Installing dependencies"

sed -i "s/DOMAIN_NAME/$domain_name/g" "$script_dir/payment.service"
cp "$script_dir/payment.service" /etc/systemd/system/payment.service

systemctl daemon-reload &>>$logs_file
systemctl enable payment &>>$logs_file
systemctl restart payment &>>$logs_file
validate $? "Start/Restart and enabling payment"

