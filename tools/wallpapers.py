#!/usr/bin/env python3
"""Processa imagens de Content/Wallpapers/ e gera dist/content/wallpapers.json.

Uso: python3 tools/wallpapers.py
"""
import hashlib, json, sys, datetime
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    sys.exit("Falta o Pillow: pip3 install Pillow  (ou rode tools/publicar.sh que instala tudo)")

ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = ROOT / "Content" / "Wallpapers"
DIST_DIR = ROOT / "dist" / "content"

MAX_W, MAX_H = 1290, 2311
MIN_W = 1000
QUALITY = 82
SCHEMA = 1
IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".webp", ".heic"}


def compute_id(src: Path) -> str:
    """ID estável baseado no SHA-256 do arquivo original."""
    sha = hashlib.sha256(src.read_bytes()).hexdigest()
    return f"wp_{sha[:12]}"


def process_image(src: Path, item_id: str, out_dir: Path) -> dict | None:
    """Redimensiona e salva JPEG. Retorna o item do índice ou None se rejeitado."""
    try:
        with Image.open(src) as raw:
            if raw.mode != "RGB":
                raw = raw.convert("RGB")
            w, h = raw.size
            if w < MIN_W:
                print(f"  REJEITADO {src.name}: largura {w}px < {MIN_W}px mínimo")
                return None
            if w > MAX_W or h > MAX_H:
                ratio = min(MAX_W / w, MAX_H / h)
                raw = raw.resize((int(w * ratio), int(h * ratio)), Image.LANCZOS)
            out_dir.mkdir(parents=True, exist_ok=True)
            out_path = out_dir / f"{item_id}.jpg"
            raw.save(out_path, "JPEG", quality=QUALITY, optimize=True)
    except Exception as e:
        print(f"  AVISO: não processou {src.name}: {e}")
        return None

    sha = hashlib.sha256(out_path.read_bytes()).hexdigest()
    return {
        "id": item_id,
        "file": f"wallpapers/{item_id}.jpg",
        "sha256": sha,
        "bytes": out_path.stat().st_size,
        "added": datetime.date.today().isoformat(),
    }


def build(src_dir: Path = SRC_DIR, dist_dir: Path = DIST_DIR) -> dict:
    """Constrói o índice de papéis de parede.

    Retorna {"new": N, "removed": M, "version": V, "items": [...]}.
    """
    out_dir = dist_dir / "wallpapers"
    index_file = dist_dir / "wallpapers.json"

    sources = sorted(
        f for f in (src_dir.iterdir() if src_dir.exists() else [])
        if f.suffix.lower() in IMAGE_EXTS and not f.name.startswith(".")
    )

    # Passo 1: calcular IDs de todas as fontes actuais (detecta duplicados)
    current_ids: dict[str, Path] = {}  # id -> arquivo fonte
    for src in sources:
        item_id = compute_id(src)
        if item_id in current_ids:
            print(f"  Duplicado ignorado: {src.name} (igual a {current_ids[item_id].name})")
        else:
            current_ids[item_id] = src

    # Passo 2: carregar índice existente
    existing_items: list[dict] = []
    old_version = 0
    if index_file.exists():
        try:
            data = json.loads(index_file.read_text(encoding="utf-8"))
            existing_items = data.get("items", [])
            old_version = data.get("version", 0)
        except Exception:
            pass
    existing_ids = {item["id"] for item in existing_items}

    # Passo 3: preservar itens cujas fontes ainda existem
    preserved = [item for item in existing_items if item["id"] in current_ids]
    preserved_ids = {item["id"] for item in preserved}
    removed_count = len(existing_ids) - len(preserved_ids)

    # Passo 4: processar imagens novas
    new_items = []
    for item_id, src in current_ids.items():
        if item_id in existing_ids:
            continue
        item = process_image(src, item_id, out_dir)
        if item is None:
            continue
        new_items.append(item)
        print(f"  + {item_id}  {item['bytes'] // 1024} KB  ({src.name})")

    items_final = preserved + new_items
    version_changed = len(new_items) > 0 or removed_count > 0
    version = (old_version + 1) if version_changed else old_version

    if not items_final and not existing_items:
        print("Nenhuma imagem em Content/Wallpapers/ — índice vazio gerado.")
    else:
        msg = f"wallpapers.json v{version}: {len(items_final)} imagem(ns)"
        if new_items:
            msg += f", {len(new_items)} nova(s)"
        if removed_count:
            msg += f", {removed_count} removida(s) do índice"
        print(msg)

    dist_dir.mkdir(parents=True, exist_ok=True)
    index = {"schema": SCHEMA, "version": version, "items": items_final}
    index_file.write_text(
        json.dumps(index, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    return {"new": len(new_items), "removed": removed_count, "version": version, "items": items_final}


if __name__ == "__main__":
    result = build()
    if result["new"] == 0 and result["removed"] == 0:
        print("Nada mudou.")
