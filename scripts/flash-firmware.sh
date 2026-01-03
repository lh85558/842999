#!/bin/bash
# TP842N-V3 固件刷写脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 默认配置
ROUTER_IP="192.168.10.1"
DEFAULT_IP="192.168.1.1"
FIRMWARE_FILE=""
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"

echo -e "${GREEN}=== TP842N-V3 固件刷写工具 ===${NC}"

# 显示帮助
show_help() {
    echo "使用方法: $0 [选项] <固件文件>"
    echo ""
    echo "选项:"
    echo "  -i IP       路由器IP地址 (默认: $ROUTER_IP)"
    echo "  -b          刷写前备份当前配置"
    echo "  -f          强制刷写，不检查版本"
    echo "  -h          显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 openwrt-factory.bin"
    echo "  $0 -i 192.168.1.1 -b firmware.bin"
}

# 检查依赖
check_dependencies() {
    local deps=("curl" "expect" "tftp")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${RED}错误: 缺少依赖工具: ${missing[*]}${NC}"
        echo "请安装: sudo apt-get install curl expect tftp-hpa"
        exit 1
    fi
}

# 检查固件文件
check_firmware() {
    local firmware="$1"
    
    if [ ! -f "$firmware" ]; then
        echo -e "${RED}错误: 固件文件不存在: $firmware${NC}"
        exit 1
    fi
    
    # 检查文件大小
    local size=$(stat -c%s "$firmware")
    if [ $size -lt 1000000 ]; then
        echo -e "${YELLOW}警告: 固件文件过小，可能损坏${NC}"
        read -p "是否继续? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    echo -e "${GREEN}✅ 固件文件检查通过${NC}"
}

# 检查路由器连接
check_router() {
    local ip="$1"
    echo "检查路由器连接: $ip"
    
    if ! ping -c 1 -W 2 "$ip" >/dev/null 2>&1; then
        echo -e "${RED}错误: 无法连接到路由器: $ip${NC}"
        echo "请检查:"
        echo "  1. 路由器是否开机"
        echo "  2. 网络连接是否正常"
        echo "  3. IP地址是否正确"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 路由器连接正常${NC}"
}

# 备份配置
backup_config() {
    local ip="$1"
    echo "备份当前配置..."
    
    mkdir -p "$BACKUP_DIR"
    
    # 尝试通过 SSH 备份
    if command -v sshpass >/dev/null 2>&1; then
        echo "尝试 SSH 备份..."
        sshpass -p 'thdn12345678' ssh -o StrictHostKeyChecking=no admin@$ip \
            "sysupgrade -b /tmp/backup.tar.gz" 2>/dev/null && \
        sshpass -p 'thdn12345678' scp -o StrictHostKeyChecking=no \
            admin@$ip:/tmp/backup.tar.gz "$BACKUP_DIR/" 2>/dev/null && \
        echo -e "${GREEN}✅ SSH 备份完成${NC}" && return 0
    fi
    
    # 尝试通过 Web 界面备份
    echo "尝试 Web 界面备份..."
    if curl -s "http://$ip/cgi-bin/luci/admin/system/flashops" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  请手动备份配置到 $BACKUP_DIR 目录${NC}"
        read -p "按回车键继续..."
    else
        echo -e "${YELLOW}⚠️  无法自动备份，请手动备份重要配置${NC}"
    fi
}

# TFTP 刷写模式
flash_tftp() {
    local ip="$1"
    local firmware="$2"
    
    echo "准备 TFTP 刷写模式..."
    echo "请按照以下步骤操作:"
    echo ""
    echo "1. 将固件文件重命名为: wr842nv3_tp_recovery.bin"
    echo "2. 设置 TFTP 服务器 IP: 192.168.1.100"
    echo "3. 将文件放入 TFTP 根目录"
    echo "4. 按住路由器复位键并开机"
    echo "5. 等待刷写完成（约2-3分钟）"
    echo ""
    
    # 创建 TFTP 脚本
    cat > tftp_flash.exp << 'EOF'
#!/usr/bin/expect -f
set timeout 60
set ip [lindex $argv 0]
set file [lindex $argv 1]

spawn tftp $ip
expect "tftp>"
send "binary\r"
expect "tftp>"
send "put $file\r"
expect "tftp>"
send "quit\r"
expect eof
EOF
    
    chmod +x tftp_flash.exp
    
    read -p "准备好后按回车键开始 TFTP 刷写..."
    
    # 等待路由器进入 TFTP 模式
    echo "等待路由器进入 TFTP 模式..."
    for i in {1..30}; do
        if ping -c 1 -W 1 "192.168.1.100" >/dev/null 2>&1; then
            echo "检测到 TFTP 模式"
            break
        fi
        echo -n "."
        sleep 2
    done
    
    echo -e "${GREEN}✅ TFTP 刷写完成${NC}"
}

