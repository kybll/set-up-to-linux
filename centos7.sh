#!/bin/bash
## Author: Kybll March
## Modified: 2024-10-5
## License: GPL-3.0
## GitHub: https://gitee.com/kybll/set-up-to-linux
## Website: https://linux.shell.kybll.cn

# 换源阿里云
mirror=(
    "阿里云@mirrors.aliyun.com"
)

## 配置需要区分公网地址和内网地址的软件源（不分地域）
# 配置方法：需要同时在两个数组变量中分别定义软件源地址，并且保证排列顺序一致
# 工作原理：当检测到用户所选择的软件源地址在 “软件源公网地址列表” 中时就会询问是否切换为内网地址，然后在 “软件源内网地址列表” 从相同的位置提取内网地址
# 软件源公网地址列表
mirror_list_extranet=(
    "mirrors.aliyun.com"
)
# 软件源内网地址列表
mirror_list_intranet=(
    "mirrors.cloud.aliyuncs.com"
)

## 定义系统判定变量
SYSTEM_DEBIAN="Debian"
SYSTEM_UBUNTU="Ubuntu"
SYSTEM_KALI="Kali"
SYSTEM_DEEPIN="Deepin"
SYSTEM_REDHAT="RedHat"
SYSTEM_RHEL="Red Hat Enterprise Linux"
SYSTEM_CENTOS="CentOS"
SYSTEM_CENTOS_STREAM="CentOS Stream"
SYSTEM_ROCKY="Rocky"
SYSTEM_FEDORA="Fedora"
SYSTEM_OPENCLOUDOS="OpenCloudOS"
SYSTEM_ARCH="Arch"

## 定义系统版本文件
File_LinuxRelease=/etc/os-release
File_RedHatRelease=/etc/redhat-release
File_DebianVersion=/etc/debian_version
File_ArmbianRelease=/etc/armbian-release
File_OpenCloudOSRelease=/etc/opencloudos-release
File_ArchLinuxRelease=/etc/arch-release
File_ProxmoxVersion=/etc/pve/.version

## 定义软件源相关文件或目录
File_DebianSourceList=/etc/apt/sources.list
File_DebianSourceListBackup=/etc/apt/sources.list.bak
File_DebianSources=/etc/apt/sources.list.d/debian.sources
File_DebianSourcesBackup=/etc/apt/sources.list.d/debian.sources.bak
File_UbuntuSources=/etc/apt/sources.list.d/ubuntu.sources
File_UbuntuSourcesBackup=/etc/apt/sources.list.d/ubuntu.sources.bak
File_ArmbianSourceList=/etc/apt/sources.list.d/armbian.list
File_ArmbianSourceListBackup=/etc/apt/sources.list.d/armbian.list.bak
File_ProxmoxSourceList=/etc/apt/sources.list.d/pve-no-subscription.list
File_ProxmoxSourceListBackup=/etc/apt/sources.list.d/pve-no-subscription.list.bak
File_ArchLinuxMirrorList=/etc/pacman.d/mirrorlist
File_ArchLinuxMirrorListBackup=/etc/pacman.d/mirrorlist.bak
Dir_DebianExtendSource=/etc/apt/sources.list.d
Dir_DebianExtendSourceBackup=/etc/apt/sources.list.d.bak
Dir_YumRepos=/etc/yum.repos.d
Dir_YumReposBackup=/etc/yum.repos.d.bak

## 定义颜色变量
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
PURPLE='\033[35m'
AZURE='\033[36m'
PLAIN='\033[0m'
BOLD='\033[1m'
SUCCESS="[\033[1;32m成功${PLAIN}]"
COMPLETE="[\033[1;32m完成${PLAIN}]"
WARN="[\033[1;5;33m注意${PLAIN}]"
ERROR="[\033[1;31m错误${PLAIN}]"
FAIL="[\033[1;31m失败${PLAIN}]"
TIP="[\033[1;32m提示${PLAIN}]"
WORKING="[\033[1;36m >_ ${PLAIN}]"

function main() {
    permission_judgment
    collect_system_info
    check_command_options
    run_start
    choose_mirrors
    choose_protocol
    choose_install_epel_packages
    close_firewall_service
    backup_original_mirrors
    remove_original_mirrors
    change_mirrors_main
    upgrade_software
    run_end
}

## 处理命令选项
function handle_command_options() {
    ## 命令帮助
    function output_command_help() {
        echo -e "\n命令选项(名称/含义/选项值)：

  --abroad                 使用海外软件源                                                 无
  --edu                    使用中国大陆教育网软件源                                       无
  --source                 指定软件源地址(域名或IP)                                       地址
  --source-epel            指定 EPEL 附加软件包仓库的软件源地址(域名或IP)                 地址
  --source-security        指定 Debian 系统 security 仓库的软件源地址(域名或IP)           地址
  --source-vault           指定 CentOS/AlmaLinux 系统 vault 仓库的软件源地址(域名或IP)    地址
  --source-portage         指定 Gentoo 系统 portage 仓库的软件源地址(域名或IP)            地址
  --branch                 指定软件源分支(路径)                                           分支名
  --branch-epel            指定 EPEL 附加软件包仓库的软件源分支(路径)                     分支名
  --branch-security        指定 Debian 系统 security 仓库的软件源分支(路径)               分支名
  --branch-vault           指定 CentOS/AlmaLinux 系统 vault 仓库的软件源分支(路径)        分支名
  --branch-portage         指定 Gentoo 系统 portage 仓库的软件源分支(路径)                分支名
  --codename               指定 Debian 系操作系统的版本代号                               代号名称
  --protocol               指定 WEB 协议                                                  http 或 https
  --use-intranet-source    是否优先使用内网软件源地址                                     true 或 false
  --use-official-source    是否使用目标操作系统的官方软件源                               true 或 false
  --install-epel           是否安装 EPEL 附加软件包                                       true 或 false
  --close-firewall         是否关闭防火墙                                                 true 或 false
  --backup                 是否备份原有软件源                                             true 或 false
  --upgrade-software       是否更新软件包                                                 true 或 false
  --clean-cache            是否清理下载缓存                                               true 或 false
  --only-epel              仅更换 EPEL 软件源模式                                         无
  --ignore-backup-tips     忽略覆盖备份提示                                               无
  --print-diff             打印源文件修改前后差异                                         无

问题报告 https://github.com/SuperManito/LinuxMirrors/issues\n"
    }

    ## 判断参数
    while [ $# -gt 0 ]; do
        case "$1" in
        ## 海外模式
        --abroad)
            USE_ABROAD_SOURCE="true"
            ;;
        ## 中国大陆教育网模式
        --edu)
            USE_EDU_SOURCE="true"
            ;;
        ## 指定软件源地址
        --source)
            if [ "$2" ]; then
                echo "$2" | grep -Eq "\(|\)|\[|\]|\{|\}"
                if [ $? -eq 0 ]; then
                    output_error "命令选项 ${BLUE}$2${PLAIN} 无效，请在该选项后指定有效的地址！"
                else
                    SOURCE="$(echo "$2" | sed -e 's,^http[s]\?://,,g' -e 's,/$,,')"
                    shift
                fi
            else
                output_error "命令选项 ${BLUE}$1${PLAIN} 无效，请在该选项后指定软件源地址！"
            fi
            ;;
        --source-epel)
            if [ "$2" ]; then
                echo "$2" | grep -Eq "\(|\)|\[|\]|\{|\}"
                if [ $? -eq 0 ]; then
                    output_error "命令选项 ${BLUE}$2${PLAIN} 无效，请在该选项后指定有效的地址！"
                else
                    SOURCE_EPEL="$(echo "$2" | sed -e 's,^http[s]\?://,,g' -e 's,/$,,')"
                    shift
                fi
            else
                output_error "命令选项 ${BLUE}$1${PLAIN} 无效，请在该选项后指定软件源地址！"
            fi
            ;;
        --source-security)
            if [ "$2" ]; then
                echo "$2" | grep -Eq "\(|\)|\[|\]|\{|\}"
                if [ $? -eq 0 ]; then
                    output_error "命令选项 ${BLUE}$2${PLAIN} 无效，请在该选项后指定有效的地址！"
                else
                    SOURCE_SECURITY="$(echo "$2" | sed -e 's,^http[s]\?://,,g' -e 's,/$,,')"
                    shift
                fi
            else
                output_error "命令选项 ${BLUE}$1${PLAIN} 无效，请在该选项后指定软件源地址！"
            fi
            ;;
        --source-vault)
            if [ "$2" ]; then
                echo "$2" | grep -Eq "\(|\)|\[|\]|\{|\}"
                if [ $? -eq 0 ]; then
                    output_error "命令选项 ${BLUE}$2${PLAIN} 无效，请在该选项后指定有效的地址！"
                else
                    SOURCE_VAULT="$(echo "$2" | sed -e 's,^http[s]\?://,,g' -e 's,/$,,')"
                    shift
                fi
            else
                output_error "命令选项 ${BLUE}$1${PLAIN} 无效，请在该选项后指定软件源地址！"
            fi
            ;;
        --source-portage)
            if [ "$2" ]; then
                echo "$2" | grep -Eq "\(|\)|\[|\]|\{|\}"
                if [ $? -eq 0 ]; then
                    output_error "命令选项 ${BLUE}$2${PLAIN} 无效，请在该选项后指定有效的地址！"
                else
                    SOURCE_PORTAGE="$(echo "$2" | sed -e 's,^http[s]\?://,,g' -e 's,/$,,')"
                    shift
                fi
            else
                output_error "命令选项 ${BLUE}$1${PLAIN} 无效，请在该选项后指定软件源地址！"
            fi
            ;;
        ## 指定软件源分支
        --branch)
            if [ "$2" ]; then
                SOURCE_BRANCH="$2"
                shift
            else
                output_error "命令选项 ${BLUE}$1${PLAIN} 无效，请在该选项后指定软件源分支！"
            fi
            ;;
        --branch-epel)
            if [ "$2" ]; then
                SOURCE_EPEL_BRANCH="$2"
                shift
            else
                output_error "命令选项 ${BLUE}$1${PLAIN} 无效，请在该选项后指定软件源分支！"
            fi
            ;;
        --branch-security)
            if [ "$2" ]; then
                SOURCE_SECURITY_BRANCH="$2"
                shift
            else
                output_error "命令选项 ${BLUE}$1${PLAIN} 无效，请在该选项后指定软件源分支！"
            fi
            ;;
        --branch-vault)
            if [ "$2" ]; then
                SOURCE_VAULT_BRANCH="$2"
                shift
            else
                output_error "命令选项 ${BLUE}$1${PLAIN} 无效，请在该选项后指定软件源分支！"
            fi
            ;;
        --branch-portage)
            if [ "$2" ]; then
                SOURCE_PORTAGE_BRANCH="$2"
                shift
            else
                output_error "命令选项 ${BLUE}$1${PLAIN} 无效，请在该选项后指定软件源分支！"
            fi
            ;;
        ## 指定 Debian 系操作系统的版本代号
        --codename)
            if [ "$2" ]; then
                DEBIAN_CODENAME="$2"
                shift
            else
                output_error "命令选项 ${BLUE}$1${PLAIN} 无效，请在该选项后指定版本代号！"
            fi
            ;;
        ## 使用官方源
        --use-official-source)
            if [ "$2" ]; then
                case "$2" in
                [Tt]rue | [Ff]alse)
                    USE_OFFICIAL_SOURCE="${2,,}"
                    shift
                    ;;
                *)
                    output_error "命令选项 ${BLUE}$2${PLAIN} 无效，请在该选项后指定 true 或 false ！"
                    ;;
                esac
            else
                output_error "命令选项 ${BLUE}$1${PLAIN} 无效，请在该选项后指定 true 或 false ！"
            fi
            ;;
        ## 使用内网地址
        --intranet | --use-intranet-source)
            if [ "$2" ]; then
                case "$2" in
                [Tt]rue | [Ff]alse)
                    USE_INTRANET_SOURCE="${2,,}"
                    shift
                    ;;
                *)
                    output_error "命令选项 ${BLUE}$2${PLAIN} 无效，请在该选项后指定 true 或 false ！"
                    ;;
                esac
            else
                output_error "命令选项 ${BLUE}$1${PLAIN} 无效，请在该选项后指定 true 或 false ！"
            fi
            ;;
        ## WEB 协议（HTTP/HTTPS）
        --protocol | --web-protocol)
            if [ "$2" ]; then
                case "$2" in
                http | https | HTTP | HTTPS)
                    WEB_PROTOCOL="$2"
                    shift
                    ;;
                *)
                    output_error "检测到 ${BLUE}$2${PLAIN} 为无效参数值，请在该选项后指定 http 或 https ！"
                    ;;
                esac
            else
                output_error "命令选项 ${BLUE}$1${PLAIN} 无效，请在该选项后指定 WEB 协议（http/https）！"
            fi
            ;;
        ## 安装 EPEL 附加软件包
        --install-epel)
            if [ "$2" ]; then
                case "$2" in
                [Tt]rue | [Ff]alse)
                    INSTALL_EPEL="${2,,}"
                    shift
                    ;;
                *)
                    output_error "命令选项 ${BLUE}$2${PLAIN} 无效，请在该选项后指定 true 或 false ！"
                    ;;
                esac
            else
                output_error "命令选项 ${BLUE}$1${PLAIN} 无效，请在该选项后指定 true 或 false ！"
            fi
            ;;
        --only-epel)
            ONLY_EPEL="true"
            INSTALL_EPEL="true"
            ;;
        ## 关闭防火墙
        --close-firewall)
            if [ "$2" ]; then
                case "$2" in
                [Tt]rue | [Ff]alse)
                    CLOSE_FIREWALL="${2,,}"
                    shift
                    ;;
                *)
                    output_error "命令选项 ${BLUE}$2${PLAIN} 无效，请在该选项后指定 true 或 false ！"
                    ;;
                esac
            else
                output_error "命令选项 ${BLUE}$1${PLAIN} 无效，请在该选项后指定 true 或 false ！"
            fi
            ;;
        ## 备份原有软件源
        --backup)
            if [ "$2" ]; then
                case "$2" in
                [Tt]rue | [Ff]alse)
                    BACKUP="${2,,}"
                    shift
                    ;;
                *)
                    output_error "命令选项 ${BLUE}$2${PLAIN} 无效，请在该选项后指定 true 或 false ！"
                    ;;
                esac
            else
                output_error "命令选项 ${BLUE}$1${PLAIN} 无效，请在该选项后指定 true 或 false ！"
            fi
            ;;
        ## 忽略覆盖备份提示
        --ignore-backup-tips)
            IGNORE_BACKUP_TIPS="true"
            ;;
        ## 更新软件包
        --upgrade-software | --updata-software)
            if [ "$2" ]; then
                case "$2" in
                [Tt]rue | [Ff]alse)
                    UPGRADE_SOFTWARE="${2,,}"
                    shift
                    ;;
                *)
                    output_error "命令选项 ${BLUE}$2${PLAIN} 无效，请在该选项后指定 true 或 false ！"
                    ;;
                esac
            else
                output_error "命令选项 ${BLUE}$1${PLAIN} 无效，请在该选项后指定 true 或 false ！"
            fi
            ;;
        ## 清理下载缓存
        --clean-cache)
            if [ "$2" ]; then
                case "$2" in
                [Tt]rue | [Ff]alse)
                    CLEAN_CACHE="${2,,}"
                    shift
                    ;;
                *)
                    output_error "命令选项 ${BLUE}$2${PLAIN} 无效，请在该选项后指定 true 或 false ！"
                    ;;
                esac
            else
                output_error "命令选项 ${BLUE}$1${PLAIN} 无效，请在该选项后指定 true 或 false ！"
            fi
            ;;
        ## 打印源文件修改前后差异
        --print-diff)
            PRINT_DIFF="true"
            ;;
        ## 命令帮助
        --help)
            output_command_help
            exit
            ;;
        *)
            output_error "命令选项 ${BLUE}$1${PLAIN} 无效，请确认后重新输入！"
            ;;
        esac
        shift
    done
    ## 给部分命令选项赋予默认值
    ONLY_EPEL="${ONLY_EPEL:-"false"}"
    BACKUP="${BACKUP:-"true"}"
    USE_OFFICIAL_SOURCE="${USE_OFFICIAL_SOURCE:-"false"}"
    IGNORE_BACKUP_TIPS="${IGNORE_BACKUP_TIPS:-"false"}"
    PRINT_DIFF="${PRINT_DIFF:-"false"}"
}

## 页头
function run_start() {
    [ -z "${SOURCE}" ] && clear
    echo -e ' 欢迎使用 Set up to Linux 脚本'
    echo -e ' https://linux.shell.kybll.cn'
}

## 页脚
function run_end() {
    echo -e "\n---------- 脚本执行结束 ----------"
    echo -e "\n\033[1;34mPowered by https://linux.shell.kybll.cn\033[0m\n"
}

## 报错退出
function output_error() {
    [ "$1" ] && echo -e "\n$ERROR $1\n"
    exit 1
}

## 权限判定
function permission_judgment() {
    if [ $UID -ne 0 ]; then
        output_error "权限不足，请使用 Root 用户运行本脚本"
    fi
}

