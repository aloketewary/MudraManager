#!/bin/bash

echo "🔑 Creating new keystore for Mudra Manager..."

# Generate new keystore
keytool -genkey -v -keystore ~/mudra-manager-upload-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias mudra-manager-upload \
  -dname "CN=Mudra Manager, OU=Development, O=GhostWork, L=Mumbai, ST=Maharashtra, C=IN" \
  -storepass mudra2024 -keypass mudra2024

echo "✅ Keystore created at ~/mudra-manager-upload-key.jks"
echo "📝 Update your key.properties file with the new path"