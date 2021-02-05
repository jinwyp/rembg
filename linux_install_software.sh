#!/bin/bash

export LC_ALL=C
export LANG=C
export LANGUAGE=en_US.UTF-8


# fonts color
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}
blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
bold(){
    echo -e "\033[1m\033[01m$1\033[0m"
}



sudoCommand=""


if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  sudoCommand="sudo"
fi


osReleaseVersion=""
osRelease=""
osSystemPackage=""
osSystemMdPath=""
osSystemShell="bash"

# 系统检测版本
function getLinuxOSVersion(){
    # copy from 秋水逸冰 ss scripts
    if [[ -f /etc/redhat-release ]]; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemMdPath="/usr/lib/systemd/system/"
    elif cat /etc/issue | grep -Eqi "debian"; then
        osRelease="debian"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        osRelease="ubuntu"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemMdPath="/usr/lib/systemd/system/"
    elif cat /proc/version | grep -Eqi "debian"; then
        osRelease="debian"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        osRelease="ubuntu"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemMdPath="/usr/lib/systemd/system/"
    fi


	if [[ -s /etc/redhat-release ]]; then
		grep -oE  "[0-9.]+" /etc/redhat-release
        osReleaseVersion=$(cat /etc/redhat-release | tr -dc '0-9.'|cut -d \. -f1)
	else
		grep -oE  "[0-9.]+" /etc/issue
        osReleaseVersion=$(cat /etc/issue | tr -dc '0-9.'|cut -d \. -f1)
	fi


    [[ -z $(echo $SHELL|grep zsh) ]] && osSystemShell="bash" || osSystemShell="zsh"

    echo "OS info: ${osRelease}, ${osReleaseVersion}, ${osSystemPackage}, ${osSystemMdPath}， ${osSystemShell}"
}


osPort80=""
osPort443=""
osSELINUXCheck=""
osSELINUXCheckIsRebootInput=""

function testLinuxPortUsage(){
    $osSystemPackage -y install net-tools socat

    osPort80=`netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 80`
    osPort443=`netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 443`

    if [ -n "$osPort80" ]; then
        process80=`netstat -tlpn | awk -F '[: ]+' '$5=="80"{print $9}'`
        red "==========================================================="
        red "检测到80端口被占用，占用进程为：${process80}，本次安装结束"
        red "==========================================================="
        exit 1
    fi

    if [ -n "$osPort443" ]; then
        process443=`netstat -tlpn | awk -F '[: ]+' '$5=="443"{print $9}'`
        red "============================================================="
        red "检测到443端口被占用，占用进程为：${process443}，本次安装结束"
        red "============================================================="
        exit 1
    fi

    osSELINUXCheck=$(grep SELINUX= /etc/selinux/config | grep -v "#")
    if [ "$osSELINUXCheck" == "SELINUX=enforcing" ]; then
        red "======================================================================="
        red "检测到SELinux为开启强制模式状态，为防止申请证书失败，请先重启VPS后，再执行本脚本"
        red "======================================================================="
        read -p "是否现在重启? 请输入 [Y/n] :" osSELINUXCheckIsRebootInput
        [ -z "${osSELINUXCheckIsRebootInput}" ] && osSELINUXCheckIsRebootInput="y"

        if [[ $osSELINUXCheckIsRebootInput == [Yy] ]]; then
            sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
            setenforce 0
            echo -e "VPS 重启中..."
            reboot
        fi
        exit
    fi

    if [ "$osSELINUXCheck" == "SELINUX=permissive" ]; then
        red "======================================================================="
        red "检测到SELinux为宽容模式状态，为防止申请证书失败，请先重启VPS后，再执行本脚本"
        red "======================================================================="
        read -p "是否现在重启? 请输入 [Y/n] :" osSELINUXCheckIsRebootInput
        [ -z "${osSELINUXCheckIsRebootInput}" ] && osSELINUXCheckIsRebootInput="y"

        if [[ $osSELINUXCheckIsRebootInput == [Yy] ]]; then
            sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
            setenforce 0
            echo -e "VPS 重启中..."
            reboot
        fi
        exit
    fi

    if [ "$osRelease" == "centos" ]; then
        if  [ -n "$(grep ' 6\.' /etc/redhat-release)" ] ; then
            red "==============="
            red "当前系统不受支持"
            red "==============="
            exit
        fi

        if  [ -n "$(grep ' 5\.' /etc/redhat-release)" ] ; then
            red "==============="
            red "当前系统不受支持"
            red "==============="
            exit
        fi

        ${sudoCommand} systemctl stop firewalld
        ${sudoCommand} systemctl disable firewalld

        if [ "$osReleaseVersion" == "7" ]; then
            rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
        fi
        


    elif [ "$osRelease" == "ubuntu" ]; then
        if  [ -n "$(grep ' 14\.' /etc/os-release)" ] ;then
            red "==============="
            red "当前系统不受支持"
            red "==============="
            exit
        fi
        if  [ -n "$(grep ' 12\.' /etc/os-release)" ] ;then
            red "==============="
            red "当前系统不受支持"
            red "==============="
            exit
        fi

        ${sudoCommand} systemctl stop ufw
        ${sudoCommand} systemctl disable ufw


    elif [ "$osRelease" == "debian" ]; then
        $osSystemPackage update -y
        $osSystemPackage install xz-utils -y
        $osSystemPackage install iputils-ping -y
    fi

}



