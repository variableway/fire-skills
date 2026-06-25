#!/usr/bin/env bash
# quality-check.sh — 检查 thought-distiller 产出的 SKILL.md 结构合规性
# 用法: ./quality-check.sh <SKILL.md路径>
# 输出通过/不通过和具体原因

set -euo pipefail

SKILL_FILE="${1:-}"
if [ -z "$SKILL_FILE" ]; then
    echo "Usage: $0 <path/to/SKILL.md>"
    echo "Example: $0 notable-figures/naval-skill/SKILL.md"
    exit 1
fi

if [ ! -f "$SKILL_FILE" ]; then
    echo "❌ File not found: $SKILL_FILE"
    exit 1
fi

PASS=0
FAIL=0

check() {
    local name="$1"
    local pattern="$2"
    local min_count="${3:-1}"
    local count
    count=$(grep -c "$pattern" "$SKILL_FILE" 2>/dev/null || echo 0)
    if [ "$count" -ge "$min_count" ]; then
        echo "  ✅ $name (found $count, need ≥$min_count)"
        PASS=$((PASS + 1))
    else
        echo "  ❌ $name (found $count, need ≥$min_count)"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== thought-distiller SKILL.md 结构检查 ==="
echo "File: $SKILL_FILE"
echo ""

# Phase coverage
echo "--- Phase Coverage ---"
check "Phase 0" "Phase 0" 1
check "Phase 1（六维调研）" "Phase 1" 1
check "Phase 2（交叉验证）" "Phase 2" 1
check "Phase 3（结构化解码）" "Phase 3" 1
check "Phase 4（质量验证）" "Phase 4" 1
check "Phase 4.5（交叉比对）" "Phase 4\.5" 1
check "Phase 5（交付）" "Phase 5" 1

echo ""
echo "--- Quality Gates ---"
check "强制检查章节" "强制检查" 1
check "失败模式列表" "失败模式" 1
check "三重验证" "三重验证" 1
check "矛盾标注" "矛盾" 1
check "排他性" "排他" 1
check "局限性是强制字段" "局限" 1
check "Progressive Disclosure 指引" "references/" 1

echo ""
echo "--- Structural ---"
LINE_COUNT=$(wc -l < "$SKILL_FILE")
if [ "$LINE_COUNT" -le 200 ]; then
    echo "  ✅ SKILL.md ≤200 行 ($LINE_COUNT)"
    PASS=$((PASS + 1))
else
    echo "  ⚠️  SKILL.md >200 行 ($LINE_COUNT)"
fi

if grep -q "references/" "$SKILL_FILE"; then
    echo "  ✅ 有 references/ 引用"
    PASS=$((PASS + 1))
else
    echo "  ⚠️  无 references/ 引用"
fi

echo ""
echo "=== 结果 ==="
TOTAL=$((PASS + FAIL))
echo "通过: $PASS/$TOTAL"
if [ "$FAIL" -eq 0 ]; then
    echo "评估: ✅ 全部通过"
else
    echo "评估: ❌ $FAIL 项未通过"
fi
