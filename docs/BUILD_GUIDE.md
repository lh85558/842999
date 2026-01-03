# TP842N-V3 打印服务器固件构建指南

## 系统要求

- **操作系统**: Ubuntu 22.04 LTS (推荐)
- **CPU**: 多核处理器 (建议 4 核以上)
- **内存**: 最少 4GB (推荐 8GB 以上)
- **磁盘空间**: 最少 20GB 可用空间
- **网络**: 稳定的互联网连接

## 快速开始

### 1. 安装依赖

```bash
# 运行依赖安装脚本
./scripts/install-deps.sh
```

或者手动安装：

```bash
sudo apt-get update
sudo apt-get install -y build-essential ccache ecj fastjar file g++ gawk \
    gettext git java-propose-classname libelf-dev libncurses5-dev \
    libncursesw5-dev libssl-dev python python2.7-dev python3 unzip \
    wget python3-distutils python3-setuptools python3-dev rsync \
    subversion swig time xsltproc zlib1g-dev
```

### 2. 克隆项目

```bash
git clone https://github.com/your-repo/tp842n3-printserver.git
cd tp842n3-printserver
```

### 3. 一键构建

```bash
# 完整构建流程
./build.sh

# 或者使用 Makefile
make build
```

### 4. 获取固件

构建完成后，固件文件将在 `output/` 目录中：

- `openwrt-ar71xx-generic-tl-wr842n-v3-squashfs-factory.bin` - 原厂刷机包
- `openwrt-ar71xx-generic-tl-wr842n-v3-squashfs-sysupgrade.bin` - 在线升级包

## 高级构建选项

### 自定义配置

```bash
# 进入 OpenWrt 配置界面
cd $HOME/openwrt-build/openwrt
make menuconfig

# 保存配置
cp .config $OLDPWD/configs/tp842n3.config
```

### 快速构建（跳过下载）

```bash
make fast-build
```

### 调试构建（单线程，详细输出）

```bash
make debug-build
```

### 清理构建

```bash
make clean
```

## GitHub Actions 云编译

### 1. Fork 项目

1. 访问项目 GitHub 页面
2. 点击右上角的 "Fork" 按钮
3. 等待 Fork 完成

### 2. 启用 Actions

1. 进入你的 Fork 项目页面
2. 点击 "Actions" 标签
3. 启用 GitHub Actions（如果提示）

### 3. 手动触发构建

1. 进入 "Actions" 页面
2. 选择 "构建 TP842N-V3 打印服务器固件"
3. 点击 "Run workflow"
4. 等待构建完成（约 30-60 分钟）

### 4. 下载固件

1. 构建完成后，进入对应的工作流运行页面
2. 在 "Artifacts" 部分下载固件文件

## 本地编译详细步骤

### 1. 创建工作目录

```bash
mkdir -p $HOME/openwrt-build
cd $HOME/openwrt-build
```

### 2. 获取 OpenWrt 源码

```bash
git clone https://github.com/openwrt/openwrt.git
cd openwrt
git checkout v23.05.3
```

### 3. 更新 feeds

```bash
./scripts/feeds update -a
./scripts/feeds install -a
```

### 4. 应用配置

```bash
cp /path/to/tp842n3.config .config
```

### 5. 配置编译选项

```bash
make defconfig
```

### 6. 下载源码包

```bash
make download -j$(nproc)
```

### 7. 开始编译

```bash
make -j$(nproc)
```

## 固件刷写

### 使用刷写脚本

```bash
# 自动刷写（推荐）
./scripts/flash-firmware.sh output/openwrt-factory.bin

# 带备份的刷写
./scripts/flash-firmware.sh -b output/openwrt-factory.bin

# 指定路由器 IP
./scripts/flash-firmware.sh -i 192.168.1.1 output/openwrt-factory.bin
```

### 手动刷写

1. **Web 界面刷写**:
   - 访问 `http://192.168.10.1`
   - 登录 (admin/thdn12345678)
   - 系统 -> 备份/升级 -> 刷写固件

2. **TFTP 刷写**:
   - 设置电脑 IP: 192.168.1.100
   - 重命名固件为: `wr842nv3_tp_recovery.bin`
   - 按住复位键开机进入 TFTP 模式
   - 使用 TFTP 客户端上传固件

## 打印机配置

### 自动配置

```bash
# 运行打印机配置脚本
./scripts/setup-printer.sh
```

### 手动配置

1. 连接 HP LaserJet 1020 打印机到 USB 接口
2. 访问 `http://192.168.10.1:631` (CUPS 管理界面)
3. 点击 "Administration" -> "Add Printer"
4. 选择 HP LaserJet 1020 并配置

## 故障排除

### 构建失败

1. **检查依赖**:
   ```bash
   ./scripts/install-deps.sh
   ```

2. **清理并重新构建**:
   ```bash
   make clean
   make build
   ```

3. **查看详细错误**:
   ```bash
   make debug-build
   ```

### 刷写失败

1. **检查固件文件**:
   ```bash
   ls -la output/*.bin
   ```

2. **验证路由器连接**:
   ```bash
   ping 192.168.10.1
   ```

3. **使用 TFTP 模式**:
   ```bash
   ./scripts/flash-firmware.sh -f output/openwrt-factory.bin
   ```

### 打印机问题

1. **检查 USB 连接**:
   ```bash
   lsusb | grep -i hp
   ```

2. **重启 CUPS 服务**:
   ```bash
   /etc/init.d/cups-setup restart
   ```

3. **查看 CUPS 日志**:
   ```bash
   tail -f /var/log/cups/error_log
   ```

## 性能优化

### 加速编译

1. **使用 ccache**:
   ```bash
   export PATH="/usr/lib/ccache:$PATH"
   ```

2. **并行编译**:
   ```bash
   make -j$(nproc)
   ```

3. **使用本地镜像**:
   修改 `build.sh` 中的源码地址为国内镜像

### 减小固件大小

1. **移除不必要的包**:
   - 编辑 `configs/tp842n3.config`
   - 注释掉不需要的软件包

2. **优化文件系统**:
   - 启用压缩
   - 移除调试符号

## 技术支持

- **GitHub Issues**: 提交问题报告
- **Discussions**: 讨论和问答
- **Wiki**: 详细文档和教程

## 更新日志

查看 [CHANGELOG.md](CHANGELOG.md) 了解最新更新内容。
