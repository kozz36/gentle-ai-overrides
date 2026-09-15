#!/usr/bin/env bash
# Public differential oracle only; never source the installer.
# Source: apply.sh, v2.6.0-overlay.3
# Commit: 6cd8caee2c8ab7a8d3121e1f513e6cacc41d2b98
init_rubric_transform() {
  local shape="$1" block anchor
  case "$shape" in
    skill) block="$INIT_RUBRIC_SKILL"; anchor='## Decision Gates' ;;
    details) block="$INIT_RUBRIC_DETAILS"; anchor='## Output Templates' ;;
    pi) block="$INIT_RUBRIC_PI"; anchor='## Memory Contract' ;;
    *) return 1 ;;
  esac

  BLOCK="$block" ANCHOR="$anchor" OPEN_MARKER="$INIT_RUBRIC_OPEN" CLOSE_MARKER="$INIT_RUBRIC_CLOSE" \
    awk 'BEGIN { block=ENVIRON["BLOCK"]; anchor=ENVIRON["ANCHOR"]; open_marker=ENVIRON["OPEN_MARKER"]; close_marker=ENVIRON["CLOSE_MARKER"] }
    { line[NR] = $0 }
    END {
      n = NR
      for (i = 1; i <= n; i++) {
        if (line[i] == anchor) { anchors++; anchor_line = i }
        if (line[i] == open_marker) { opens++; open_line = i }
        if (line[i] == close_marker) { closes++; close_line = i }
      }
      if (anchors != 1 || opens != closes || opens > 1 || (opens == 1 && open_line >= close_line) || \
          (opens == 1 && anchor_line > open_line && anchor_line < close_line)) exit 1

      for (i = 1; i <= n; i++) {
        if (line[i] == anchor) { print block; print "" }
        if (opens == 1 && i > open_line && i < close_line) continue
        if (opens == 1 && i == open_line) continue
        if (opens == 1 && i == close_line) continue
        # The canonical block owns one separator before its anchor. Drop only
        # that exact generated separator so replacement stays byte-idempotent.
        if (opens == 1 && i == close_line + 1 && line[i] ~ /^[ \t]*$/ && line[i + 1] == anchor) continue
        print line[i]
      }
      exit 0
    }
  '
}
