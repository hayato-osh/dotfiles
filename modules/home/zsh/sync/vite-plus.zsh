###############
# Vite+ (vp)
###############
# インストーラ (curl https://vite.plus | bash) は ~/.zshrc を書き換えようとするが、
# HM 管理下で read-only のため失敗する。代わりにここから env を読む。
# TODO: nixpkgs で vite-plus が配布されたら home.packages 側に移行し、本ファイルは削除する。
# 注意: vp env は Node.js を管理しに来るが、このリポでは mise (modules/home/mise.nix) が
# ランタイムを所有している。`vp env use` を使うと PATH の取り合いになるので避ける。
[[ -f "$HOME/.vite-plus/env" ]] && source "$HOME/.vite-plus/env"
