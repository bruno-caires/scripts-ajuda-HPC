#!/bin/bash
#ativar-net.sh - Libera acesso a internet para os nodes de processamento via nat
#Bruno L. Amadio Caires -  bruno @ ft.unicamp.br 2013
modprobe iptable_nat
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
