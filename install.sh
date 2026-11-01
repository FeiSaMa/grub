#!/usr/bin/env bash
#
# Install the Catppuccin Mocha GRUB theme shipped in this repository.
#
# Default target: /boot/grub/themes/catppuccin-mocha
# Touches only that theme directory, one GRUB_THEME line in /etc/default/grub
# (backed up first) and, unless --no-mkconfig is given, /boot/grub/grub.cfg.
#
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly THEME_SRC="${SCRIPT_DIR}/src/catppuccin-mocha-grub-theme"
readonly GRUB_DEFAULTS="/etc/default/grub"
readonly GRUB_CFG="/boot/grub/grub.cfg"
readonly REQUIRED_FILES=(theme.txt background.png logo.png jetbrainsmono-28.pf2 font.pf2
  select_c.png select_e.png select_w.png)
readonly REQUIRED_DIRS=(icons)

THEME_DIR="/boot/grub/themes/catppuccin-mocha"
DRY_RUN=0
RUN_MKCONFIG=1
FORCE=0
original_args=("$@")

usage() {
  cat <<'EOF'
用法: install.sh [选项]

把本仓库的 Catppuccin Mocha 主题安装到 /boot/grub/themes/catppuccin-mocha，
备份 /etc/default/grub，写入 GRUB_THEME 并刷新 grub.cfg。

选项:
  --theme-dir PATH   安装到 PATH（默认 /boot/grub/themes/catppuccin-mocha）
  --no-mkconfig      只装文件和 GRUB_THEME，不运行 grub-mkconfig
  --force            目标目录已存在却不含 theme.txt 时仍然继续
  --dry-run          只打印将要执行的每一步，不写任何文件、不刷新 grub.cfg
  -h, --help         显示本帮助

需要 root 权限（本机 sudo 已禁用，请用 pkexec）。
EOF
}

die() {
  printf '错误: %s\n' "$*" >&2
  exit 2
}

