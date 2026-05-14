#!/usr/bin/env bash
# test.sh — Lua lapi.c showcase 的端對端測試
#
# 流程：
#   1. 用 PAREN/C 生成 lua-push-families.c
#   2. 下載 Lua 5.4.7 源碼
#   3. 把生成的函數植入 lapi.c（取代原本手寫的版本）
#   4. 編譯 Lua
#   5. 跑 Lua 官方測試套件 (testes/all.lua)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PAREN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LUA_VERSION="5.4.7"
LUA_TAG="v${LUA_VERSION}"
WORKDIR="${TMPDIR:-/tmp}/paren-lua-test-$$"

echo "=== PAREN/C × Lua lapi.c showcase ==="
echo "workdir: $WORKDIR"
mkdir -p "$WORKDIR"

# ── 步驟 1：生成 C 代碼 ────────────────────────────────────────────────────────
echo ""
echo "--- Step 1: 用 PAREN/C 生成 lua-push-families.c ---"

GEN_C="$SCRIPT_DIR/lua-push-families.c"

nix-shell "$PAREN_ROOT/shell.nix" --run \
  "sbcl --noinform --non-interactive \
    --eval '(require :asdf)' \
    --eval '(asdf:load-asd \"$PAREN_ROOT/paren.asd\")' \
    --eval '(asdf:load-system :paren)' \
    --eval '(uiop:with-current-directory (\"$SCRIPT_DIR/\") (uiop:symbol-call :paren :compile-parenc-file \"lua-push-families.parenc\"))' \
    --eval '(uiop:quit)'"

echo "生成完成：$GEN_C"

# ── 步驟 2：下載 Lua ───────────────────────────────────────────────────────────
echo ""
echo "--- Step 2: 下載 Lua $LUA_VERSION ---"

LUA_SRC="$WORKDIR/lua"
if [ ! -d "$LUA_SRC" ]; then
  git clone --quiet --depth 1 --branch "$LUA_TAG" \
    https://github.com/lua/lua.git "$LUA_SRC"
fi

# ── 步驟 3：植入生成的函數 ─────────────────────────────────────────────────────
echo ""
echo "--- Step 3: 把生成的函數植入 lapi.c ---"

LAPI_ORIG="$LUA_SRC/lapi.c"
GEN_INJECT="$LUA_SRC/lua_generated_families.c"

# 複製生成的 C 到 Lua 源碼目錄（只含函數定義，header 由 lapi.c 提供）
# 把 lapi.c 已有的 #include 部分去掉，只保留函數定義
awk '/^#include/{next} /^$/ && !found{next} {found=1; print}' "$GEN_C" > "$GEN_INJECT"

# 用 Python 從 lapi.c 中移除原本的函數，再 #include 生成版本
python3 - "$LAPI_ORIG" "$GEN_INJECT" <<'PYEOF'
import re, sys

lapi_path = sys.argv[1]
gen_path   = sys.argv[2]
gen_name   = gen_path.split("/")[-1]

with open(lapi_path) as f:
    src = f.read()

targets = [
    "lua_pushnumber",
    "lua_pushinteger",
    "lua_pushlightuserdata",
    "lua_tonumberx",
    "lua_tointegerx",
    "lua_isfunction",
    "lua_istable",
    "lua_islightuserdata",
    "lua_isnil",
    "lua_isboolean",
    "lua_isthread",
]

def remove_function(text, name):
    pattern = re.compile(
        r'LUA_API\s+\S[^{;]*\b' + re.escape(name) + r'\s*\([^)]*\)\s*\{',
        re.MULTILINE
    )
    m = pattern.search(text)
    if not m:
        print(f"  警告：找不到 {name}，跳過", file=sys.stderr)
        return text
    start = m.start()
    depth = 0
    i = m.end() - 1
    while i < len(text):
        if text[i] == '{':
            depth += 1
        elif text[i] == '}':
            depth -= 1
            if depth == 0:
                end = i + 1
                print(f"  移除 {name} (line ~{text[:start].count(chr(10))+1})")
                return text[:start] + text[end:]
        i += 1
    print(f"  警告：{name} 找不到結尾 }}，跳過", file=sys.stderr)
    return text

for fn in targets:
    src = remove_function(src, fn)

inject = f'\n/* === PAREN/C generated families === */\n#include "{gen_name}"\n'
src += inject

with open(lapi_path, "w") as f:
    f.write(src)

print("patch 完成")
PYEOF

echo "lapi.c 已更新"

# ── 步驟 4：編譯 Lua ───────────────────────────────────────────────────────────
echo ""
echo "--- Step 4: 編譯 Lua ---"
cd "$LUA_SRC"
make -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu)" MYCFLAGS="-DLUA_COMPAT_5_3" MYLDFLAGS=""
echo "編譯成功"

# ── 步驟 5：跑官方測試 ────────────────────────────────────────────────────────
echo ""
echo "--- Step 5: 跑 Lua 官方測試套件 ---"
cd "$LUA_SRC/testes"
../lua -e "_U=true" all.lua
echo ""
echo "=== 全部通過！PAREN/C 生成的 lapi 函數與 Lua 官方測試相容 ==="
