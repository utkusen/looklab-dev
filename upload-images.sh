#!/bin/bash

# Upload images to Firebase Storage using Firebase CLI
# This script uploads all clothing images to the gallery folder

echo "Starting image upload to Firebase Storage..."

cd "/Users/utkusen/Desktop/dev/looklab-dev"

# Function to upload category images
upload_category() {
    local gender=$1
    local folder_name=$2
    local category_name=$3
    
    local source_dir="./images/${gender}/${folder_name}/removed-background"
    local dest_path="gallery/${gender}/${category_name}"
    
    if [ -d "$source_dir" ]; then
        echo "Uploading ${gender}/${category_name}..."
        
        # Upload all webp files in the directory
        for file in "${source_dir}"/*.webp; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                echo "  Uploading $filename..."
                firebase storage:upload "$file" "${dest_path}/${filename}" --project looklab-7acba
            fi
        done
        
        echo "✅ Completed ${gender}/${category_name}"
    else
        echo "⚠️  Directory not found: $source_dir"
    fi
}

# Upload men's clothing
upload_category "men" "top" "tops"
upload_category "men" "bottom" "bottoms"
upload_category "men" "fullbody" "fullbody"
upload_category "men" "outwear" "outerwear"
upload_category "men" "shoe" "shoes"
upload_category "men" "accessories" "accessories"
upload_category "men" "head" "head"

# Upload women's clothing
upload_category "women" "top" "tops"
upload_category "women" "bottom" "bottoms"
upload_category "women" "fullbody" "fullbody"
upload_category "women" "outwear" "outerwear"
upload_category "women" "shoe" "shoes"
upload_category "women" "accessories" "accessories"
upload_category "women" "head" "head"
upload_category "women" "other" "other"

echo "🎉 All images uploaded successfully!"
echo ""
echo "Images are now available at:"
echo "https://storage.googleapis.com/looklab-7acba.appspot.com/gallery/{gender}/{category}/{filename}"