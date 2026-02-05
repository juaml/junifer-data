#!/usr/bin/env -S uv run --script
#
# /// script
# requires-python = ">=3.13"
# dependencies = [
#   "siibra",
#   "nibabel",
#   "polars",
#   "nilearn",
# ]
# ///

# Synchon Mandal, 2026
# Naive fetching of Julich-Brain via siibra, no tricks

import re
from pathlib import Path

import polars as pl
import nibabel as nib
import nilearn.image as nimg
import siibra as s

a = s.atlases.get("human")
ps = [p for p in a.parcellations.keys if p.startswith("JULICH")]
pattern = re.compile(r"V[\d_]+\d+$")
base_dir = Path("./parcellations/Julich-Brain")
base_dir.mkdir(parents=True, exist_ok=True)
for p in ps:
    # Get labelled data
    ml = s.get_map(space="mni152", parcellation=p, maptype=s.MapType.LABELLED)
    try:
        ml_c = ml.compress()
    except RuntimeError:
        ml_c = ml
    l_img = ml_c.fetch()
    v = re.search(pattern, p).group(0)
    v_dir = base_dir / v
    v_dir.mkdir(parents=True, exist_ok=True)
    nib.save(l_img, v_dir / "labelled.nii.gz")
    df = pl.DataFrame({"label": list(ml_c.labels), "region": ml_c.regions})
    df.write_csv(v_dir / "labels.csv")
    # Get statistical data
    ms = s.get_map(space="mni152", parcellation=p, maptype=s.MapType.STATISTICAL)
    s_img = nimg.concat_imgs(filter(lambda x: x is not None, [v.fetch() for v in ms.volumes]))
    nib.save(s_img, v_dir / "statistical.nii.gz")
