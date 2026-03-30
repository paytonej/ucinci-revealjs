from pathlib import Path
from send2trash import send2trash
import os

def is_effectively_empty(path: Path) -> bool:
    """
    Returns True if the file has no meaningful content.
    Handles text and binary files differently.
    """

    TEXT_EXTENSIONS = {".txt", ".md", ".html", ".qmd", ".m", ".py",
                   ".csv", ".tex", ".dat", ".log"}

    BINARY_EXTENSIONS = {".pdf", ".docx", ".pptx", ".xlsx"}

    # Truly empty
    if path.stat().st_size == 0:
        return True

    ext = path.suffix.lower()

    # Text-like files: check decoded contents
    if ext in TEXT_EXTENSIONS:
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
            return not text.strip()   # empty or whitespace-only
        except Exception:
            return False

    # Binary files: treat very small files as empty/corrupt
    if ext in BINARY_EXTENSIONS:
        return path.stat().st_size < 100  # bytes (adjust if needed)

    return False

EXTENSIONS = {
    ".txt", ".md", ".html", ".pdf", ".qmd", ".docx", ".pptx",
    ".m", ".py", ".xlsx", ".csv", ".tex", ".dat", ".log"
}

def move_empty_output_files_to_trash(directory):
    directory = Path(directory)

    for path in directory.iterdir():
        if (
            path.is_file()
            and path.suffix.lower() in EXTENSIONS
            and is_effectively_empty(path)
        ):
            send2trash(path)
            print(f"Moved empty file to trash: {path}")

move_empty_output_files_to_trash(os.getenv("QUARTO_PROJECT_OUTPUT_DIR"))