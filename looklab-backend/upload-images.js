const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK with Application Default Credentials
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  storageBucket: 'looklab-7acba.appspot.com'
});

const bucket = admin.storage().bucket();

async function uploadImages() {
  const imagesDir = '../images';
  const genders = ['men', 'women'];
  const categories = {
    'top': 'tops',
    'bottom': 'bottoms', 
    'fullbody': 'fullbody',
    'outwear': 'outerwear',
    'shoe': 'shoes',
    'accessories': 'accessories',
    'head': 'head',
    'other': 'other'
  };

  for (const gender of genders) {
    for (const [folderName, categoryName] of Object.entries(categories)) {
      const categoryPath = path.join(imagesDir, gender, folderName, 'removed-background');
      
      if (!fs.existsSync(categoryPath)) {
        console.log(`Skipping ${categoryPath} - directory not found`);
        continue;
      }

      const files = fs.readdirSync(categoryPath).filter(file => file.endsWith('.webp'));
      console.log(`\nUploading ${files.length} images from ${gender}/${folderName}...`);

      for (const file of files) {
        try {
          const localPath = path.join(categoryPath, file);
          const storagePath = `gallery/${gender}/${categoryName}/${file}`;
          
          await bucket.upload(localPath, {
            destination: storagePath,
            metadata: {
              cacheControl: 'public, max-age=31536000',
              contentType: 'image/webp'
            }
          });
          
          // Make the file publicly readable
          const storageFile = bucket.file(storagePath);
          await storageFile.makePublic();
          
          console.log(`✓ Uploaded ${storagePath}`);
        } catch (error) {
          console.error(`✗ Failed to upload ${file}:`, error.message);
        }
      }
    }
  }
  
  console.log('\n✅ Image upload completed!');
}

uploadImages().catch(console.error);