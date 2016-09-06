#!/bin/bash

# 
# docker-createvps db-gtm.dc 172.30.1.10 tpl-pgxl-gtm /bin/bash
# 

vpsname=$1
vpsip=$2
vpsimage=$3
vpscommand=$4
companydomain="vivasent.com"

# Создаем контейнер без сети:
docker run -itd --name $vpsname --net=none -h ${vpsname}.${companydomain}  $vpsimage $vpscommand

# Создаем Net NameSpace:
#hostif="vth${vpsname}"
hostif="vth`echo $vpsip|sed 's/172.30//'`"
#vpsif="vtc${vpsname}"
vpsif="vtc`echo $vpsip|sed 's/172.30//'`"

vpspid=`docker inspect -f '{{ .State.Pid }}' $vpsname`
mkdir -p /var/run/netns
ln -s /proc/$vpspid/ns/net /var/run/netns/$vpspid


# Создаем линк для контейнера:
ip link add $hostif type veth peer name $vpsif
ip link set $hostif up

# Подключаем линк в свич и в контейнер:
ovs-vsctl add-port ovs.sw-VMs $hostif
ip link set $vpsif netns $vpspid

# В контейнере переименовываем, поднимаем и настраиваем линк:    
ip netns exec $vpspid ip link set dev $vpsif name eth0
ip netns exec $vpspid ip link set dev eth0 up

  #ip netns exec $vpspid ip link set eth0 address 12:34:56:78:9a:bc
ip netns exec $vpspid ip addr add ${vpsip}/16 dev eth0
ip netns exec $vpspid ip route add default via 172.30.0.1