# 编辑 SSH 公钥 文件用于 免密码登录
function editLinuxLoginWithPublicKey(){
    if [ ! -d "${HOME}/ssh" ]; then
        mkdir -p ${HOME}/.ssh
    fi

    vi ${HOME}/.ssh/authorized_keys
}

# 修改SSH 端口号
function changeLinuxSSHPort(){
    green "修改的SSH登陆的端口号, 不要使用常用的端口号. 例如 20|21|23|25|53|69|80|110|443|123!"
    read -p "请输入要修改的端口号(必须是纯数字并且在1024~65535之间或22):" osSSHLoginPortInput
    osSSHLoginPortInput=${osSSHLoginPortInput:-0}

    if [ $osSSHLoginPortInput -eq 22 -o $osSSHLoginPortInput -gt 1024 -a $osSSHLoginPortInput -lt 65535 ]; then
        sed -i "s/#\?Port [0-9]*/Port $osSSHLoginPortInput/g" /etc/ssh/sshd_config

        if [ "$osRelease" == "centos" ] ; then
            $osSystemPackage -y install policycoreutils-python

            semanage port -a -t ssh_port_t -p tcp $osSSHLoginPortInput
            firewall-cmd --add-port=$osSSHLoginPortInput/tcp --permanent
            firewall-cmd --reload
            ${sudoCommand} service sshd restart
            ${sudoCommand} systemctl restart sshd
        fi

        if [ "$osRelease" == "ubuntu" ] || [ "$osRelease" == "debian" ] ; then
            ${sudoCommand} service ssh restart
            ${sudoCommand} systemctl restart ssh
        fi

        green "设置成功, 请记住设置的端口号 ${osSSHLoginPortInput}!"
        green "登陆服务器命令: ssh -p ${osSSHLoginPortInput} root@111.111.111.your ip !"
    else
        echo "输入的端口号错误! 范围: 22,1025~65534"
    fi
}

