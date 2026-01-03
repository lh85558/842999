#!/bin/bash
# TP842N-V3 打印服务器固件构建脚本
# 适用于 Ubuntu 22.04 LTS

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== TP842N-V3 打印服务器固件构建脚本 ===${NC}"

# 检查系统
if ! grep -q "Ubuntu 22.04" /etc/os-release; then
    echo -e "${YELLOW}警告: 建议使用 Ubuntu 22.04 LTS${NC}"
fi

# 安装依赖
echo -e "${GREEN}安装构建依赖...${NC}"
sudo apt-get update
sudo apt-get install -y \
    build-essential ccache ecj fastjar file g++ gawk \
    gettext git java-propose-classname libelf-dev \
    libncurses5-dev libncursesw5-dev libssl-dev \
    python python2.7-dev python3 unzip wget \
    python3-distutils python3-setuptools python3-dev \
    rsync subversion swig time xsltproc zlib1g-dev

# 创建工作目录
WORK_DIR="$HOME/openwrt-build"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# 克隆 OpenWrt 源码（使用国内镜像）
echo -e "${GREEN}克隆 OpenWrt 源码...${NC}"
if [ ! -d "openwrt" ]; then
    git clone https://mirrors.tuna.tsinghua.edu.cn/git/openwrt/openwrt.git
fi

cd openwrt

# 切换到稳定版本
echo -e "${GREEN}切换到 OpenWrt 23.05 稳定版...${NC}"
git checkout v23.05.3

# 更新和安装 feeds
echo -e "${GREEN}更新 feeds...${NC}"
./scripts/feeds update -a
./scripts/feeds install -a

# 复制配置文件
echo -e "${GREEN}应用配置文件...${NC}"
cp "$OLDPWD/configs/tp842n3.config" .config

# 下载额外软件包
echo -e "${GREEN}下载额外软件包...${NC}"
./scripts/feeds install cups cups-bjnp luci-i18n-base-zh-cn

# 配置编译选项
echo -e "${GREEN}配置编译选项...${NC}"
make defconfig

# 开始编译
echo -e "${GREEN}开始编译固件...${NC}"
make -j$(nproc) download world

# 检查编译结果
if [ -f "bin/targets/ar71xx/generic/openwrt-ar71xx-generic-tl-wr842n-v3-squashfs-factory.bin" ]; then
    echo -e "${GREEN}编译成功！${NC}"
    echo -e "${GREEN}固件位置: bin/targets/ar71xx/generic/${NC}"
    
    # 复制固件到项目目录
    mkdir -p "$OLDPWD/output"
    cp bin/targets/ar71xx/generic/*842n-v3* "$OLDPWD/output/"
    
    echo -e "${GREEN}固件已复制到 output/ 目录${NC}"
else
    echo -e "${RED}编译失败，请检查错误信息${NC}"
    exit 1
fi

echo -e "${GREEN}构建完成！${NC}"
