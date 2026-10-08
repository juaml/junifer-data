#!/usr/bin/env -S uv run --script
#
# /// script
# requires-python = ">=3.13"
# dependencies = [
#   "polars",
#   "fastexcel",
# ]
# ///

# Convert the Brainnetome subregions table (BNA_subregions.xlsx, as
# distributed by the Brainnetome Atlas) to a CSV with one row per label.
#
# Each row of the table is a pair of subregions, named for both hemispheres
# (e.g., "SFG_L(R)_7_1") and with one label ID per hemisphere. The output has
# one row per label ID, with the hemisphere in the name (e.g., "SFG_L_7_1"
# and "SFG_R_7_1").

import re
from pathlib import Path

import polars as pl

base_dir = Path("./parcellations/Brainnetome")
table = pl.read_excel(base_dir / "BNA_subregions.xlsx")

# The description header spans two cells, so its values are in the unnamed
# column; lobe and gyrus are merged cells, so only set in their first row
table = (
    table.rename(
        {
            "Left and Right Hemisphere": "name",
            "__UNNAMED__5": "description",
        }
    )
    .with_columns(
        # Some cells have trailing spaces
        pl.col(pl.String).str.strip_chars(),
    )
    .with_columns(pl.col("Lobe", "Gyrus").forward_fill())
)


def mni(coords: str) -> list[int]:
    """Parse MNI coordinates written as "x, y, z" (with irregular spaces)."""
    return [int(x) for x in re.findall(r"-?\d+", coords)]


rows = []
for row in table.iter_rows(named=True):
    for hemi, id_col, mni_col in (
        ("L", "Label ID.L", "lh.MNI(X,Y,Z)"),
        ("R", "Label ID.R", "rh.MNI(X,Y,Z)"),
    ):
        x, y, z = mni(row[mni_col])
        rows.append(
            {
                "idx": row[id_col],
                # Some names have spaces (e.g., "LOcC _L(R)_4_2")
                "label": re.sub(r"\s+", "", row["name"]).replace("L(R)", hemi),
                "hemisphere": hemi,
                "lobe": row["Lobe"],
                "gyrus": row["Gyrus"],
                "description": row["description"],
                "mni_x": x,
                "mni_y": y,
                "mni_z": z,
            }
        )

labels = pl.DataFrame(rows).sort("idx")
# Every label ID once, with a unique name
assert labels["idx"].to_list() == list(range(1, 247))
assert labels["label"].n_unique() == len(labels)
labels.write_csv(base_dir / "labels.csv")