# 设置北京时区
function setLinuxDateZone(){

    tempCurrentDateZone=$(date +'%z')

    if [[ ${tempCurrentDateZone} == "+0800" ]]; then
        yellow "当前时区已经为北京时间  $tempCurrentDateZone | $(date -R) "
    else 
        green " =================================================="
        yellow "当前时区为: $tempCurrentDateZone | $(date -R) "
        yellow "是否设置时区为北京时间 +0800区, 以便cron定时重启脚本按照北京时间运行."
        green " =================================================="
        # read 默认值 https://stackoverflow.com/questions/2642585/read-a-variable-in-bash-with-a-default-value

        read -p "是否设置为北京时间 +0800 时区? 请输入[Y/n]?" osTimezoneInput
        osTimezoneInput=${osTimezoneInput:-Y}

        if [[ $osTimezoneInput == [Yy] ]]; then
            if [[ -f /etc/localtime ]] && [[ -f /usr/share/zoneinfo/Asia/Shanghai ]];  then
                mv /etc/localtime /etc/localtime.bak
                cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

                yellow "设置成功! 当前时区已设置为 $(date -R)"
                green " =================================================="
            fi
        fi

    fi


    if [ "$osRelease" == "centos" ]; then   
        $osSystemPackage -y install ntpdate
        ntpdate -q 0.rhel.pool.ntp.org
        systemctl enable ntpd
        systemctl restart ntpd
    else
        $osSystemPackage install -y ntp
        systemctl enable ntp
        systemctl restart ntp
    fi
    
}




# 安装 BBR 加速网络软件
function installBBR(){
    wget -O tcp_old.sh -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp_old.sh && ./tcp_old.sh
}

function installBBR2(){
    
    if [[ -f ./tcp.sh ]];  then
        mv ./tcp.sh ./tcp_old.sh
    fi    
    wget -N --no-check-certificate "https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
}


function installSoftEditor(){

    $osSystemPackage update -y
    $osSystemPackage install -y curl wget git unzip zip tar nano
    $osSystemPackage install -y iputils-ping 

    if [ "$osRelease" == "centos" ]; then   
        
        $osSystemPackage install -y xz 
    else
        $osSystemPackage install -y vim-gui-common vim-runtime vim 
        $osSystemPackage install -y xz-utils

        ${sudoCommand} add-apt-repository ppa:deadsnakes/ppa -y 
        ${sudoCommand} add-apt-repository ppa:nginx/stable -y
    fi

    # 安装 micro 编辑器
    if [[ ! -f "${HOME}/bin/micro" ]] ;  then
        mkdir -p ${HOME}/bin
        cd ${HOME}/bin
        curl https://getmic.ro | bash

        cp ${HOME}/bin/micro /usr/local/bin

        green " =================================================="
        yellow " micro 编辑器 安装成功!"
        green " =================================================="
    fi



    # 设置vim 中文乱码
    if [[ ! -d "${HOME}/.vimrc" ]] ;  then
        cat > "${HOME}/.vimrc" <<-EOF
set fileencodings=utf-8,gb2312,gb18030,gbk,ucs-bom,cp936,latin1
set enc=utf8
set fencs=utf8,gbk,gb2312,gb18030

syntax on
set nu!
colorscheme elflord

EOF
    fi
}



function installNodejs(){

    if [ "$osRelease" == "centos" ] ; then

        if [ "$osReleaseVersion" == "8" ]; then
            ${sudoCommand} dnf module list nodejs
            ${sudoCommand} dnf module enable nodejs:14
            ${sudoCommand} dnf install nodejs
        fi

        if [ "$osReleaseVersion" == "7" ]; then
            curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
            ${sudoCommand} yum install -y nodejs
        fi

    else 
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
        echo 'export NVM_DIR="$HOME/.nvm"' >> ${HOME}/.zshrc
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ${HOME}/.zshrc
        source ${HOME}/.zshrc

        command -v nvm
        nvm --version
        nvm ls-remote
        nvm install --lts

    fi

    green " Nodejs 版本:"
    node --version 
    green " NPM 版本:"
    npm --version  

    green " =================================================="
    yellow " 准备安装 PM2 进程守护程序"
    green " =================================================="
    npm install -g pm2 

    green " ================================================== "
    green "   Nodejs 与 PM2 安装成功 !"
    green " ================================================== "

}


configPythonDownloadPath="${HOME}/download/python3"
configU2netDownloadPath="${HOME}/.u2net"
configPythonVERSION="3.8.7"
configPythonDownloadFile="Python-${configPythonVERSION}.tgz"


