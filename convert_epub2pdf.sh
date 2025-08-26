#!/usr/bin/env bash
set -euo pipefail

# 可改：输出目录
OUT_DIR="pdf_out"
mkdir -p "$OUT_DIR"

# 允许手工指定 binary： EBOOK_CONVERT_BIN=/path/to/ebook-convert ./convert_all.sh
BIN="${EBOOK_CONVERT_BIN:-ebook-convert}"

# 若命令不可用，尝试 Calibre 默认路径
if ! command -v "$BIN" >/dev/null 2>&1; then
  ALT="/Applications/calibre.app/Contents/MacOS/ebook-convert"
  if [ -x "$ALT" ]; then
    BIN="$ALT"
  else
    echo "找不到 ebook-convert，请先安装 Calibre 或设置 EBOOK_CONVERT_BIN 环境变量。"
    exit 1
  fi
fi

echo "使用转换器：$BIN"
echo "输出目录：$OUT_DIR"
echo "开始批量转换……"

FAIL_LOG="$OUT_DIR/failed.txt"
: > "$FAIL_LOG"

# 批量处理（支持空格/特殊字符）
find . -maxdepth 1 -type f \( -iname "*.epub" -o -iname "*.mobi" \) -print0 |
while IFS= read -r -d '' f; do
  base="$(basename "$f")"
  name="${base%.*}"
  out="$OUT_DIR/$name.pdf"

  if [ -s "$out" ]; then
    echo "已存在，跳过：$out"
    continue
  fi

  echo "转换：$base  ->  $out"
  # 可根据需要调整纸张/页边距
  if ! "$BIN" "$f" "$out" \
      --pdf-page-numbers \
      --paper-size a4 \
      --margin-left 36 --margin-right 36 --margin-top 36 --margin-bottom 36; then
    echo "$base" >> "$FAIL_LOG"
    echo "❌ 失败：$base（已记录到 $FAIL_LOG）"
  fi
done

echo "✅ 全部完成。PDF 在：$OUT_DIR"
if [ -s "$FAIL_LOG" ]; then
  echo "以下文件失败（见 $FAIL_LOG）："
  cat "$FAIL_LOG"
fi
