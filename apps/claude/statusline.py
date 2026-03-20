#!/usr/bin/env python3
"""Braille dots statusline - dotted progress bar using braille characters."""
import json
import os
import sys
import time

try:
    data = json.load(sys.stdin)
except (json.JSONDecodeError, ValueError):
    sys.exit(0)

BRAILLE = " ⣀⣄⣤⣦⣶⣷⣿"
R = "\033[0m"
DIM = "\033[2m"


def gradient(pct):
    if pct < 50:
        r = int(pct * 5.1)
        return f"\033[38;2;{r};200;80m"
    else:
        g = int(200 - (pct - 50) * 4)
        return f"\033[38;2;255;{max(g, 0)};60m"


def braille_bar(pct, width=8):
    pct = min(max(pct, 0), 100)
    level = pct / 100
    bar = ""
    for i in range(width):
        seg_start = i / width
        seg_end = (i + 1) / width
        if level >= seg_end:
            bar += BRAILLE[7]
        elif level <= seg_start:
            bar += BRAILLE[0]
        else:
            frac = (level - seg_start) / (seg_end - seg_start)
            bar += BRAILLE[min(int(frac * 8), 7)]
    return bar


def fmt_reset(epoch):
    if epoch is None:
        return ""
    remaining = epoch - time.time()
    if remaining <= 0:
        return ""
    h = int(remaining // 3600)
    m = int((remaining % 3600) // 60)
    if h > 0:
        return f" {DIM}{h}h{m:02d}m{R}"
    return f" {DIM}{m}m{R}"


def fmt(label, pct, resets_at=None):
    p = round(pct)
    reset = fmt_reset(resets_at)
    return f"{label} {gradient(pct)}{braille_bar(pct)}{R} {p}%{reset}"


SEP = f" {DIM}│{R} "
model = data.get("model", {}).get("display_name", "Claude")

# Line 1: model │ cost │ duration │ +lines -lines
line1 = [model]
cost_data = data.get("cost", {})
cost = cost_data.get("total_cost_usd")
if cost is not None:
    line1.append(f"${float(cost):.2f}")
duration_ms = cost_data.get("total_duration_ms")
if duration_ms is not None:
    s = int(duration_ms) // 1000
    h, s = divmod(s, 3600)
    m, s = divmod(s, 60)
    if h > 0:
        line1.append(f"{h}h{m:02d}m")
    else:
        line1.append(f"{m}m{s:02d}s")
added = cost_data.get("total_lines_added")
removed = cost_data.get("total_lines_removed")
if added is not None or removed is not None:
    line1.append(f"\033[38;2;80;200;80m+{added or 0}{R} \033[38;2;255;100;80m-{removed or 0}{R}")

# Line 2: ctx (threshold bar + full bar) │ 5h │ 7d
line2 = []
ctx = data.get("context_window", {}).get("used_percentage")
compact_pct = int(os.environ.get("CLAUDE_AUTOCOMPACT_PCT_OVERRIDE", "95"))
if ctx is not None:
    threshold_ratio = min(ctx / compact_pct * 100, 100) if compact_pct > 0 else 0
    bar_thresh = f"{gradient(threshold_ratio)}{braille_bar(threshold_ratio)}{R}"
    bar_full = f"{gradient(ctx)}{braille_bar(ctx)}{R}"
    p = round(ctx)
    line2.append(f"ctx {bar_thresh} {bar_full} {p}%/{compact_pct}%")

five_hr = data.get("rate_limits", {}).get("five_hour", {})
five = five_hr.get("used_percentage")
if five is not None:
    line2.append(fmt("5h", five, five_hr.get("resets_at")))

seven_day = data.get("rate_limits", {}).get("seven_day", {})
week = seven_day.get("used_percentage")
if week is not None:
    line2.append(fmt("7d", week, seven_day.get("resets_at")))

lines = [SEP.join(line1)]
if line2:
    lines.append(SEP.join(line2))
print("\n".join(lines), end="")
