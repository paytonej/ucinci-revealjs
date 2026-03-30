import os
from pathlib import Path
from bs4 import BeautifulSoup

print("Converting rendered Quarto HTML to Canvas-compatible fragments (if it exists)...")

classes_to_remove = ['sidebar', 'margin-sidebar', 'quarto-alternate-formats']

for output_file in os.getenv("QUARTO_PROJECT_OUTPUT_FILES").split("\n"):
    print(f"Processing output file: {output_file}")

    output_file_ext = output_file.split('.')[-1].lower()
    output_file_parent = "/".join(output_file.split('/')[:-1])
    output_file_stem = ".".join(output_file.split('/')[-1].split('.')[:-1])

    #print(f"  - ext: {output_file_ext}")
    #print(f"  - parent: {output_file_parent}")
    #print(f"  - stem: {output_file_stem}")

    # Only process HTML files
    if output_file_ext == "html":
        # Read the HTML
        with open(output_file, "r", encoding="utf-8") as f:
            soup = BeautifulSoup(f, "html.parser")

        # Remove tag with id="header"
        header_tag = soup.find(id="title-block-header")
        if header_tag:
            header_tag.decompose()

        # Remove script with id="quarto-html-after-body"
        post_script_tag = soup.find(id="quarto-html-after-body")
        if post_script_tag:
            post_script_tag.decompose()

        # Remove elements with any of the specified classes
        for cls in classes_to_remove:
            for tag in soup.select(f".{cls}"):
                tag.decompose()  # completely remove it from the tree

        main_tag = soup.find("main")
        if main_tag and main_tag.contents:
            # Get inner HTML
            main_content = "".join(str(c) for c in main_tag.contents)
            print(main_content)
        else:
            print("No content found in <main>")
            main_content = ""

        # Extract main content
        #main_content = main_tag.decode_contents()

        # Create the 'pages' directory inside the rendering directory
        pages_dir = Path(output_file_parent) / "pages"
        pages_dir.mkdir(parents=True, exist_ok=True)
        print(f"  - pages_dir: {pages_dir}")

        # Create output file path in 'pages' directory
        output_path = Path(pages_dir) / "".join([output_file_stem, "_body.txt"])

        # Write the extracted body content
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(main_content)

        print(f"Processed: {output_file} → {output_path}")
    else:
        print(f"Skipping non-HTML file: {output_file}")