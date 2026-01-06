#!/bin/bash
# 同步 Sisyphus Prompt 並產生中文翻譯
#
# 用法:
#   ./sync-sisyphus-prompt.sh [--translate]
#
# 選項:
#   --translate  使用 opencode CLI + 免費模型產生中文翻譯
#
# 輸出:
#   reference/sisyphus-prompt/prompt-en.md    - 組裝後的 markdown（英文）
#   reference/sisyphus-prompt/prompt-zh-TW.md - 中文翻譯（需 --translate）
#   reference/sisyphus-prompt/source/         - 原始 TypeScript 檔案

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$CONFIG_DIR/reference/sisyphus-prompt"
SOURCE_DIR="$OUTPUT_DIR/source"
REPO_BASE="https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/dev/src/agents"

FREE_MODELS=(
  "opencode/glm-4.7-free"
  "opencode/minimax-m2.1-free"
  "opencode/gpt-5-nano"
)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

mkdir -p "$SOURCE_DIR"

get_latest_commit() {
  curl -sf "https://api.github.com/repos/code-yeongyu/oh-my-opencode/commits/dev" \
    | grep -m1 '"sha"' \
    | cut -d'"' -f4 \
    | head -c 7
}

download_sources() {
  log_info "下載 sisyphus.ts..."
  curl -sf "$REPO_BASE/sisyphus.ts" -o "$SOURCE_DIR/sisyphus.ts"
  
  log_info "下載 sisyphus-prompt-builder.ts..."
  curl -sf "$REPO_BASE/sisyphus-prompt-builder.ts" -o "$SOURCE_DIR/sisyphus-prompt-builder.ts"
}

extract_and_assemble() {
  local commit_hash="$1"
  local output_file="$OUTPUT_DIR/prompt-en.md"
  local ts_file="$SOURCE_DIR/sisyphus.ts"
  
  log_info "組裝 system prompt..."
  
  node --eval "
const fs = require('fs');
const tsFile = process.argv[1];
const outputFile = process.argv[2];
const commitHash = process.argv[3];

const content = fs.readFileSync(tsFile, 'utf-8');

const sections = [];
const regex = /const\\s+(SISYPHUS_\\w+)\\s*=\\s*\\\`([\\s\\S]*?)\\\`/g;
let match;

while ((match = regex.exec(content)) !== null) {
  sections.push({ name: match[1], content: match[2] });
}

const orderedNames = [
  'SISYPHUS_ROLE_SECTION',
  'SISYPHUS_PHASE0_STEP1_3',
  'SISYPHUS_PHASE1',
  'SISYPHUS_PARALLEL_EXECUTION',
  'SISYPHUS_PHASE2B_PRE_IMPLEMENTATION',
  'SISYPHUS_DELEGATION_PROMPT_STRUCTURE',
  'SISYPHUS_GITHUB_WORKFLOW',
  'SISYPHUS_CODE_CHANGES',
  'SISYPHUS_PHASE2C',
  'SISYPHUS_PHASE3',
  'SISYPHUS_TASK_MANAGEMENT',
  'SISYPHUS_TONE_AND_STYLE',
  'SISYPHUS_SOFT_GUIDELINES'
];

const sectionMap = Object.fromEntries(sections.map(s => [s.name, s.content]));

const header = \`# Sisyphus Agent System Prompt

**來源**: [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode) (dev branch)
**Commit**: [\\\`\${commitHash}\\\`](https://github.com/code-yeongyu/oh-my-opencode/commit/\${commitHash})
**同步時間**: \${new Date().toISOString().split('T')[0]}

> 此檔案由 \\\`script/sync-sisyphus-prompt.sh\\\` 自動產生
> 動態組裝的部分（如 agent 列表、tool 表格）未包含在內，詳見 \\\`source/\\\` 目錄

---

\`;

let assembled = header;
for (const name of orderedNames) {
  if (sectionMap[name]) {
    assembled += sectionMap[name] + '\\n\\n';
  }
}

fs.writeFileSync(outputFile, assembled.trim() + '\\n');
console.log('已寫入: ' + outputFile);
" "$ts_file" "$output_file" "$commit_hash"
}

translate_to_chinese() {
  local input_file="$OUTPUT_DIR/prompt-en.md"
  local output_file="$OUTPUT_DIR/prompt-zh-TW.md"
  local prompt_file="$OUTPUT_DIR/.translate-prompt.txt"
  
  log_info "準備翻譯..."
  
  cat > "$prompt_file" << 'TRANSLATE_PROMPT'
請將附加的 Markdown 文件翻譯成繁體中文。

翻譯規則：
1. 保持所有 Markdown 格式（標題、表格、程式碼區塊、列表）
2. 保留所有英文技術術語（如 agent、todo、prompt、token 等）
3. 保留所有程式碼範例不翻譯
4. 保留所有 XML 標籤名稱（如 <Role>、<Behavior_Instructions>）
5. 翻譯說明文字和註解

直接輸出翻譯結果，不要加任何額外說明。
TRANSLATE_PROMPT

  for model in "${FREE_MODELS[@]}"; do
    log_info "嘗試模型: $model （超時 180 秒）"
    
    if timeout 180 opencode run -m "$model" "$(cat "$prompt_file")" -f "$input_file" > "$output_file.tmp" 2>/dev/null; then
      if [ -f "$output_file.tmp" ] && [ "$(wc -c < "$output_file.tmp")" -gt 1000 ]; then
        mv "$output_file.tmp" "$output_file"
        rm -f "$prompt_file"
        log_info "翻譯完成: $output_file"
        return 0
      fi
    fi
    
    log_warn "模型 $model 失敗，嘗試下一個..."
    rm -f "$output_file.tmp"
  done
  
  rm -f "$prompt_file"
  log_error "所有免費模型都失敗了。可手動執行："
  log_error "  opencode run -m MODEL '翻譯成繁體中文' -f '$input_file'"
  return 1
}

main() {
  local do_translate=false
  
  while [[ $# -gt 0 ]]; do
    case $1 in
      --translate)
        do_translate=true
        shift
        ;;
      -h|--help)
        head -14 "$0" | tail -13
        exit 0
        ;;
      *)
        log_error "未知參數: $1"
        exit 1
        ;;
    esac
  done
  
  log_info "開始同步 Sisyphus Prompt..."
  
  local commit_hash
  commit_hash=$(get_latest_commit)
  log_info "最新 commit: $commit_hash"
  
  download_sources
  extract_and_assemble "$commit_hash"
  
  if $do_translate; then
    translate_to_chinese
  fi
  
  log_info "完成！"
  echo ""
  echo "產生的檔案："
  find "$OUTPUT_DIR" -type f -name "*.md" -o -name "*.ts" 2>/dev/null | sort | while read -r f; do
    echo "  $f"
  done
}

main "$@"
