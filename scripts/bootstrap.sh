#!/usr/bin/env bash
# 新規 Mac をこの dotfiles の状態まで持っていく。冪等 — 途中で失敗しても再実行でよい。
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=0
PROFILE=""

usage() {
  cat <<'EOF'
usage: scripts/bootstrap.sh [-n|--dry-run] [-p|--profile <name>]

  Xcode CLT / Homebrew / Nix / git identity / 初回 switch までを順に済ませる。
  --profile を省くと `scutil --get LocalHostName` の出力を使う。
EOF
}

step() { printf '\n==> %s\n' "$1"; }
skip() { printf '    済: %s\n' "$1"; }
die() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

run() {
  printf '    $ %s\n' "$*"
  ((DRY_RUN)) && return 0
  "$@"
}

while (($#)); do
  case "$1" in
    -n | --dry-run) DRY_RUN=1 ;;
    -p | --profile)
      PROFILE="${2:-}"
      [[ -n "$PROFILE" ]] || die "--profile に値が無い"
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      die "不明なオプション: $1"
      ;;
  esac
  shift
done

[[ "$(uname -s)" == Darwin ]] || die "macOS 専用"
((DRY_RUN)) && printf '[dry-run] 実行はせずコマンドだけ表示する\n'

step "Xcode Command Line Tools"
if xcode-select -p >/dev/null 2>&1; then
  skip "$(xcode-select -p)"
else
  run xcode-select --install || true
  if ((DRY_RUN == 0)); then
    printf '    GUI インストーラの完了を待っています...\n'
    until xcode-select -p >/dev/null 2>&1; do sleep 10; done
  fi
fi

step "Homebrew"
# cask / mas の実体は brew が引く (nix-darwin が activation 時に brew bundle を呼ぶ)。
BREW_PREFIX=/opt/homebrew
[[ "$(uname -m)" == x86_64 ]] && BREW_PREFIX=/usr/local
BREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
if [[ -x "$BREW_PREFIX/bin/brew" ]]; then
  skip "$BREW_PREFIX/bin/brew"
elif ((DRY_RUN)); then
  printf '    $ /bin/bash -c "$(curl -fsSL %s)"\n' "$BREW_INSTALL_URL"
else
  # curl をパイプで渡さないのは、インストーラが stdin で確認プロンプトを読むため。
  /bin/bash -c "$(curl -fsSL "$BREW_INSTALL_URL")"
fi
[[ -x "$BREW_PREFIX/bin/brew" ]] && eval "$("$BREW_PREFIX/bin/brew" shellenv)"

step "Nix"
# --determinate は付けない。Determinate Nix は /etc/nix/nix.conf を自分で所有するため、
# nix.conf を nix-darwin に管理させているこの構成と衝突する。
if command -v nix >/dev/null 2>&1; then
  skip "$(command -v nix)"
else
  run bash -c "curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
fi
# インストール直後のこのシェルでも nix を使えるようにする。
if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  set +u
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  set -u
fi

step "git identity (~/.config/git/local.conf)"
# 追跡外。public リポジトリにメールアドレスを載せないため、宣言せずここで作る。
GIT_LOCAL="$HOME/.config/git/local.conf"
if [[ -f "$GIT_LOCAL" ]]; then
  skip "$GIT_LOCAL"
elif ((DRY_RUN)); then
  printf '    $ (対話入力して %s を作成)\n' "$GIT_LOCAL"
else
  [[ -t 0 ]] || die "$GIT_LOCAL が無い。対話端末で再実行するか手で作る"
  read -r -p "    git user.name:  " git_name
  read -r -p "    git user.email: " git_email
  [[ -n "$git_name" && -n "$git_email" ]] || die "name / email が空"
  mkdir -p "$(dirname "$GIT_LOCAL")"
  cat >"$GIT_LOCAL" <<EOF
[user]
	name = $git_name
	email = $git_email
EOF
fi

step "構成を適用"
: "${PROFILE:=$(scutil --get LocalHostName)}"
printf '    profile: %s\n' "$PROFILE"

# path: で読むのは、追跡外の hosts.local.nix を見せるため (git 参照だと落ちる)。
cd "$REPO_ROOT"
if command -v nh >/dev/null 2>&1; then
  # nh は自分で昇格するので sudo を付けない (root で呼ぶと弾かれる)。
  run nh darwin switch path:. -H "$PROFILE"
else
  # 初回は nh も darwin-rebuild もまだ入っていないので nix run で起動する。
  run sudo "$(command -v nix)" run nix-darwin -- switch --flake "path:.#$PROFILE"
fi

step "残りは手作業"
cat <<'EOF'
    - App Store に Apple ID でサインインし、このスクリプトを再実行する (masApps が入る)
    - GUI アプリの権限 (アクセシビリティ / 画面収録) は初回起動時に許可する
    - 新しいシェルを開き直す
EOF