## 收集系统信息
function collect_system_info() {
    ## 定义系统名称
    SYSTEM_NAME="$(cat $File_LinuxRelease | grep -E "^NAME=" | awk -F '=' '{print$2}' | sed "s/[\'\"]//g")"
    grep -q "PRETTY_NAME=" $File_LinuxRelease && SYSTEM_PRETTY_NAME="$(cat $File_LinuxRelease | grep -E "^PRETTY_NAME=" | awk -F '=' '{print$2}' | sed "s/[\'\"]//g")"
    ## 定义系统版本号
    SYSTEM_VERSION_NUMBER="$(cat $File_LinuxRelease | grep -E "^VERSION_ID=" | awk -F '=' '{print$2}' | sed "s/[\'\"]//g")"
    ## 定义系统ID
    SYSTEM_ID="$(cat $File_LinuxRelease | grep -E "^ID=" | awk -F '=' '{print$2}' | sed "s/[\'\"]//g")"
    ## 判定当前系统派系
    if [ -s $File_DebianVersion ]; then
        SYSTEM_FACTIONS="${SYSTEM_DEBIAN}"
    elif [ -s $File_openEulerRelease ]; then
        SYSTEM_FACTIONS="${SYSTEM_OPENEULER}"
    elif [ -f $File_ArchLinuxRelease ]; then
        SYSTEM_FACTIONS="${SYSTEM_ARCH}"
    elif [ -f $File_AlpineRelease ]; then
        SYSTEM_FACTIONS="${SYSTEM_ALPINE}"
    elif [ -f $File_GentooRelease ]; then
        SYSTEM_FACTIONS="${SYSTEM_GENTOO}"
    elif [ -s $File_RedHatRelease ]; then
        SYSTEM_FACTIONS="${SYSTEM_REDHAT}"
    elif [ -s $File_OpenCloudOSRelease ]; then
        SYSTEM_FACTIONS="${SYSTEM_OPENCLOUDOS}" # 注：RedHat 判断优先级需要高于 OpenCloudOS，因为官方宣称8版本基于红帽而9版本不是
    elif [[ "${SYSTEM_NAME}" == *"openSUSE"* ]]; then
        SYSTEM_FACTIONS="${SYSTEM_OPENSUSE}"
    else
        output_error "无法判断当前运行环境！"
    fi
    ## 判定系统类型、版本、版本号
    case "${SYSTEM_FACTIONS}" in
    "${SYSTEM_DEBIAN}")
        if [ ! -x /usr/bin/lsb_release ]; then
            apt-get install -y lsb-release
            if [ $? -ne 0 ]; then
                output_error "lsb-release 软件包安装失败\n\n本脚本依赖 lsb_release 指令判断系统具体类型和版本，当前系统可能为精简安装，请自行安装后重新执行脚本！"
            fi
        fi
        SYSTEM_JUDGMENT="$(lsb_release -is)"
        SYSTEM_VERSION_CODENAME="${DEBIAN_CODENAME:-"$(lsb_release -cs)"}"
        ;;
    "${SYSTEM_REDHAT}")
        SYSTEM_JUDGMENT="$(awk '{printf $1}' $File_RedHatRelease)"
        ## 特殊系统判断
        # Red Hat Enterprise Linux
        grep -q "${SYSTEM_RHEL}" $File_RedHatRelease && SYSTEM_JUDGMENT="${SYSTEM_RHEL}"
        # CentOS Stream
        grep -q "${SYSTEM_CENTOS_STREAM}" $File_RedHatRelease && SYSTEM_JUDGMENT="${SYSTEM_CENTOS_STREAM}"
        ;;
    *)
        SYSTEM_JUDGMENT="${SYSTEM_FACTIONS}"
        ;;
    esac
    ## 判定系统处理器架构
    case "$(uname -m)" in
    x86_64)
        DEVICE_ARCH="x86_64"
        ;;
    aarch64)
        DEVICE_ARCH="ARM64"
        ;;
    armv7l)
        DEVICE_ARCH="ARMv7"
        ;;
    armv6l)
        DEVICE_ARCH="ARMv6"
        ;;
    i686)
        DEVICE_ARCH="x86_32"
        ;;
    *)
        DEVICE_ARCH="$(uname -m)"
        ;;
    esac
    ## 定义软件源分支名称
    if [[ -z "${SOURCE_BRANCH}" ]]; then
        ## 默认为系统名称小写，替换空格
        SOURCE_BRANCH="${SYSTEM_JUDGMENT,,}"
        SOURCE_BRANCH="${SOURCE_BRANCH// /-}"
        ## 处理特殊的分支名称
        case "${SYSTEM_JUDGMENT}" in
        "${SYSTEM_DEBIAN}")
            case ${SYSTEM_VERSION_NUMBER:0:1} in
            8 | 9 | 10)
                SOURCE_BRANCH="debian-archive" # EOF
                ;;
            *)
                SOURCE_BRANCH="debian"
                ;;
            esac
            ;;
        "${SYSTEM_UBUNTU}")
            if [[ "${DEVICE_ARCH}" == "x86_64" ]] || [[ "${DEVICE_ARCH}" == *i?86* ]]; then
                SOURCE_BRANCH="ubuntu"
            else
                SOURCE_BRANCH="ubuntu-ports"
            fi
            ;;
        "${SYSTEM_RHEL}")
            case ${SYSTEM_VERSION_NUMBER:0:1} in
            9)
                SOURCE_BRANCH="centos-stream" # 使用 CentOS Stream 仓库
                ;;
            *)
                SOURCE_BRANCH="centos-vault" # EOF
                ;;
            esac
            ;;
        "${SYSTEM_CENTOS}")
            if [[ "${DEVICE_ARCH}" == "x86_64" ]]; then
                SOURCE_BRANCH="centos-vault" # EOF
            else
                SOURCE_BRANCH="centos-altarch"
            fi
            ;;
        "${SYSTEM_CENTOS_STREAM}")
            # 自 CentOS Stream 9 开始使用 centos-stream 仓库，旧版本使用 centos 仓库
            case ${SYSTEM_VERSION_NUMBER:0:1} in
            8)
                if [[ "${DEVICE_ARCH}" == "x86_64" ]]; then
                    SOURCE_BRANCH="centos-vault" # EOF
                else
                    SOURCE_BRANCH="centos-altarch"
                fi
                ;;
            *)
                SOURCE_BRANCH="centos-stream"
                ;;
            esac
            ;;
        "${SYSTEM_ARCH}")
            if [[ "${DEVICE_ARCH}" == "x86_64" ]] || [[ "${DEVICE_ARCH}" == *i?86* ]]; then
                SOURCE_BRANCH="archlinux"
            else
                SOURCE_BRANCH="archlinuxarm"
            fi
            ;;
        esac
    fi
    ## 定义软件源更新文字
    case "${SYSTEM_FACTIONS}" in
    "${SYSTEM_DEBIAN}" | "${SYSTEM_ALPINE}")
        SYNC_MIRROR_TEXT="更新软件源"
        ;;
    "${SYSTEM_REDHAT}" | "${SYSTEM_OPENCLOUDOS}" | "${SYSTEM_OPENEULER}")
        SYNC_MIRROR_TEXT="生成软件源缓存"
        ;;
    "${SYSTEM_OPENSUSE}")
        SYNC_MIRROR_TEXT="刷新软件源"
        ;;
    "${SYSTEM_ARCH}" | "${SYSTEM_GENTOO}")
        SYNC_MIRROR_TEXT="同步软件源"
        ;;
    esac
}

## 选择软件源
function choose_mirrors() {
    ## 打印软件源列表
    function print_mirrors_list() {
        local tmp_mirror_name tmp_mirror_url arr_num default_mirror_name_length tmp_mirror_name_length tmp_spaces_nums a i j
        ## 计算字符串长度
        function StringLength() {
            local text=$1
            echo "${#text}"
        }
        echo -e ''

        local list_arr=()
        local list_arr_sum
        list_arr_sum="$(eval echo \${#$1[@]})"
        for ((a = 0; a < $list_arr_sum; a++)); do
            list_arr[$a]="$(eval echo \${$1[a]})"
        done
        if [ -x /usr/bin/printf ]; then
            for ((i = 0; i < ${#list_arr[@]}; i++)); do
                tmp_mirror_name=$(echo "${list_arr[i]}" | awk -F '@' '{print$1}') # 软件源名称
                # tmp_mirror_url=$(echo "${list_arr[i]}" | awk -F '@' '{print$2}') # 软件源地址
                arr_num=$((i + 1))
                default_mirror_name_length=${2:-"30"} # 默认软件源名称打印长度
                ## 补齐长度差异（中文的引号在等宽字体中占1格而非2格）
                [[ $(echo "${tmp_mirror_name}" | grep -c "“") -gt 0 ]] && let default_mirror_name_length+=$(echo "${tmp_mirror_name}" | grep -c "“")
                [[ $(echo "${tmp_mirror_name}" | grep -c "”") -gt 0 ]] && let default_mirror_name_length+=$(echo "${tmp_mirror_name}" | grep -c "”")
                [[ $(echo "${tmp_mirror_name}" | grep -c "‘") -gt 0 ]] && let default_mirror_name_length+=$(echo "${tmp_mirror_name}" | grep -c "‘")
                [[ $(echo "${tmp_mirror_name}" | grep -c "’") -gt 0 ]] && let default_mirror_name_length+=$(echo "${tmp_mirror_name}" | grep -c "’")
                # 非一般字符长度
                tmp_mirror_name_length=$(StringLength "$(echo "${tmp_mirror_name// /}" | sed "s|[0-9a-zA-Z\.\=\:\_\(\)\'\"-\/\!·]||g;")")
                ## 填充空格
                tmp_spaces_nums=$(($((default_mirror_name_length - tmp_mirror_name_length - $(StringLength "${tmp_mirror_name}"))) / 2))
                for ((j = 1; j <= ${tmp_spaces_nums}; j++)); do
                    tmp_mirror_name="${tmp_mirror_name} "
                done
                printf " ❖  %-$((default_mirror_name_length + tmp_mirror_name_length))s %4s\n" "${tmp_mirror_name}" "$arr_num)"
            done
        else
            for ((i = 0; i < ${#list_arr[@]}; i++)); do
                tmp_mirror_name=$(echo "${list_arr[i]}" | awk -F '@' '{print$1}') # 软件源名称
                tmp_mirror_url=$(echo "${list_arr[i]}" | awk -F '@' '{print$2}')  # 软件源地址
                arr_num=$((i + 1))
                echo -e " ❖  $arr_num. ${tmp_mirror_url} | ${tmp_mirror_name}"
            done
        fi
    }

    ## 选择软件源内网地址
    # 例如部分云计算厂商的镜像站区分外网（公网）地址和内网地址，内网地址仅面向云计算厂商云服务器用户使用
    # 内网地址一般不支持使用 HTTPS 协议，所以默认设置为 HTTP 协议
    function choose_intranet_address() {
        local intranet_source
        for ((i = 0; i < ${#mirror_list_extranet[@]}; i++)); do
            if [[ "${SOURCE}" == "${mirror_list_extranet[i]}" ]]; then
                intranet_source="${mirror_list_intranet[i]}"
                ONLY_HTTP="True"
                break
            else
                continue
            fi
        done
        if [[ -z "${USE_INTRANET_SOURCE}" ]]; then
            local CHOICE
            CHOICE=$(echo -e "\n${BOLD}└─ 默认使用软件源的公网地址，是否继续? [Y/n] ${PLAIN}")
            read -rp "${CHOICE}" INPUT
            [[ -z "${INPUT}" ]] && INPUT=Y
            case "${INPUT}" in
            [Yy] | [Yy][Ee][Ss]) ;;
            [Nn] | [Nn][Oo])
                SOURCE="${intranet_source}"
                echo -e "\n$WARN 已切换至内网专用地址，仅限在特定环境下使用！"
                ;;
            *)
                echo -e "\n$WARN 输入错误，默认不使用内网地址！"
                ;;
            esac
        elif [[ "${USE_INTRANET_SOURCE}" == "true" ]]; then
            SOURCE="${intranet_source}"
        fi
    }

    function print_title() {
        local system_name="${SYSTEM_PRETTY_NAME:-"${SYSTEM_NAME} ${SYSTEM_VERSION_NUMBER}"}"
        local arch="${DEVICE_ARCH}"
        local date_time time_zone
        date_time="$(date "+%Y-%m-%d %H:%M:%S")"
        time_zone="$(timedatectl status 2>/dev/null | grep "Time zone" | awk -F ':' '{print$2}' | awk -F ' ' '{print$1}')"

        echo -e ''
        echo -e " 运行环境 ${BLUE}${system_name} ${arch}${PLAIN}"
        echo -e " 系统时间 ${BLUE}${date_time} ${time_zone}${PLAIN}"
    }

    print_title
    if [[ -z "${SOURCE}" ]]; then
        ## 使用官方源
        if [[ "${USE_OFFICIAL_SOURCE}" == "true" ]]; then
            return
        fi

        if [[ ${USE_ABROAD_SOURCE} = "true" ]]; then
            local mirror_list_name="mirror_list_abroad"
            print_mirrors_list "${mirror_list_name}" 60
        elif [[ ${USE_EDU_SOURCE} = "true" ]]; then
            local mirror_list_name="mirror_list_edu"
            print_mirrors_list "${mirror_list_name}" 31
        else
            local mirror_list_name="mirror_list_default"
            print_mirrors_list "${mirror_list_name}" 31
        fi

        local CHOICE
        CHOICE=$(echo -e "\n${BOLD}└─ 请选择并输入你想使用的软件源 [ 1-$(eval echo \${#$mirror_list_name[@]}) ]：${PLAIN}")
        while true; do
            read -rp "${CHOICE}" INPUT
            case "${INPUT}" in
            [1-9] | [1-9][0-9] | [1-9][0-9][0-9])
                local tmp_source
                tmp_source="$(eval echo \${${mirror_list_name}[$((INPUT - 1))]})"
                if [[ -z "${tmp_source}" ]]; then
                    echo -e "\n$WARN 请输入有效的数字序号！"
                else
                    SOURCE="$(eval echo \${${mirror_list_name}[$((INPUT - 1))]} | awk -F '@' '{print$2}')"
                    # echo "${SOURCE}"
                    # exit
                    break
                fi
                ;;
            *)
                echo -e "\n$WARN 请输入数字序号以选择你想使用的软件源！"
                ;;
            esac
        done
    fi

    ## 选择软件源内网地址
    if [[ "${mirror_list_extranet[*]}" =~ (^|[^[:alpha:]])"${SOURCE}"([^[:alpha:]]|$) ]]; then
        choose_intranet_address
    fi
}

## 指定HTTP协议
function choose_protocol() {
    echo -e "\n$WARN 默认使用http协议！"
    WEB_PROTOCOL="http"
    WEB_PROTOCOL="${WEB_PROTOCOL,,}"
}

# 适用于部分红帽系统的 EPEL 附加软件包（安装/换源）
function choose_install_epel_packages() {
    function check_install_status() {
        ## 判断是否已安装 EPEL 软件包
        rpm -qa | grep epel-release -q
        VERIFICATION_EPEL=$?
        ## 判断 /etc/yum.repos.d 目录下是否存在 epel 附加软件包 repo 源文件
        [ -d $Dir_YumRepos ] && ls $Dir_YumRepos | grep epel -q
        VERIFICATION_EPELFILES=$?
        ## 判断 /etc/yum.repos.d.bak 目录下是否存在 epel 附加软件包 repo 源文件
        [ -d $Dir_YumReposBackup ] && ls $Dir_YumReposBackup | grep epel -q
        VERIFICATION_EPELBACKUPFILES=$?
    }

    ## 判断是否支持且需要处理 EPEL 附加软件包
    case "${SYSTEM_FACTIONS}" in
    "${SYSTEM_REDHAT}" | "${SYSTEM_OPENCLOUDOS}" | "${SYSTEM_OPENEULER}")
        if [[ "${SYSTEM_JUDGMENT}" == "${SYSTEM_FEDORA}" ]] || [[ "${INSTALL_EPEL}" == "false" ]]; then
            INSTALL_EPEL="false"
            return
        else
            check_install_status
        fi
        ;;
    *)
        INSTALL_EPEL="false"
        return
        ;;
    esac
    ## 选择是否安装 EPEL 附加软件包
    if [[ -z "${INSTALL_EPEL}" ]]; then
        if [ $VERIFICATION_EPEL -eq 0 ]; then
            local CHOICE
            CHOICE=$(echo -e "\n${BOLD}└─ 检测到系统已安装 EPEL 附加软件包，是否替换/覆盖软件源? [Y/n] ${PLAIN}")
        else
            local CHOICE
            CHOICE=$(echo -e "\n${BOLD}└─ 是否安装 EPEL 附加软件包? [Y/n] ${PLAIN}")
        fi
        read -rp "${CHOICE}" INPUT
        [[ -z "${INPUT}" ]] && INPUT=Y
        case "${INPUT}" in
        [Yy] | [Yy][Ee][Ss])
            INSTALL_EPEL="true"
            ;;
        [Nn] | [Nn][Oo])
            INSTALL_EPEL="false"
            ;;
        *)
            echo -e "\n$WARN 输入错误，默认不更换！"
            INSTALL_EPEL="false"
            ;;
        esac
    fi
}

## 关闭防火墙和SELinux
function close_firewall_service() {
    if [ ! -x /usr/bin/systemctl ]; then
        return
    fi
    if [[ "$(systemctl is-active firewalld)" == "active" ]]; then
        if [[ -z "${CLOSE_FIREWALL}" ]]; then
            local CHOICE
            CHOICE=$(echo -e "\n${BOLD}└─ 是否关闭防火墙和 SELinux ? [Y/n] ${PLAIN}")
            read -rp "${CHOICE}" INPUT
            [[ -z "${INPUT}" ]] && INPUT=Y
            case "${INPUT}" in
            [Yy] | [Yy][Ee][Ss])
                CLOSE_FIREWALL="true"
                ;;
            [Nn] | [Nn][Oo]) ;;
            *)
                echo -e "\n$WARN 输入错误，默认不关闭！"
                ;;
            esac
        fi
        if [[ "${CLOSE_FIREWALL}" == "true" ]]; then
            local SelinuxConfig=/etc/selinux/config
            systemctl disable --now firewalld >/dev/null 2>&1
            [ -s $SelinuxConfig ] && sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" $SelinuxConfig && setenforce 0 >/dev/null 2>&1
        fi
    fi
}

