#!/bin/bash
#by alexmod80
#repo:golden
declare -A cor=( [0]="\033[33m" [1]="\033[33m" [2]="\033[33m" [3]="\033[33m" [4]="\033[33m" )
barra="\033[0m\e[33m======================================================\033[1;37m"
id=$1
SCPfrm="/etc/ger-frm" && [[ ! -d ${SCPfrm} ]] && exit
SCPinst="/etc/ger-inst" && [[ ! -d ${SCPinst} ]] && exit
BadVPN () {
pid_badvpn=$(ps x | grep badvpn | grep -v grep | awk '{print $1}')
if [ "$pid_badvpn" = "" ]; then
    echo -e "${cor[5]} $(fun_trans ${id} "Liberando Badvpn")"
    echo -e "${barra}"
    if [[ ! -e /bin/badvpn-udpgw ]]; then
    wget -O /bin/badvpn-udpgw https://raw.githubusercontent.com/scriptsmx/herramientas/master/BadUDP/badvpn-udpgw &>/dev/null
    chmod +x /bin/badvpn-udpgw
    fi
    screen -dmS screen /bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 50
    [[ "$(ps x | grep badvpn | grep -v grep | awk '{print $1}')" ]] && echo -e "${cor[5]} $(fun_trans ${id} "Activado")" || echo -e "${cor[5]} $(fun_trans ${id} "Falla al Instalar")"
else
    echo -e "${cor[5]} $(fun_trans ${id} "deteniendo Badvpn")"
    echo -e "${barra}"
    kill -9 $(ps x | grep badvpn | grep -v grep | awk '{print $1'}) > /dev/null 2>&1
    killall badvpn-udpgw > /dev/null 2>&1
    [[ ! "$(ps x | grep badvpn | grep -v grep | awk '{print $1}')" ]] && echo -e "${cor[4]} detenido con exito"
    unset pid_badvpn
    fi
