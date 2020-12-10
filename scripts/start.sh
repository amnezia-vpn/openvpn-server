#!/bin/bash

source ./functions.sh

mkdir -p /dev/net

if [ ! -c /dev/net/tun ]; then
    echo "$(datef) Creating tun/tap device."
    mknod /dev/net/tun c 10 200
fi

# Allow UDP traffic on port 1194.
iptables -A INPUT -i eth0 -p udp -m state --state NEW,ESTABLISHED --dport 1194 -j ACCEPT
iptables -A OUTPUT -o eth0 -p udp -m state --state ESTABLISHED --sport 1194 -j ACCEPT

# Allow traffic on the TUN interface.
iptables -A INPUT -i tun0 -j ACCEPT
iptables -A FORWARD -i tun0 -j ACCEPT
iptables -A OUTPUT -o tun0 -j ACCEPT

# Allow forwarding traffic only from the VPN.
iptables -A FORWARD -i tun0 -o eth0 -s 10.8.0.0/24 -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

LOCKFILE=.gen

# Regenerate certs only on the first start 
if [ ! -f $LOCKFILE ]; then

  cd ${APP_INSTALL_PATH}
  cp config/server.conf /etc/openvpn/server.conf

  mkdir -p ${APP_PERSIST_DIR}
  cd ${APP_PERSIST_DIR}

  #Initialize pki and generate dh file
  easyrsa init-pki
  easyrsa gen-dh

  # DH parameters of size 2048 created at /usr/share/easy-rsa/pki/dh.pem
  # Copy DH file
  cp pki/dh.pem /etc/openvpn
  easyrsa build-ca nopass << EOF

EOF
    # CA creation complete and you may now import and sign cert requests.
    # Your new CA certificate file for publishing is at:
    # /opt/Dockovpn_data/pki/ca.crt

  easyrsa gen-req MyReq nopass << EOF2

EOF2
    # Keypair and certificate request completed. Your files are:
    # req: /opt/Dockovpn_data/pki/reqs/MyReq.req
    # key: /opt/Dockovpn_data/pki/private/MyReq.key

  easyrsa sign-req server MyReq << EOF3
yes
EOF3
    # Certificate created at: /opt/Dockovpn_data/pki/issued/MyReq.crt

  openvpn --genkey --secret ta.key << EOF4
yes
EOF4

  touch $LOCKFILE
fi

# Copy server keys and certificates
cp pki/ca.crt pki/issued/MyReq.crt pki/private/MyReq.key ta.key /etc/openvpn

cd "$APP_INSTALL_PATH"

# Need to feed key password
openvpn --config /etc/openvpn/server.conf &

# By some strange reason we need to do echo command to get to the next command
echo " "

tail -f /dev/null
