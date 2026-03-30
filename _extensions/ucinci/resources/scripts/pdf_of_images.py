from pypdf import PdfWriter, PdfReader
import os
from pdf2image import convert_from_path
from PIL import Image
import io

print("Rendering vectors and text in pdf into images...")

for output_file in os.getenv("QUARTO_PROJECT_OUTPUT_FILES").split("\n"):
    print(f"Processing output file: {output_file}")

    output_file_ext = output_file.split('.')[-1].lower()

    # Only process .txt files
    if output_file_ext == "pdf":  

        starting_file_size_MB = os.path.getsize(output_file) / (1024 * 1024)

        # 1. Convert PDF pages to PIL images using pdf2image
        # This might require configuring the path to your Poppler bin directory 
        # if it's not in your system's PATH.
        images = convert_from_path(output_file)
        
        #output_pdf_path = output_file.replace('.pdf', 'i.pdf')

        writer = PdfWriter()
        
        for img in images:
            # Save the PIL image to a byte stream as a temporary PDF
            with io.BytesIO() as img_bytes:
                # Save the image as a single-page PDF to the byte stream
                # The 'save_all=False' ensures a single PDF page is generated
                img.save(img_bytes, format='PDF', save_all=False)

                # 2. Add the image-based PDF page to the writer
                # We treat the single-page image PDF as an input source
                reader_img = PdfReader(img_bytes)
                writer.add_page(reader_img.pages[0])

        # 3. Write the final output PDF file
        with open(output_file, "wb") as f:
            writer.write(f)

            ending_file_size_MB = os.path.getsize(output_file) / (1024 * 1024)

        print(f"Successfully created image-based PDF: {output_file}")
        print(f"Original vector-containing file size: {starting_file_size_MB} MB")
        print(f"Image-only pdf file size: {ending_file_size_MB} MB")