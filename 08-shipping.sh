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

dnf module enable maven:3.9 -y &>>$logs_file
dnf install maven java-25-openjdk-devel -y &>>$logs_file
validate $? "Installing Java and Maven"

alternatives --set java "/usr/lib/jvm/java-25-openjdk/bin/java"
validate $? "Setting java 25 as default java version"

echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f /usr/bin/java)))" > /etc/profile.d/java.sh
source /etc/profile.d/java.sh
echo $JAVA_HOME
validate $? "Setting Java home for Maven"


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

curl -L -o /tmp/shipping.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/shipping-v4.zip &>>$logs_file
validate $? "Downloading shipping"

cd /app
unzip /tmp/shipping.zip &>>$logs_file
validate $? "Unzipping shipping"

mvn clean package &>>$logs_file
validate $? "Installing dependencies"

mv target/shipping.jar shipping.jar
validate $? "Moving shipping.jar"

sed -i "s/DOMAIN_NAME/$domain_name/g" "$script_dir/shipping.service"
cp "$script_dir/shipping.service" /etc/systemd/system/shipping.service

dnf install mysql -y &>>$logs_file
validate $? "Installing Mysql client"

count=$(mysql -h "mysql.$domain_name" -uroot -pRoboShop@1 -N -B -e "SELECT count(*) FROM cities.cities;" 2>>$logs_file)
if [ -z "$count" ] || [$count -eq 0 ]; then 
    mysql -h "mysql.$domain_name" -uroot -pRoboShop@1 < /app/db/master-data.sql
    validate $? "Loading shipping data"
else
   echo -e "$(timestamp) [INFO] Master data Already loaded...${Y} Skipping${N}"
fi

mysql -h "mysql.$domain_name" -uroot -pRoboShop@1 < /app/db/app-user.sql
validate $? "Creating App User"

systemctl daemon-reload &>>$logs_file
systemctl enable shipping &>>$logs_file
systemctl start shipping &>>$logs_file
validate $? "Start and enabling shipping"

systemctl restart shipping
validate $? "Restart shipping" 


