# TP842N-V3 打印服务器固件 Makefile

.PHONY: all clean download config build

# 默认目标
all: build

# 清理工作目录
clean:
	@echo "清理工作目录..."
	@rm -rf $(HOME)/openwrt-build/openwrt/bin
	@rm -rf $(HOME)/openwrt-build/openwrt/build_dir
	@rm -rf $(HOME)/openwrt-build/openwrt/tmp
	@echo "清理完成"

# 下载源码
download:
	@echo "准备下载源码..."
	@./build.sh download

# 配置编译选项
config:
	@echo "配置编译选项..."
	@cd $(HOME)/openwrt-build/openwrt && make defconfig

# 编译固件
build:
	@echo "开始编译固件..."
	@./build.sh

# 快速编译（跳过下载）
fast-build:
	@echo "快速编译模式..."
	@cd $(HOME)/openwrt-build/openwrt && make -j$$(nproc)

# 单线程调试编译
debug-build:
	@echo "调试编译模式..."
	@cd $(HOME)/openwrt-build/openwrt && make -j1 V=s

# 显示帮助
help:
	@echo "TP842N-V3 打印服务器固件构建系统"
	@echo ""
	@echo "使用方法:"
	@echo "  make          - 完整编译流程"
	@echo "  make clean    - 清理工作目录"
	@echo "  make download - 下载源码包"
	@echo "  make config   - 配置编译选项"
	@echo "  make build    - 编译固件"
	@echo "  make fast-build - 快速编译（跳过下载）"
	@echo "  make debug-build - 单线程调试编译"
	@echo "  make help     - 显示此帮助信息"
	@echo ""
	@echo "输出文件位置: output/"

# 安装依赖
install-deps:
	@echo "安装构建依赖..."
	@sudo apt-get update
	@sudo apt-get install -y \
		build-essential ccache ecj fastjar file g++ gawk \
		gettext git java-propose-classname libelf-dev \
		libncurses5-dev libncursesw5-dev libssl-dev \
		python python2.7-dev python3 unzip wget \
		python3-distutils python3-setuptools python3-dev \
		rsync subversion swig time xsltproc zlib1g-dev
	@echo "依赖安装完成"

# 创建输出目录
output:
	@mkdir -p output
	@echo "输出目录已创建: output/"

# 检查环境
check:
	@echo "检查构建环境..."
	@echo "系统信息: $$(lsb_release -a 2>/dev/null || echo '无法获取系统信息')"
	@echo "可用内存: $$(free -h | grep Mem:)"
	@echo "磁盘空间: $$(df -h .)"
	@echo "CPU 核心数: $$(nproc)"