installPython3(){
    # 注意事项 1  阿里云无法访问github的代码 需要改host vi /etc/hosts 加入 199.232.68.133 raw.githubusercontent.com
    # 注意事项 2  backports.lzma 库 如果报错出问题 需要替换python3 源代码 某些centos出问题，不是必须步骤
    # 注意事项 3 torch 库下载速度慢, 可以人工下载 人工安装

    read -p "是否使用国内安装源? 例如阿里云的VPS下载慢 默认为是 请输入[Y/n]?" isUsedChinaSource
    isUsedChinaSource=${isUsedChinaSource:-Y}

    if [[ $isUsedChinaSource == [Yy] ]]; then
        echo "199.232.68.133 raw.githubusercontent.com">>/etc/hosts
    fi

    green " =================================================="
    yellow " 准备安装 Python ${configPythonVERSION} "
    green " =================================================="

    $osSystemPackage update -y
    
    mkdir -p ${configPythonDownloadPath}
    cd ${configPythonDownloadPath}

    if [ "$osRelease" == "centos" ] ; then

        if [ "$osReleaseVersion" == "8" ]; then
            ${sudoCommand} sudo dnf groupinstall 'development tools'
            ${sudoCommand} dnf install bzip2-devel expat-devel gdbm-devel ncurses-devel openssl-devel sqlite-devel
            ${sudoCommand} dnf install readline-devel wget tk-devel xz-devel zlib-devel libffi-devel python-backports-lzma
        fi


        if [ "$osReleaseVersion" == "7" ]; then
            yum groupinstall 'development tools'
            yum install -y gcc make openssl-devel bzip2-devel libffi-devel 
            yum install -y zlib-devel ncurses-devel sqlite-devel readline-devel tk-devel xz-devel python-backports-lzma
            yum install -y wget
        fi


        if [[ $isUsedChinaSource == [Yy] ]]; then
            wget -O ${configPythonDownloadPath}/${configPythonDownloadFile} https://mirrors.huaweicloud.com/python/${configPythonVERSION}/${configPythonDownloadFile}
        else
            wget -O ${configPythonDownloadPath}/${configPythonDownloadFile} https://www.python.org/ftp/python/${configPythonVERSION}/${configPythonDownloadFile}
        fi
        

        tar -zxvf ${configPythonDownloadPath}/${configPythonDownloadFile}
        cd Python-${configPythonVERSION}

        # ./configure prefix=/usr/local/python3 --enable-optimizations
        ./configure prefix=/usr/local/python3
        
        make altinstall

        /usr/local/python3/bin/python3.8 -m pip install --upgrade pip

        export PATH=$PATH:/usr/local/python3/bin

        # 添加python3的软链接 
        # rm -f /usr/bin/python3
        ln -s /usr/local/python3/bin/python3.8 /usr/bin/python3
        ln -s /usr/local/python3/bin/python3.8 /usr/bin/python3.8

        # 添加 pip3 的软链接 
        #rm -f /usr/bin/pip
        ln -s /usr/local/python3/bin/pip3.8 /usr/bin/pip

    else 
        
        ${sudoCommand} $osSystemPackage install -y software-properties-common
        ${sudoCommand} $osSystemPackage install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev wget libbz2-dev liblzma-dev
        ${sudoCommand} add-apt-repository ppa:deadsnakes/ppa -y 
        ${sudoCommand} apt-get install -y python3-dev manpages-dev build-essential
        
        $osSystemPackage update -y

        ${sudoCommand} $osSystemPackage install -y python3.8
        ${sudoCommand} $osSystemPackage install -y python3.8-dev
        
        ${sudoCommand} update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 3
        ${sudoCommand} update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 2
        ${sudoCommand} update-alternatives --config python3

        /usr/bin/python3.8 -m pip install --upgrade pip
        
    fi



    # backports.lzma 库 如果出现报错问题 需要替换python3 源代码
    wget -O ${configPythonDownloadPath}/lzma.py https://github.com/jinwyp/one_click_script/raw/master/download/lzma.py
    #cp ${configPythonDownloadPath}/lzma.py /usr/local/python3/lib/python3.8




    if [[ $isUsedChinaSource == [Yy] ]]; then
    
        # torch 库下载速度慢, 可以人工下载 人工安装

        # wget -O ${configPythonDownloadPath}/torch-1.7.1+cpu-cp38-cp38-linux_x86_64.whl https://download.pytorch.org/whl/cpu/torch-1.7.1%2Bcpu-cp38-cp38-linux_x86_64.whl
        # wget -O ${configPythonDownloadPath}/torchvision-0.8.2+cpu-cp38-cp38-linux_x86_64.whl https://download.pytorch.org/whl/cpu/torchvision-0.8.2%2Bcpu-cp38-cp38-linux_x86_64.whl

        wget -O ${configPythonDownloadPath}/torch-1.7.1+cpu-cp38-cp38-linux_x86_64.whl https://rt1.jinss2.cf/torch-1.7.1%2Bcpu-cp38-cp38-linux_x86_64.whl
        wget -O ${configPythonDownloadPath}/torchvision-0.8.2+cpu-cp38-cp38-linux_x86_64.whl https://rt1.jinss2.cf/torchvision-0.8.2%2Bcpu-cp38-cp38-linux_x86_64.whl
        pip install ${configPythonDownloadPath}/torch-1.7.1+cpu-cp38-cp38-linux_x86_64.whl 
        pip install ${configPythonDownloadPath}/torchvision-0.8.2+cpu-cp38-cp38-linux_x86_64.whl

        pip install backports.lzma -i https://mirrors.aliyun.com/pypi/simple/

    else
        # Install for CUDA by NVIDIA GeForce Card
        # pip install torch torchvision

        pip install torch==1.7.1+cpu torchvision==0.8.2+cpu -f https://download.pytorch.org/whl/torch_stable.html
        pip install backports.lzma
    fi


    green " ================================================== "
    green "    Python ${configPythonVERSION} 安装成功  !"
    green " ================================================== "
    python3 --version
    
}


