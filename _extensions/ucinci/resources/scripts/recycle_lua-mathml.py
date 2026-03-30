import os
from send2trash import send2trash

print("\n\n")
print("Checking for litter that luamml mathml may have rudely left in our project directory.\n")

target_dir = os.sep.join(os.getenv("QUARTO_PROJECT_OUTPUT_DIR").split(os.sep)[0:-1])
# File extension to match
suffix = "-luamml-mathml.html"

for filename in os.listdir(target_dir):
    if filename.endswith(suffix):
        full_path = os.path.join(target_dir, filename)
        send2trash(full_path)
        print("--> sending to recycle bin: {0}\n".format(full_path))