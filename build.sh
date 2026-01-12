#!/bin/bash
# =============================================================================
# AdapterX2 Typst 编译脚本
# =============================================================================
# 用法: ./build.sh [watch]
#   无参数: 单次编译
#   watch:  监视模式，文件变更时自动重新编译
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/30-39_文档输出/31_Typst源文件"
OUT_DIR="$SCRIPT_DIR/30-39_文档输出/32_PDF输出"

# 确保输出目录存在
mkdir -p "$OUT_DIR"

# 主文档路径
MAIN_FILE="$SRC_DIR/main.typ"
OUTPUT_FILE="$OUT_DIR/AdapterX2_设计文档.pdf"

# 检查 typst 是否安装
if ! command -v typst &> /dev/null; then
    echo "❌ 错误: 未找到 typst 命令"
    echo ""
    echo "请先安装 Typst:"
    echo "  cargo install typst-cli"
    echo "  # 或者"
    echo "  pacman -S typst  # Arch Linux"
    echo "  # 或者"
    echo "  brew install typst  # macOS"
    exit 1
fi

if [ "$1" = "watch" ]; then
    echo "👀 启动监视模式..."
    echo "   源文件: $MAIN_FILE"
    echo "   输出:   $OUTPUT_FILE"
    echo ""
    echo "   按 Ctrl+C 停止"
    echo ""
    typst watch "$MAIN_FILE" "$OUTPUT_FILE"
else
    echo "🔨 编译中..."
    typst compile "$MAIN_FILE" "$OUTPUT_FILE"
    echo "✅ 编译完成: $OUTPUT_FILE"
fi
