#! /bin/bash
yum install sshpass -y  > /dev/null 2>&1
csf -ta 10.10.10.10 7200 > /dev/null 2>&1
echo -e "Did you whitelist ip in the backup server \nIf you have already done then enter \e[1;31m yes \e[0m \nIf it's not done, Please whitelist ip in backup server"
read csf
if [ $csf == 'yes' ]
then

    echo "Provide root password of backup server 10.10.10.10"
    read password
    echo "Provide domain name"
    read domain
    cat /etc/trueuserdomains > /dev/null 2>&1
    cpanel=$?

    if [ $cpanel -eq 0 ]
    # CPANEL ###########################

        if [[ $( cat /etc/trueuserdomains | grep $domain | awk '{print $2}' | wc -c ) -ne 0 ]]
        then      
                account=$( cat /etc/trueuserdomains | grep $domain | awk '{print $2}' )
                echo " ## Compressing domain data, please wait it take time ## "
                if /scripts/pkgacct $account | grep -q 'pkgacct completed'
                then
                        cd /backup
                        mkdir $domain 2>/dev/null
                        mv -f /home/cpmove-$account.tar.gz /backup/$domain
                        cd /backup/logbackup/
			tar cvzf $account-domlog.tar.gz domlog/$domain* > /dev/null 2>&1                        
                        mv -f $account-domlog.tar.gz /backup/$domain
                        echo -e "Enter 1 if domain is based on Merchant \nEnter 2 if the domain is based on C1"
                        read merchantc1
                        echo " ## copying data to remote server, please wait it take time ## "
                        if [ $merchantc1 == '1' ]
                        then
                            sshpass -p "$password" scp -P 25 -o StrictHostKeyChecking=no -r /backup/$domain  root@10.10.10.10:/BACKUP/Merchant-Domains
                            echo " ## Backup size in backup server ## "
                            sshpass -p "$password" ssh -p 25 -o StrictHostKeyChecking=no root@10.10.10.10 du -h /BACKUP/Merchant-Domains/$domain/* 
                            rm -rf /backup/$domain
                        elif [ $merchantc1 == '2' ]
                        then 
                            sshpass -p "$password" scp -P 25 -o StrictHostKeyChecking=no -r /backup/$domain  root@10.10.10.10:/BACKUP/C1-Domain-fullback
                            echo " ## Backup size in backup server ## "
                            sshpass -p "$password" ssh -p 25 -o StrictHostKeyChecking=no root@10.10.10.10 du -h /BACKUP/C1-Domain-fullback/$domain/*
                            rm -rf /backup/$domain
                        else
                            echo "wrong input"
                        fi
                else
                        echo "Issue faced when generating backup"
                fi

        else
            echo "Wrong Domain"
        fi

    fi
else
    echo "Wrong input"
fi
