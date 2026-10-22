{ lib, pkgs, ... }:

let
  # L1: model | dir | branch | git status、L2: context / 5h / 7d の使用率バー。
  # rate_limits は Pro / Max でしか届かない。欠けた値は出さない。
  statusLine = pkgs.writeShellScript "claude-statusline" ''
    input=$(cat)
    dir=$(${lib.getExe pkgs.jq} -r '.workspace.current_dir' <<<"$input")
    branch=$(git -C "$dir" branch --show-current 2>/dev/null)
    # +staged !modified ?untracked
    st=$(git -C "$dir" --no-optional-locks status --porcelain 2>/dev/null | awk '
      /^\?\?/ { u++; next }
      { if (substr($0,1,1) != " ") s++; if (substr($0,2,1) != " ") m++ }
      END { printf "%s %s %s", (s ? "+" s : ""), (m ? "!" m : ""), (u ? "?" u : "") }')
    exec ${lib.getExe pkgs.jq} -r --arg branch "$branch" --arg st "$st" '
      def c($n): "\u001b[\($n)m\(.)\u001b[0m";
      def bar: (. / 10 | floor) as $n | [range(10) | if . < $n then "█" else "░" end] | join("");
      # 50% 未満は緑、80% 未満は黄、それ以上は赤
      def gauge($l): (if . < 50 then 32 elif . < 80 then 33 else 31 end) as $col
        | "\($l | c(2)) \(bar | c($col)) \(floor)%";
      ( [ (.model.display_name | c(36)), (.workspace.current_dir | split("/") | last | c(34)),
          ($branch | select(. != "") | c(35)),
          ($st | gsub("^ +| +$"; "") | gsub(" +"; " ") | select(. != "") | c(33)) ]
        | join(" | " | c(2)) ),
      ( [ (.context_window.used_percentage // empty | gauge("ctx")),
          (.rate_limits.five_hour // empty
            | "\(.used_percentage | gauge("5h")) (\(.resets_at | strflocaltime("%H:%M")))"),
          (.rate_limits.seven_day.used_percentage // empty | gauge("7d")) ]
        | join("  ") | select(. != "") )' <<<"$input"
  '';
in
{
  # バイナリは mise。settings.json は Claude Code 自身も書き換えるので、
  # symlink にせず statusLine キーだけを switch のたびにマージする。
  home.activation.claudeCodeStatusLine = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    f="$HOME/.claude/settings.json"
    mkdir -p "$HOME/.claude"
    [ -f "$f" ] || echo '{}' > "$f"
    tmp=$(mktemp)
    ${lib.getExe pkgs.jq} --arg cmd "${statusLine}" \
      '.statusLine = { type: "command", command: $cmd }' "$f" > "$tmp" && mv "$tmp" "$f"
  '';
}