installPython3Rembg(){
    pip install rembg

    if [ "$osRelease" == "centos" ] ; then
        # 添加 pip3 的软链接 
        ln -s /usr/local/python3/bin/rembg /usr/bin/rembg
        ln -s /usr/local/python3/bin/rembg-server /usr/bin/rembg-server
    else
        # 添加 pip3 的软链接 
        ln -s /usr/local/bin/rembg /usr/bin/rembg
        ln -s /usr/local/bin/rembg-server /usr/bin/rembg-server
    fi


    mkdir -p ${configU2netDownloadPath} 
    wget -O ${configU2netDownloadPath}/u2netp.pth https://rt1.jinss2.cf/u2netp.pth
    wget -O ${configU2netDownloadPath}/u2net.pth https://rt1.jinss2.cf/u2net.pth

    green " ================================================== "
    green "    rembg 安装成功  !"
    echo "   "
    green "    命令行运行  rembg -o output1.jpg test1.jpg"
    green "    参数 -p 指定源文件目录, 批量转换该目录下的所有文件"
    green "    参数 -m u2net 指定模型 共2种 u2net 或 u2netp 默认为 u2net"
    green "    参数 -a 是否使用 alpha matting cutout 例如 rembg -a -ae 15 > output.png"
    green "    参数 -ae 默认10  erosion 图片侵蚀程度"
    green "    参数 -af 默认240 foreground-threshold 图片前景阈值"
    green "    参数 -ab 默认10 background-threshold 图片背景阈值"
    green "    参数 -az 默认1000 The image base size 图片基础大小"
    
    echo "   "
    green "    运行网站API服务命令 rembg-server 请开启5000端口防火墙, 或用nginx反向代理5000端口"
    green "    后台运行网站API服务命令 nohup rembg-server > /root/rembg.log 2>&1 &"
    green " ================================================== "
    
}






configDockerPath="${HOME}/download"
configV2rayPoseidonPath="${HOME}"


