#!/usr/bin/env python3
import sys
import re
import subprocess
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Set, Optional

# ANSI color codes
RESET = "\033[0m"
BOLD = "\033[1m"
GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
CYAN = "\033[36m"
GRAY = "\033[90m"
MAGENTA = "\033[35m"
BLUE = "\033[34m"

def get_node_color(name: str) -> str:
    if name.startswith("Feature"):
        return CYAN
    elif name.startswith("Domain"):
        return GREEN
    elif name.startswith("Data"):
        return YELLOW
    elif name.startswith("Core"):
        return MAGENTA
    elif "App" in name or "MyTuist" in name:
        return BLUE
    return RESET

def parse_dot_file(dot_path: Path):
    content = dot_path.read_text(encoding="utf-8")
    nodes = set()
    deps: Dict[str, List[str]] = defaultdict(list)
    dependents: Dict[str, List[str]] = defaultdict(list)

    for line in content.splitlines():
        line = line.strip()
        m = re.match(r'^"?([A-Za-z0-9_]+)"?\s*->\s*"?([A-Za-z0-9_]+)"?', line)
        if m:
            src, dst = m.group(1), m.group(2)
            deps[src].append(dst)
            dependents[dst].append(src)
            nodes.add(src)
            nodes.add(dst)
        else:
            m_node = re.match(r'^"?([A-Za-z0-9_]+)"?\s*\[', line)
            if m_node:
                nodes.add(m_node.group(1))

    return nodes, deps, dependents

def render_tree(node: str, deps: Dict[str, List[str]], prefix: str = "", visited: Optional[Set[str]] = None, max_depth: int = 5, current_depth: int = 0):
    if visited is None:
        visited = set()

    children = sorted(deps.get(node, []))
    for i, child in enumerate(children):
        is_last = (i == len(children) - 1)
        branch = "└── " if is_last else "├── "
        next_prefix = prefix + ("    " if is_last else "│   ")
        
        c_color = get_node_color(child)
        if child in visited:
            print(f"{prefix}{branch}{c_color}{child}{RESET} {GRAY}(cycle/repeat){RESET}")
        else:
            print(f"{prefix}{branch}{c_color}{BOLD}{child}{RESET}")
            if current_depth < max_depth:
                visited.add(child)
                render_tree(child, deps, next_prefix, visited, max_depth, current_depth + 1)
                visited.remove(child)

def generate_mermaid(nodes: Set[str], deps: Dict[str, List[str]], filter_target: Optional[str] = None) -> str:
    lines = ["```mermaid", "graph TD"]

    included_nodes = set()
    if filter_target:
        # Include target, its dependencies, and dependents
        included_nodes.add(filter_target)
        included_nodes.update(deps.get(filter_target, []))
        for k, v in deps.items():
            if filter_target in v:
                included_nodes.add(k)
    else:
        included_nodes = nodes

    for src in sorted(included_nodes):
        for dst in sorted(deps.get(src, [])):
            if dst in included_nodes:
                lines.append(f"    {src} --> {dst}")

    lines.append("```")
    return "\n".join(lines)

