# TP842N-V3 打印服务器固件

基于 OpenWrt 23.05 稳定版，为 TP842N-V3 (AR9531) 芯片定制的打印服务器固件。

## 功能特性

- ✅ 集成 CUPS 中文打印服务
- ✅ 预装 HP LaserJet 1020/1020 plus 驱动
- ✅ USB 打印机支持
- ✅ 定时重启功能
- ✅ 中文界面
- ✅ 16MB 闪存优化

## 默认配置

- **LAN IP**: 192.168.10.1
- **Web 登录**: admin / thdn12345678
- **Wi-Fi SSID**: THDN-dayin
- **Wi-Fi 密码**: thdn12345678
- **主机名**: THDN-PrintServer

## 快速开始

### 本地编译

```bash
# 克隆项目
git clone https://github.com/your-repo/tp842n3-printserver.git
cd tp842n3-printserver

# 一键编译
./build.sh
```

### GitHub Actions 云编译

1. Fork 本项目
2. 进入 Actions 标签页
3. 手动触发工作流
4. 下载生成的固件

## 固件文件

- `openwrt-ar71xx-generic-tl-wr842n-v3-squashfs-factory.bin` - 原厂刷机包
- `openwrt-ar71xx-generic-tl-wr842n-v3-squashfs-sysupgrade.bin` - 在线升级包

## 技术支持

如有问题请提交 Issue 或 Discussion。
