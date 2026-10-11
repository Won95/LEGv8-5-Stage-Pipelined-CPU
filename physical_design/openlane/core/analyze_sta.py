#!/usr/bin/env python3
"""Classify OpenLane STAPrePNR setup violations by semantic RTL signal.

Usage:
    python3 analyze_sta.py runs/RUN_YYYY-MM-DD_HH-MM-SS

The script needs only Python's standard library.  It maps synthesized flip-flop
instance names back to their Q-net names using the Yosys netlist, then groups the
slow-corner violator list by start/end signal class.  This is intended to replace
manual one-path-at-a-time timing triage.
"""

from __future__ import annotations

import argparse
import collections
import re
from pathlib import Path


def parse_ff_map(netlist: Path):
    text = netlist.read_text(errors="replace")
    pat = re.compile(
        r"sky130_fd_sc_hd__dfxtp_\d+\s+(_\d+_)\s*\("
        r"\s*\.CLK\([^)]+\),\s*\.D\(([^)]+)\),\s*\.Q\(([^)]+)\)\s*\);",
        re.S,
    )
    out = {}
    for m in pat.finditer(text):
        inst, dnet, qnet = m.groups()
        out[inst] = (qnet.strip(), dnet.strip())
    return out


def semantic_pin(pin: str, ff_map, endpoint: bool = False):
    m = re.fullmatch(r"(_\d+_)/(Q|D)", pin)
    if not m:
        return pin
    inst = m.group(1)
    if inst not in ff_map:
        return pin
    # Endpoint semantics are easier to read using the destination FF's Q name.
    return ff_map[inst][0]


def signal_class(name: str):
    n = name.replace("\\", "")
    tests = [
        (r"(^|\.)dmem_re$|Memread_mem", "MEM read/control"),
        (r"ALU\.is_sub", "ALU SUB control"),
        (r"instruction", "instruction/decode"),
        (r"REG\.Regwritedata|Regwritedata_wb", "WB data"),
        (r"REG\.zero_flags|zero", "zero metadata"),
        (r"Rd_wb", "WB destination"),
        (r"Readdata1_ex", "EX operand A"),
        (r"Readdata2_ex", "EX operand B"),
        (r"result_mem|dmem_addr", "MEM result/address"),
        (r"branch_target", "branch target"),
        (r"imem_req_addr|pc_if|\.PC\.", "PC/fetch address"),
        (r"imem_flush|imem_req_valid|imem_rsp_ready", "fetch/flush control"),
        (r"fwdmux|muxa|muxb", "forwarding select"),
    ]
    for pat, label in tests:
        if re.search(pat, n):
            return label
    return re.sub(r"\[.*", "", n)


def parse_violators(path: Path, ff_map):
    rows = []
    pat = re.compile(
        r"\[setup ([^]]+)\]\s+(.+?)\s+->\s+(.+?)\s+:\s+(-?\d+(?:\.\d+)?)"
    )
    for line in path.read_text(errors="replace").splitlines():
        m = pat.search(line)
        if not m:
            continue
        ptype, start, end, slack = m.groups()
        ssem = semantic_pin(start, ff_map)
        esem = semantic_pin(end, ff_map, endpoint=True)
        rows.append((ptype, start, end, float(slack), ssem, esem))
    return rows


def print_group(title, rows, keyfn, limit=15):
    groups = collections.defaultdict(lambda: [0, 0.0, 0.0])
    for row in rows:
        key = keyfn(row)
        g = groups[key]
        g[0] += 1
        g[1] += row[3]
        g[2] = min(g[2], row[3])

    print(f"\n{title}")
    print("-" * len(title))
    print(f"{'group':48s} {'count':>7s} {'TNS(ns)':>12s} {'worst(ns)':>12s}")
    for key, (count, tns, worst) in sorted(
        groups.items(), key=lambda kv: (kv[1][1], kv[1][2])
    )[:limit]:
        print(f"{key[:48]:48s} {count:7d} {tns:12.3f} {worst:12.3f}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("run", type=Path, help="OpenLane RUN_* directory")
    ap.add_argument("--corner", default="nom_ss_100C_1v60")
    args = ap.parse_args()

    run = args.run.resolve()
    netlist = run / "06-yosys-synthesis" / "core_pd_top.nl.v"
    sta = run / "12-openroad-staprepnr"
    viol = sta / args.corner / "violator_list.rpt"
    summary = sta / "summary.rpt"

    for p in (netlist, viol, summary):
        if not p.exists():
            raise SystemExit(f"missing: {p}")

    print(summary.read_text(errors="replace"))

    ff_map = parse_ff_map(netlist)
    rows = parse_violators(viol, ff_map)
    setup = [r for r in rows if r[3] < 0]

    print(f"Mapped FFs: {len(ff_map)}")
    print(f"Setup violations in {args.corner}: {len(setup)}")
    if setup:
        worst = min(setup, key=lambda r: r[3])
        print(
            "Worst: "
            f"{worst[4]} -> {worst[5]} : {worst[3]:.6f} ns "
            f"({worst[0]})"
        )

    print_group(
        "By start signal",
        setup,
        lambda r: r[4],
    )
    print_group(
        "By start class",
        setup,
        lambda r: signal_class(r[4]),
    )
    print_group(
        "By start class -> endpoint class",
        setup,
        lambda r: f"{signal_class(r[4])} -> {signal_class(r[5])}",
        limit=25,
    )


if __name__ == "__main__":
    main()
