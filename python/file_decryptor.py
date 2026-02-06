#!/usr/bin/env python3
import os
from cryptography.fernet import Fernet

def load_key():
    """Load the Fernet key from the file."""
    return open("secret.key", "rb").read()  

def decrypt_file(file_path, key):
    """Decrypt the contents of a file."""
    fernet = Fernet(key)
    with open(file_path, "rb") as file:
        encrypted = file.read()
    decrypted = fernet.decrypt(encrypted)
    with open(file_path, "wb") as decrypted_file:
        decrypted_file.write(decrypted)
    print(f"File '{file_path}' decrypted.")

def check_secret_word(word):
    """Check if the provided word is correct."""
    correct_word = "coffee"
    if word == correct_word:
        return True
    return False

if __name__ == "__main__":
    key = None
    if not os.path.exists("secret.key"):
        raise FileNotFoundError("Secret key file not found. Cannot decrypt files.")
    else:
        key = load_key()

    files = []
    fileToSckip = ["secret.key", "file_encryptor.py", "file_decryptor.py"
                   ]
    if not check_secret_word(input("Enter the secret word to decrypt files: ")):
        print("Incorrect secret word. Exiting.")
        exit(1)
        
    for file in os.listdir("."):
        if file not in fileToSckip and os.path.isfile(file):
            files.append(file)  

    for file in files:
        decrypt_file(file, key)

    print("All files decrypted.")