def main():
    root_dir = Path(__file__).resolve().parent.parent
    target_filter = None
    is_mermaid = False

    for arg in sys.argv[1:]:
        if arg.startswith("target=") or arg.startswith("TARGET=") or arg.startswith("name=") or arg.startswith("NAME="):
            target_filter = arg.split("=", 1)[1]
        elif arg in ["--mermaid", "-m", "mermaid"]:
            is_mermaid = True
        elif not arg.startswith("-") and target_filter is None:
            target_filter = arg

    # Export graph via Tuist to scratch directory
    temp_dir = root_dir / ".build" / "graph"
    temp_dir.mkdir(parents=True, exist_ok=True)
    
    res = subprocess.run(
        ["tuist", "graph", "--skip-external-dependencies", "--skip-test-targets", "--format", "dot", "--no-open", "--output-path", str(temp_dir)],
        cwd=root_dir,
        capture_output=True,
        text=True
    )
    if res.returncode != 0:
        print(f"{RED}❌ Gagal menjalankan tuist graph:{RESET}")
        print(res.stderr or res.stdout)
        sys.exit(1)

    dot_file = temp_dir / "graph.dot"
    if not dot_file.exists():
        print(f"{RED}❌ File graph.dot tidak ditemukan di {dot_file}{RESET}")
        sys.exit(1)

    nodes, deps, dependents = parse_dot_file(dot_file)

    # Resolve target filter if provided
    matched_target = None
    if target_filter:
        clean_target = target_filter.lower()
        exact_matches = [n for n in nodes if n.lower() == clean_target]
        if exact_matches:
            matched_target = exact_matches[0]
        else:
            partial_matches = [n for n in nodes if clean_target in n.lower()]
            if partial_matches:
                # Prefer Feature if ambiguous
                feat_pref = [n for n in partial_matches if n.startswith("Feature")]
                matched_target = feat_pref[0] if feat_pref else partial_matches[0]
            else:
                print(f"{YELLOW}⚠️ Target '{target_filter}' tidak ditemukan. Menampilkan seluruh graph.{RESET}")

    if is_mermaid:
        mermaid_code = generate_mermaid(nodes, deps, matched_target)
        print(f"\n{BOLD}{CYAN}📊 Mermaid Architecture Graph:{RESET}\n")
        print(mermaid_code)
        print()
        sys.exit(0)

    print(f"\n{BOLD}{CYAN}======================================================={RESET}")
    print(f"{BOLD}{CYAN}📊 MyTuistProject Architecture Dependency Graph{RESET}")
    print(f"{BOLD}{CYAN}======================================================={RESET}\n")

    if matched_target:
        t_color = get_node_color(matched_target)
        print(f"🎯 {BOLD}Target:{RESET} {t_color}{BOLD}{matched_target}{RESET}")
        print(f"{GRAY}   (Menampilkan dependensi dan modul yang mengonsumsinya){RESET}\n")

        print(f"{BOLD}📦 Outbound Dependencies (Modul yang dibutuhkan):{RESET}")
        direct_deps = deps.get(matched_target, [])
        if not direct_deps:
            print(f"   {GRAY}(Tidak memiliki dependensi internal ke modul lain){RESET}")
        else:
            render_tree(matched_target, deps)
        print()

        print(f"{BOLD}🔄 Inbound Consumers (Modul yang mengonsumsi target ini):{RESET}")
        direct_consumers = dependents.get(matched_target, [])
        if not direct_consumers:
            print(f"   {GRAY}(Tidak ada modul lain yang mengonsumsi target ini){RESET}")
        else:
            for consumer in sorted(direct_consumers):
                c_color = get_node_color(consumer)
                print(f"   └── {c_color}{BOLD}{consumer}{RESET}")
        print()

    else:
        # Overview by Layer
        print(f"{BOLD}🗺️  Ringkasan Arsitektur Modular per Layer:{RESET}\n")

        layers = {
            "📱 Application Target": [n for n in sorted(nodes) if "App" in n or "MyTuist" in n],
            "🎨 Feature Modules": [n for n in sorted(nodes) if n.startswith("Feature")],
            "💼 Domain Modules": [n for n in sorted(nodes) if n.startswith("Domain")],
            "💾 Data Modules": [n for n in sorted(nodes) if n.startswith("Data")],
            "⚙️  Core Modules": [n for n in sorted(nodes) if n.startswith("Core")]
        }

        for layer_title, layer_nodes in layers.items():
            if not layer_nodes:
                continue
            print(f"{BOLD}{layer_title} ({len(layer_nodes)}):{RESET}")
            for node in layer_nodes:
                n_deps = deps.get(node, [])
                n_color = get_node_color(node)
                deps_summary = f"{GRAY}→ [{', '.join(n_deps)}]{RESET}" if n_deps else f"{GRAY}→ (None){RESET}"
                print(f"   • {n_color}{BOLD}{node:<22}{RESET} {deps_summary}")
            print()

        print(f"{GRAY}💡 Tip: Jalankan 'make graph target=FeatureName' untuk melihat visualisasi pohon per target.{RESET}")
        print(f"{GRAY}💡 Tip: Tambahkan 'mermaid=true' untuk mencetak diagram Mermaid.{RESET}\n")

if __name__ == "__main__":
    main()
