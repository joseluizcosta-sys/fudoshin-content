#!/usr/bin/env python3
"""Testes unitários para tools/wallpapers.py.

Uso: python3 tools/test_wallpapers.py
"""
import json, shutil, tempfile, unittest
from pathlib import Path

from PIL import Image

import sys
sys.path.insert(0, str(Path(__file__).parent))
from wallpapers import build, compute_id


def make_jpeg(path: Path, w: int = 1400, h: int = 2500) -> Path:
    """Cria um JPEG sintético para testes."""
    img = Image.new("RGB", (w, h), color=(80 + w % 100, 120, 200))
    img.save(path, "JPEG")
    return path


class TestBuild(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.src = self.tmp / "Wallpapers"
        self.dist = self.tmp / "dist"
        self.src.mkdir()
        self.dist.mkdir()

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def result(self):
        return build(src_dir=self.src, dist_dir=self.dist)

    # --- Deduplicação ---

    def test_same_image_twice_one_item(self):
        p1 = make_jpeg(self.src / "img1.jpg")
        shutil.copy(p1, self.src / "img1_copia.jpg")
        r = self.result()
        self.assertEqual(len(r["items"]), 1)

    def test_different_images_two_items(self):
        make_jpeg(self.src / "img1.jpg", w=1400)
        make_jpeg(self.src / "img2.jpg", w=1500)
        r = self.result()
        self.assertEqual(len(r["items"]), 2)

    # --- Versão ---

    def test_version_starts_at_1(self):
        make_jpeg(self.src / "img1.jpg")
        r = self.result()
        self.assertEqual(r["version"], 1)

    def test_version_does_not_rise_without_change(self):
        make_jpeg(self.src / "img1.jpg")
        r1 = self.result()
        r2 = self.result()
        self.assertEqual(r1["version"], r2["version"])

    def test_version_rises_when_image_added(self):
        make_jpeg(self.src / "img1.jpg")
        r1 = self.result()
        make_jpeg(self.src / "img2.jpg", w=1500)
        r2 = self.result()
        self.assertEqual(r2["version"], r1["version"] + 1)

    def test_version_rises_when_image_removed(self):
        p1 = make_jpeg(self.src / "img1.jpg")
        p2 = make_jpeg(self.src / "img2.jpg", w=1500)
        r1 = self.result()
        p2.unlink()
        r2 = self.result()
        self.assertEqual(r2["version"], r1["version"] + 1)
        self.assertEqual(len(r2["items"]), 1)

    # --- Redimensionamento ---

    def test_resize_to_max(self):
        make_jpeg(self.src / "big.jpg", w=2000, h=3500)
        r = self.result()
        self.assertEqual(len(r["items"]), 1)
        item = r["items"][0]
        from PIL import Image as PILImage
        out = self.dist / "wallpapers" / f"{item['id']}.jpg"
        img = PILImage.open(out)
        self.assertLessEqual(img.width, 1290)
        self.assertLessEqual(img.height, 2311)

    def test_no_resize_when_small_enough(self):
        make_jpeg(self.src / "ok.jpg", w=1000, h=2000)
        r = self.result()
        item = r["items"][0]
        from PIL import Image as PILImage
        out = self.dist / "wallpapers" / f"{item['id']}.jpg"
        img = PILImage.open(out)
        self.assertEqual(img.width, 1000)
        self.assertEqual(img.height, 2000)

    # --- Rejeição ---

    def test_reject_too_narrow(self):
        make_jpeg(self.src / "tiny.jpg", w=800, h=2000)
        r = self.result()
        self.assertEqual(len(r["items"]), 0)

    # --- Estrutura do item ---

    def test_item_fields(self):
        make_jpeg(self.src / "img.jpg")
        r = self.result()
        item = r["items"][0]
        self.assertTrue(item["id"].startswith("wp_"))
        self.assertEqual(len(item["id"]), 3 + 12)  # "wp_" + 12 hex chars
        self.assertIn("sha256", item)
        self.assertIn("bytes", item)
        self.assertIn("added", item)
        self.assertEqual(item["file"], f"wallpapers/{item['id']}.jpg")

    # --- SHA no arquivo de saída ---

    def test_sha256_in_item_matches_output_file(self):
        import hashlib
        make_jpeg(self.src / "img.jpg")
        r = self.result()
        item = r["items"][0]
        out = self.dist / "wallpapers" / f"{item['id']}.jpg"
        actual = hashlib.sha256(out.read_bytes()).hexdigest()
        self.assertEqual(item["sha256"], actual)


if __name__ == "__main__":
    unittest.main(verbosity=2)
