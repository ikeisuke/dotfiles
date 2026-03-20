#!/usr/bin/env python3
"""Braille dots statusline - dotted progress bar using braille characters."""
import json
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
    return f"{DIM}{label}{R} {gradient(pct)}{braille_bar(pct)}{R} {p}%{reset}"


model = data.get("model", {}).get("display_name", "Claude")
parts = [model]

ctx = data.get("context_window", {}).get("used_percentage")
if ctx is not None:
    parts.append(fmt("ctx", ctx))

five_hr = data.get("rate_limits", {}).get("five_hour", {})
five = five_hr.get("used_percentage")
if five is not None:
    parts.append(fmt("5h", five, five_hr.get("resets_at")))

seven_day = data.get("rate_limits", {}).get("seven_day", {})
week = seven_day.get("used_percentage")
if week is not None:
    parts.append(fmt("7d", week, seven_day.get("resets_at")))

print(f" {DIM}│{R} ".join(parts), end="")
