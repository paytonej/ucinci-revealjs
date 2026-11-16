import fnmatch
import json
import os
import shutil
from pathlib import Path

output_dir = os.environ["QUARTO_PROJECT_OUTPUT_DIR"]
project_dir = Path(os.environ["QUARTO_PROJECT_DIR"])

secrets = json.loads((project_dir / "_secrets.json").read_text())
sync_dir = Path(secrets["sync_directory"])

# Optional <project>/.sync-exclude: one glob per line (# comments allowed), matched against the
# output's path relative to the output dir and against its file name. Matching files are not synced.
exclude_file = project_dir / ".sync-exclude"
excludes = []
if exclude_file.exists():
    excludes = [l.strip() for l in exclude_file.read_text().splitlines() if l.strip() and not l.strip().startswith("#")]

print(f"Syncing newly rendered files to {sync_dir}...")

for output_file in os.getenv("QUARTO_PROJECT_OUTPUT_FILES", "").splitlines():
    if not output_file:
        continue
    rel_path = os.path.relpath(output_file, output_dir)
    if any(fnmatch.fnmatch(rel_path, g) or fnmatch.fnmatch(os.path.basename(rel_path), g) for g in excludes):
        print(f"  {rel_path} skipped (.sync-exclude)")
        continue
    dest = sync_dir / rel_path
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(output_file, dest)
    print(f"  {rel_path} -> {dest}")
