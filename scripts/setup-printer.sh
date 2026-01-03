#!/bin/bash
# HP LaserJet 1020 打印机设置脚本

set -e

echo "=== HP LaserJet 1020 打印机自动配置脚本 ==="

# 检查 USB 连接
check_usb_connection() {
    echo "检查 USB 打印机连接..."
    if lsusb | grep -i "hewlett-packard\|hp" > /dev/null; then
        echo "✅ 检测到 HP 打印机连接"
        return 0
    else
        echo "⚠️  未检测到 HP 打印机，请检查 USB 连接"
        return 1
    fi
}

# 安装 HP 驱动
install_hp_driver() {
    echo "安装 HP LaserJet 1020 驱动..."
    
    # 创建 PPD 文件目录
    mkdir -p /etc/cups/ppd
    
    # 下载 HP 1020 PPD 文件
    if [ ! -f "/etc/cups/ppd/HP-LaserJet-1020.ppd" ]; then
        echo "下载 HP 1020 PPD 文件..."
        wget -O /etc/cups/ppd/HP-LaserJet-1020.ppd \
            "https://github.com/koenkooi/foo2zjs/blob/master/PPD/HP-LaserJet_1020.ppd" \
            || echo "⚠️  PPD 文件下载失败，使用默认配置"
    fi
    
    # 设置文件权限
    chmod 644 /etc/cups/ppd/HP-LaserJet-1020.ppd 2>/dev/null || true
    
    echo "✅ HP 驱动安装完成"
}

# 配置 CUPS
configure_cups() {
    echo "配置 CUPS 打印服务..."
    
    # 重启 CUPS 服务
    /etc/init.d/cups-setup restart
    
    # 等待服务启动
    sleep 3
    
    # 检查 CUPS 状态
    if pgrep cupsd > /dev/null; then
        echo "✅ CUPS 服务运行正常"
    else
        echo "❌ CUPS 服务未运行，尝试重新启动..."
        /etc/init.d/cups-setup start
    fi
}

# 添加打印机
add_printer() {
    echo "添加 HP LaserJet 1020 打印机..."
    
    # 使用 lpadmin 添加打印机
    if command -v lpadmin >/dev/null 2>&1; then
        # 尝试自动检测 USB 打印机
        USB_URI=$(lpinfo -v 2>/dev/null | grep "usb://" | head -1 | awk '{print $2}')
        
        if [ -n "$USB_URI" ]; then
            echo "检测到 USB 打印机: $USB_URI"
            
            # 添加打印机
            lpadmin -p "HP-LaserJet-1020" \
                -E \
                -v "$USB_URI" \
                -P "/etc/cups/ppd/HP-LaserJet-1020.ppd" \
                -o printer-is-shared=true \
                -o printer-error-policy=retry-job \
                -o printer-op-policy=default \
                -L "USB Printer" \
                -D "HP LaserJet 1020" \
                2>/dev/null || echo "⚠️  打印机添加可能需要手动配置"
                
            # 设置为默认打印机
            lpadmin -d "HP-LaserJet-1020" 2>/dev/null || true
            
            echo "✅ 打印机添加完成"
        else
            echo "⚠️  未检测到 USB 打印机，请手动添加"
            echo "   1. 访问 http://192.168.10.1:631"
            echo "   2. 点击 'Administration' -> 'Add Printer'"
            echo "   3. 选择 HP LaserJet 1020"
        fi
    else
        echo "⚠️  lpadmin 命令不可用，请手动配置打印机"
    fi
}

# 测试打印
test_print() {
    echo "测试打印机..."
    
    # 创建测试页
    cat > /tmp/test_page.txt << 'EOF'
HP LaserJet 1020 打印机测试页
=====================================

打印机型号: HP LaserJet 1020
连接方式: USB
测试时间: $(date)
IP地址: $(uci get network.lan.ipaddr)

如果看到这页内容，说明打印机配置成功！

=====================================
EOF
    
    # 尝试打印测试页
    if lp /tmp/test_page.txt 2>/dev/null; then
        echo "✅ 测试页已发送到打印机"
    else
        echo "⚠️  测试页发送失败，请检查打印机状态"
    fi
    
    # 清理测试文件
    rm -f /tmp/test_page.txt
}

# 显示状态
show_status() {
    echo ""
    echo "=== 打印机状态 ==="
    echo "CUPS 服务: $(pgrep cupsd >/dev/null && echo '运行中' || echo '未运行')"
    echo "USB 设备: $(lsusb | grep -i hp | wc -l) 个 HP 设备"
    echo "已配置打印机: $(lpstat -p 2>/dev/null | wc -l) 台"
    echo ""
    echo "管理地址: http://192.168.10.1:631"
    echo "默认登录: admin / thdn12345678"
    echo ""
}

# 主函数
main() {
    echo "开始配置 HP LaserJet 1020 打印机..."
    
    # 检查 USB 连接
    if check_usb_connection; then
        install_hp_driver
        configure_cups
        add_printer
        test_print
    else
        echo "请连接打印机后重新运行此脚本"
    fi
    
    show_status
    
    echo "=== 配置完成 ==="
}

# 运行主函数
main "$@"
