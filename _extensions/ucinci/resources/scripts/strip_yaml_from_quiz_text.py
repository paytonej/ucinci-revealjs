import os

print("Stripping yaml from rendered markdown quizzes (if they exist)...")

for output_file in os.getenv("QUARTO_PROJECT_OUTPUT_FILES").split("\n"):
    print(f"Processing output file: {output_file}")

    output_file_ext = output_file.split('.')[-1].lower()

    # Only process .txt files
    if output_file_ext == "txt":
        # Read file
        with open(output_file, "r", encoding="utf-8") as f:
            lines = f.readlines()

        new_content = None

        # Check if the file starts with YAML front matter
        if lines and lines[0].strip() == "---":
            for i in range(1, len(lines)):
                if lines[i].strip() == "---":
                    # Strip YAML (everything up to and including this line)
                    new_content = "".join(lines[i+1:])
                    break

        # If no YAML found, keep original content
        if new_content is None:
            new_content = "".join(lines)

        # Rewrite the same file with stripped content
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(new_content)

        print(f"Stripped YAML header from {output_file}")
    else:
        print(f"Skipping non-txt file: {output_file}")