#!/usr/bin/env python3
"""Copy each lab *.camel.yaml into the Integration spec.flows block.

Labs 04 and 05 also embed platform/SandboxTrust.java under spec.sources.
The camel file stays the file Kaoto opens. up.sh runs this before oc apply.
"""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LABS = ROOT / "labs"
JAVA = ROOT / "platform" / "SandboxTrust.java"
FLOWS_START = "    # >>> flows"
FLOWS_END = "    # <<< flows"
SOURCES_START = "    # >>> sources"
SOURCES_END = "    # <<< sources"


def indent(text: str, spaces: int) -> str:
    pad = " " * spaces
    lines = []
    for line in text.replace("\r\n", "\n").strip().split("\n"):
        lines.append(pad + line if line.strip() else "")
    return "\n".join(lines) + "\n"


def replace_block(text: str, start: str, end: str, body: str) -> str:
    if start not in text or end not in text:
        raise SystemExit(f"Faltan marcadores {start!r} / {end!r}")
    pre, rest = text.split(start, 1)
    _, post = rest.split(end, 1)
    return pre + start + "\n" + body + end + post


def java_source(path: Path) -> str:
    content = path.read_text(encoding="utf-8").replace("\r\n", "\n").rstrip() + "\n"
    lines = []
    for line in content.split("\n"):
        lines.append(("        " + line) if line else "")
    indented = "\n".join(lines)
    return f"    - name: {path.name}\n      content: |\n{indented}\n"


def main() -> None:
    if not LABS.is_dir():
        raise SystemExit(f"No existe {LABS}")
    for lab in sorted(path for path in LABS.iterdir() if path.is_dir()):
        integration = lab / "integration.yaml"
        if not integration.exists():
            continue
        camel_files = sorted(lab.glob("*.camel.yaml"))
        if len(camel_files) != 1:
            raise SystemExit(f"{lab.name}: se espera un solo *.camel.yaml")
        text = integration.read_text(encoding="utf-8").replace("\r\n", "\n")
        text = replace_block(text, FLOWS_START, FLOWS_END, indent(camel_files[0].read_text(encoding="utf-8"), 4))
        if SOURCES_START in text:
            if not JAVA.exists():
                raise SystemExit(f"Falta {JAVA}")
            text = replace_block(text, SOURCES_START, SOURCES_END, java_source(JAVA))
        if not text.endswith("\n"):
            text += "\n"
        current = integration.read_text(encoding="utf-8").replace("\r\n", "\n")
        if current != text:
            integration.write_text(text, encoding="utf-8", newline="\n")
            print(f"synced {integration.relative_to(ROOT)}")
        else:
            print(f"ok {integration.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