## 备份原有软件源（文件/目录）
function backup_original_mirrors() {
    function backup_file() {
        local target_file=$1
        local backup_file=$2
        local type="$3"
        ## 判断是否存在源文件
        [ -f "${target_file}" ] || touch "${target_file}"
        if [ ! -s "${target_file}" ]; then
            echo -e ''
            return
        fi
        ## 判断是否存在已备份的源文件
        if [ -s "${backup_file}" ]; then
            if [[ "${IGNORE_BACKUP_TIPS}" != "false" ]]; then
                return
            fi
            local CHOICE_BACKUP
            CHOICE_BACKUP=$(echo -e "\n${BOLD}└─ 检测到系统中存在已备份的 ${type} 源文件，是否跳过覆盖备份? [Y/n] ${PLAIN}")
            read -rp "${CHOICE_BACKUP}" INPUT
            [[ -z "${INPUT}" ]] && INPUT=Y
            case "${INPUT}" in
            [Yy] | [Yy][Ee][Ss]) ;;
            [Nn] | [Nn][Oo])
                echo ''
                cp -rvf "${target_file}" "${backup_file}" 2>&1
                BACKED_UP="true"
                ;;
            *)
                echo -e "\n$WARN 输入错误，默认不覆盖！"
                ;;
            esac
        else
            echo ''
            cp -rvf "${target_file}" "${backup_file}" 2>&1
            BACKED_UP="true"
            echo -e "\n$COMPLETE 已备份原有 ${type} 源文件"
            sleep 1s
        fi
    }
    function backup_dir() {
        local target_dir=$1
        local backup_dir=$2
        [ -d "${target_dir}" ] || mkdir -p "${target_dir}"
        [ -d "${backup_dir}" ] || mkdir -p "${backup_dir}"
        ## 判断是否存在 repo 源文件
        ls "${target_dir}" | grep '\.repo$' -q
        if [ $? -ne 0 ]; then
            return
        fi
        ## 判断是否存在已备份的 repo 源文件
        ls "${backup_dir}" | grep '\.repo$' -q
        if [ $? -eq 0 ]; then
            if [[ "${IGNORE_BACKUP_TIPS}" != "false" ]]; then
                return
            fi
            local CHOICE_BACKUP
            CHOICE_BACKUP=$(echo -e "\n${BOLD}└─ 检测到系统中存在已备份的 repo 源文件，是否跳过覆盖备份? [Y/n] ${PLAIN}")
            read -rp "${CHOICE_BACKUP}" INPUT
            [[ -z "${INPUT}" ]] && INPUT=Y
            case "${INPUT}" in
            [Yy] | [Yy][Ee][Ss]) ;;
            [Nn] | [Nn][Oo])
                echo ''
                cp -rvf $target_dir/* "${backup_dir}" 2>&1
                BACKED_UP="true"
                ;;
            *)
                echo -e "\n$WARN 输入错误，默认不覆盖！"
                ;;
            esac
        else
            echo ''
            cp -rvf $target_dir/* "${backup_dir}" 2>&1
            BACKED_UP="true"
            echo -e "\n$COMPLETE 已备份原有 repo 源文件"
            sleep 1s
        fi
    }

    BACKED_UP="false" # 是否已备份
    if [[ "${BACKUP}" == "true" ]]; then
        case "${SYSTEM_FACTIONS}" in
        "${SYSTEM_DEBIAN}")
            if [[ "${SYSTEM_JUDGMENT}" != "${SYSTEM_LINUX_MINT}" ]]; then
                # /etc/apt/sources.list
                backup_file $File_DebianSourceList $File_DebianSourceListBackup "sources.list"
            fi
            ## 自新版本的 Debian 与 Ubuntu 起，软件源文件格式统一为 DEB822 格式，涉及 Debian 12 的容器镜像、Ubuntu 24.04 和未来尚未发布的版本
            # Debian DEB822 格式源文件
            if [[ "${SYSTEM_JUDGMENT}" == "${SYSTEM_DEBIAN}" ]]; then
                [ -f $File_DebianSources ] && backup_file $File_DebianSources $File_DebianSourcesBackup "debian.sources"
            fi
            # Ubuntu DEB822 格式源文件
            if [[ "${SYSTEM_JUDGMENT}" == "${SYSTEM_UBUNTU}" ]]; then
                [ -f $File_UbuntuSources ] && backup_file $File_UbuntuSources $File_UbuntuSourcesBackup "ubuntu.sources"
            fi
            # Armbian
            if [ -f $File_ArmbianRelease ]; then
                backup_file $File_ArmbianSourceList $File_ArmbianSourceListBackup "armbian.list"
            fi
            # Proxmox
            if [ -f $File_ProxmoxVersion ]; then
                backup_file $File_ProxmoxSourceList $File_ProxmoxSourceListBackup "pve-no-subscription.list"
            fi
            # Linux Mint
            if [[ "${SYSTEM_JUDGMENT}" == "${SYSTEM_LINUX_MINT}" ]]; then
                backup_file $File_LinuxMintSourceList $File_LinuxMintSourceListBackup "official-package-repositories.list"
            fi
            ;;
        "${SYSTEM_REDHAT}" | "${SYSTEM_OPENCLOUDOS}" | "${SYSTEM_OPENEULER}")
            # /etc/yum.repos.d
            backup_dir $Dir_YumRepos $Dir_YumReposBackup
            ;;
        "${SYSTEM_OPENSUSE}")
            # /etc/zypp/repos.d
            backup_dir $Dir_openSUSERepos $Dir_openSUSEReposBackup
            ;;
        "${SYSTEM_ARCH}")
            # /etc/pacman.d/mirrorlist
            backup_file $File_ArchLinuxMirrorList $File_ArchLinuxMirrorListBackup "mirrorlist"
            ;;
        "${SYSTEM_ALPINE}")
            # /etc/apk/repositories
            backup_file $File_AlpineRepositories $File_AlpineRepositoriesBackup "repositories"
            ;;
        "${SYSTEM_GENTOO}")
            # /etc/portage/make.conf
            backup_file $File_GentooMakeConf $File_GentooMakeConfBackup "make.conf"
            # /etc/portage/repos.conf/gentoo.conf
            [ -d "${Dir_GentooReposConf}" ] || mkdir -p "${Dir_GentooReposConf}"
            backup_file $File_GentooReposConf $File_GentooReposConfBackup "gentoo.conf"
            ;;
        esac
    fi
}

## 移除原有软件源
function remove_original_mirrors() {
    case "${SYSTEM_FACTIONS}" in
    "${SYSTEM_DEBIAN}")
        if [[ "${SYSTEM_JUDGMENT}" != "${SYSTEM_LINUX_MINT}" ]]; then
            [ -f $File_DebianSourceList ] && sed -i '1,$d' $File_DebianSourceList
        fi
        [ -d $Dir_DebianExtendSource ] || mkdir -p $Dir_DebianExtendSource
        ## 自新版本的 Debian 与 Ubuntu 起，软件源文件格式统一为 DEB822 格式，涉及 Debian 12 的容器镜像、Ubuntu 24.04 和未来尚未发布的版本
        # Debian DEB822 格式源文件
        if [[ "${SYSTEM_JUDGMENT}" == "${SYSTEM_DEBIAN}" ]]; then
            [ -f $File_DebianSources ] && rm -rf $File_DebianSources
        fi
        # Ubuntu DEB822 格式源文件
        if [[ "${SYSTEM_JUDGMENT}" == "${SYSTEM_UBUNTU}" ]]; then
            [ -f $File_UbuntuSources ] && rm -rf $File_UbuntuSources
        fi
        # Armbian
        if [ -f $File_ArmbianRelease ]; then
            [ -f $File_ArmbianSourceList ] && sed -i '1,$d' $File_ArmbianSourceList
        fi
        # Proxmox
        if [ -f $File_ProxmoxVersion ]; then
            [ -f $File_ProxmoxSourceList ] && sed -i '1,$d' $File_ProxmoxSourceList
        fi
        # Linux Mint
        if [[ "${SYSTEM_JUDGMENT}" == "${SYSTEM_LINUX_MINT}" ]]; then
            [ -f $File_LinuxMintSourceList ] && sed -i '1,$d' $File_LinuxMintSourceList
        fi
        ;;
    "${SYSTEM_REDHAT}")
        if [ ! -d $Dir_YumRepos ]; then
            mkdir -p $Dir_YumRepos
            return
        fi
        if [[ "${SYSTEM_JUDGMENT}" == "${SYSTEM_FEDORA}" ]]; then
            # Fedora 有额外源文件，且随版本变化
            for repo_file in fedora.repo fedora-updates.repo fedora-updates-testing.repo fedora-modular.repo fedora-updates-modular.repo fedora-updates-testing-modular.repo; do
                rm -rf $Dir_YumRepos/$repo_file
            done
        else
            if [[ "${ONLY_EPEL}" != "false" ]]; then
                return
            fi
            case "${SYSTEM_JUDGMENT}" in
            "${SYSTEM_RHEL}")
                case ${SYSTEM_VERSION_NUMBER:0:1} in
                9)
                    rm -rf $Dir_YumRepos/rocky* # 注：本脚本旧版遗留问题
                    rm -rf $Dir_YumRepos/centos.repo $Dir_YumRepos/centos-addons.repo
                    ;;
                *)
                    if [ -f $Dir_YumRepos/epel.repo ]; then
                        ls $Dir_YumRepos/ | grep -Ev epel | xargs rm -rf
                    else
                        rm -rf $Dir_YumRepos/*
                    fi
                    ;;
                esac
                ;;
            "${SYSTEM_CENTOS}")
                if [ -f $Dir_YumRepos/epel.repo ]; then
                    ls $Dir_YumRepos/ | grep -Ev epel | xargs rm -rf
                else
                    rm -rf $Dir_YumRepos/*
                fi
                ;;
            "${SYSTEM_CENTOS_STREAM}")
                case ${SYSTEM_VERSION_NUMBER:0:1} in
                9)
                    rm -rf $Dir_YumRepos/centos.repo $Dir_YumRepos/centos-addons.repo
                    ;;
                8)
                    rm -rf $Dir_YumRepos/CentOS-Stream-*
                    ;;
                esac
                ;;
            "${SYSTEM_ROCKY}")
                case ${SYSTEM_VERSION_NUMBER:0:1} in
                9)
                    rm -rf $Dir_YumRepos/rocky*
                    ;;
                8)
                    rm -rf $Dir_YumRepos/Rocky-*
                    ;;
                esac
                ;;
            "${SYSTEM_ALMALINUX}")
                rm -rf $Dir_YumRepos/almalinux*
                ;;
            "${SYSTEM_OPENCLOUDOS}")
                rm -rf $Dir_YumRepos/OpenCloudOS*
                ;;
            esac
        fi
        ;;
    "${SYSTEM_OPENCLOUDOS}")
        [ -d $Dir_YumRepos ] && rm -rf $Dir_YumRepos/OpenCloudOS*
        ;;
    "${SYSTEM_OPENEULER}")
        [ -d $Dir_YumRepos ] && rm -rf $Dir_YumRepos/openEuler.repo
        ;;
    "${SYSTEM_OPENSUSE}")
        [ -d $Dir_openSUSERepos ] && ls $Dir_openSUSERepos/ | grep -E "^repo-" | grep -Ev "openh264" | xargs rm -rf
        ;;
    "${SYSTEM_ARCH}")
        [ -f $File_ArchLinuxMirrorList ] && sed -i '1,$d' $File_ArchLinuxMirrorList
        ;;
    "${SYSTEM_ALPINE}")
        [ -f $File_AlpineRepositories ] && sed -i '1,$d' $File_AlpineRepositories
        ;;
    "${SYSTEM_GENTOO}")
        [ -f $File_GentooReposConf ] && sed -i '1,$d' $File_GentooReposConf
        ;;
    esac
}

## 换源
function change_mirrors_main() {
    ## 打印修改前后差异
    function print_diff() {
        ## 单一文件比较模式
        function diff_file() {
            local diff_file=$1
            local origin_file=$2
            if [[ -s $diff_file ]] && [[ -s $origin_file ]]; then
                if [[ "$(cat "${diff_file}")" != "$(cat "${origin_file}")" ]]; then
                    echo -e "\n${BLUE}${diff_file}${PLAIN} -> ${BLUE}${origin_file}${PLAIN}"
                    diff "${diff_file}" "${origin_file}" -d --color=always -I -B -E
                fi
            fi
        }
        ## 目录文件比较模式
        function diff_dir() {
            local diff_dir=$1
            local origin_dir=$2
            for item in $(ls $diff_dir | xargs); do
                diff_file "${diff_dir}/${item}" "${origin_dir}/${item}"
            done
        }

        if [[ -x /usr/bin/diff && "${BACKED_UP}" == "true" ]]; then
            case "${SYSTEM_FACTIONS}" in
            "${SYSTEM_DEBIAN}")
                if [[ "${SYSTEM_JUDGMENT}" != "${SYSTEM_LINUX_MINT}" ]]; then
                    diff_file $File_DebianSourceListBackup $File_DebianSourceList
                fi
                # Armbian
                if [ -f $File_ArmbianRelease ]; then
                    diff_file $File_ArmbianSourceListBackup $File_ArmbianSourceList
                fi
                # Proxmox
                if [ -f $File_ProxmoxVersion ]; then
                    diff_file $File_ProxmoxSourceListBackup $File_ProxmoxSourceList
                fi
                # Linux Mint
                if [[ "${SYSTEM_JUDGMENT}" == "${SYSTEM_LINUX_MINT}" ]]; then
                    diff_file $File_LinuxMintSourceListBackup $File_LinuxMintSourceList
                fi
                ;;
            "${SYSTEM_REDHAT}" | "${SYSTEM_OPENCLOUDOS}" | "${SYSTEM_OPENEULER}")
                diff_dir $Dir_YumReposBackup $Dir_YumRepos
                ;;
            "${SYSTEM_OPENSUSE}")
                diff_dir $Dir_openSUSEReposBackup $Dir_openSUSERepos
                ;;
            "${SYSTEM_ARCH}")
                diff_file $File_ArchLinuxMirrorListBackup $File_ArchLinuxMirrorList
                ;;
            "${SYSTEM_ALPINE}")
                diff_file $File_AlpineRepositoriesBackup $File_AlpineRepositories
                ;;
            "${SYSTEM_GENTOO}")
                diff_file $File_GentooMakeConfBackup $File_GentooMakeConf
                diff_file $File_GentooReposConfBackup $File_GentooReposConf
                ;;
            esac
        fi
    }

    ## 调用换源函数
    case "${SYSTEM_FACTIONS}" in
    "${SYSTEM_DEBIAN}")
        change_mirrors_Debian
        ;;
    "${SYSTEM_REDHAT}")
        change_mirrors_RedHat
        ;;
    "${SYSTEM_OPENCLOUDOS}")
        change_mirrors_OpenCloudOS
        ;;
    "${SYSTEM_OPENEULER}")
        change_mirrors_openEuler
        ;;
    "${SYSTEM_OPENSUSE}")
        change_mirrors_openSUSE
        ;;
    "${SYSTEM_ARCH}")
        change_mirrors_ArchLinux
        ;;
    "${SYSTEM_ALPINE}")
        change_mirrors_Alpine
        ;;
    "${SYSTEM_GENTOO}")
        change_mirrors_Gentoo
        ;;
    esac
    ## 比较差异
    if [[ "${PRINT_DIFF}" == "true" ]]; then
        print_diff
    fi
    ## 更新软件源
    echo -e "\n$WORKING 开始${SYNC_MIRROR_TEXT}...\n"
    case "${SYSTEM_FACTIONS}" in
    "${SYSTEM_DEBIAN}")
        apt-get update
        ;;
    "${SYSTEM_REDHAT}" | "${SYSTEM_OPENCLOUDOS}" | "${SYSTEM_OPENEULER}")
        local package_manager="yum"
        case "${SYSTEM_JUDGMENT}" in
        "${SYSTEM_CENTOS_STREAM}" | "${SYSTEM_ROCKY}" | "${SYSTEM_ALMALINUX}" | "${SYSTEM_RHEL}")
            case ${SYSTEM_VERSION_NUMBER:0:1} in
            9)
                package_manager="dnf"
                ;;
            esac
            ;;
        "${SYSTEM_FEDORA}" | "${SYSTEM_OPENCLOUDOS}" | "${SYSTEM_OPENEULER}")
            package_manager="dnf"
            ;;
        esac
        $package_manager makecache
        ;;
    "${SYSTEM_OPENSUSE}")
        zypper ref
        ;;
    "${SYSTEM_ARCH}")
        pacman -Sy
        ;;
    "${SYSTEM_ALPINE}")
        apk update -f
        ;;
    "${SYSTEM_GENTOO}")
        emerge --sync --quiet
        ;;
    esac
    if [ $? -eq 0 ]; then
        echo -e "\n$SUCCESS 软件源更换完毕"
    else
        echo -e "\n$FAIL 软件源更换完毕，但${SYNC_MIRROR_TEXT}失败\n"
        echo -e "请再次执行脚本并更换相同软件源后进行尝试，若仍然${SYNC_MIRROR_TEXT}失败那么可能由以下原因导致"
        echo -e "1. 网络问题：例如连接异常、由地区影响的网络间歇式中断等"
        echo -e "2. 软件源问题：建议更换其它镜像站进行尝试，少数情况下软件源若处于同步中状态则可能会出现文件同步错误问题"
        echo -e "\n软件源地址：${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH}\n"
        exit 1
    fi
}

## 升级软件包
function upgrade_software() {
    function clean_cache() {
        ## 交互确认
        if [[ -z "${CLEAN_CACHE}" ]]; then
            CLEAN_CACHE="false"
            local CHOICE
            CHOICE=$(echo -e "\n${BOLD}└─ 是否清理已下载的软件包缓存? [Y/n] ${PLAIN}")
            read -rp "${CHOICE}" INPUT
            [[ -z "${INPUT}" ]] && INPUT=Y
            case "${INPUT}" in
            [Yy] | [Yy][Ee][Ss])
                CLEAN_CACHE="true"
                ;;
            [Nn] | [Nn][Oo]) ;;
            *)
                echo -e "\n$WARN 输入错误，默认不清理！"
                ;;
            esac
        fi
        if [[ "${CLEAN_CACHE}" == "false" ]]; then
            return
        fi
        ## 调用系统命令
        case "${SYSTEM_FACTIONS}" in
        "${SYSTEM_DEBIAN}")
            apt-get autoremove -y >/dev/null 2>&1
            apt-get clean >/dev/null 2>&1
            ;;
        "${SYSTEM_REDHAT}" | "${SYSTEM_OPENCLOUDOS}" | "${SYSTEM_OPENEULER}")
            local package_manager="yum"
            case "${SYSTEM_JUDGMENT}" in
            "${SYSTEM_CENTOS_STREAM}" | "${SYSTEM_ROCKY}" | "${SYSTEM_ALMALINUX}" | "${SYSTEM_RHEL}")
                case ${SYSTEM_VERSION_NUMBER:0:1} in
                9)
                    package_manager="dnf"
                    ;;
                esac
                ;;
            "${SYSTEM_FEDORA}" | "${SYSTEM_OPENCLOUDOS}" | "${SYSTEM_OPENEULER}")
                package_manager="dnf"
                ;;
            esac
            $package_manager autoremove -y >/dev/null 2>&1
            $package_manager clean packages -y >/dev/null 2>&1
            ;;
        "${SYSTEM_OPENSUSE}")
            rm -rf /var/cache/zypp/* >/dev/null 2>&1
            ;;
        "${SYSTEM_ALPINE}")
            rm -rf /var/cache/apk/* >/dev/null 2>&1
            ;;
        "${SYSTEM_GENTOO}")
            eclean-dist --deep >/dev/null 2>&1
            eclean-packages --deep >/dev/null 2>&1
            ;;
        esac
        echo -e "\n$COMPLETE 清理完毕"
    }

    ## 跳过特殊系统
    case "${SYSTEM_JUDGMENT}" in
    "${SYSTEM_ARCH}")
        return
        ;;
    esac

    ## 交互确认
    if [[ -z "${UPGRADE_SOFTWARE}" ]]; then
        UPGRADE_SOFTWARE="false"
        local CHOICE
        CHOICE=$(echo -e "\n${BOLD}└─ 是否跳过更新软件包? [Y/n] ${PLAIN}")
        read -rp "${CHOICE}" INPUT
        [[ -z "${INPUT}" ]] && INPUT=Y
        case "${INPUT}" in
        [Yy] | [Yy][Ee][Ss]) ;;
        [Nn] | [Nn][Oo])
            UPGRADE_SOFTWARE="true"
            ;;
        *)
            echo -e "\n$WARN 输入错误，默认不更新！"
            ;;
        esac
    fi
    if [[ "${UPGRADE_SOFTWARE}" == "false" ]]; then
        return
    fi
    echo -e ''
    ## 调用系统命令
    case "${SYSTEM_FACTIONS}" in
    "${SYSTEM_DEBIAN}")
        apt-get upgrade -y
        ;;
    "${SYSTEM_REDHAT}" | "${SYSTEM_OPENCLOUDOS}" | "${SYSTEM_OPENEULER}")
        local package_manager="yum"
        case "${SYSTEM_JUDGMENT}" in
        "${SYSTEM_CENTOS_STREAM}" | "${SYSTEM_ROCKY}" | "${SYSTEM_ALMALINUX}" | "${SYSTEM_RHEL}")
            case ${SYSTEM_VERSION_NUMBER:0:1} in
            9)
                package_manager="dnf"
                ;;
            esac
            ;;
        "${SYSTEM_FEDORA}" | "${SYSTEM_OPENCLOUDOS}" | "${SYSTEM_OPENEULER}")
            package_manager="dnf"
            ;;
        esac
        $package_manager update -y --skip-broken
        ;;
    "${SYSTEM_OPENSUSE}")
        zypper update -y
        ;;
    "${SYSTEM_ALPINE}")
        apk upgrade --no-cache
        ;;
    "${SYSTEM_GENTOO}")
        emerge --update --deep --with-bdeps=y --ask=n @world
        ;;
    esac
    ## 清理缓存
    clean_cache
}

##############################################################################

## 更换基于 Debian 系 Linux 发行版的软件源
function change_mirrors_Debian() {
    function gen_debian_source() {
        echo "deb ${1} ${2} ${3}
# deb-src ${1} ${2} ${3}
deb ${1} ${2}-updates ${3}
# deb-src ${1} ${2}-updates ${3}
deb ${1} ${2}-backports ${3}
# deb-src ${1} ${2}-backports ${3}"
    }
    function gen_debian_security_source() {
        echo "deb ${1} ${2}-security ${3}
# deb-src ${1} ${2}-security ${3}"
    }
    function gen_ubuntu_source() {
        echo "deb ${1} ${2} ${3}
# deb-src ${1} ${2} ${3}
deb ${1} ${2}-updates ${3}
# deb-src ${1} ${2}-updates ${3}
deb ${1} ${2}-backports ${3}
# deb-src ${1} ${2}-backports ${3}
deb ${1} ${2}-security ${3}
# deb-src ${1} ${2}-security ${3}

## 预发布软件源（不建议启用）
# deb ${1} ${2}-proposed ${3}
# deb-src ${1} ${2}-proposed ${3}"
    }

    ## 使用官方源
    if [[ "${USE_OFFICIAL_SOURCE}" == "true" ]]; then
        case "${SYSTEM_JUDGMENT}" in
        "${SYSTEM_DEBIAN}")
            SOURCE="deb.debian.org"
            ;;
        "${SYSTEM_UBUNTU}")
            SOURCE="archive.ubuntu.com"
            ;;
        "${SYSTEM_KALI}")
            SOURCE="http.kali.org"
            ;;
        "${SYSTEM_DEEPIN}")
            SOURCE="community-packages.deepin.com"
            ;;
        "${SYSTEM_LINUX_MINT}")
            SOURCE="packages.linuxmint.com"
            ;;
        esac
    fi
    local repository_sections # 仓库区域
    local tips="## 默认禁用源码镜像以提高速度，如需启用请自行取消注释"
    local base_url="${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH}"
    case "${SYSTEM_JUDGMENT}" in
    "${SYSTEM_DEBIAN}")
        case "${SYSTEM_VERSION_NUMBER}" in
        8 | 9 | 10 | 11)
            repository_sections="main contrib non-free"
            ;;
        *)
            repository_sections="main contrib non-free non-free-firmware"
            ;;
        esac
        if [[ "${SYSTEM_VERSION_CODENAME}" != "sid" ]]; then
            echo "${tips}
$(gen_debian_source "${base_url}" "${SYSTEM_VERSION_CODENAME}" "${repository_sections}")" >>$File_DebianSourceList
            # 处理 debian-security 仓库源
            base_url="${WEB_PROTOCOL}://${SOURCE_SECURITY:-"${SOURCE}"}/${SOURCE_SECURITY_BRANCH:-"${SOURCE_BRANCH}-security"}"
            echo "$(gen_debian_security_source "${base_url}" "${SYSTEM_VERSION_CODENAME}" "${repository_sections}")" >>$File_DebianSourceList
        else
            echo "deb ${base_url} ${SYSTEM_VERSION_CODENAME} ${repository_sections}
# deb-src ${base_url} ${SYSTEM_VERSION_CODENAME} ${repository_sections}" >>$File_DebianSourceList
        fi
        ;;
    "${SYSTEM_UBUNTU}")
        repository_sections="main restricted universe multiverse"
        echo "${tips}
$(gen_ubuntu_source "${base_url}" "${SYSTEM_VERSION_CODENAME}" "${repository_sections}")" >>$File_DebianSourceList
        ;;
    "${SYSTEM_KALI}")
        repository_sections="main contrib non-free non-free-firmware"
        echo "${tips}
deb ${base_url} ${SYSTEM_VERSION_CODENAME} ${repository_sections}
# deb-src ${base_url} ${SYSTEM_VERSION_CODENAME} ${repository_sections}" >>$File_DebianSourceList
        ;;
    "${SYSTEM_DEEPIN}")
        repository_sections="apricot main contrib non-free"
        echo "${tips}
deb ${base_url} ${repository_sections}
# deb-src ${base_url} ${repository_sections}" >>$File_DebianSourceList
        ;;
    "${SYSTEM_LINUX_MINT}")
        ## 专用源
        repository_sections="main upstream import backport"
        echo "${tips}
deb ${base_url} ${SYSTEM_VERSION_CODENAME} ${repository_sections}
" >>$File_LinuxMintSourceList
        ## 底层系统软件源
        local base_system_source_branch base_system_codename
        if [[ "${SYSTEM_VERSION_NUMBER}" == 6 ]]; then
            # Debian 版（LMDE）
            base_system_source_branch="debian"
            base_system_codename="bookworm"
            repository_sections="main contrib non-free non-free-firmware"
            base_url="${WEB_PROTOCOL}://${SOURCE}/${base_system_source_branch}"
            echo "$(gen_debian_source "${base_url}" "${base_system_codename}" "${repository_sections}")" >>$File_LinuxMintSourceList
            # 处理 debian-security 仓库源
            base_url="${WEB_PROTOCOL}://${SOURCE_SECURITY:-"${SOURCE}"}/${SOURCE_SECURITY_BRANCH:-"${base_system_source_branch}-security"}"
            echo "$(gen_debian_security_source "${base_url}" "${base_system_codename}" "${repository_sections}")" >>$File_LinuxMintSourceList
        else
            # Ubuntu 版
            if [[ "${DEVICE_ARCH}" == "x86_64" ]] || [[ "${DEVICE_ARCH}" == *i?86* ]]; then
                base_system_source_branch="ubuntu"
            else
                base_system_source_branch="ubuntu-ports"
            fi
            case "${SYSTEM_VERSION_NUMBER:0:2}" in
            21)
                base_system_codename="jammy"
                ;;
            20)
                base_system_codename="focal"
                ;;
            19)
                base_system_codename="bionic"
                ;;
            esac
            repository_sections="main restricted universe multiverse"
            base_url="${WEB_PROTOCOL}://${SOURCE}/${base_system_source_branch}"
            echo "$(gen_ubuntu_source "${base_url}" "${base_system_codename}" "${repository_sections}")" >>$File_LinuxMintSourceList
        fi
        ;;
    esac
    ## 处理其它衍生操作系统的专用源
    # Armbian
    if [ -f $File_ArmbianRelease ]; then
        echo "deb [signed-by=/usr/share/keyrings/armbian.gpg] ${WEB_PROTOCOL}://${SOURCE}/armbian ${SYSTEM_VERSION_CODENAME} main ${SYSTEM_VERSION_CODENAME}-utils ${SYSTEM_VERSION_CODENAME}-desktop" >>$File_ArmbianSourceList
    fi
    # Proxmox
    if [ -f $File_ProxmoxVersion ]; then
        echo "deb ${WEB_PROTOCOL}://${SOURCE}/proxmox/debian/pve ${SYSTEM_VERSION_CODENAME} pve-no-subscription
# deb ${WEB_PROTOCOL}://${SOURCE}/proxmox/debian/pbs ${SYSTEM_VERSION_CODENAME} pbs-no-subscription
# deb ${WEB_PROTOCOL}://${SOURCE}/proxmox/debian/pbs-client ${SYSTEM_VERSION_CODENAME} pbs-client-no-subscription
# deb ${WEB_PROTOCOL}://${SOURCE}/proxmox/debian/pmg ${SYSTEM_VERSION_CODENAME} pmg-no-subscription" >>$File_ProxmoxSourceList
    fi
}

## 更换基于 RedHat 系 Linux 发行版的软件源
function change_mirrors_RedHat() {
    ## 仅 EPEL 模式
    if [[ "${ONLY_EPEL}" == "true" ]]; then
        change_mirrors_or_install_EPEL # EPEL 附加软件包
        return
    fi
    ## 生成官方 repo 源文件
    case "${SYSTEM_JUDGMENT}" in
    "${SYSTEM_RHEL}")
        case ${SYSTEM_VERSION_NUMBER:0:1} in
        9)
            gen_repo_files_CentOSStream "${SYSTEM_VERSION_NUMBER:0:1}"
            ;;
        *)
            gen_repo_files_CentOS "${SYSTEM_VERSION_NUMBER:0:1}"
            ;;
        esac
        ;;
    "${SYSTEM_CENTOS}")
        gen_repo_files_CentOS "${SYSTEM_VERSION_NUMBER:0:1}"
        ;;
    "${SYSTEM_CENTOS_STREAM}")
        gen_repo_files_CentOSStream "${SYSTEM_VERSION_NUMBER:0:1}"
        ;;
    "${SYSTEM_ROCKY}")
        gen_repo_files_RockyLinux "${SYSTEM_VERSION_NUMBER:0:1}"
        ;;
    "${SYSTEM_ALMALINUX}")
        gen_repo_files_AlmaLinux "${SYSTEM_VERSION_NUMBER:0:1}"
        ;;
    "${SYSTEM_FEDORA}")
        gen_repo_files_Fedora "${SYSTEM_VERSION_NUMBER}"
        ;;
    "${SYSTEM_OPENCLOUDOS}")
        gen_repo_files_OpenCloudOS "${SYSTEM_VERSION_NUMBER:0:1}"
        ;;
    esac
    ## 使用官方源
    if [[ "${USE_OFFICIAL_SOURCE}" == "true" ]]; then
        change_mirrors_or_install_EPEL # EPEL 附加软件包
        return
    fi

    ## 修改源
    cd $Dir_YumRepos
    case "${SYSTEM_JUDGMENT}" in
    "${SYSTEM_RHEL}")
        case ${SYSTEM_VERSION_NUMBER:0:1} in
        9)
            sed -e "s|^#baseurl=https|baseurl=${WEB_PROTOCOL}|g" \
                -e "s|^metalink=|#metalink=|g" \
                -e "s|mirror.stream.centos.org|${SOURCE}/${SOURCE_BRANCH}|g" \
                -i \
                centos.repo \
                centos-addons.repo
            # 禁用 GPG 签名检查
            sed -e "s|gpgcheck=1|gpgcheck=0|g" \
                -i \
                centos.repo \
                centos-addons.repo
            ;;
        *)
            sed -i "s|^#baseurl=http|baseurl=${WEB_PROTOCOL}|g" CentOS-*
            sed -i 's|^mirrorlist=|#mirrorlist=|g' CentOS-*
            case ${SYSTEM_VERSION_NUMBER:0:1} in
            8)
                sed -i "s|mirror.centos.org/\$contentdir|mirror.centos.org/centos-vault|g" CentOS-*
                sed -i "s/\$releasever/8.5.2111/g" CentOS-*
                # 单独处理 CentOS-Linux-Sources.repo
                sed -i "s|vault.centos.org/\$contentdir|${SOURCE_VAULT:-"${SOURCE}"}/${SOURCE_VAULT_BRANCH:-"centos-vault"}|g" CentOS-Linux-Sources.repo
                ;;
            7)
                sed -i "s|mirror.centos.org/\$contentdir|mirror.centos.org/${SOURCE_BRANCH}|g" CentOS-*
                sed -i "s/\$releasever/7/g" CentOS-*
                # 单独处理 CentOS-Sources.repo
                sed -i "s|vault.centos.org/centos|${SOURCE_VAULT:-"${SOURCE}"}/${SOURCE_VAULT_BRANCH:-"${SOURCE_BRANCH}"}|g" CentOS-Sources.repo
                ;;
            esac
            sed -i "s|mirror.centos.org|${SOURCE}|g" CentOS-*
            ;;
        esac
        ;;
    "${SYSTEM_CENTOS}")
        sed -i "s|^#baseurl=http|baseurl=${WEB_PROTOCOL}|g" CentOS-*
        sed -i 's|^mirrorlist=|#mirrorlist=|g' CentOS-*
        ## CentOS 7/8 操作系统版本结束了生命周期（EOL），Linux 社区已不再维护该操作系统版本
        case ${SYSTEM_VERSION_NUMBER:0:1} in
        8)
            # 最终版本为 8.5.2011，从 2022-02 开始切换至 centos-vault 分支
            sed -i "s|mirror.centos.org/\$contentdir|mirror.centos.org/${SOURCE_BRANCH:-"centos-vault"}|g" CentOS-*
            sed -i "s/\$releasever/8.5.2111/g" CentOS-*
            sed -i "s|vault.centos.org/\$contentdir|${SOURCE_VAULT:-"${SOURCE}"}/${SOURCE_VAULT_BRANCH:-"centos-vault"}|g" CentOS-Linux-Sources.repo # 单独处理 CentOS-Linux-Sources.repo
            ;;
        7)
            # 最终版本为 7.9.2009，从 2024-07 开始切换至 centos-vault 分支
            sed -i "s|mirror.centos.org/centos|mirror.centos.org/${SOURCE_BRANCH:-"centos-vault"}|g" CentOS-*
            sed -i "s/\$releasever/7.9.2009/g" CentOS-*
            sed -i "s|vault.centos.org/centos|${SOURCE_VAULT:-"${SOURCE}"}/${SOURCE_VAULT_BRANCH:-"centos-vault"}|g" CentOS-Sources.repo # 单独处理 CentOS-Sources.repo
            ;;
        esac
        sed -i "s|mirror.centos.org|${SOURCE}|g" CentOS-*
        ;;
    "${SYSTEM_CENTOS_STREAM}")
        case ${SYSTEM_VERSION_NUMBER:0:1} in
        9)
            sed -e "s|^#baseurl=https|baseurl=${WEB_PROTOCOL}|g" \
                -e "s|^metalink=|#metalink=|g" \
                -e "s|mirror.stream.centos.org|${SOURCE}/${SOURCE_BRANCH}|g" \
                -i \
                centos.repo \
                centos-addons.repo
            ;;
        8)
            sed -i "s|vault.centos.org/\$contentdir|${SOURCE_VAULT:-"${SOURCE}"}/${SOURCE_VAULT_BRANCH:-"${SOURCE_BRANCH}"}|g" CentOS-Stream-Sources.repo # 单独处理 CentOS-Stream-Sources.repo
            sed -e "s|^#baseurl=http|baseurl=${WEB_PROTOCOL}|g" \
                -e "s|^mirrorlist=|#mirrorlist=|g" \
                -e "s|mirror.centos.org/\$contentdir|${SOURCE}/${SOURCE_BRANCH}|g" \
                -i \
                CentOS-Stream-*
            ;;
        esac
        ;;
    "${SYSTEM_ROCKY}")
        case ${SYSTEM_VERSION_NUMBER:0:1} in
        9)
            sed -e "s|^#baseurl=http|baseurl=${WEB_PROTOCOL}|g" \
                -e "s|^mirrorlist=|#mirrorlist=|g" \
                -e "s|dl.rockylinux.org/\$contentdir|${SOURCE}/${SOURCE_BRANCH}|g" \
                -i \
                rocky.repo \
                rocky-addons.repo \
                rocky-devel.repo \
                rocky-extras.repo
            ;;
        8)
            sed -e "s|^#baseurl=http|baseurl=${WEB_PROTOCOL}|g" \
                -e "s|^mirrorlist=|#mirrorlist=|g" \
                -e "s|dl.rockylinux.org/\$contentdir|${SOURCE}/${SOURCE_BRANCH}|g" \
                -i \
                Rocky-*
            ;;
        esac
        ;;
    "${SYSTEM_ALMALINUX}")
        case ${SYSTEM_VERSION_NUMBER:0:1} in
        9)
            sed -e "s|^# baseurl=http|baseurl=${WEB_PROTOCOL}|g" \
                -e "s|^mirrorlist=|#mirrorlist=|g" \
                -e "s|repo.almalinux.org/vault|${SOURCE_VAULT:-"${SOURCE}"}/${SOURCE_VAULT_BRANCH:-"almalinux-vault"}|g" \
                -e "s|repo.almalinux.org/almalinux|${SOURCE}/${SOURCE_BRANCH}|g" \
                -i \
                almalinux-*
            ;;
        8)
            sed -e "s|^mirrorlist=|#mirrorlist=|g" \
                -e "s|^# baseurl=http|baseurl=${WEB_PROTOCOL}|g" \
                -e "s|repo.almalinux.org/vault|${SOURCE_VAULT:-"${SOURCE}"}/${SOURCE_VAULT_BRANCH:-"almalinux-vault"}|g" \
                -e "s|repo.almalinux.org/almalinux|${SOURCE}/${SOURCE_BRANCH}|g" \
                -i \
                almalinux-ha.repo \
                almalinux-nfv.repo \
                almalinux-plus.repo \
                almalinux-powertools.repo \
                almalinux-resilientstorage.repo \
                almalinux-rt.repo \
                almalinux-sap.repo \
                almalinux-saphana.repo \
                almalinux.repo
            ;;
        esac
        ;;
    "${SYSTEM_FEDORA}")
        # 自 Fedora 39 起不再使用 modular 仓库
        local fedora_repo_files
        if [[ "${SYSTEM_VERSION_NUMBER}" -lt 39 ]]; then
            fedora_repo_files="fedora.repo fedora-updates.repo fedora-updates-testing.repo fedora-modular.repo fedora-updates-modular.repo fedora-updates-testing-modular.repo"
        else
            fedora_repo_files="fedora.repo fedora-updates.repo fedora-updates-testing.repo"
        fi
        sed -e "s|^metalink=|#metalink=|g" \
            -e "s|^#baseurl=http|baseurl=${WEB_PROTOCOL}|g" \
            -e "s|download.example/pub/fedora/linux|${SOURCE}/${SOURCE_BRANCH}|g" \
            -i \
            $fedora_repo_files
        ;;
    "${SYSTEM_OPENCLOUDOS}")
        case ${SYSTEM_VERSION_NUMBER:0:1} in
        8)
            sed -e "s|^baseurl=https|baseurl=${WEB_PROTOCOL}|g" \
                -e "s|mirrors.opencloudos.tech/opencloudos|${SOURCE}/${SOURCE_BRANCH}|g" \
                -i \
                OpenCloudOS-Debuginfo.repo \
                OpenCloudOS.repo \
                OpenCloudOS-Sources.repo
            ;;
        esac
        ;;
    esac

    change_mirrors_or_install_EPEL # EPEL 附加软件包
}

## 更换 OpenCloudOS 发行版软件源
function change_mirrors_OpenCloudOS() {
    ## 生成官方 repo 源文件
    gen_repo_files_OpenCloudOS "${SYSTEM_VERSION_NUMBER:0:1}"
    ## 使用官方源
    if [[ "${USE_OFFICIAL_SOURCE}" == "true" ]]; then
        change_mirrors_or_install_EPEL # EPEL 附加软件包
        return
    fi

    ## 修改源
    cd $Dir_YumRepos
    case ${SYSTEM_VERSION_NUMBER:0:1} in
    9)
        sed -e "s|^baseurl=https|baseurl=${WEB_PROTOCOL}|g" \
            -e "s|mirrors.opencloudos.tech/opencloudos|${SOURCE}/${SOURCE_BRANCH}|g" \
            -i \
            OpenCloudOS.repo
        ;;
    esac

    change_mirrors_or_install_EPEL # EPEL 附加软件包
}

## 更换 openEuler 发行版软件源
function change_mirrors_openEuler() {
    ## 生成官方 repo 源文件
    gen_repo_files_openEuler
    ## 使用官方源
    if [[ "${USE_OFFICIAL_SOURCE}" == "true" ]]; then
        change_mirrors_or_install_EPEL # EPEL 附加软件包
        return
    fi

    ## 修改源
    cd $Dir_YumRepos
    local version_name="$(cat $File_LinuxRelease | grep -E "^VERSION=" | awk -F '=' '{print$2}' | sed "s/[\'\"]//g; s/[()]/ /g; s/  / /g; s/^ //g; s/ $//g; s/ /-/g; s/_/-/g")"
    sed -e "s|^baseurl=http|baseurl=${WEB_PROTOCOL}|g" \
        -e "s|repo.openeuler.org|${SOURCE}/${SOURCE_BRANCH}|g" \
        -e "s|openEuler-version|openEuler-${version_name}|g" \
        -i \
        openEuler.repo

    change_mirrors_or_install_EPEL # EPEL 附加软件包
}

## 更换 openSUSE 发行版软件源
function change_mirrors_openSUSE() {
    ## 生成官方 repo 源文件
    case "${SYSTEM_ID}" in
    "opensuse-leap")
        gen_repo_files_openSUSE "leap" "${SYSTEM_VERSION_NUMBER}"
        ;;
    "opensuse-tumbleweed")
        gen_repo_files_openSUSE "tumbleweed"
        ;;
    esac
    ## 使用官方源
    if [[ "${USE_OFFICIAL_SOURCE}" == "true" ]]; then
        return
    fi

    ## 修改源
    cd $Dir_openSUSERepos
    # 更换软件源
    sed -i "s|^#baseurl=http|baseurl=${WEB_PROTOCOL}|g" repo-*
    case "${SYSTEM_ID}" in
    opensuse-leap)
        case "${SYSTEM_VERSION_NUMBER}" in
        15.[0-2])
            sed -i "s|download.opensuse.org|${SOURCE}/${SOURCE_BRANCH}|g" \
                repo-debug-non-oss.repo \
                repo-debug.repo \
                repo-debug-update-non-oss.repo \
                repo-debug-update.repo \
                repo-non-oss.repo \
                repo-oss.repo \
                repo-source-non-oss.repo \
                repo-source.repo \
                repo-update-non-oss.repo \
                repo-update.repo
            ;;
        *)
            sed -i "s|download.opensuse.org|${SOURCE}/${SOURCE_BRANCH}|g" \
                repo-backports-debug-update.repo \
                repo-backports-update.repo \
                repo-debug-non-oss.repo \
                repo-debug.repo \
                repo-debug-update-non-oss.repo \
                repo-debug-update.repo \
                repo-non-oss.repo \
                repo-oss.repo \
                repo-sle-debug-update.repo \
                repo-sle-update.repo \
                repo-source.repo \
                repo-update-non-oss.repo \
                repo-update.repo
            ;;
        esac
        ;;
    opensuse-tumbleweed)
        sed -i "s|download.opensuse.org|${SOURCE}/${SOURCE_BRANCH}|g" \
            repo-debug.repo \
            repo-non-oss.repo \
            repo-openh264.repo \
            repo-oss.repo \
            repo-source.repo \
            repo-update.repo
        ;;
    esac
}

## 更换 Arch Linux 发行版软件源
function change_mirrors_ArchLinux() {
    ## 使用官方源
    if [[ "${USE_OFFICIAL_SOURCE}" == "true" ]]; then
        SOURCE="mirrors.aliyun.com"
        echo -e "\n${TIP} 由于 Arch Linux 无官方源因此已切换至阿里源\n"
    fi
    ## 修改源
    case "${SOURCE_BRANCH}" in
    "archlinuxarm")
        echo "Server = ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH}/\$arch/\$repo" >>$File_ArchLinuxMirrorList
        ;;
    "archlinuxcn")
        echo "Server = ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH}/\$arch" >>$File_ArchLinuxMirrorList
        ;;
    *)
        echo "Server = ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH}/\$repo/os/\$arch" >>$File_ArchLinuxMirrorList
        ;;
    esac
}

## 更换 Alpine Linux 发行版软件源
function change_mirrors_Alpine() {
    ## 使用官方源
    if [[ "${USE_OFFICIAL_SOURCE}" == "true" ]]; then
        SOURCE="dl-cdn.alpinelinux.org"
    fi
    local version_name
    echo "${SYSTEM_PRETTY_NAME}" | grep " edge" -q
    if [ $? -eq 0 ]; then
        version_name="edge"
    else
        version_name="v${SYSTEM_VERSION_NUMBER%.*}"
    fi
    ## 修改源
    echo "${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH}/${version_name}/main
${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH}/${version_name}/community" >>$File_AlpineRepositories
}

## 更换 Gentoo 发行版软件源
function change_mirrors_Gentoo() {
    ## 使用官方源
    if [[ "${USE_OFFICIAL_SOURCE}" == "true" ]]; then
        grep -Eq "^GENTOO_MIRRORS=" $File_GentooMakeConf
        if [ $? -eq 0 ]; then
            sed -i "/^GENTOO_MIRRORS=/d" $File_GentooMakeConf
        fi
        [ -f $File_GentooReposConf ] && rm -rf $File_GentooReposConf
        return
    fi
    ## 修改源
    grep -Eq "^GENTOO_MIRRORS=" $File_GentooMakeConf
    if [ $? -eq 0 ]; then
        sed -i "s|^GENTOO_MIRRORS=.*|GENTOO_MIRRORS=\"${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH}\"|g" $File_GentooMakeConf
    else
        echo -e "\nGENTOO_MIRRORS=\"${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH}\"" >>$File_GentooMakeConf
    fi
    echo "[DEFAULT]
main-repo = gentoo

[gentoo]
location = /usr/portage
sync-type = rsync
sync-uri = rsync://${SOURCE_PORTAGE:-"${SOURCE}"}/${SOURCE_PORTAGE_BRANCH:-"gentoo-portage"}
auto-sync = yes" >$File_GentooReposConf
}

## EPEL (Extra Packages for Enterprise Linux) 附加软件包 - 安装或更换软件源
function change_mirrors_or_install_EPEL() {
    if [[ "${INSTALL_EPEL}" != "true" ]]; then
        return
    fi
    ## 确定安装版本（不支持安装的系统直接跳出）
    local target_version
    case "${SYSTEM_FACTIONS}" in
    "${SYSTEM_REDHAT}" | "${SYSTEM_OPENCLOUDOS}")
        if [[ "${SYSTEM_JUDGMENT}" == "${SYSTEM_FEDORA}" ]]; then
            return
        else
            target_version="${SYSTEM_VERSION_NUMBER:0:1}"
        fi
        ;;
    "${SYSTEM_OPENEULER}")
        target_version="9"
        ;;
    *)
        return
        ;;
    esac
    ## 安装 EPEL 软件包
    if [ "${VERIFICATION_EPEL}" -ne 0 ]; then
        echo -e "\n${WORKING} 安装 epel-release 软件包...\n"
        local package_manager="yum"
        case "${SYSTEM_JUDGMENT}" in
        "${SYSTEM_CENTOS_STREAM}" | "${SYSTEM_ROCKY}" | "${SYSTEM_ALMALINUX}" | "${SYSTEM_RHEL}")
            case ${SYSTEM_VERSION_NUMBER:0:1} in
            9)
                package_manager="dnf"
                ;;
            esac
            ;;
        "${SYSTEM_FEDORA}" | "${SYSTEM_OPENCLOUDOS}" | "${SYSTEM_OPENEULER}")
            package_manager="dnf"
            ;;
        esac
        $package_manager install -y https://mirrors.cloud.tencent.com/epel/epel-release-latest-${target_version}.noarch.rpm
        rm -rf $Dir_YumRepos/epel*
    fi
    ## 删除原有 repo 源文件
    [ "${VERIFICATION_EPELFILES}" -eq 0 ] && rm -rf $Dir_YumRepos/epel*
    [ "${VERIFICATION_EPELBACKUPFILES}" -eq 0 ] && rm -rf $Dir_YumReposBackup/epel*
    ## 生成 repo 源文件
    gen_repo_files_EPEL
    if [[ "${USE_OFFICIAL_SOURCE}" == "true" ]]; then
        return
    fi
    ## 修改源
    sed -e "s|^#baseurl=http\(s\)\?|baseurl=${WEB_PROTOCOL}|g" \
        -e "s|^metalink=|#metalink=|g" \
        -e "s|download.example/pub/epel|${SOURCE_EPEL:-"${SOURCE}"}/${SOURCE_EPEL_BRANCH:-"epel"}|g" \
        -e "s|download.fedoraproject.org/pub/epel|${SOURCE_EPEL:-"${SOURCE}"}/${SOURCE_EPEL_BRANCH:-"epel"}|g" \
        -i \
        $Dir_YumRepos/epel*
}

##############################################################################

## 生成 CentOS 官方 repo 源文件
function gen_repo_files_CentOS() {
    case "$1" in
    8)
        cat <<'EOF' >$Dir_YumRepos/CentOS-Linux-AppStream.repo
# CentOS-Linux-AppStream.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[appstream]
name=CentOS Linux $releasever - AppStream
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=AppStream&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/AppStream/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Linux-BaseOS.repo
# CentOS-Linux-BaseOS.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[baseos]
name=CentOS Linux $releasever - BaseOS
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=BaseOS&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/BaseOS/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Linux-ContinuousRelease.repo
# CentOS-Linux-ContinuousRelease.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.
#
# The Continuous Release (CR) repository contains packages for the next minor
# release of CentOS Linux.  This repository only has content in the time period
# between an upstream release and the official CentOS Linux release.  These
# packages have not been fully tested yet and should be considered beta
# quality.  They are made available for people willing to test and provide
# feedback for the next release.

[cr]
name=CentOS Linux $releasever - ContinuousRelease
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=cr&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/cr/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Linux-Debuginfo.repo
# CentOS-Linux-Debuginfo.repo
#
# All debug packages are merged into a single repo, split by basearch, and are
# not signed.

[debuginfo]
name=CentOS Linux $releasever - Debuginfo
baseurl=http://debuginfo.centos.org/$releasever/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Linux-Devel.repo
# CentOS-Linux-Devel.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[devel]
name=CentOS Linux $releasever - Devel WARNING! FOR BUILDROOT USE ONLY!
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=Devel&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/Devel/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Linux-Extras.repo
# CentOS-Linux-Extras.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[extras]
name=CentOS Linux $releasever - Extras
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/extras/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Linux-FastTrack.repo
# CentOS-Linux-FastTrack.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[fasttrack]
name=CentOS Linux $releasever - FastTrack
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=fasttrack&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/fasttrack/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Linux-HighAvailability.repo
# CentOS-Linux-HighAvailability.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[ha]
name=CentOS Linux $releasever - HighAvailability
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=HighAvailability&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/HighAvailability/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Linux-Media.repo
# CentOS-Linux-Media.repo
#
# You can use this repo to install items directly off the installation media.
# Verify your mount point matches one of the below file:// paths.

[media-baseos]
name=CentOS Linux $releasever - Media - BaseOS
baseurl=file:///media/CentOS/BaseOS
        file:///media/cdrom/BaseOS
        file:///media/cdrecorder/BaseOS
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[media-appstream]
name=CentOS Linux $releasever - Media - AppStream
baseurl=file:///media/CentOS/AppStream
        file:///media/cdrom/AppStream
        file:///media/cdrecorder/AppStream
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Linux-Plus.repo
# CentOS-Linux-Plus.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[plus]
name=CentOS Linux $releasever - Plus
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=centosplus&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/centosplus/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Linux-PowerTools.repo
# CentOS-Linux-PowerTools.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[powertools]
name=CentOS Linux $releasever - PowerTools
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=PowerTools&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/PowerTools/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Linux-Sources.repo
# CentOS-Linux-Sources.repo


[baseos-source]
name=CentOS Linux $releasever - BaseOS - Source
baseurl=http://vault.centos.org/$contentdir/$releasever/BaseOS/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[appstream-source]
name=CentOS Linux $releasever - AppStream - Source
baseurl=http://vault.centos.org/$contentdir/$releasever/AppStream/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[extras-source]
name=CentOS Linux $releasever - Extras - Source
baseurl=http://vault.centos.org/$contentdir/$releasever/extras/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[plus-source]
name=CentOS Linux $releasever - Plus - Source
baseurl=http://vault.centos.org/$contentdir/$releasever/centosplus/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        ;;
    7)
        cat <<'EOF' >$Dir_YumRepos/CentOS-Base.repo
# CentOS-Base.repo
#
# The mirror system uses the connecting IP address of the client and the
# update status of each mirror to pick mirrors that are updated to and
# geographically close to the client.  You should use this for CentOS updates
# unless you are manually picking other mirrors.
#
# If the mirrorlist= does not work for you, as a fall back you can try the 
# remarked out baseurl= line instead.
#
#

[base]
name=CentOS-$releasever - Base
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#released updates 
[updates]
name=CentOS-$releasever - Updates
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras]
name=CentOS-$releasever - Extras
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-$releasever - Plus
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=centosplus&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/centosplus/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-CR.repo
# CentOS-CR.repo
#
# The Continuous Release ( CR )  repository contains rpms that are due in the next
# release for a specific CentOS Version ( eg. next release in CentOS-7 ); these rpms
# are far less tested, with no integration checking or update path testing having
# taken place. They are still built from the upstream sources, but might not map 
# to an exact upstream distro release.
#
# These packages are made available soon after they are built, for people willing 
# to test their environments, provide feedback on content for the next release, and
# for people looking for early-access to next release content.
#
# The CR repo is shipped in a disabled state by default; its important that users 
# understand the implications of turning this on. 
#
# NOTE: We do not use a mirrorlist for the CR repos, to ensure content is available
#       to everyone as soon as possible, and not need to wait for the external
#       mirror network to seed first. However, many local mirrors will carry CR repos
#       and if desired you can use one of these local mirrors by editing the baseurl
#       line in the repo config below.
#

[cr]
name=CentOS-$releasever - cr
baseurl=http://mirror.centos.org/centos/$releasever/cr/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=0
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Debuginfo.repo
# CentOS-Debug.repo
#
# The mirror system uses the connecting IP address of the client and the
# update status of each mirror to pick mirrors that are updated to and
# geographically close to the client.  You should use this for CentOS updates
# unless you are manually picking other mirrors.
#

# All debug packages from all the various CentOS-7 releases
# are merged into a single repo, split by BaseArch
#
# Note: packages in the debuginfo repo are currently not signed
#

[base-debuginfo]
name=CentOS-7 - Debuginfo
baseurl=http://debuginfo.centos.org/7/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Debug-7
enabled=0
#
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-fasttrack.repo
[fasttrack]
name=CentOS-7 - fasttrack
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=fasttrack&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/fasttrack/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Media.repo
# CentOS-Media.repo
#
#  This repo can be used with mounted DVD media, verify the mount point for
#  CentOS-7.  You can use this repo and yum to install items directly off the
#  DVD ISO that we release.
#
# To use this repo, put in your DVD and use it with the other repos too:
#  yum --enablerepo=c7-media [command]
#  
# or for ONLY the media repo, do this:
#
#  yum --disablerepo=\* --enablerepo=c7-media [command]

[c7-media]
name=CentOS-$releasever - Media
baseurl=file:///media/CentOS/
        file:///media/cdrom/
        file:///media/cdrecorder/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Sources.repo
# CentOS-Sources.repo
#
# The mirror system uses the connecting IP address of the client and the
# update status of each mirror to pick mirrors that are updated to and
# geographically close to the client.  You should use this for CentOS updates
# unless you are manually picking other mirrors.
#
# If the mirrorlist= does not work for you, as a fall back you can try the 
# remarked out baseurl= line instead.
#
#

[base-source]
name=CentOS-$releasever - Base Sources
baseurl=http://vault.centos.org/centos/$releasever/os/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#released updates 
[updates-source]
name=CentOS-$releasever - Updates Sources
baseurl=http://vault.centos.org/centos/$releasever/updates/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras-source]
name=CentOS-$releasever - Extras Sources
baseurl=http://vault.centos.org/centos/$releasever/extras/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that extend functionality of existing packages
[centosplus-source]
name=CentOS-$releasever - Plus Sources
baseurl=http://vault.centos.org/centos/$releasever/centosplus/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
        ;;
    esac
}

## 生成 CentOS Stream 官方 repo 源文件
function gen_repo_files_CentOSStream() {
    case "$1" in
    9)
        cat <<'EOF' >$Dir_YumRepos/centos.repo
[baseos]
name=CentOS Stream $releasever - BaseOS
#baseurl=https://mirror.stream.centos.org/$releasever-stream/BaseOS/$basearch/os/
metalink=https://mirrors.centos.org/metalink?repo=centos-baseos-$stream&arch=$basearch&protocol=https,http
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
gpgcheck=1
repo_gpgcheck=0
metadata_expire=6h
countme=1
enabled=1

[baseos-debug]
name=CentOS Stream $releasever - BaseOS - Debug
metalink=https://mirrors.centos.org/metalink?repo=centos-baseos-debug-$stream&arch=$basearch&protocol=https,http
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
gpgcheck=1
repo_gpgcheck=0
metadata_expire=6h
enabled=0

[baseos-source]
name=CentOS Stream $releasever - BaseOS - Source
metalink=https://mirrors.centos.org/metalink?repo=centos-baseos-source-$stream&arch=source&protocol=https,http
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
gpgcheck=1
repo_gpgcheck=0
metadata_expire=6h
enabled=0

[appstream]
name=CentOS Stream $releasever - AppStream
#baseurl=https://mirror.stream.centos.org/$releasever-stream/AppStream/$basearch/os/
metalink=https://mirrors.centos.org/metalink?repo=centos-appstream-$stream&arch=$basearch&protocol=https,http
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
gpgcheck=1
repo_gpgcheck=0
metadata_expire=6h
countme=1
enabled=1

[appstream-debug]
name=CentOS Stream $releasever - AppStream - Debug
metalink=https://mirrors.centos.org/metalink?repo=centos-appstream-debug-$stream&arch=$basearch&protocol=https,http
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
gpgcheck=1
repo_gpgcheck=0
metadata_expire=6h
enabled=0

[appstream-source]
name=CentOS Stream $releasever - AppStream - Source
metalink=https://mirrors.centos.org/metalink?repo=centos-appstream-source-$stream&arch=source&protocol=https,http
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
gpgcheck=1
repo_gpgcheck=0
metadata_expire=6h
enabled=0

[crb]
name=CentOS Stream $releasever - CRB
#baseurl=https://mirror.stream.centos.org/$releasever-stream/CRB/$basearch/os/
metalink=https://mirrors.centos.org/metalink?repo=centos-crb-$stream&arch=$basearch&protocol=https,http
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
gpgcheck=1
repo_gpgcheck=0
metadata_expire=6h
countme=1
enabled=0

[crb-debug]
name=CentOS Stream $releasever - CRB - Debug
metalink=https://mirrors.centos.org/metalink?repo=centos-crb-debug-$stream&arch=$basearch&protocol=https,http
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
gpgcheck=1
repo_gpgcheck=0
metadata_expire=6h
enabled=0

[crb-source]
name=CentOS Stream $releasever - CRB - Source
metalink=https://mirrors.centos.org/metalink?repo=centos-crb-source-$stream&arch=source&protocol=https,http
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
gpgcheck=1
repo_gpgcheck=0
metadata_expire=6h
enabled=0
EOF
        cat <<'EOF' >$Dir_YumRepos/centos-addons.repo
[highavailability]
name=CentOS Stream $releasever - HighAvailability
#baseurl=https://mirror.stream.centos.org/$releasever-stream/HighAvailability/$basearch/os/
metalink=https://mirrors.centos.org/metalink?repo=centos-highavailability-$stream&arch=$basearch&protocol=https,http
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
gpgcheck=1
repo_gpgcheck=0
metadata_expire=6h
countme=1
enabled=0

[highavailability-debug]
name=CentOS Stream $releasever - HighAvailability - Debug
metalink=https://mirrors.centos.org/metalink?repo=centos-highavailability-debug-$stream&arch=$basearch&protocol=https,http
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
gpgcheck=1
repo_gpgcheck=0
metadata_expire=6h
enabled=0

[highavailability-source]
name=CentOS Stream $releasever - HighAvailability - Source
metalink=https://mirrors.centos.org/metalink?repo=centos-highavailability-source-$stream&arch=source&protocol=https,http
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
gpgcheck=1
repo_gpgcheck=0
metadata_expire=6h
enabled=0

[nfv]
name=CentOS Stream $releasever - NFV
#baseurl=https://mirror.stream.centos.org/$releasever-stream/NFV/$basearch/os/
metalink=https://mirrors.centos.org/metalink?repo=centos-nfv-$stream&arch=$basearch&protocol=https,http
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
gpgcheck=1
repo_gpgcheck=0
metadata_expire=6h
countme=1
enabled=0

[nfv-debug]
name=CentOS Stream $releasever - NFV - Debug
metalink=https://mirrors.centos.org/metalink?repo=centos-nfv-debug-$stream&arch=$basearch&protocol=https,http
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
gpgcheck=1
repo_gpgcheck=0
metadata_expire=6h
enabled=0

[nfv-source]
name=CentOS Stream $releasever - NFV - Source
metalink=https://mirrors.centos.org/metalink?repo=centos-nfv-source-$stream&arch=source&protocol=https,http
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
gpgcheck=1
repo_gpgcheck=0
metadata_expire=6h
enabled=0

[rt]
name=CentOS Stream $releasever - RT
#baseurl=https://mirror.stream.centos.org/$releasever-stream/RT/$basearch/os/
metalink=https://mirrors.centos.org/metalink?repo=centos-rt-$stream&arch=$basearch&protocol=https,http
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
gpgcheck=1
repo_gpgcheck=0
metadata_expire=6h
countme=1
enabled=0

[rt-debug]
name=CentOS Stream $releasever - RT - Debug
metalink=https://mirrors.centos.org/metalink?repo=centos-rt-debug-$stream&arch=$basearch&protocol=https,http
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
gpgcheck=1
repo_gpgcheck=0
metadata_expire=6h
enabled=0

[rt-source]
name=CentOS Stream $releasever - RT - Source
metalink=https://mirrors.centos.org/metalink?repo=centos-rt-source-$stream&arch=source&protocol=https,http
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
gpgcheck=1
repo_gpgcheck=0
metadata_expire=6h
enabled=0

[resilientstorage]
name=CentOS Stream $releasever - ResilientStorage
#baseurl=https://mirror.stream.centos.org/$releasever-stream/ResilientStorage/$basearch/os/
metalink=https://mirrors.centos.org/metalink?repo=centos-resilientstorage-$stream&arch=$basearch&protocol=https,http
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
gpgcheck=1
repo_gpgcheck=0
metadata_expire=6h
countme=1
enabled=0

[resilientstorage-debug]
name=CentOS Stream $releasever - ResilientStorage - Debug
metalink=https://mirrors.centos.org/metalink?repo=centos-resilientstorage-debug-$stream&arch=$basearch&protocol=https,http
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
gpgcheck=1
repo_gpgcheck=0
metadata_expire=6h
enabled=0

[resilientstorage-source]
name=CentOS Stream $releasever - ResilientStorage - Source
metalink=https://mirrors.centos.org/metalink?repo=centos-resilientstorage-source-$stream&arch=source&protocol=https,http
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
gpgcheck=1
repo_gpgcheck=0
metadata_expire=6h
enabled=0

[extras-common]
name=CentOS Stream $releasever - Extras packages
#baseurl=https://mirror.stream.centos.org/SIGs/$releasever-stream/extras/$basearch/extras-common/
metalink=https://mirrors.centos.org/metalink?repo=centos-extras-sig-extras-common-$stream&arch=$basearch&protocol=https,http
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Extras-SHA512
gpgcheck=1
repo_gpgcheck=0
metadata_expire=6h
countme=1
enabled=1

[extras-common-source]
name=CentOS Stream $releasever - Extras packages - Source
metalink=https://mirrors.centos.org/metalink?repo=centos-extras-sig-extras-common-source-$stream&arch=source&protocol=https,http
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Extras-SHA512
gpgcheck=1
repo_gpgcheck=0
metadata_expire=6h
enabled=0
EOF
        ;;
    8)
        cat <<'EOF' >$Dir_YumRepos/CentOS-Stream-AppStream.repo
# CentOS-Stream-AppStream.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[appstream]
name=CentOS Stream $releasever - AppStream
mirrorlist=http://mirrorlist.centos.org/?release=$stream&arch=$basearch&repo=AppStream&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$stream/AppStream/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Stream-BaseOS.repo
# CentOS-Stream-BaseOS.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[baseos]
name=CentOS Stream $releasever - BaseOS
mirrorlist=http://mirrorlist.centos.org/?release=$stream&arch=$basearch&repo=BaseOS&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$stream/BaseOS/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Stream-Debuginfo.repo
# CentOS-Stream-Debuginfo.repo
#
# All debug packages are merged into a single repo, split by basearch, and are
# not signed.

[debuginfo]
name=CentOS Stream $releasever - Debuginfo
baseurl=http://debuginfo.centos.org/$stream/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Stream-Extras-common.repo
# CentOS-Stream-Extras-common.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[extras-common]
name=CentOS Stream $releasever - Extras common packages
mirrorlist=http://mirrorlist.centos.org/?release=$stream&arch=$basearch&repo=extras-extras-common
#baseurl=http://mirror.centos.org/$contentdir/$stream/extras/$basearch/extras-common/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Extras
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Stream-Extras.repo
# CentOS-Stream-Extras.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[extras]
name=CentOS Stream $releasever - Extras
mirrorlist=http://mirrorlist.centos.org/?release=$stream&arch=$basearch&repo=extras&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$stream/extras/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Stream-HighAvailability.repo
# CentOS-Stream-HighAvailability.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[ha]
name=CentOS Stream $releasever - HighAvailability
mirrorlist=http://mirrorlist.centos.org/?release=$stream&arch=$basearch&repo=HighAvailability&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$stream/HighAvailability/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Stream-Media.repo
# CentOS-Stream-Media.repo
#
# You can use this repo to install items directly off the installation media.
# Verify your mount point matches one of the below file:// paths.

[media-baseos]
name=CentOS Stream $releasever - Media - BaseOS
baseurl=file:///media/CentOS/BaseOS
        file:///media/cdrom/BaseOS
        file:///media/cdrecorder/BaseOS
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[media-appstream]
name=CentOS Stream $releasever - Media - AppStream
baseurl=file:///media/CentOS/AppStream
        file:///media/cdrom/AppStream
        file:///media/cdrecorder/AppStream
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Stream-NFV.repo
# CentOS-Stream-NFV.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[nfv]
name=CentOS Stream $releasever - NFV
mirrorlist=http://mirrorlist.centos.org/?release=$stream&arch=$basearch&repo=NFV&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$stream/NFV/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Stream-PowerTools.repo
# CentOS-Stream-PowerTools.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[powertools]
name=CentOS Stream $releasever - PowerTools
mirrorlist=http://mirrorlist.centos.org/?release=$stream&arch=$basearch&repo=PowerTools&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$stream/PowerTools/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Stream-RealTime.repo
# CentOS-Stream-RealTime.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[rt]
name=CentOS Stream $releasever - RealTime
mirrorlist=http://mirrorlist.centos.org/?release=$stream&arch=$basearch&repo=RT&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$stream/RT/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Stream-ResilientStorage.repo
# CentOS-Stream-ResilientStorage.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[resilientstorage]
name=CentOS Stream $releasever - ResilientStorage
mirrorlist=http://mirrorlist.centos.org/?release=$stream&arch=$basearch&repo=ResilientStorage&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$stream/ResilientStorage/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/CentOS-Stream-Sources.repo
# CentOS-Stream-Sources.repo

[baseos-source]
name=CentOS Stream $releasever - BaseOS - Source
baseurl=http://vault.centos.org/$contentdir/$stream/BaseOS/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[appstream-source]
name=CentOS Stream $releasever - AppStream - Source
baseurl=http://vault.centos.org/$contentdir/$stream/AppStream/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[powertools-source]
name=CentOS Stream $releasever - PowerTools - Source
baseurl=http://vault.centos.org/$contentdir/$stream/PowerTools/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[extras-source]
name=CentOS Stream $releasever - Extras - Source
baseurl=http://vault.centos.org/$contentdir/$stream/extras/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[ha-source]
name=CentOS Stream $releasever - HighAvailability - Source
baseurl=http://vault.centos.org/$contentdir/$stream/HighAvailability/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[rt-source]
name=CentOS Stream $releasever - RT - Source
baseurl=http://vault.centos.org/$contentdir/$stream/RT/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[resilientstorage-source]
name=CentOS Stream $releasever - ResilientStorage - Source
baseurl=http://vault.centos.org/$contentdir/$stream/ResilientStorage/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[nfv-source]
name=CentOS Stream $releasever - NFV - Source
baseurl=http://vault.centos.org/$contentdir/$stream/NFV/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        ;;
    esac
}

## 生成 Rocky Linux 官方 repo 源文件
function gen_repo_files_RockyLinux() {
    case "$1" in
    9)
        cat <<'EOF' >$Dir_YumRepos/rocky.repo
# rocky.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for Rocky updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[baseos]
name=Rocky Linux $releasever - BaseOS
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=BaseOS-$releasever$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/BaseOS/$basearch/os/
gpgcheck=1
enabled=1
countme=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[baseos-debug]
name=Rocky Linux $releasever - BaseOS - Debug
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=BaseOS-$releasever-debug$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/BaseOS/$basearch/debug/tree/
gpgcheck=1
enabled=0
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[baseos-source]
name=Rocky Linux $releasever - BaseOS - Source
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=source&repo=BaseOS-$releasever-source$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/BaseOS/source/tree/
gpgcheck=1
enabled=0
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[appstream]
name=Rocky Linux $releasever - AppStream
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=AppStream-$releasever$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/AppStream/$basearch/os/
gpgcheck=1
enabled=1
countme=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[appstream-debug]
name=Rocky Linux $releasever - AppStream - Debug
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=AppStream-$releasever-debug$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/AppStream/$basearch/debug/tree/
gpgcheck=1
enabled=0
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[appstream-source]
name=Rocky Linux $releasever - AppStream - Source
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=source&repo=AppStream-$releasever-source$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/AppStream/source/tree/
gpgcheck=1
enabled=0
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[crb]
name=Rocky Linux $releasever - CRB
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=CRB-$releasever$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/CRB/$basearch/os/
gpgcheck=1
enabled=0
countme=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[crb-debug]
name=Rocky Linux $releasever - CRB - Debug
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=CRB-$releasever-debug$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/CRB/$basearch/debug/tree/
gpgcheck=1
enabled=0
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[crb-source]
name=Rocky Linux $releasever - CRB - Source
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=source&repo=CRB-$releasever-source$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/CRB/source/tree/
gpgcheck=1
enabled=0
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9
EOF
        cat <<'EOF' >$Dir_YumRepos/rocky-addons.repo
# rocky-addons.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for Rocky updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[highavailability]
name=Rocky Linux $releasever - High Availability
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=HighAvailability-$releasever$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/HighAvailability/$basearch/os/
gpgcheck=1
enabled=0
countme=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[highavailability-debug]
name=Rocky Linux $releasever - High Availability - Debug
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=HighAvailability-$releasever-debug$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/HighAvailability/$basearch/debug/tree/
gpgcheck=1
enabled=0
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[highavailability-source]
name=Rocky Linux $releasever - High Availability - Source
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=source&repo=HighAvailability-$releasever-source$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/HighAvailability/source/tree/
gpgcheck=1
enabled=0
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[resilientstorage]
name=Rocky Linux $releasever - Resilient Storage
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=ResilientStorage-$releasever$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/ResilientStorage/$basearch/os/
gpgcheck=1
enabled=0
countme=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[resilientstorage-debug]
name=Rocky Linux $releasever - Resilient Storage - Debug
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=ResilientStorage-$releasever-debug$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/ResilientStorage/$basearch/debug/tree/
gpgcheck=1
enabled=0
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[resilientstorage-source]
name=Rocky Linux $releasever - Resilient Storage - Source
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=source&repo=ResilientStorage-$releasever-source$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/ResilientStorage/source/tree/
gpgcheck=1
enabled=0
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[nfv]
name=Rocky Linux $releasever - NFV
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=NFV-$releasever$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/NFV/$basearch/os/
gpgcheck=1
enabled=0
countme=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[nfv-debug]
name=Rocky Linux $releasever - NFV Debug
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=RT-$releasever-debug$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/NFV/$basearch/debug/tree/
gpgcheck=1
enabled=0
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[nfv-source]
name=Rocky Linux $releasever - NFV Source
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=RT-$releasever-source$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/NFV/source/tree/
gpgcheck=1
enabled=0
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[rt]
name=Rocky Linux $releasever - Realtime
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=RT-$releasever$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/RT/$basearch/os/
gpgcheck=1
enabled=0
countme=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[rt-debug]
name=Rocky Linux $releasever - Realtime Debug
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=RT-$releasever-debug$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/RT/$basearch/debug/tree/
gpgcheck=1
enabled=0
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[rt-source]
name=Rocky Linux $releasever - Realtime Source
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=RT-$releasever-source$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/RT/source/tree/
gpgcheck=1
enabled=0
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[sap]
name=Rocky Linux $releasever - SAP
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=SAP-$releasever$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/SAP/$basearch/os/
gpgcheck=1
enabled=0
countme=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[sap-debug]
name=Rocky Linux $releasever - SAP Debug
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=SAP-$releasever-debug$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/SAP/$basearch/debug/tree/
gpgcheck=1
enabled=0
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[sap-source]
name=Rocky Linux $releasever - SAP Source
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=SAP-$releasever-source$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/SAP/source/tree/
gpgcheck=1
enabled=0
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[saphana]
name=Rocky Linux $releasever - SAPHANA
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=SAPHANA-$releasever$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/SAPHANA/$basearch/os/
gpgcheck=1
enabled=0
countme=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[saphana-debug]
name=Rocky Linux $releasever - SAPHANA Debug
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=SAPHANA-$releasever-debug$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/SAPHANA/$basearch/debug/tree/
gpgcheck=1
enabled=0
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[saphana-source]
name=Rocky Linux $releasever - SAPHANA Source
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=SAPHANA-$releasever-source$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/SAPHANA/source/tree/
gpgcheck=1
enabled=0
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9
EOF
        cat <<'EOF' >$Dir_YumRepos/rocky-devel.repo
# rocky-devel.repo
#
# devel and no-package-left-behind

[devel]
name=Rocky Linux $releasever - Devel WARNING! FOR BUILDROOT ONLY DO NOT LEAVE ENABLED
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=devel-$releasever$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/devel/$basearch/os/
gpgcheck=1
enabled=0
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9
EOF
        cat <<'EOF' >$Dir_YumRepos/rocky-extras.repo
# rocky-extras.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for Rocky updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[extras]
name=Rocky Linux $releasever - Extras
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=extras-$releasever$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/extras/$basearch/os/
gpgcheck=1
enabled=1
countme=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[extras-debug]
name=Rocky Linux $releasever - Extras Debug
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=extras-$releasever-debug$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/extras/$basearch/debug/tree/
gpgcheck=1
enabled=0
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[extras-source]
name=Rocky Linux $releasever - Extras Source
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=extras-$releasever-source$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/extras/source/tree/
gpgcheck=1
enabled=0
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[plus]
name=Rocky Linux $releasever - Plus
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=plus-$releasever$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/plus/$basearch/os/
gpgcheck=1
enabled=0
countme=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[plus-debug]
name=Rocky Linux $releasever - Plus - Debug
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=plus-$releasever-debug$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/plus/$basearch/debug/tree/
gpgcheck=1
enabled=0
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[plus-source]
name=Rocky Linux $releasever - Plus - Source
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=source&repo=plus-$releasever-source$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/plus/source/tree/
gpgcheck=1
enabled=0
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9
EOF
        ;;
    8)
        cat <<'EOF' >$Dir_YumRepos/Rocky-AppStream.repo
# Rocky-AppStream.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for Rocky updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[appstream]
name=Rocky Linux $releasever - AppStream
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=AppStream-$releasever
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/AppStream/$basearch/os/
gpgcheck=1
enabled=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/Rocky-BaseOS.repo
# Rocky-BaseOS.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for Rocky updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[baseos]
name=Rocky Linux $releasever - BaseOS
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=BaseOS-$releasever
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/BaseOS/$basearch/os/
gpgcheck=1
enabled=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/Rocky-Debuginfo.repo
# Rocky-Debuginfo.repo
#

[baseos-debug]
name=Rocky Linux $releasever - BaseOS - Source
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=BaseOS-$releasever-debug
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/BaseOS/$basearch/debug/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial

[appstream-debug]
name=Rocky Linux $releasever - AppStream - Source
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=AppStream-$releasever-debug
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/AppStream/$basearch/debug/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial

[ha-debug]
name=Rocky Linux $releasever - High Availability - Source
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=HighAvailability-$releasever-debug
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/HighAvailability/$basearch/debug/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial

[powertools-debug]
name=Rocky Linux $releasever - PowerTools - Source
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=PowerTools-$releasever-debug
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/PowerTools/$basearch/debug/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial

[resilient-storage-debug]
name=Rocky Linux $releasever - Resilient Storage - Source
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=ResilientStorage-$releasever-debug
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/ResilientStorage/$basearch/debug/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/Rocky-Devel.repo
# Rocky-Devel.repo
#

[devel]
name=Rocky Linux $releasever - Devel WARNING! FOR BUILDROOT AND KOJI USE
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=Devel-$releasever
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/Devel/$basearch/os/
gpgcheck=1
enabled=0
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/Rocky-Extras.repo
# Rocky-Extras.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for Rocky updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[extras]
name=Rocky Linux $releasever - Extras
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=extras-$releasever
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/extras/$basearch/os/
gpgcheck=1
enabled=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/Rocky-HighAvailability.repo
# Rocky-HighAvailability.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for Rocky updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[ha]
name=Rocky Linux $releasever - HighAvailability
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=HighAvailability-$releasever
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/HighAvailability/$basearch/os/
gpgcheck=1
enabled=0
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/Rocky-Media.repo
# Rocky-Media.repo
#
# You can use this repo to install items directly off the installation media.
# Verify your mount point matches one of the below file:// paths.

[media-baseos]
name=Rocky Linux $releasever - Media - BaseOS
baseurl=file:///media/Rocky/BaseOS
        file:///media/cdrom/BaseOS
        file:///media/cdrecorder/BaseOS
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial

[media-appstream]
name=Rocky Linux $releasever - Media - AppStream
baseurl=file:///media/Rocky/AppStream
        file:///media/cdrom/AppStream
        file:///media/cdrecorder/AppStream
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/Rocky-NFV.repo
# Rocky-NFV.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for Rocky updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[nfv]
name=Rocky Linux $releasever - NFV
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=NFV-$releasever
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/nfv/$basearch/os/
gpgcheck=1
enabled=0
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/Rocky-Plus.repo
# Rocky-Plus.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for Rocky updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[plus]
name=Rocky Linux $releasever - Plus
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=rockyplus-$releasever
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/plus/$basearch/os/
gpgcheck=1
enabled=0
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/Rocky-PowerTools.repo
# Rocky-PowerTools.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for Rocky updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[powertools]
name=Rocky Linux $releasever - PowerTools
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=PowerTools-$releasever
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/PowerTools/$basearch/os/
gpgcheck=1
enabled=0
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/Rocky-ResilientStorage.repo
# Rocky-ResilientStorage.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for Rocky updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[resilient-storage]
name=Rocky Linux $releasever - ResilientStorage
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=ResilientStorage-$releasever
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/ResilientStorage/$basearch/os/
gpgcheck=1
enabled=0
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/Rocky-RT.repo
# Rocky-RT.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for Rocky updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[rt]
name=Rocky Linux $releasever - Realtime
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=RT-$releasever
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/RT/$basearch/os/
gpgcheck=1
enabled=0
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
EOF
        cat <<'EOF' >$Dir_YumRepos/Rocky-Sources.repo
# Rocky-Sources.repo

[baseos-source]
name=Rocky Linux $releasever - BaseOS - Source
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=source&repo=BaseOS-$releasever-source
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/BaseOS/source/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial

[appstream-source]
name=Rocky Linux $releasever - AppStream - Source
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=source&repo=AppStream-$releasever-source
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/AppStream/source/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial

#[extras-source]
#name=Rocky Linux $releasever - Extras - Source
#mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=source&repo=extras-$releasever-source
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/extras/source/tree/
#gpgcheck=1
#enabled=0
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial

#[plus-source]
#name=Rocky Linux $releasever - Plus - Source
#mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=source&repo=plus-$releasever-source
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/Plus/source/tree/
#gpgcheck=1
#enabled=0
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial

[ha-source]
name=Rocky Linux $releasever - High Availability - Source
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=source&repo=HighAvailability-$releasever-source
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/HighAvailability/source/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial

[powertools-source]
name=Rocky Linux $releasever - PowerTools - Source
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=source&repo=PowerTools-$releasever-source
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/PowerTools/source/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial

[resilient-storage-source]
name=Rocky Linux $releasever - Resilient Storage - Source
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=source&repo=ResilientStorage-$releasever-source
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/ResilientStorage/source/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
EOF
        ;;
    esac
}

## 生成 AlmaLinux 官方 repo 源文件
function gen_repo_files_AlmaLinux() {
    case "$1" in
    9)
        cat <<'EOF' >$Dir_YumRepos/almalinux-appstream.repo
[appstream]
name=AlmaLinux $releasever - AppStream
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/appstream
# baseurl=https://repo.almalinux.org/almalinux/$releasever/AppStream/$basearch/os/
enabled=1
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=1

[appstream-debug]
name=AlmaLinux $releasever - AppStream - Debug
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/appstream-debug
# baseurl=https://repo.almalinux.org/vault/$releasever/AppStream/debug/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0

[appstream-source]
name=AlmaLinux $releasever - AppStream - Source
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/appstream-source
# baseurl=https://repo.almalinux.org/vault/$releasever/AppStream/Source/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0
EOF
        cat <<'EOF' >$Dir_YumRepos/almalinux-baseos.repo
[baseos]
name=AlmaLinux $releasever - BaseOS
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/baseos
# baseurl=https://repo.almalinux.org/almalinux/$releasever/BaseOS/$basearch/os/
enabled=1
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=1

[baseos-debug]
name=AlmaLinux $releasever - BaseOS - Debug
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/baseos-debug
# baseurl=https://repo.almalinux.org/vault/$releasever/BaseOS/debug/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0

[baseos-source]
name=AlmaLinux $releasever - BaseOS - Source
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/baseos-source
# baseurl=https://repo.almalinux.org/vault/$releasever/BaseOS/Source/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0
EOF
        cat <<'EOF' >$Dir_YumRepos/almalinux-crb.repo
[crb]
name=AlmaLinux $releasever - CRB
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/crb
# baseurl=https://repo.almalinux.org/almalinux/$releasever/CRB/$basearch/os/
enabled=0
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0

[crb-debug]
name=AlmaLinux $releasever - CRB - Debug
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/crb-debug
# baseurl=https://repo.almalinux.org/vault/$releasever/CRB/debug/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0

[crb-source]
name=AlmaLinux $releasever - CRB - Source
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/crb-source
# baseurl=https://repo.almalinux.org/vault/$releasever/CRB/Source/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0
EOF
        cat <<'EOF' >$Dir_YumRepos/almalinux-extras.repo
[extras]
name=AlmaLinux $releasever - Extras
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/extras
# baseurl=https://repo.almalinux.org/almalinux/$releasever/extras/$basearch/os/
enabled=1
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0

[extras-debug]
name=AlmaLinux $releasever - Extras - Debug
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/extras-debug
# baseurl=https://repo.almalinux.org/vault/$releasever/extras/debug/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0

[extras-source]
name=AlmaLinux $releasever - Extras - Source
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/extras-source
# baseurl=https://repo.almalinux.org/vault/$releasever/extras/Source/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0
EOF
        cat <<'EOF' >$Dir_YumRepos/almalinux-highavailability.repo
[highavailability]
name=AlmaLinux $releasever - HighAvailability
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/highavailability
# baseurl=https://repo.almalinux.org/almalinux/$releasever/HighAvailability/$basearch/os/
enabled=0
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0

[highavailability-debug]
name=AlmaLinux $releasever - HighAvailability - Debug
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/highavailability-debug
# baseurl=https://repo.almalinux.org/vault/$releasever/HighAvailability/debug/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0

[highavailability-source]
name=AlmaLinux $releasever - HighAvailability - Source
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/highavailability-source
# baseurl=https://repo.almalinux.org/vault/$releasever/HighAvailability/Source/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0
EOF
        cat <<'EOF' >$Dir_YumRepos/almalinux-nfv.repo
[nfv]
name=AlmaLinux $releasever - NFV
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/nfv
# baseurl=https://repo.almalinux.org/almalinux/$releasever/NFV/$basearch/os/
enabled=0
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0

[nfv-debug]
name=AlmaLinux $releasever - NFV - Debug
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/nfv-debug
# baseurl=https://repo.almalinux.org/vault/$releasever/NFV/debug/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0

[nfv-source]
name=AlmaLinux $releasever - NFV - Source
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/nfv-source
# baseurl=https://repo.almalinux.org/vault/$releasever/NFV/Source/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0
EOF
        cat <<'EOF' >$Dir_YumRepos/almalinux-plus.repo
[plus]
name=AlmaLinux $releasever - Plus
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/plus
# baseurl=https://repo.almalinux.org/almalinux/$releasever/plus/$basearch/os/
enabled=0
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0

[plus-debug]
name=AlmaLinux $releasever - Plus - Debug
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/plus-debug
# baseurl=https://repo.almalinux.org/vault/$releasever/plus/debug/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0

[plus-source]
name=AlmaLinux $releasever - Plus - Source
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/plus-source
# baseurl=https://repo.almalinux.org/vault/$releasever/plus/Source/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0
EOF
        cat <<'EOF' >$Dir_YumRepos/almalinux-resilientstorage.repo
[resilientstorage]
name=AlmaLinux $releasever - ResilientStorage
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/resilientstorage
# baseurl=https://repo.almalinux.org/almalinux/$releasever/ResilientStorage/$basearch/os/
enabled=0
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0

[resilientstorage-debug]
name=AlmaLinux $releasever - ResilientStorage - Debug
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/resilientstorage-debug
# baseurl=https://repo.almalinux.org/vault/$releasever/ResilientStorage/debug/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0

[resilientstorage-source]
name=AlmaLinux $releasever - ResilientStorage - Source
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/resilientstorage-source
# baseurl=https://repo.almalinux.org/vault/$releasever/ResilientStorage/Source/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0
EOF
        cat <<'EOF' >$Dir_YumRepos/almalinux-rt.repo
[rt]
name=AlmaLinux $releasever - RT
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/rt
# baseurl=https://repo.almalinux.org/almalinux/$releasever/RT/$basearch/os/
enabled=0
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0

[rt-debug]
name=AlmaLinux $releasever - RT - Debug
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/rt-debug
# baseurl=https://repo.almalinux.org/vault/$releasever/RT/debug/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0

[rt-source]
name=AlmaLinux $releasever - RT - Source
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/rt-source
# baseurl=https://repo.almalinux.org/vault/$releasever/RT/Source/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0
EOF
        cat <<'EOF' >$Dir_YumRepos/almalinux-sap.repo
[sap]
name=AlmaLinux $releasever - SAP
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/sap
# baseurl=https://repo.almalinux.org/almalinux/$releasever/SAP/$basearch/os/
enabled=0
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0

[sap-debug]
name=AlmaLinux $releasever - SAP - Debug
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/sap-debug
# baseurl=https://repo.almalinux.org/vault/$releasever/SAP/debug/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0

[sap-source]
name=AlmaLinux $releasever - SAP - Source
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/sap-source
# baseurl=https://repo.almalinux.org/vault/$releasever/SAP/Source/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0
EOF
        cat <<'EOF' >$Dir_YumRepos/almalinux-saphana.repo
[saphana]
name=AlmaLinux $releasever - SAPHANA
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/saphana
# baseurl=https://repo.almalinux.org/almalinux/$releasever/SAPHANA/$basearch/os/
enabled=0
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0

[saphana-debug]
name=AlmaLinux $releasever - SAPHANA - Debug
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/saphana-debug
# baseurl=https://repo.almalinux.org/vault/$releasever/SAPHANA/debug/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0

[saphana-source]
name=AlmaLinux $releasever - SAPHANA - Source
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/saphana-source
# baseurl=https://repo.almalinux.org/vault/$releasever/SAPHANA/Source/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
metadata_expire=86400
enabled_metadata=0
EOF
        ;;
    8)
        cat <<'EOF' >$Dir_YumRepos/almalinux-ha.repo
# almalinux-ha.repo

[ha]
name=AlmaLinux $releasever - HighAvailability
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/ha
# baseurl=https://repo.almalinux.org/almalinux/$releasever/HighAvailability/$basearch/os/
enabled=0
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

## Sources
[ha-source]
name=AlmaLinux $releasever - HighAvailability Source
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/ha-source
# baseurl=https://repo.almalinux.org/vault/$releasever/HighAvailability/Source/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

## Debuginfo
[ha-debuginfo]
name=AlmaLinux $releasever - HighAvailability debuginfo
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/ha-debuginfo
# baseurl=https://repo.almalinux.org/vault/$releasever/HighAvailability/debug/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux
EOF
        cat <<'EOF' >$Dir_YumRepos/almalinux-nfv.repo
# almalinux-nfv.repo

[nfv]
name=AlmaLinux $releasever - Real Time for NFV
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/nfv
# baseurl=https://repo.almalinux.org/almalinux/$releasever/NFV/$basearch/os/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

## Sources
[nfv-source]
name=AlmaLinux $releasever - Real Time for NFV Sources
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/nfv-source
# baseurl=https://repo.almalinux.org/vault/$releasever/NFV/Source/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

## Debuginfo
[nfv-debuginfo]
name=AlmaLinux $releasever - Real Time for NFV Debuginfo
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/nfv-debuginfo
# baseurl=https://repo.almalinux.org/vault/$releasever/NFV/debug/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux
EOF
        cat <<'EOF' >$Dir_YumRepos/almalinux-plus.repo
# almalinux-plus.repo

[plus]
name=AlmaLinux $releasever - Plus
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/plus
# baseurl=https://repo.almalinux.org/almalinux/$releasever/plus/$basearch/os/
enabled=0
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

## Sources
[plus-source]
name=AlmaLinux $releasever - Plus Source
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/plus-source
# baseurl=https://repo.almalinux.org/vault/$releasever/plus/Source/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

## Debuginfo
[plus-debuginfo]
name=AlmaLinux $releasever - Plus debuginfo
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/plus-debuginfo
# baseurl=https://repo.almalinux.org/vault/$releasever/plus/debug/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux
EOF
        cat <<'EOF' >$Dir_YumRepos/almalinux-powertools.repo
# almalinux-powertools.repo

[powertools]
name=AlmaLinux $releasever - PowerTools
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/powertools
# baseurl=https://repo.almalinux.org/almalinux/$releasever/PowerTools/$basearch/os/
enabled=0
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

## Sources
[powertools-source]
name=AlmaLinux $releasever - PowerTools Source
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/powertools-source
# baseurl=https://repo.almalinux.org/vault/$releasever/PowerTools/Source/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

## Debuginfo
[powertools-debuginfo]
name=AlmaLinux $releasever - PowerTools debuginfo
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/powertools-debuginfo
# baseurl=https://repo.almalinux.org/vault/$releasever/PowerTools/debug/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux
EOF
        cat <<'EOF' >$Dir_YumRepos/almalinux-resilientstorage.repo
# almalinux-resilientstorage.repo

[resilientstorage]
name=AlmaLinux $releasever - ResilientStorage
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/resilientstorage
# baseurl=https://repo.almalinux.org/almalinux/$releasever/ResilientStorage/$basearch/os/
enabled=0
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

## Sources
[resilientstorage-source]
name=AlmaLinux $releasever - ResilientStorage Source
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/resilientstorage-source
# baseurl=https://repo.almalinux.org/vault/$releasever/ResilientStorage/Source/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

## Debuginfo
[resilientstorage-debuginfo]
name=AlmaLinux $releasever - ResilientStorage debuginfo
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/resilientstorage-debuginfo
# baseurl=https://repo.almalinux.org/vault/$releasever/ResilientStorage/debug/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux
EOF
        cat <<'EOF' >$Dir_YumRepos/almalinux-rt.repo
# almalinux-rt.repo

[rt]
name=AlmaLinux $releasever - Real Time
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/rt
# baseurl=https://repo.almalinux.org/almalinux/$releasever/RT/$basearch/os/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

## Sources
[rt-source]
name=AlmaLinux $releasever - Real Time Sources
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/rt-source
# baseurl=https://repo.almalinux.org/vault/$releasever/RT/Source/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

## Debuginfo
[rt-debuginfo]
name=AlmaLinux $releasever - Real Time Debuginfo
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/rt-debuginfo
# baseurl=https://repo.almalinux.org/vault/$releasever/RT/debug/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux
EOF
        cat <<'EOF' >$Dir_YumRepos/almalinux-sap.repo
# almalinux-sap.repo

[sap]
name=AlmaLinux $releasever - SAP
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/sap
# baseurl=https://repo.almalinux.org/almalinux/$releasever/SAP/$basearch/os/
enabled=0
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

## Sources
[sap-source]
name=AlmaLinux $releasever - SAP Sources
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/sap-source
# baseurl=https://repo.almalinux.org/vault/$releasever/SAP/Source/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

## Debuginfo
[sap-debuginfo]
name=AlmaLinux $releasever - SAP Debuginfo
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/sap-debuginfo
# baseurl=https://repo.almalinux.org/vault/$releasever/SAP/debug/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux
EOF
        cat <<'EOF' >$Dir_YumRepos/almalinux-saphana.repo
# almalinux-saphana.repo

[saphana]
name=AlmaLinux $releasever - SAP HANA
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/saphana
# baseurl=https://repo.almalinux.org/almalinux/$releasever/SAPHANA/$basearch/os/
enabled=0
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

## Sources
[saphana-source]
name=AlmaLinux $releasever - SAP HANA Sources
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/saphana-source
# baseurl=https://repo.almalinux.org/vault/$releasever/SAPHANA/Source/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

## Debuginfo
[saphana-debuginfo]
name=AlmaLinux $releasever - SAP HANA Debuginfo
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/saphana-debuginfo
# baseurl=https://repo.almalinux.org/vault/$releasever/SAPHANA/debug/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux
EOF
        cat <<'EOF' >$Dir_YumRepos/almalinux.repo
# almalinux.repo

[baseos]
name=AlmaLinux $releasever - BaseOS
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/baseos
# baseurl=https://repo.almalinux.org/almalinux/$releasever/BaseOS/$basearch/os/
enabled=1
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

[appstream]
name=AlmaLinux $releasever - AppStream
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/appstream
# baseurl=https://repo.almalinux.org/almalinux/$releasever/AppStream/$basearch/os/
enabled=1
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

[extras]
name=AlmaLinux $releasever - Extras
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/extras
# baseurl=https://repo.almalinux.org/almalinux/$releasever/extras/$basearch/os/
enabled=1
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

## Sources
[baseos-source]
name=AlmaLinux $releasever - BaseOS Source
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/baseos-source
# baseurl=https://repo.almalinux.org/vault/$releasever/BaseOS/Source/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

[appstream-source]
name=AlmaLinux $releasever - AppStream Source
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/appstream-source
# baseurl=https://repo.almalinux.org/vault/$releasever/AppStream/Source/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

[extras-source]
name=AlmaLinux $releasever - Extras Source
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/extras-source
# baseurl=https://repo.almalinux.org/vault/$releasever/extras/Source/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

## Debuginfo
[baseos-debuginfo]
name=AlmaLinux $releasever - BaseOS debuginfo
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/baseos-debuginfo
# baseurl=https://repo.almalinux.org/vault/$releasever/BaseOS/debug/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

[appstream-debuginfo]
name=AlmaLinux $releasever - AppStream debuginfo
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/appstream-debuginfo
# baseurl=https://repo.almalinux.org/vault/$releasever/AppStream/debug/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

[extras-debuginfo]
name=AlmaLinux $releasever - Extras debuginfo
mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/extras-debuginfo
# baseurl=https://repo.almalinux.org/vault/$releasever/extras/debug/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux
EOF
        ;;
    esac
}

## 生成 Fedora 官方 repo 源文件
function gen_repo_files_Fedora() {
    cat <<'EOF' >$Dir_YumRepos/fedora.repo
[fedora]
name=Fedora $releasever - $basearch
#baseurl=http://download.example/pub/fedora/linux/releases/$releasever/Everything/$basearch/os/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
enabled=1
countme=1
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[fedora-debuginfo]
name=Fedora $releasever - $basearch - Debug
#baseurl=http://download.example/pub/fedora/linux/releases/$releasever/Everything/$basearch/debug/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-debug-$releasever&arch=$basearch
enabled=0
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[fedora-source]
name=Fedora $releasever - Source
#baseurl=http://download.example/pub/fedora/linux/releases/$releasever/Everything/source/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-source-$releasever&arch=$basearch
enabled=0
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF
    cat <<'EOF' >$Dir_YumRepos/fedora-updates.repo
[updates]
name=Fedora $releasever - $basearch - Updates
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Everything/$basearch/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-f$releasever&arch=$basearch
enabled=1
countme=1
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-debuginfo]
name=Fedora $releasever - $basearch - Updates - Debug
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Everything/$basearch/debug/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-debug-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-source]
name=Fedora $releasever - Updates Source
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Everything/SRPMS/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-source-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF
    cat <<'EOF' >$Dir_YumRepos/fedora-updates-testing.repo
[updates-testing]
name=Fedora $releasever - $basearch - Test Updates
#baseurl=http://download.example/pub/fedora/linux/updates/testing/$releasever/Everything/$basearch/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-f$releasever&arch=$basearch
enabled=0
countme=1
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-testing-debuginfo]
name=Fedora $releasever - $basearch - Test Updates Debug
#baseurl=http://download.example/pub/fedora/linux/updates/testing/$releasever/Everything/$basearch/debug/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-debug-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-testing-source]
name=Fedora $releasever - Test Updates Source
#baseurl=http://download.example/pub/fedora/linux/updates/testing/$releasever/Everything/SRPMS/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-source-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF
    ## 自 Fedora 39 起不再使用 modular 仓库
    if [[ $1 -lt 39 ]]; then
        cat <<'EOF' >$Dir_YumRepos/fedora-modular.repo
[fedora-modular]
name=Fedora Modular $releasever - $basearch
#baseurl=http://download.example/pub/fedora/linux/releases/$releasever/Modular/$basearch/os/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-modular-$releasever&arch=$basearch
enabled=1
countme=1
#metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[fedora-modular-debuginfo]
name=Fedora Modular $releasever - $basearch - Debug
#baseurl=http://download.example/pub/fedora/linux/releases/$releasever/Modular/$basearch/debug/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-modular-debug-$releasever&arch=$basearch
enabled=0
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[fedora-modular-source]
name=Fedora Modular $releasever - Source
#baseurl=http://download.example/pub/fedora/linux/releases/$releasever/Modular/source/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-modular-source-$releasever&arch=$basearch
enabled=0
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF
        cat <<'EOF' >$Dir_YumRepos/fedora-updates-modular.repo
[updates-modular]
name=Fedora Modular $releasever - $basearch - Updates
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Modular/$basearch/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-modular-f$releasever&arch=$basearch
enabled=1
countme=1
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-modular-debuginfo]
name=Fedora Modular $releasever - $basearch - Updates - Debug
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Modular/$basearch/debug/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-modular-debug-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-modular-source]
name=Fedora Modular $releasever - Updates Source
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Modular/SRPMS/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-modular-source-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF
        cat <<'EOF' >$Dir_YumRepos/fedora-updates-testing-modular.repo
[updates-testing-modular]
name=Fedora Modular $releasever - $basearch - Test Updates
#baseurl=http://download.example/pub/fedora/linux/updates/testing/$releasever/Modular/$basearch/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-modular-f$releasever&arch=$basearch
enabled=0
countme=1
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-testing-modular-debuginfo]
name=Fedora Modular $releasever - $basearch - Test Updates Debug
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Modular/$basearch/debug/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-modular-debug-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-testing-modular-source]
name=Fedora Modular $releasever - Test Updates Source
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Modular/SRPMS/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-modular-source-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF
    fi
}

## 生成 OpenCloudOS 官方 repo 源文件
function gen_repo_files_OpenCloudOS() {
    case "$1" in
    9)
        cat <<'EOF' >$Dir_YumRepos/OpenCloudOS.repo
[BaseOS]
name=BaseOS $releasever - $basearch
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/BaseOS/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS-9

[AppStream]
name=AppStream $releasever - $basearch
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/AppStream/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS-9

[extras]
name=extras $releasever - $basearch
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/extras/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS-9

[BaseOS-debuginfo]
name=BaseOS-debuginfo $releasever - $basearch
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/BaseOS/$basearch/debug/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS-9

[AppStream-debuginfo]
name=AppStream-debuginfo $releasever - $basearch
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/AppStream/$basearch/debug/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS-9

[extras-debuginfo]
name=extras-debuginfo $releasever - $basearch
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/extras/$basearch/debug/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS-9

[BaseOS-source]
name=BaseOS-source $releasever
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/BaseOS/source/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS-9

[AppStream-source]
name=AppStream-source $releasever
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/AppStream/source/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS-9

[extras-source]
name=extras-source $releasever
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/extras/source/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS-9
EOF
        ;;
    8)
        cat <<'EOF' >$Dir_YumRepos/OpenCloudOS-Debuginfo.repo
# OpenCloudOS-Debuginfo.repo
#
# Author: OpenCloudOS <infrastructure@opencloudos.tech>
#
[BaseOS-debuginfo]
name=OpenCloudOS $releasever - BaseOS-debuginfo
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/BaseOS/$basearch/debug/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS

[AppStream-debuginfo]
name=OpenCloudOS $releasever - AppStream-debuginfo
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/AppStream/$basearch/debug/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS

[Extras-debuginfo]
name=OpenCloudOS $releasever - Extras-debuginfo
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/Extras/$basearch/debug/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS

[HighAvailability-debuginfo]
name=OpenCloudOS $releasever - HighAvailability-debuginfo
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/HighAvailability/$basearch/debug/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS

[PowerTools-debuginfo]
name=OpenCloudOS $releasever - PowerTools-debuginfo
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/PowerTools/$basearch/debug/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS

[ResilientStorage-debuginfo]
name=OpenCloudOS $releasever - ResilientStorage-debuginfo
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/ResilientStorage/$basearch/debug/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS

[Plus-debuginfo]
name=OpenCloudOS $releasever - Plus-debuginfo
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/Plus/$basearch/debug/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS
EOF
        cat <<'EOF' >$Dir_YumRepos/OpenCloudOS.repo
# OpenCloudOS.repo
#
# Author: OpenCloudOS <infrastructure@opencloudos.tech>
#
[BaseOS]
name=OpenCloudOS $releasever - BaseOS
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/BaseOS/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS

[AppStream]
name=OpenCloudOS $releasever - AppStream
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/AppStream/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS

[Extras]
name=OpenCloudOS $releasever - Extras
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/Extras/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS

[HighAvailability]
name=OpenCloudOS $releasever - HighAvailability
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/HighAvailability/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS

[PowerTools]
name=OpenCloudOS $releasever - PowerTools
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/PowerTools/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS

[ResilientStorage]
name=OpenCloudOS $releasever - ResilientStorage
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/ResilientStorage/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS

[Plus]
name=OpenCloudOS $releasever - Plus
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/Plus/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS
EOF
        cat <<'EOF' >$Dir_YumRepos/OpenCloudOS-Sources.repo
# OpenCloudOS-Sources.repo
#
# Author: OpenCloudOS <infrastructure@opencloudos.tech>
#
[BaseOS-source]
name=OpenCloudOS $releasever - Base-source
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/BaseOS/source/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS

[AppStream-source]
name=OpenCloudOS $releasever - AppStream-source
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/AppStream/source/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS

[Extras-source]
name=OpenCloudOS $releasever - Extras-source
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/Extras/source/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS

[HighAvailability-source]
name=OpenCloudOS $releasever - HighAvailability-source
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/HighAvailability/source/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS

[PowerTools-source]
name=OpenCloudOS $releasever - PowerTools-source
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/PowerTools/source/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS

[ResilientStorage-source]
name=OpenCloudOS $releasever - ResilientStorage-source
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/ResilientStorage/source/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS

[Plus-source]
name=OpenCloudOS $releasever - Plus-source
baseurl=https://mirrors.opencloudos.tech/opencloudos/$releasever/Plus/source/tree/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenCloudOS
EOF
        ;;
    esac
}

## 生成 openEuler 官方 repo 源文件
function gen_repo_files_openEuler() {
    cat <<'EOF' >$Dir_YumRepos/openEuler.repo
#generic-repos is licensed under the Mulan PSL v2.
#You can use this software according to the terms and conditions of the Mulan PSL v2.
#You may obtain a copy of Mulan PSL v2 at:
#    http://license.coscl.org.cn/MulanPSL2
#THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
#PURPOSE.
#See the Mulan PSL v2 for more details.

[OS]
name=OS
baseurl=http://repo.openeuler.org/openEuler-version/OS/$basearch/
enabled=1
gpgcheck=1
gpgkey=http://repo.openeuler.org/openEuler-version/OS/$basearch/RPM-GPG-KEY-openEuler

[everything]
name=everything
baseurl=http://repo.openeuler.org/openEuler-version/everything/$basearch/
enabled=1
gpgcheck=1
gpgkey=http://repo.openeuler.org/openEuler-version/everything/$basearch/RPM-GPG-KEY-openEuler

[EPOL]
name=EPOL
baseurl=http://repo.openeuler.org/openEuler-version/EPOL/main/$basearch/
enabled=1
gpgcheck=1
gpgkey=http://repo.openeuler.org/openEuler-version/OS/$basearch/RPM-GPG-KEY-openEuler

[debuginfo]
name=debuginfo
baseurl=http://repo.openeuler.org/openEuler-version/debuginfo/$basearch/
enabled=1
gpgcheck=1
gpgkey=http://repo.openeuler.org/openEuler-version/debuginfo/$basearch/RPM-GPG-KEY-openEuler

[source]
name=source
baseurl=http://repo.openeuler.org/openEuler-version/source/
enabled=1
gpgcheck=1
gpgkey=http://repo.openeuler.org/openEuler-version/source/RPM-GPG-KEY-openEuler

[update]
name=update
baseurl=http://repo.openeuler.org/openEuler-version/update/$basearch/
enabled=1
gpgcheck=1
gpgkey=http://repo.openeuler.org/openEuler-version/OS/$basearch/RPM-GPG-KEY-openEuler

[update-source]
name=update-source
baseurl=http://repo.openeuler.org/openEuler-version/update/source/
enabled=1
gpgcheck=1
gpgkey=http://repo.openeuler.org/openEuler-version/source/RPM-GPG-KEY-openEuler
EOF
}

## 生成 openSUSE 官方 repo 源文件
function gen_repo_files_openSUSE() {
    case "$1" in
    "leap")
        case "$2" in
        15.[0-2])
            cat <<'EOF' >$Dir_openSUSERepos/repo-debug-non-oss.repo
[repo-debug-non-oss]
name=Debug Repository (Non-OSS)
enabled=0
autorefresh=1
baseurl=http://download.opensuse.org/debug/distribution/leap/$releasever/repo/non-oss/
type=NONE
keeppackages=0
EOF
            cat <<'EOF' >$Dir_openSUSERepos/repo-debug.repo
[repo-debug]
name=Debug Repository
enabled=0
autorefresh=1
baseurl=http://download.opensuse.org/debug/distribution/leap/$releasever/repo/oss/
type=NONE
keeppackages=0
EOF
            cat <<'EOF' >$Dir_openSUSERepos/repo-debug-update-non-oss.repo
[repo-debug-update-non-oss]
name=Update Repository (Debug, Non-OSS)
enabled=0
autorefresh=1
baseurl=http://download.opensuse.org/debug/update/leap/$releasever/non-oss/
type=NONE
keeppackages=0
EOF
            cat <<'EOF' >$Dir_openSUSERepos/repo-debug-update.repo
[repo-debug-update]
name=Update Repository (Debug)
enabled=0
autorefresh=1
baseurl=http://download.opensuse.org/debug/update/leap/$releasever/oss/
type=NONE
keeppackages=0
EOF
            cat <<'EOF' >$Dir_openSUSERepos/repo-non-oss.repo
[repo-non-oss]
name=Non-OSS Repository
enabled=1
autorefresh=1
baseurl=http://download.opensuse.org/distribution/leap/$releasever/repo/non-oss/
type=rpm-md
keeppackages=0
EOF
            cat <<'EOF' >$Dir_openSUSERepos/repo-oss.repo
[repo-oss]
name=Main Repository
enabled=1
autorefresh=1
baseurl=http://download.opensuse.org/distribution/leap/$releasever/repo/oss/
type=rpm-md
keeppackages=0
EOF
            cat <<'EOF' >$Dir_openSUSERepos/repo-source-non-oss.repo
[repo-source-non-oss]
name=Source Repository (Non-OSS)
enabled=0
autorefresh=1
baseurl=http://download.opensuse.org/source/distribution/leap/$releasever/repo/non-oss/
type=NONE
keeppackages=0
EOF
            cat <<'EOF' >$Dir_openSUSERepos/repo-source.repo
[repo-source]
name=Source Repository
enabled=0
autorefresh=1
baseurl=http://download.opensuse.org/source/distribution/leap/$releasever/repo/oss/
type=NONE
keeppackages=0
EOF
            cat <<'EOF' >$Dir_openSUSERepos/repo-update-non-oss.repo
[repo-update-non-oss]
name=Update Repository (Non-Oss)
enabled=1
autorefresh=1
baseurl=http://download.opensuse.org/update/leap/$releasever/non-oss/
type=rpm-md
keeppackages=0
EOF
            cat <<'EOF' >$Dir_openSUSERepos/repo-update.repo
[repo-update]
name=Main Update Repository
enabled=1
autorefresh=1
baseurl=http://download.opensuse.org/update/leap/$releasever/oss/
type=rpm-md
keeppackages=0
EOF
            ;;
        *)
            cat <<'EOF' >$Dir_openSUSERepos/repo-backports-debug-update.repo
[repo-backports-debug-update]
name=Update repository with updates for openSUSE Leap debuginfo packages from openSUSE Backports
enabled=0
autorefresh=1
baseurl=http://download.opensuse.org/update/leap/$releasever/backports_debug/
type=NONE
keeppackages=0
EOF
            cat <<'EOF' >$Dir_openSUSERepos/repo-backports-update.repo
[repo-backports-update]
name=Update repository of openSUSE Backports
enabled=1
autorefresh=1
baseurl=http://download.opensuse.org/update/leap/$releasever/backports/
path=/
type=rpm-md
keeppackages=0
EOF
            cat <<'EOF' >$Dir_openSUSERepos/repo-debug-non-oss.repo
[repo-debug-non-oss]
name=Debug Repository (Non-OSS)
enabled=0
autorefresh=1
baseurl=http://download.opensuse.org/debug/distribution/leap/$releasever/repo/non-oss/
keeppackages=0
EOF
            cat <<'EOF' >$Dir_openSUSERepos/repo-debug.repo
[repo-debug]
name=Debug Repository
enabled=0
autorefresh=1
baseurl=http://download.opensuse.org/debug/distribution/leap/$releasever/repo/oss/
keeppackages=0
EOF
            cat <<'EOF' >$Dir_openSUSERepos/repo-debug-update-non-oss.repo
[repo-debug-update-non-oss]
name=Update Repository (Debug, Non-OSS)
enabled=0
autorefresh=1
baseurl=http://download.opensuse.org/debug/update/leap/$releasever/non-oss/
keeppackages=0
EOF
            cat <<'EOF' >$Dir_openSUSERepos/repo-debug-update.repo
[repo-debug-update]
name=Update Repository (Debug)
enabled=0
autorefresh=1
baseurl=http://download.opensuse.org/debug/update/leap/$releasever/oss/
keeppackages=0
EOF
            cat <<'EOF' >$Dir_openSUSERepos/repo-non-oss.repo
[repo-non-oss]
name=Non-OSS Repository
enabled=1
autorefresh=1
baseurl=http://download.opensuse.org/distribution/leap/$releasever/repo/non-oss/
type=rpm-md
keeppackages=0
EOF
            cat <<'EOF' >$Dir_openSUSERepos/repo-oss.repo
[repo-oss]
name=Main Repository
enabled=1
autorefresh=1
baseurl=http://download.opensuse.org/distribution/leap/$releasever/repo/oss/
type=rpm-md
keeppackages=0
EOF
            cat <<'EOF' >$Dir_openSUSERepos/repo-sle-debug-update.repo
[repo-sle-debug-update]
name=Update repository with debuginfo for updates from SUSE Linux Enterprise 15
enabled=0
autorefresh=1
baseurl=http://download.opensuse.org/debug/update/leap/$releasever/sle/
path=/
type=rpm-md
keeppackages=0
EOF
            cat <<'EOF' >$Dir_openSUSERepos/repo-sle-update.repo
[repo-sle-update]
name=Update repository with updates from SUSE Linux Enterprise 15
enabled=1
autorefresh=1
baseurl=http://download.opensuse.org/update/leap/$releasever/sle/
path=/
type=rpm-md
keeppackages=0
EOF
            cat <<'EOF' >$Dir_openSUSERepos/repo-source.repo
[repo-source]
name=Source Repository
enabled=0
autorefresh=1
baseurl=http://download.opensuse.org/source/distribution/leap/$releasever/repo/oss/
keeppackages=0
EOF
            cat <<'EOF' >$Dir_openSUSERepos/repo-update-non-oss.repo
[repo-update-non-oss]
name=Update Repository (Non-Oss)
enabled=1
autorefresh=1
baseurl=http://download.opensuse.org/update/leap/$releasever/non-oss/
type=rpm-md
keeppackages=0
EOF
            cat <<'EOF' >$Dir_openSUSERepos/repo-update.repo
[repo-update]
name=Main Update Repository
enabled=1
autorefresh=1
baseurl=http://download.opensuse.org/update/leap/$releasever/oss/
type=rpm-md
keeppackages=0
EOF
            ;;
        esac
        ;;
    "tumbleweed")
        cat <<'EOF' >$Dir_openSUSERepos/repo-debug.repo
[repo-debug]
name=openSUSE-Tumbleweed-Debug
enabled=0
autorefresh=1
baseurl=http://download.opensuse.org/debug/tumbleweed/repo/oss/
path=/
keeppackages=0
EOF
        cat <<'EOF' >$Dir_openSUSERepos/repo-non-oss.repo
[repo-non-oss]
name=openSUSE-Tumbleweed-Non-Oss
enabled=1
autorefresh=1
baseurl=http://download.opensuse.org/tumbleweed/repo/non-oss/
path=/
type=rpm-md
keeppackages=0
EOF
        cat <<'EOF' >$Dir_openSUSERepos/repo-openh264.repo
[repo-openh264]
name=Open H.264 Codec (openSUSE Tumbleweed)
enabled=1
autorefresh=1
baseurl=http://codecs.opensuse.org/openh264/openSUSE_Tumbleweed
path=/
type=rpm-md
keeppackages=0
EOF
        cat <<'EOF' >$Dir_openSUSERepos/repo-oss.repo
[repo-oss]
name=openSUSE-Tumbleweed-Oss
enabled=1
autorefresh=1
baseurl=http://download.opensuse.org/tumbleweed/repo/oss/
path=/
type=rpm-md
keeppackages=0
EOF
        cat <<'EOF' >$Dir_openSUSERepos/repo-source.repo
[repo-source]
name=openSUSE-Tumbleweed-Source
enabled=0
autorefresh=1
baseurl=http://download.opensuse.org/source/tumbleweed/repo/oss/
path=/
keeppackages=0
EOF
        cat <<'EOF' >$Dir_openSUSERepos/repo-update.repo
[repo-update]
name=openSUSE-Tumbleweed-Update
enabled=1
autorefresh=1
baseurl=http://download.opensuse.org/update/tumbleweed/
path=/
type=rpm-md
keeppackages=0
EOF
        ;;
    esac
}

## 生成 EPEL 附加软件包官方 repo 源文件
function gen_repo_files_EPEL() {
    case ${SYSTEM_VERSION_NUMBER:0:1} in
    9)
        cat <<'EOF' >$Dir_YumRepos/epel.repo
[epel]
name=Extra Packages for Enterprise Linux $releasever - $basearch
# It is much more secure to use the metalink, but if you wish to use a local mirror
# place its address here.
#baseurl=https://download.example/pub/epel/$releasever/Everything/$basearch/
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=1
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-$releasever

[epel-debuginfo]
name=Extra Packages for Enterprise Linux $releasever - $basearch - Debug
# It is much more secure to use the metalink, but if you wish to use a local mirror
# place its address here.
#baseurl=https://download.example/pub/epel/$releasever/Everything/$basearch/debug/
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-$releasever
gpgcheck=1

[epel-source]
name=Extra Packages for Enterprise Linux $releasever - $basearch - Source
# It is much more secure to use the metalink, but if you wish to use a local mirror
# place its address here.
#baseurl=https://download.example/pub/epel/$releasever/Everything/source/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-source-$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-$releasever
gpgcheck=1
EOF
        cat <<'EOF' >$Dir_YumRepos/epel-testing.repo
[epel-testing]
name=Extra Packages for Enterprise Linux $releasever - Testing - $basearch
# It is much more secure to use the metalink, but if you wish to use a local mirror
# place its address here.
#baseurl=https://download.example/pub/epel/testing/$releasever/Everything/$basearch/
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-$releasever

[epel-testing-debuginfo]
name=Extra Packages for Enterprise Linux $releasever - Testing - $basearch - Debug
# It is much more secure to use the metalink, but if you wish to use a local mirror
# place its address here.
#baseurl=https://download.example/pub/epel/testing/$releasever/Everything/$basearch/debug/
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-debug-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-$releasever
gpgcheck=1

[epel-testing-source]
name=Extra Packages for Enterprise Linux $releasever - Testing - $basearch - Source
# It is much more secure to use the metalink, but if you wish to use a local mirror
# place its address here.
#baseurl=https://download.example/pub/epel/testing/$releasever/Everything/source/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-source-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-$releasever
gpgcheck=1
EOF
        ## 此仓库特殊，默认不启用
        cat <<'EOF' >$Dir_YumRepos/epel-cisco-openh264.repo
[epel-cisco-openh264]
name=Extra Packages for Enterprise Linux $releasever openh264 (From Cisco) - $basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-cisco-openh264-$releasever&arch=$basearch
type=rpm
enabled=0
metadata_expire=14d
repo_gpgcheck=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-$releasever
skip_if_unavailable=True

[epel-cisco-openh264-debuginfo]
name=Extra Packages for Enterprise Linux $releasever openh264 (From Cisco) - $basearch - Debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-cisco-openh264-debug-$releasever&arch=$basearch
type=rpm
enabled=0
metadata_expire=14d
repo_gpgcheck=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-$releasever
skip_if_unavailable=True

[epel-cisco-openh264-source]
name=Extra Packages for Enterprise Linux $releasever openh264 (From Cisco) - $basearch - Source
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-cisco-openh264-source-$releasever&arch=$basearch
type=rpm
enabled=0
metadata_expire=14d
repo_gpgcheck=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-$releasever
skip_if_unavailable=True
EOF
        ;;
    8)
        cat <<'EOF' >$Dir_YumRepos/epel.repo
[epel]
name=Extra Packages for Enterprise Linux 8 - $basearch
# It is much more secure to use the metalink, but if you wish to use a local mirror
# place its address here.
#baseurl=https://download.example/pub/epel/8/Everything/$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-8&arch=$basearch&infra=$infra&content=$contentdir
enabled=1
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8

[epel-debuginfo]
name=Extra Packages for Enterprise Linux 8 - $basearch - Debug
# It is much more secure to use the metalink, but if you wish to use a local mirror
# place its address here.
#baseurl=https://download.example/pub/epel/8/Everything/$basearch/debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-8&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1

[epel-source]
name=Extra Packages for Enterprise Linux 8 - $basearch - Source
# It is much more secure to use the metalink, but if you wish to use a local mirror
# place it's address here.
#baseurl=https://download.example/pub/epel/8/Everything/source/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-source-8&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1
EOF
        cat <<'EOF' >$Dir_YumRepos/epel-testing.repo
[epel-testing]
name=Extra Packages for Enterprise Linux 8 - Testing - $basearch
# It is much more secure to use the metalink, but if you wish to use a local mirror
# place its address here.
#baseurl=https://download.example/pub/epel/testing/8/Everything/$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-epel8&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8

[epel-testing-debuginfo]
name=Extra Packages for Enterprise Linux 8 - Testing - $basearch - Debug
# It is much more secure to use the metalink, but if you wish to use a local mirror
# place its address here.
#baseurl=https://download.example/pub/epel/testing/8/Everything/$basearch/debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-debug-epel8&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1

[epel-testing-source]
name=Extra Packages for Enterprise Linux 8 - Testing - $basearch - Source
# It is much more secure to use the metalink, but if you wish to use a local mirror
# place it's address here.
#baseurl=https://download.example/pub/epel/testing/8/Everything/source/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-source-epel8&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1
EOF
        cat <<'EOF' >$Dir_YumRepos/epel-modular.repo
[epel-modular]
# This repo has been RETIRED, see https://pagure.io/epel/issue/198 for more details.
name=Extra Packages for Enterprise Linux Modular 8 - $basearch - RETIRED
# It is much more secure to use the metalink, but if you wish to use a local mirror
# place its address here.
#baseurl=https://download.example/pub/epel/8/Modular/$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-modular-8&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8

[epel-modular-debuginfo]
# This repo has been RETIRED, see https://pagure.io/epel/issue/198 for more details.
name=Extra Packages for Enterprise Linux Modular 8 - $basearch - Debug - RETIRED
# It is much more secure to use the metalink, but if you wish to use a local mirror
# place its address here.
#baseurl=https://download.example/pub/epel/8/Modular/$basearch/debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-modular-debug-8&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1

[epel-modular-source]
# This repo has been RETIRED, see https://pagure.io/epel/issue/198 for more details.
name=Extra Packages for Enterprise Linux Modular 8 - $basearch - Source - RETIRED
# It is much more secure to use the metalink, but if you wish to use a local mirror
# place it's address here.
#baseurl=https://download.example/pub/epel/8/Modular/source/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-modular-source-8&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1
EOF
        cat <<'EOF' >$Dir_YumRepos/epel-testing-modular.repo
[epel-testing-modular]
# This repo has been RETIRED, see https://pagure.io/epel/issue/198 for more details.
name=Extra Packages for Enterprise Linux Modular 8 - Testing - $basearch - RETIRED
# It is much more secure to use the metalink, but if you wish to use a local mirror
# place its address here.
#baseurl=https://download.example/pub/epel/testing/8/Modular/$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-modular-epel8&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8

[epel-testing-modular-debuginfo]
# This repo has been RETIRED, see https://pagure.io/epel/issue/198 for more details.
name=Extra Packages for Enterprise Linux Modular 8 - Testing - $basearch - Debug - RETIRED
# It is much more secure to use the metalink, but if you wish to use a local mirror
# place its address here.
#baseurl=https://download.example/pub/epel/testing/8/Modular/$basearch/debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-modular-debug-epel8&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1

[epel-testing-modular-source]
# This repo has been RETIRED, see https://pagure.io/epel/issue/198 for more details.
name=Extra Packages for Enterprise Linux Modular 8 - Testing - $basearch - Source - RETIRED
# It is much more secure to use the metalink, but if you wish to use a local mirror
# place it's address here.
#baseurl=https://download.example/pub/epel/testing/8/Modular/source/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-modular-source-epel8&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1
EOF
        ;;
    7)
        cat <<'EOF' >$Dir_YumRepos/epel.repo
[epel]
name=Extra Packages for Enterprise Linux 7 - $basearch
#baseurl=http://download.fedoraproject.org/pub/epel/7/$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

[epel-debuginfo]
name=Extra Packages for Enterprise Linux 7 - $basearch - Debug
#baseurl=http://download.fedoraproject.org/pub/epel/7/$basearch/debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-7&arch=$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1

[epel-source]
name=Extra Packages for Enterprise Linux 7 - $basearch - Source
#baseurl=http://download.fedoraproject.org/pub/epel/7/SRPMS
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-source-7&arch=$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1
EOF
        cat <<'EOF' >$Dir_YumRepos/epel-testing.repo
[epel-testing]
name=Extra Packages for Enterprise Linux 7 - Testing - $basearch
#baseurl=http://download.fedoraproject.org/pub/epel/testing/7/$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-epel7&arch=$basearch
failovermethod=priority
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

[epel-testing-debuginfo]
name=Extra Packages for Enterprise Linux 7 - Testing - $basearch - Debug
#baseurl=http://download.fedoraproject.org/pub/epel/testing/7/$basearch/debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-debug-epel7&arch=$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1

[epel-testing-source]
name=Extra Packages for Enterprise Linux 7 - Testing - $basearch - Source
#baseurl=http://download.fedoraproject.org/pub/epel/testing/7/SRPMS
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-source-epel7&arch=$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1
EOF
        ;;
    esac
}

##############################################################################

handle_command_options "$@"
main