unset pid_badvpn
}
TCPspeed () {
if [[ `grep -c "^#ADMIN" /etc/sysctl.conf` -eq 0 ]]; then
#INSTALA
echo -e "${cor[5]} $(fun_trans ${id} "TCP Speed No Activado, Desea Activar Ahora")?"
echo -e "${barra}"
while [[ ${resposta} != @(s|S|n|N|y|Y) ]]; do
read -p " [S/N]: " -e -i s resposta
tput cuu1 && tput dl1
done
[[ "$resposta" = @(s|S|y|Y) ]] && {
echo "#ADMIN" >> /etc/sysctl.conf
echo "net.ipv4.tcp_window_scaling = 1
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 16384 16777216
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_slow_start_after_idle = 0" >> /etc/sysctl.conf
sysctl -p /etc/sysctl.conf > /dev/null 2>&1
echo -e "${cor[5]} $(fun_trans ${id} "TCP Activo Con Exito")!"
} || echo -e "${cor[5]} $(fun_trans ${id} "Cancelado")!"
 else
#REMOVE
echo -e "${cor[5]} $(fun_trans ${id} "TCP Speed ya Activado, Desea Parar Ahora")?"
echo -e "${barra}"
while [[ ${resposta} != @(s|S|n|N|y|Y) ]]; do
read -p " [S/N]: " -e -i s resposta
tput cuu1 && tput dl1
done
[[ "$resposta" = @(s|S|y|Y) ]] && {
grep -v "^#ADMIN
net.ipv4.tcp_window_scaling = 1
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 16384 16777216
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_slow_start_after_idle = 0" /etc/sysctl.conf > /tmp/syscl && mv -f /tmp/syscl /etc/sysctl.conf
sysctl -p /etc/sysctl.conf > /dev/null 2>&1
echo -e "${cor[5]} $(fun_trans ${id} "TCP Parado Con exito")!"
} || echo -e "${cor[5]} $(fun_trans ${id} "Cancelado")!"
fi
}
SquidCACHE () {
echo -e "${cor[5]} $(fun_trans ${id} "Squid Cache, Aplicar cache en el squid")"
echo -e "${cor[5]} $(fun_trans ${id} "mejora la velocidad del squid")"
echo -e "${barra}"
if [ -e /etc/squid/squid.conf ]; then
squid_var="/etc/squid/squid.conf"
elif [ -e /etc/squid3/squid.conf ]; then
squid_var="/etc/squid3/squid.conf"
else
echo -e "${cor[5]} $(fun_trans ${id} "Su sistema no posee un squid")!" && return 1
fi
teste_cache="#CACHE DO SQUID"
if [[ `grep -c "^$teste_cache" $squid_var` -gt 0 ]]; then
  [[ -e ${squid_var}.bakk ]] && {
  echo -e "${cor[5]} $(fun_trans ${id} "Cache squid identificado, removiendo")!"
  mv -f ${squid_var}.bakk $squid_var
  echo -e "${cor[5]} $(fun_trans ${id} "cache squid removido")!"
  service squid restart > /dev/null 2>&1 &
  service squid3 restart > /dev/null 2>&1 &
  return 0
  }
fi
echo -e "${cor[5]} $(fun_trans ${id} "Aplicando Cache Squid")!"
echo -e "${barra}"
_tmp="#CACHE DO SQUID\ncache_mem 200 MB\nmaximum_object_size_in_memory 32 KB\nmaximum_object_size 1024 MB\nminimum_object_size 0 KB\ncache_swap_low 90\ncache_swap_high 95"
[[ "$squid_var" = "/etc/squid/squid.conf" ]] && _tmp+="\ncache_dir ufs /var/spool/squid 100 16 256\naccess_log /var/log/squid/access.log squid" || _tmp+="\ncache_dir ufs /var/spool/squid3 100 16 256\naccess_log /var/log/squid3/access.log squid"
while read s_squid; do
[[ "$s_squid" != "cache deny all" ]] && _tmp+="\n${s_squid}"
done < $squid_var
cp ${squid_var} ${squid_var}.bakk
echo -e "${_tmp}" > $squid_var
echo -e "${cor[5]} $(fun_trans ${id} "Cache Aplicado Con Sucesso")!"
service squid restart > /dev/null 2>&1 &
service squid3 restart > /dev/null 2>&1 &
}
block_torrent () {
mportas () {
unset portas
portas_var=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND" | grep "LISTEN")
while read port; do
var1=$(echo $port | awk '{print $1}') && var2=$(echo $port | awk '{print $9}' | awk -F ":" '{print $2}')
[[ "$(echo -e $portas|grep "$var1 $var2")" ]] || portas+="$var1 $var2\n"
done <<< "$portas_var"
i=1
echo -e "$portas"
}
fun_ip () {
if [[ -e /etc/MEUIPADM ]]; then
IP="$(cat /etc/MEUIPADM)"
else
MEU_IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
MEU_IP2=$(wget -qO- ipv4.icanhazip.com)
[[ "$MEU_IP" != "$MEU_IP2" ]] && IP="$MEU_IP2" || IP="$MEU_IP"
echo "$MEU_IP2" > /etc/MEUIPADM
fi
}
[[ $(iptables -h|wc -l) -lt 5 ]] && apt-get install iptables -y > /dev/null 2>-1
NIC=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
echo -e "$(fun_trans ${id} "Esas configuraciones se Deven ser adicionadas")"
echo -e "$(fun_trans ${id} "la vps deve estar totalmente configurada!")\n$barra"
echo -e "$(fun_trans ${id} "Deseja Seguir?")"
read -p " [S/N]: " -e -i n PROS
[[ $PROS = @(s|S|y|Y) ]] || return 1
fun_ip #Pega IP e armazena em uma variavel
#Inicia Procedimentos
#Parametros iniciais
echo 'iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -t filter -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT' > ./torrent-adm
chmod +x ./torrent-adm
#libera DNS
echo 'iptables -A OUTPUT -p tcp --dport 53 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -p udp --dport 53 -m state --state NEW -j ACCEPT' >> ./torrent-adm
#Liberar DHCP
echo 'iptables -A OUTPUT -p tcp --dport 67 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -p udp --dport 67 -m state --state NEW -j ACCEPT' >> ./torrent-adm
#Liberando Servi�os Ativos
list_ips=$(mportas|awk '{print $2}')
while read PORT; do
echo "iptables -A INPUT -p tcp --dport $PORT -j ACCEPT
iptables -A INPUT -p udp --dport $PORT -j ACCEPT
iptables -A OUTPUT -p tcp --dport $PORT -j ACCEPT
iptables -A OUTPUT -p udp --dport $PORT -j ACCEPT
iptables -A FORWARD -p tcp --dport $PORT -j ACCEPT
iptables -A FORWARD -p udp --dport $PORT -j ACCEPT
iptables -A OUTPUT -p tcp -d $IP --dport $PORT -m state --state NEW -j ACCEPT
iptables -A OUTPUT -p udp -d $IP --dport $PORT -m state --state NEW -j ACCEPT" >> ./torrent-adm
done <<< "$list_ips"
#Bloqueando Ping
echo 'iptables -A INPUT -p icmp --icmp-type echo-request -j DROP' >> ./torrent-adm
#Liberar WEBMIN
echo 'iptables -A INPUT -p tcp --dport 10000 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 10000 -j ACCEPT' >> ./torrent-adm
#Bloqueando torrent
echo "iptables -t nat -A PREROUTING -i $NIC -p tcp --dport 6881:6889 -j DNAT --to-dest $IP
iptables -A FORWARD -p tcp -i $NIC --dport 6881:6889 -d $IP -j REJECT
iptables -A OUTPUT -p tcp --dport 6881:6889 -j DROP
iptables -A OUTPUT -p udp --dport 6881:6889 -j DROP" >> ./torrent-adm
echo 'iptables -A FORWARD -m string --algo bm --string "BitTorrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP
iptables -A FORWARD -m string --algo bm --string "peer_id=" -j DROP
iptables -A FORWARD -m string --algo bm --string ".torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce.php?passkey=" -j DROP
iptables -A FORWARD -m string --algo bm --string "torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce" -j DROP
iptables -A FORWARD -m string --algo bm --string "info_hash" -j DROP
iptables -A FORWARD -m string --string "get_peers" --algo bm -j DROP
iptables -A FORWARD -m string --string "announce_peer" --algo bm -j DROP
iptables -A FORWARD -m string --string "find_node" --algo bm -j DROP' >> ./torrent-adm
./torrent-adm && rm ./torrent-adm
echo -e "$barra\n $(fun_trans ${id} "Aplicado!")"
}
on="\033[1;32m(ON)"
off="\033[1;31m(OFF)"
[[ $(ps x | grep badvpn | grep -v grep | awk '{print $1}') ]] && badvpn=$on || badvpn=$off
[[ `grep -c "^#ADMIN" /etc/sysctl.conf` -eq 0 ]] && tcp=$off || tcp=$on
if [ -e /etc/squid/squid.conf ]; then
[[ `grep -c "^#CACHE DO SQUID" /etc/squid/squid.conf` -gt 0 ]] && squid=$on || squid=$off
elif [ -e /etc/squid3/squid.conf ]; then
[[ `grep -c "^#CACHE DO SQUID" /etc/squid3/squid.conf` -gt 0 ]] && squid=$on || squid=$off
fi
echo -e "${cor[5]} $(fun_trans ${id} "MENU DE UTILIDADES")"
echo -e "$barra"
echo -e "${cor[4]} [1] >\033[33m $(fun_trans ${id} "BADVPN") $badvpn"
echo -e "${cor[4]} [2] >\033[33m $(fun_trans ${id} "TCP-SPEED") $tcp"
echo -e "${cor[4]} [3] >\033[33m $(fun_trans ${id} "CACHE PARA SQUID") $squid"
echo -e "${cor[4]} [4] >\033[33m $(fun_trans ${id} "BLOQUEAR TORRENT")"
echo -e "${cor[4]} [0] >\033[33m $(fun_trans ${id} "VOLVER")"
echo -e "$barra"
while [[ ${arquivoonlineadm} != @(0|[1-4]) ]]; do
read -p "[0-4]: " arquivoonlineadm
tput cuu1 && tput dl1
done
case $arquivoonlineadm in
1)BadVPN;;
2)TCPspeed;;
3)SquidCACHE;;
4)block_torrent;;
0)exit;;
esac
echo -e "$barra"