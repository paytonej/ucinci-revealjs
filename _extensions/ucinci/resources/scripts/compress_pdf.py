from pypdf import PdfReader, PdfWriter
import os

print("Compressing pdf files...")

for output_file in os.getenv("QUARTO_PROJECT_OUTPUT_FILES").split("\n"):
    print(f"Processing output file: {output_file}")

    output_file_ext = output_file.split('.')[-1].lower()

    # Only process .txt files
    if output_file_ext == "pdf":
        
        #output_pdf_path = output_file.replace('.pdf', 'i.pdf')

        starting_file_size_MB = os.path.getsize(output_file) / (1024 * 1024)

        reader = PdfReader(output_file)
        writer = PdfWriter()

        # 1. Add pages from the reader to the writer
        for page in reader.pages:
            writer.add_page(page)

        writer.compress_identical_objects(remove_identicals=True, remove_orphans=True)
        
        # 2. Compress the content streams of pages within the writer
        # Note: This has to be done on the writer's pages, not the reader's pages.
        for page in writer.pages:
            for img in page.images:
                img.replace(img.image, quality=90)
            page.compress_content_streams(level=9) # level 9 for highest compression

        with open(output_file, "wb") as f:
            writer.write(f)
            ending_file_size_MB = os.path.getsize(output_file) / (1024 * 1024)
        
        print("PDF compression completed.")
        print(f"Original file size: {starting_file_size_MB} MB")
        print(f"Compressed file size: {ending_file_size_MB} MB")