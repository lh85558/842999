#!/bin/bash
# Ubuntu 22.04 LTS OpenWrt 构建依赖安装脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== OpenWrt 构建依赖安装脚本 ===${NC}"
echo -e "${BLUE}适用于 Ubuntu 22.04 LTS${NC}"

# 检查系统版本
check_system() {
    if ! grep -q "Ubuntu 22.04" /etc/os-release; then
        echo -e "${YELLOW}警告: 此脚本专为 Ubuntu 22.04 LTS 设计${NC}"
        read -p "是否继续? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# 更新软件包列表
update_packages() {
    echo -e "${GREEN}更新软件包列表...${NC}"
    sudo apt-get update
}

# 安装基础构建工具
install_base_tools() {
    echo -e "${GREEN}安装基础构建工具...${NC}"
    sudo apt-get install -y \
        build-essential \
        ccache \
        ecj \
        fastjar \
        file \
        g++ \
        gawk \
        gettext \
        git \
        java-propose-classname \
        libelf-dev \
        libncurses5-dev \
        libncursesw5-dev \
        libssl-dev \
        2to3 \
        python2 \
        python-is-python3 \
        python3 \
        unzip \
        wget \
        python3-distutils \
        python3-setuptools \
        python3-dev \
        rsync \
        subversion \
        swig \
        time \
        xsltproc \
        zlib1g-dev
}

# 安装额外开发工具
install_dev_tools() {
    echo -e "${GREEN}安装额外开发工具...${NC}"
    sudo apt-get install -y \
        libxml-parser-perl \
        libusb-dev \
        libusb-1.0-0-dev \
        gperf \
        flex \
        bison \
        libncurses-dev \
        libreadline-dev \
        libglib2.0-dev \
        libfdt-dev \
        libpixman-1-dev \
        zlib1g-dev \
        libaio-dev \
        libbluetooth-dev \
        libbrlapi-dev \
        libbz2-dev \
        libcap-dev \
        libcap-ng-dev \
        libcurl4-openssl-dev \
        libgtk-3-dev \
        libibverbs-dev \
        libjpeg8-dev \
        liblzo2-dev \
        libncurses5-dev \
        libnuma-dev \
        libnss3-dev \
        libopus-dev \
        libpng-dev \
        librbd-dev \
        libsasl2-dev \
        libsdl1.2-dev \
        libseccomp-dev \
        libsnappy-dev \
        libssh2-1-dev \
        libspice-server-dev \
        libusb-1.0-0-dev \
        libusb-dev \
        libvde-dev \
        libvdeplug-dev \
        libvorbis-dev \
        libxen-dev \
        libxinerama-dev \
        libxml2-dev \
        libxrandr-dev \
        libxrender-dev \
        libxslt1-dev \
        libyajl-dev \
        linux-libc-dev \
        make \
        pkg-config \
        python3-dev \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        uuid-dev \
        xfslibs-dev
}

# 安装可选工具
install_optional_tools() {
    echo -e "${GREEN}安装可选工具...${NC}"
    sudo apt-get install -y \
        htop \
        tree \
        curl \
        jq \
        expect \
        tftp-hpa \
        sshpass \
        screen \
        tmux \
        vim \
        nano
}

# 配置 Git
configure_git() {
    echo -e "${GREEN}配置 Git...${NC}"
    
    # 设置 Git 用户信息（如果不存在）
    if [ -z "$(git config --global user.name 2>/dev/null)" ]; then
        git config --global user.name "OpenWrt Builder"
    fi
    
    if [ -z "$(git config --global user.email 2>/dev/null)" ]; then
        git config --global user.email "builder@openwrt.local"
    fi
    
    # 配置 Git 加速
    git config --global http.postBuffer 524288000
    git config --global core.compression 0
    
    echo -e "${GREEN}✅ Git 配置完成${NC}"
}

# 配置环境变量
setup_environment() {
    echo -e "${GREEN}配置环境变量...${NC}"
    
    # 添加到 .bashrc
    if ! grep -q "OPENWRT_BUILD_ENV" ~/.bashrc; then
        cat >> ~/.bashrc << 'EOF'

# OpenWrt 构建环境
export OPENWRT_BUILD_ENV=1
export PATH=$PATH:$HOME/openwrt-build/openwrt/staging_dir/host/bin
export STAGING_DIR=$HOME/openwrt-build/openwrt/staging_dir

# 构建优化
export FORCE_UNSAFE_CONFIGURE=1
EOF
        echo -e "${GREEN}✅ 环境变量已添加到 ~/.bashrc${NC}"
        echo -e "${YELLOW}请运行: source ~/.bashrc 使配置生效${NC}"
    fi
}

# 创建工作目录
create_workdir() {
    echo -e "${GREEN}创建工作目录...${NC}"
    mkdir -p "$HOME/openwrt-build"
    echo -e "${GREEN}✅ 工作目录已创建: $HOME/openwrt-build${NC}"
}

# 显示系统信息
show_system_info() {
    echo -e "${BLUE}=== 系统信息 ===${NC}"
    echo "操作系统: $(lsb_release -d | cut -f2)"
    echo "内核版本: $(uname -r)"
    echo "CPU 信息: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
    echo "CPU 核心数: $(nproc)"
    echo "总内存: $(free -h | grep Mem: | awk '{print $2}')"
    echo "可用磁盘: $(df -h $HOME | tail -1 | awk '{print $4}')"
    echo ""
}

# 验证安装
verify_installation() {
    echo -e "${GREEN}验证安装...${NC}"
    
    local tools=("gcc" "g++" "make" "git" "wget" "curl" "python3" "java")
    local missing=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing+=("$tool")
        fi
    done
    
    if [ ${#missing[@]} -eq 0 ]; then
        echo -e "${GREEN}✅ 所有依赖安装成功${NC}"
    else
        echo -e "${RED}❌ 以下工具未安装: ${missing[*]}${NC}"
        return 1
    fi
}

# 显示使用说明
show_usage() {
    echo ""
    echo -e "${GREEN}=== 安装完成！===${NC}"
    echo ""
    echo -e "${BLUE}下一步操作:${NC}"
    echo "1. 重新加载环境变量: source ~/.bashrc"
    echo "2. 克隆项目: git clone <项目地址>"
    echo "3. 开始构建: ./build.sh"
    echo ""
    echo -e "${BLUE}常用命令:${NC}"
    echo "  make help     - 显示构建帮助"
    echo "  make build    - 完整构建"
    echo "  make clean    - 清理构建"
    echo ""
    echo -e "${YELLOW}提示: 首次构建可能需要较长时间，请耐心等待${NC}"
}

# 主函数
main() {
    show_system_info
    check_system
    
    echo -e "${BLUE}开始安装 OpenWrt 构建依赖...${NC}"
    
    update_packages
    install_base_tools
    install_dev_tools
    install_optional_tools
    configure_git
    setup_environment
    create_workdir
    
    if verify_installation; then
        show_usage
    else
        echo -e "${RED}安装验证失败，请检查错误信息${NC}"
        exit 1
    fi
}

# 运行主函数
main "$@"