function installDocker(){

    green " =================================================="
    yellow " 准备安装 Docker 与 Docker Compose"
    green " =================================================="

    mkdir -p ${configDockerPath}
    cd ${configDockerPath}

    curl -fsSL https://get.docker.com -o get-docker.sh  
    sh get-docker.sh

    ${sudoCommand} curl -L "https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    ${sudoCommand} chmod a+x /usr/local/bin/docker-compose

    rm -f `which dc`
    ${sudoCommand} ln -s /usr/local/bin/docker-compose /usr/bin/dc
    ${sudoCommand} ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    systemctl start docker
    systemctl enable docker.service


    green " ================================================== "
    green "   Docker 与 Docker Compose 安装成功 !"
    green " ================================================== "
    docker-compose --version

    # systemctl status docker.service
}




function deleteDockerLogs(){
     truncate -s 0 /var/lib/docker/containers/*/*-json.log
}




configNetworkRealIp=""
configNetworkLocalIp=""
configSSLDomain=""

configSSLCertPath="${HOME}/website/cert"
configWebsitePath="${HOME}/website/html"


function getHTTPSCertificate(){

    # 申请https证书
	mkdir -p ${configSSLCertPath}
	mkdir -p ${configWebsitePath}
	curl https://get.acme.sh | sh

    green "=========================================="

	if [[ $1 == "standalone" ]] ; then
	    green "  开始申请证书 acme.sh standalone mode !"
	    ~/.acme.sh/acme.sh  --issue  -d ${configSSLDomain}  --standalone

        ~/.acme.sh/acme.sh  --installcert  -d ${configSSLDomain}   \
        --key-file   ${configSSLCertPath}/private.key \
        --fullchain-file ${configSSLCertPath}/fullchain.cer

	else
	    green "  开始申请证书 acme.sh nginx mode !"
        ~/.acme.sh/acme.sh  --issue  -d ${configSSLDomain}  --webroot ${configWebsitePath}/

        ~/.acme.sh/acme.sh  --installcert  -d ${configSSLDomain}   \
        --key-file   ${configSSLCertPath}/private.key \
        --fullchain-file ${configSSLCertPath}/fullchain.cer \
        --reloadcmd  "systemctl force-reload  nginx.service"
    fi

}


function compareRealIpWithLocalIp(){

    yellow " 是否检测域名指向的IP正确 (默认检测，如果域名指向的IP不是本机器IP则无法继续. 如果已开启CDN不方便关闭可以选择否)"
    read -p "是否检测域名指向的IP正确? 请输入[Y/n]?" isDomainValidInput
    isDomainValidInput=${isDomainValidInput:-Y}

    if [[ $isDomainValidInput == [Yy] ]]; then
        if [ -n $1 ]; then
            configNetworkRealIp=`ping $1 -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
            # configNetworkLocalIp=`curl ipv4.icanhazip.com`
            configNetworkLocalIp=`curl v4.ident.me`

            green " ================================================== "
            green "     域名解析地址为 ${configNetworkRealIp}, 本VPS的IP为 ${configNetworkLocalIp}. "
            green " ================================================== "

            if [[ ${configNetworkRealIp} == ${configNetworkLocalIp} ]] ; then
                green " ================================================== "
                green "     域名解析的IP正常!"
                green " ================================================== "
                true
            else
                green " ================================================== "
                red "     域名解析地址与本VPS IP地址不一致!"
                red "     本次安装失败，请确保域名解析正常, 请检查域名和DNS是否生效!"
                green " ================================================== "
                false
            fi
        else
            green " ================================================== "        
            red "     域名输入错误!"
            green " ================================================== "        
            false
        fi
        
    else
        green " ================================================== "
        green "     不检测域名解析是否正确!"
        green " ================================================== "
        true
    fi
}




function getHTTPS(){

    testLinuxPortUsage

    green " ================================================== "
    yellow " 请输入绑定到本VPS的域名 例如www.xxx.com: (此步骤请关闭CDN后和nginx后安装 避免80端口占用导致申请证书失败)"
    green " ================================================== "

    read configSSLDomain

    read -p "是否申请证书? 默认为自动申请证书,如果二次安装或已有证书可以选否 请输入[Y/n]?" isDomainSSLRequestInput
    isDomainSSLRequestInput=${isDomainSSLRequestInput:-Y}

    if compareRealIpWithLocalIp "${configSSLDomain}" ; then
        if [[ $isDomainSSLRequestInput == [Yy] ]]; then

            getHTTPSCertificate "standalone"

            if test -s ${configSSLCertPath}/fullchain.cer; then
                green " =================================================="
                green "   域名SSL证书申请成功 !"
                green " ${configSSLDomain} 域名证书内容文件路径 ${configSSLCertPath}/fullchain.cer "
                green " ${configSSLDomain} 域名证书私钥文件路径 ${configSSLCertPath}/private.key "
                green " =================================================="

            else
                red "==================================="
                red " https证书没有申请成功，安装失败!"
                red " 请检查域名和DNS是否生效, 同一域名请不要一天内多次申请!"
                red " 请检查80和443端口是否开启, VPS服务商可能需要添加额外防火墙规则，例如阿里云、谷歌云等!"
                red " 重启VPS, 重新执行脚本, 可重新选择修复证书选项再次申请证书 ! "
                red "==================================="
                exit
            fi

        else
            green " =================================================="
            green "   不申请域名的证书, 请把证书放到如下目录, 或自行修改trojan或v2ray配置!"
            green " ${configSSLDomain} 域名证书内容文件路径 ${configSSLCertPath}/fullchain.cer "
            green " ${configSSLDomain} 域名证书私钥文件路径 ${configSSLCertPath}/private.key "
            green " =================================================="
        fi
    else
        exit
    fi

}








function start_menu(){
    clear

    if [[ $1 == "first" ]] ; then
        getLinuxOSVersion
        ${osSystemPackage} -y install wget curl git 
    fi

    green " =================================================="
    green " Trojan Trojan-go V2ray 一键安装脚本 2020-12-6 更新.  系统支持：centos7+ / debian9+ / ubuntu16.04+"
    red " *请不要在任何生产环境使用此脚本 请不要有其他程序占用80和443端口"
    red " *若是已安装trojan 或第二次使用脚本，请先执行卸载trojan"
    green " =================================================="
    green " 1. 安装 老版本 BBR-PLUS 加速4合一脚本"
    green " 2. 安装 新版本 BBR-PLUS 加速6合一脚本"
    echo
    green " 3. 编辑 SSH 登录的用户公钥 用于SSH密码登录免登录"
    green " 4. 修改 SSH 登陆端口号"
    green " 5. 设置时区为北京时间"
    green " 6. 安装 Vim Nano Micro 编辑器"
    green " 7. 安装 Nodejs 与 PM2"
    green " 8. 安装 Docker 与 Docker Compose"
    green " 9. 安装 Python3.8 "
    green " 10. 安装 remgb "
    echo
    green " 21. 单独申请域名SSL证书"
    green " 28. 清空 Docker日志"
    echo
    green " 0. 退出脚本"
    echo
    read -p "请输入数字:" menuNumberInput
    case "$menuNumberInput" in
        1 )
            installBBR
        ;;
        2 )
            installBBR2
        ;;
        3 )
            editLinuxLoginWithPublicKey
        ;;
        4 )
            changeLinuxSSHPort
        ;;
        5 )
            setLinuxDateZone
        ;;
        6 )
            installSoftEditor
        ;;
        7 )
            installNodejs
        ;;
        8 )
            testLinuxPortUsage
            setLinuxDateZone
            installSoftEditor
            installDocker
        ;;
        9 )
            installPython3
        ;;
        10 )
            installPython3
            installPython3Rembg
        ;;
        21 )
            setLinuxDateZone
            getHTTPS
        ;;
        28 )
            deleteDockerLogs
        ;;                      
        0 )
            exit 1
        ;;
        * )
            clear
            red "请输入正确数字 !"
            sleep 2s
            start_menu
        ;;
    esac
}



start_menu "first"