# run CMD... —— dry-run 时只回显命令，否则执行
run() {
  if ((DRY_RUN)); then
    printf '[dry-run] $'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

while (($#)); do
  case "$1" in
    --theme-dir)
      (($# >= 2)) || die "--theme-dir 需要一个路径参数"
      THEME_DIR="$2"
      shift 2
      ;;
    --theme-dir=*)
      THEME_DIR="${1#*=}"
      shift
      ;;
    --no-mkconfig)
      RUN_MKCONFIG=0
      shift
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      die "未知参数: $1（用 -h 查看帮助）"
      ;;
  esac
done

# 归一化目标目录：去尾部斜杠、要求绝对路径
while [[ "$THEME_DIR" == */ && "$THEME_DIR" != "/" ]]; do
  THEME_DIR="${THEME_DIR%/}"
done
[[ -n "$THEME_DIR" ]] || die "--theme-dir 不能为空"
[[ "$THEME_DIR" == /* ]] || die "--theme-dir 需要绝对路径，收到: $THEME_DIR"
[[ "$THEME_DIR" != "/" ]] || die "--theme-dir 不能是 /，请指定 themes 下的一个独立目录"

# 解析后的目标不能等于源主题目录、也不能落在它里面（即不要把主题装回仓库自身）
THEME_DIR_REAL="$(realpath -m -- "$THEME_DIR")"
THEME_SRC_REAL="$(realpath -m -- "$THEME_SRC")"
case "${THEME_DIR_REAL}/" in
  "${THEME_SRC_REAL}/"*) die "--theme-dir 不能是主题源目录或其子目录: ${THEME_DIR}" ;;
esac

if [[ -e "$THEME_DIR" && ! -d "$THEME_DIR" ]]; then
  die "--theme-dir 已存在且不是目录: ${THEME_DIR}"
fi
if [[ -d "$THEME_DIR" && ! -f "${THEME_DIR}/theme.txt" ]] && ((!FORCE)); then
  die "目标目录不像 GRUB 主题（没有 theme.txt）: ${THEME_DIR}，确认无误请加 --force"
fi

[[ -d "$THEME_SRC" ]] || die "找不到主题源目录: $THEME_SRC"

for f in "${REQUIRED_FILES[@]}"; do
  [[ -f "${THEME_SRC}/${f}" ]] || die "源主题缺少文件: ${THEME_SRC}/${f}"
done
for d in "${REQUIRED_DIRS[@]}"; do
  [[ -d "${THEME_SRC}/${d}" ]] || die "源主题缺少目录: ${THEME_SRC}/${d}"
done

[[ -f "$GRUB_DEFAULTS" ]] || die "找不到 $GRUB_DEFAULTS"

if ((!DRY_RUN)) && [[ "$(id -u)" -ne 0 ]]; then
  printf '请用 pkexec/sudo 运行（本机 sudo 已禁用，推荐 pkexec）:\n  pkexec %q' \
    "${SCRIPT_DIR}/$(basename -- "$0")" >&2
  ((${#original_args[@]} == 0)) || printf ' %q' "${original_args[@]}" >&2
  printf '\n' >&2
  exit 1
fi

THEME_PATH="${THEME_DIR}/theme.txt"
BACKUP="${GRUB_DEFAULTS}.bak-$(date +%Y%m%d-%H%M%S)"

printf '==> 源主题:   %s\n' "$THEME_SRC"
printf '==> 目标目录: %s\n' "$THEME_DIR"
printf '==> 写入项:   GRUB_THEME="%s"\n' "$THEME_PATH"

# 1. 备份 /etc/default/grub
# 不用 cp -a/-p：GNU cp 的 -p 同样包含 ownership（chown），目标盘若不支持
# 属主（vfat/exfat）会 EPERM，在 set -euo pipefail 下直接中止脚本。
# 备份只需要 mode + 时间戳，显式限定 preserve 列表即可。
printf '==> 备份 %s -> %s\n' "$GRUB_DEFAULTS" "$BACKUP"
run cp --preserve=mode,timestamps "$GRUB_DEFAULTS" "$BACKUP"

# 2. 安装主题文件（整目录覆盖，不删除目标目录里已有的其它文件）
# 必须用 cp -R 而不是 cp -a：本例的 /boot/grub 是 → /efi/grub 的符号链接，
# 落在 vfat 分区上；vfat 没有 ownership/xattr，cp -a（--archive）内含的
# preserve-ownership 即使以 root 运行也会 EPERM，set -e 会让脚本在
# 「已备份、内容已拷」之后中途退出。主题文件的属主/时间戳对 GRUB 无意义。
printf '==> 安装主题文件到 %s\n' "$THEME_DIR"
run mkdir -p "$THEME_DIR"
run cp -R "${THEME_SRC}/." "${THEME_DIR}/"

# 3. 写 GRUB_THEME：已存在的生效行 / 被注释的行 / 完全缺失三种情况
escaped="${THEME_PATH//\\/\\\\}"
escaped="${escaped//&/\\&}"
escaped="${escaped//|/\\|}"

if grep -qE '^[[:space:]]*#?[[:space:]]*GRUB_THEME=' "$GRUB_DEFAULTS"; then
  printf '==> 更新已有的 GRUB_THEME 行（含被注释的行）\n'
  sed_expr="s|^[[:space:]]*#?[[:space:]]*GRUB_THEME=.*|GRUB_THEME=\"${escaped}\"|"
  if ((DRY_RUN)); then
    printf "[dry-run] \$ sed -i -E '%s' %q\n" "$sed_expr" "$GRUB_DEFAULTS"
  else
    sed -i -E "$sed_expr" "$GRUB_DEFAULTS"
  fi
else
  printf '==> 未找到 GRUB_THEME 行，追加到 %s\n' "$GRUB_DEFAULTS"
  if ((DRY_RUN)); then
    printf '[dry-run] $ printf %s >> %q\n' "'\\nGRUB_THEME=\"${THEME_PATH}\"\\n'" "$GRUB_DEFAULTS"
  else
    printf '\nGRUB_THEME="%s"\n' "$THEME_PATH" >>"$GRUB_DEFAULTS"
  fi
fi
printf '    将写入: GRUB_THEME="%s"\n' "$THEME_PATH"

# 4. 刷新 grub.cfg
if ((RUN_MKCONFIG)); then
  if ((!DRY_RUN)); then
    command -v grub-mkconfig >/dev/null 2>&1 || die "找不到 grub-mkconfig"
  fi
  run grub-mkconfig -o "$GRUB_CFG"
else
  printf '==> 跳过 grub-mkconfig（--no-mkconfig），记得自行刷新 %s\n' "$GRUB_CFG"
fi

if ((DRY_RUN)); then
  printf '==> dry-run 结束，未修改任何文件\n'
else
  printf '==> 完成。当前配置: '
  grep -E '^GRUB_THEME=' "$GRUB_DEFAULTS"
fi
