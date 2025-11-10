#!/bin/bash

echo "Creating keystore for FindMyTutor app..."
echo

# Check if Java is available
if ! command -v keytool &> /dev/null; then
    echo "ERROR: keytool is not in PATH. Please install Java JDK or add it to PATH."
    echo
    echo "You can install Java with:"
    echo "  macOS: brew install openjdk"
    echo "  Linux: sudo apt-get install openjdk-11-jdk"
    echo
    exit 1
fi

# Create keystore
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass findmytutor2024 -keypass findmytutor2024 -dname "CN=FindMyTutor, OU=Development, O=FindMyTutor, L=City, ST=State, C=IN"

if [ $? -eq 0 ]; then
    echo
    echo "Keystore created successfully!"
    echo
    echo "Now create key.properties file with:"
    echo "storePassword=findmytutor2024"
    echo "keyPassword=findmytutor2024"
    echo "keyAlias=upload"
    echo "storeFile=upload-keystore.jks"
    echo
else
    echo
    echo "ERROR: Failed to create keystore"
    echo
    exit 1
fi

