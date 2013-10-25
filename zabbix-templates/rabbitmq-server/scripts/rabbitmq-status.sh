#!/bin/bash
#UserParameter=rabbitmq[*],<%= zabbix_script_dir %>/rabbitmq-status.sh

NODE=$(echo $1| sed 's!__dog__!@!g')
VHOST=$2
METRIC=$3
ITEM=$4

#rabbitmq[rabbit,\/,list_queues,none]
if [ "$METRIC" = "list_queues" ]; then
    sudo /usr/sbin/rabbitmqctl -n $NODE -p $VHOST list_queues | grep -cv '\.\.\.'
fi

#rabbitmq[rabbit,\/,list_exchanges,none]
if [ "$METRIC" = "list_exchanges" ]; then
    sudo /usr/sbin/rabbitmqctl -n $NODE -p $VHOST list_exchanges | grep -cv '\.\.\.'
fi

#rabbitmq[rabbit,\/,queue_durable,queue-name]
if [ "$METRIC" = "queue_durable" ]; then
    sudo /usr/sbin/rabbitmqctl -n $NODE -p $VHOST list_queues name durable | grep "^$ITEM\s.*$" | awk '{ print $2 }'
fi

#rabbitmq[rabbit,\/,queue_msg_ready,queue-name]
if [ "$METRIC" = "queue_msg_ready" ]; then
    sudo /usr/sbin/rabbitmqctl -n $NODE -p $VHOST list_queues name messages_ready | grep "^$ITEM\s.*$" | awk '{ print $2 }'
fi

#rabbitmq[rabbit,\/,queue_msg_unackd,queue-name]
if [ "$METRIC" = "queue_msg_unackd" ]; then
    sudo /usr/sbin/rabbitmqctl -n $NODE -p $VHOST list_queues name messages_unacknowledged | grep "^$ITEM\s.*$" | awk '{ print $2 }'
fi

#rabbitmq[rabbit,\/,queue_msgs,queue-name]
if [ "$METRIC" = "queue_msgs" ]; then
    sudo /usr/sbin/rabbitmqctl -n $NODE -p $VHOST list_queues name messages | grep "^$ITEM\s.*$" | awk '{ print $2 }'
fi

#rabbitmq[rabbit,\/,queue_consumers,queue-name]
if [ "$METRIC" = "queue_consumers" ]; then
    sudo /usr/sbin/rabbitmqctl -n $NODE -p $VHOST list_queues name consumers | grep "^$ITEM\s.*$" | awk '{ print $2 }'
fi

#rabbitmq[rabbit,\/,queue_memory,queue-name]
if [ "$METRIC" = "queue_memory" ]; then
    sudo /usr/sbin/rabbitmqctl -n $NODE -p $VHOST list_queues name memory | grep "^$ITEM\s.*$" | awk '{ print $2 }'
fi

#rabbitmq[rabbit,\/,exchange_durable,exchange-name]
if [ "$METRIC" = "exchange_durable" ]; then
    sudo /usr/sbin/rabbitmqctl -n $NODE -p $VHOST list_exchanges name durable | grep "^$ITEM\s.*$" | awk '{ print $2 }'
fi

#rabbitmq[rabbit,\/,exchange_type,exchange-name]
if [ "$METRIC" = "exchange_type" ]; then
    sudo /usr/sbin/rabbitmqctl -n $NODE -p $VHOST list_exchanges name type | grep "^$ITEM\s.*$" | awk '{ print $2 }'
fi


