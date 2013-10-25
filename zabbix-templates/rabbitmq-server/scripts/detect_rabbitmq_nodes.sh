#!/bin/bash

#LIST_NODES=$(sudo /usr/sbin/rabbitmqctl cluster_status|sed -n '3p'| sed -n '/running_nodes,\[.*\]\},/p' | sed  -r 's/\[|\]|\{|\}|running_nodes,//g')

LIST_NODES=$(sudo -u root /usr/sbin/rabbitmqctl cluster_status|sed -n '2p'| grep -o 'running_nodes,\[.*\]\}' | sed -r 's/\[|\]|\{|\}|running_nodes,//g')

ARRAY_LIST_NODES=$(echo $LIST_NODES | tr "," "\n"| tr "\'" "\ ")
FIRST_ELEMENT=1
type_detect=0

function json_head {
    printf "{"
    printf "\"data\":["
}

function json_end {
    printf "]"
    printf "}"
}

function check_first_element {
    if [[ $FIRST_ELEMENT -ne 1 ]]; then
        printf ","
    fi
    FIRST_ELEMENT=0
}

function nodes_detect {
    json_head
    for node in $ARRAY_LIST_NODES
    do
       local VHOST_LIST=$(sudo /usr/sbin/rabbitmqctl -n ${node} list_vhosts|sed '1d'|sed '/...done./d')
       for vhost in  $VHOST_LIST
       do
           local vhost_t=$(echo $vhost| sed 's!/!\\/!g')  
           local node_t=$(echo $node| sed 's!@!__dog__!g') 
           #only nodes
           if [[ $type_detect -eq 0 ]]; then
               check_first_element
               printf "{"
               printf "\"{#NODENAME}\":\"$node_t\", \"{#VHOSTNAME}\":\"$vhost_t\""
               printf "}"
           fi  
           #queue  
           if [[ $type_detect -eq 1 ]]; then
               local list_queue=$(sudo /usr/sbin/rabbitmqctl -n ${node} -p ${vhost} list_queues | sed '1d'|sed '/...done./d'|awk '{print $1}')
               for queue in  $list_queue
               do
                   check_first_element
                   printf "{"
                   printf "\"{#NODENAME}\":\"$node_t\", \"{#VHOSTNAME}\":\"$vhost_t\", \"{#QUEUENAME}\":\"$queue\" "
                   printf "}"
               done
           fi
           #exchanges
           if [[ $type_detect -eq 2 ]]; then
               local list_exchange=$(sudo /usr/sbin/rabbitmqctl -n ${node} -p ${vhost} list_exchanges | sed '1d'|sed '/...done./d'|awk '{print $1}')
               for exchange in  $list_exchange
               do
                   check_first_element
                   printf "{"
                   printf "\"{#NODENAME}\":\"$node_t\", \"{#VHOSTNAME}\":\"$vhost_t\", \"{#EXCHANGENAME}\":\"$exchange\" "
                   printf "}"
               done
           fi
       done
    done
    json_end
}

case $1 in
    queue)
        type_detect=1
        nodes_detect
        ;;
    exchange)
        type_detect=2
        nodes_detect
        ;;
    *)
        type_detect=0
        nodes_detect
        ;;
esac