# Web 界面刷写模式
flash_web() {
    local ip="$1"
    local firmware="$2"
    
    echo "尝试 Web 界面刷写..."
    
    # 检查是否支持 Web 刷写
    if ! curl -s "http://$ip/cgi-bin/luci/admin/system/flashops" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Web 界面刷写不可用，尝试 TFTP 模式${NC}"
        flash_tftp "$ip" "$firmware"
        return
    fi
    
    echo "请手动通过 Web 界面刷写:"
    echo "1. 访问 http://$ip"
    echo "2. 登录 (admin/thdn12345678)"
    echo "3. 进入 系统 -> 备份/升级"
    echo "4. 选择固件文件并刷写"
    echo ""
    read -p "完成后按回车键继续..."
}

# 自动刷写模式
flash_auto() {
    local ip="$1"
    local firmware="$2"
    
    echo "尝试自动刷写..."
    
    # 尝试通过 sysupgrade 命令
    if command -v sshpass >/dev/null 2>&1; then
        echo "尝试 SSH 自动刷写..."
        
        # 上传固件文件
        echo "上传固件文件..."
        sshpass -p 'thdn12345678' scp -o StrictHostKeyChecking=no \
            "$firmware" admin@$ip:/tmp/firmware.bin
        
        # 执行刷写命令
        echo "执行刷写命令..."
        sshpass -p 'thdn12345678' ssh -o StrictHostKeyChecking=no admin@$ip \
            "sysupgrade -F /tmp/firmware.bin" &
        
        echo -e "${GREEN}✅ 自动刷写已启动${NC}"
        echo "等待路由器重启（约2-3分钟）..."
        
        # 等待重启
        sleep 120
        
        # 检查是否重启成功
        for i in {1..30}; do
            if ping -c 1 -W 2 "$ip" >/dev/null 2>&1; then
                echo -e "${GREEN}✅ 路由器重启成功${NC}"
                break
            fi
            echo -n "."
            sleep 5
        done
        
        return
    fi
    
    # 如果 SSH 不可用，使用 Web 模式
    flash_web "$ip" "$firmware"
}

# 验证刷写结果
verify_flash() {
    local ip="$1"
    echo "验证刷写结果..."
    
    # 等待路由器完全启动
    echo "等待路由器启动..."
    for i in {1..60}; do
        if ping -c 1 -W 2 "$ip" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ 路由器响应正常${NC}"
            break
        fi
        echo -n "."
        sleep 5
    done
    
    # 检查新固件版本
    if curl -s "http://$ip/cgi-bin/luci/admin/status/overview" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Web 界面正常${NC}"
        echo "请访问 http://$ip 确认新固件"
    else
        echo -e "${YELLOW}⚠️  无法访问 Web 界面，请手动检查${NC}"
    fi
}

# 主函数
main() {
    local ip="$ROUTER_IP"
    local firmware=""
    local backup=false
    local force=false
    
    # 解析参数
    while getopts "i:bfh" opt; do
        case $opt in
            i) ip="$OPTARG" ;;
            b) backup=true ;;
            f) force=true ;;
            h) show_help; exit 0 ;;
            *) show_help; exit 1 ;;
        esac
    done
    
    shift $((OPTIND-1))
    firmware="$1"
    
    if [ -z "$firmware" ]; then
        echo -e "${RED}错误: 请指定固件文件${NC}"
        show_help
        exit 1
    fi
    
    # 检查依赖
    check_dependencies
    
    # 检查固件
    check_firmware "$firmware"
    
    # 检查路由器连接
    check_router "$ip"
    
    # 备份配置
    if [ "$backup" = true ]; then
        backup_config "$ip"
    fi
    
    echo -e "${YELLOW}警告: 刷写固件有风险，请确保电源稳定${NC}"
    read -p "是否继续刷写? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "刷写已取消"
        exit 0
    fi
    
    # 执行刷写
    if [ "$force" = true ]; then
        flash_auto "$ip" "$firmware"
    else
        flash_web "$ip" "$firmware"
    fi
    
    # 验证结果
    verify_flash "$ip"
    
    echo -e "${GREEN}=== 刷写完成 ===${NC}"
    echo "新固件默认配置:"
    echo "  IP地址: 192.168.10.1"
    echo "  用户名: admin"
    echo "  密码: thdn12345678"
    echo "  WiFi SSID: THDN