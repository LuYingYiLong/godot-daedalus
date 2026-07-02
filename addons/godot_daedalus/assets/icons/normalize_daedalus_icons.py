#!/usr/bin/env python3
"""清洗当前目录下的 SVG 图标，让 Godot 编辑器主题颜色转换更稳定。"""

from __future__ import annotations

import argparse
import re
import shutil
import xml.etree.ElementTree as ET
from pathlib import Path


SVG_NS = "http://www.w3.org/2000/svg"
INKSCAPE_NS = "http://www.inkscape.org/namespaces/inkscape"
SODIPODI_NS = "http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
XML_NS = "http://www.w3.org/XML/1998/namespace"

STYLE_PROPS = {
    "fill",
    "fill-rule",
    "fill-opacity",
    "stroke",
    "stroke-width",
    "stroke-linecap",
    "stroke-linejoin",
    "stroke-miterlimit",
    "stroke-opacity",
}

STRIP_ATTRS = {
    "class",
    "data-name",
    "id",
    "style",
    "version",
    f"{{{XML_NS}}}space",
}

THEME_FOREGROUND_ALIASES = {
    "#fff": "#e0e0e0",
    "#ffffff": "#e0e0e0",
}

ET.register_namespace("", SVG_NS)


def local_name(tag: str) -> str:
    if tag.startswith("{"):
        return tag.rsplit("}", 1)[1]
    return tag


def normalize_color(value: str) -> str:
    value = value.strip()
    return THEME_FOREGROUND_ALIASES.get(value.lower(), value)


def parse_declarations(style_text: str) -> dict[str, str]:
    props: dict[str, str] = {}

    for declaration in style_text.split(";"):
        if ":" not in declaration:
            continue

        key, value = declaration.split(":", 1)
        key = key.strip()
        value = normalize_color(value.strip())
        if key in STYLE_PROPS and value:
            props[key] = value

    return props


def parse_style_blocks(root: ET.Element) -> dict[str, dict[str, str]]:
    class_styles: dict[str, dict[str, str]] = {}

    for element in root.iter():
        if local_name(element.tag) != "style" or not element.text:
            continue

        for selector_text, body in re.findall(r"([^{}]+)\{([^{}]+)\}", element.text):
            props = parse_declarations(body)
            if not props:
                continue

            selectors = [selector.strip() for selector in selector_text.split(",")]
            for selector in selectors:
                if selector.startswith(".") and re.fullmatch(r"\.[A-Za-z_][\w-]*", selector):
                    class_styles.setdefault(selector[1:], {}).update(props)

    return class_styles


def apply_styles(root: ET.Element, class_styles: dict[str, dict[str, str]]) -> None:
    for element in root.iter():
        class_attr = element.attrib.get("class", "")
        for class_name in class_attr.split():
            for key, value in class_styles.get(class_name, {}).items():
                element.attrib.setdefault(key, value)

        inline_style = element.attrib.get("style", "")
        for key, value in parse_declarations(inline_style).items():
            element.attrib[key] = value

        normalize_inline_colors(element)


def normalize_inline_colors(element: ET.Element) -> None:
    for attr in ("fill", "stroke"):
        if attr in element.attrib:
            element.attrib[attr] = normalize_color(element.attrib[attr])


def strip_editor_metadata(element: ET.Element) -> None:
    for child in list(element):
        child_name = local_name(child.tag)
        namespace = child.tag[1:].split("}", 1)[0] if child.tag.startswith("{") else ""
        if child_name in {"style", "metadata", "namedview"} or namespace in {INKSCAPE_NS, SODIPODI_NS}:
            element.remove(child)
            continue

        strip_editor_metadata(child)

        if child_name == "defs" and len(child) == 0 and not (child.text or "").strip():
            element.remove(child)

    for attr in list(element.attrib):
        namespace = attr[1:].split("}", 1)[0] if attr.startswith("{") else ""
        if attr in STRIP_ATTRS or namespace in {INKSCAPE_NS, SODIPODI_NS}:
            del element.attrib[attr]


def indent(element: ET.Element, level: int = 0) -> None:
    children = list(element)
    if not children:
        return

    padding = "\n" + "  " * level
    child_padding = "\n" + "  " * (level + 1)

    if not element.text or not element.text.strip():
        element.text = child_padding

    for child in children:
        indent(child, level + 1)
        if not child.tail or not child.tail.strip():
            child.tail = child_padding

    children[-1].tail = padding


def normalize_svg(source_path: Path, output_path: Path) -> None:
    parser = ET.XMLParser(target=ET.TreeBuilder(insert_comments=False))
    tree = ET.parse(source_path, parser=parser)
    root = tree.getroot()

    class_styles = parse_style_blocks(root)
    apply_styles(root, class_styles)
    strip_editor_metadata(root)
    indent(root)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    tree.write(output_path, encoding="unicode", xml_declaration=False, short_empty_elements=True)

    text = output_path.read_text(encoding="utf-8")
    output_path.write_text(text.rstrip() + "\n", encoding="utf-8", newline="\n")


def parse_args() -> argparse.Namespace:
    script_dir = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source",
        type=Path,
        default=script_dir,
        help="原始 SVG 图标目录，默认是脚本所在目录",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="输出目录；不传时直接覆盖源目录 SVG",
    )
    parser.add_argument(
        "--clean",
        action="store_true",
        help="生成前清空输出目录；直接覆盖源目录时会忽略",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    source_dir = args.source.resolve()
    output_dir = args.output.resolve() if args.output else source_dir

    if args.clean and output_dir != source_dir and output_dir.exists():
        shutil.rmtree(output_dir)

    svg_paths = sorted(source_dir.glob("*.svg"))
    if not svg_paths:
        raise SystemExit(f"No SVG files found: {source_dir}")

    for source_path in svg_paths:
        output_path = output_dir / source_path.name
        normalize_svg(source_path, output_path)

    action = "in place" if output_dir == source_dir else str(output_dir)
    print(f"Normalized {len(svg_paths)} SVG files {action}")


if __name__ == "__main__":
    main()
