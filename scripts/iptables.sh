yum install --assumeyes iptables-services >> $LOG

message "Adding rules in iptables file"

if
    grep --silent CHEMINFO /etc/sysconfig/iptables
then
    ok
    info "The service was already configured and CHEMINFO is in the file"
else
    if
        [ ! -z "$SSH_ACCESS" ]
    then
        DATA="";
        for IP in $SSH_ACCESS; do
            DATA=$DATA"-A INPUT -s $IP -p tcp -m tcp --dport 22 -j ACCEPT\\n"
        done
    else
        DATA="-A INPUT -p tcp --dport 22 -j ACCEPT\\n"
    fi
    IPTABLES=`cat ../configs/iptables | sed ':a;N;$!ba;s/\n/\\\\n/g'`
    DATA="$DATA\\n$IPTABLES\\n"


    if
        sed -i.bcp "/--dport 22/c$DATA" /etc/sysconfig/iptables
    then
        ok
        info "Rules where added in iptables"
	if
		[ $REDHAT_RELEASE -eq 7 ]
	then
        	systemctl mask firewalld >> $LOG
		systemctl enable iptables >> $LOG
		systemctl stop firewalld.service >> $LOG
	else
		service iptables stop >> $LOG
		chkconfig iptables on >> $LOG
	fi

        echo "options xt_recent ip_list_tot=4000 ip_pkt_list_tot=20" >> /etc/modprobe.d/options.conf
        modprobe -r xt_recent
        modprobe xt_recent 
	if
		[ $REDHAT_RELEASE -eq 7 ]
	then
        	systemctl start iptables.service >> $LOG
	else
		service iptables start >> $LOG
	fi
    else
        error
        info "Could not add rules in the iptables file"
    fi
fi
