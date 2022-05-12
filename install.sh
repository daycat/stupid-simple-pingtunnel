#!/bin/bash
 
blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}
yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}

get_latest_release() {
  version=`curl --silent "https://api.github.com/repos/esrrhs/pingtunnel/releases/latest" | 
    grep '"tag_name":' |                                           
    sed -E 's/.*"([^"]+)".*/\1/' `    
  echo Latest version: $version
  firewall_config               
}


firewall_config(){
    echo
    iptables -A INPUT -p icmp -j ACCEPT
    bash -c "iptables-save > /etc/iptables/rules.v4"
    yellow "ICMP traffic is now enabled through iptables"
    echo
    green "if no other firewalls are present, then you should now be able to send ICMP traffic to this server."
    download_pt
}


success(){

    echo
    green "===================================================="
    green " Installation of pingtunnel has succedded"
    green " You may wish to control pingtunnel via systemctl:"
    green " stop:       systemctl stop pingtunnel"
    green " start:      systemctl start pingtunnel"
    green " restart:    systemctl restart pingtunnel"
    echo "  Blog: https://daycat.space"
    green "===================================================="
}


download_pt(){
    echo
    green "Downloading PingTunnel"
    sleep 1
    case $(uname -m) in
      "x86_64" ) platform='linux_amd64'
        ;;
      "i686" ) platform='linux_386'
        ;;
      "aarch64" ) platform='linux_arm64'
        ;;
      "s390x" ) platform='linux_s390x'
        ;;
      "armv5l" ) platform='linux_arm'
        ;;
      "armv6l" ) platform='linux_arm'
        ;;
      "armv7l" ) platform='linux_arm'
        ;;
      *)
        red "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
        red "  You are running an unsupported system"
        red "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
        exit 1
        ;;
    esac

    url='https://github.com/esrrhs/pingtunnel/releases/download/'$version'/pingtunnel_'$platform'.zip'
    wget $url
    unzip pingtunnel_$platform.zip
    chmod +x pingtunnel
    mv pingtunnel /usr/bin/pingtunnel

    cat > /etc/systemd/system/pingtunnel.service<<-EOF
    [Unit]
    Description=A flexible ICMP tunnel for proxying network traffic
    After=network.target
    StartLimitIntervalSec=10

    [Service]
    Type=simple
    Restart=always
    RestartSec=1
    User=root
    ExecStart=/usr/bin/pingtunnel -type server
    Restart=on-failure

    [Install]
    WantedBy=multi-user.target
EOF
    systemctl start pingtunnel
    success
}



uninstall_pc(){
    systemctl stop pingtunnel.service
    rm -fr /usr/bin/pingtunnel
    rm -fr /etc/systemd/system/pingtunnel.service
    green "Uninstall complete"
    exit 0
}

start_menu(){
    clear
    green "====================================================="
    green " Simple PingTunnel installation on Debian systems"
    echo " 

    .___                                  __   
  __| _/_____    ___.__.  ____  _____   _/  |_ 
 / __ | \__  \  <   |  |_/ ___\ \__  \  \   __\ 
/ /_/ |  / __ \_ \___  |\  \___  / __ \_ |  |  
\____ | (____  / / ____| \___  >(____  / |__|  
     \/      \/  \/          \/      \/        

"
    green " This script is first published on:"
    green " https://github.com/daycat/stupid-simple-pingtunnel"
    green "====================================================="
    green "1. Install pingtunnel"
    green "2. Uninstall pingtunnel"
    yellow "0. Quit"
    echo
    read -p "Please select an option:" num
    case "$num" in
    1)
    get_latest_release
    ;;
    2)
    uninstall_pc
    ;;
    0)
    exit 1
    ;;
    *)
    clear
    echo "Invalid option!"
    sleep 2s
    start_menu
    ;;
    esac
}

start_menu