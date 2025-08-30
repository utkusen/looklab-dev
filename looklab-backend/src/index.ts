import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { VertexAI } from '@google-cloud/vertexai';

admin.initializeApp();

const vertex_ai = new VertexAI({
  project: process.env.GOOGLE_CLOUD_PROJECT || 'looklab-project',
  location: 'us-central1',
});

interface ClothingItemData {
  id: string;
  name: string;
  category: string;
  imageURL: string;
  color: string;
}

interface GenerateOutfitRequest {
  clothingItems: ClothingItemData[];
  background: string;
  userBodyPhoto: string;
}

export const generateOutfit = functions
  .runWith({ 
    timeoutSeconds: 300,
    memory: '1GB' 
  })
  .https
  .onCall(async (data: GenerateOutfitRequest, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('failed-precondition', 'The function must be called while authenticated.');
    }

    try {
      const { clothingItems, background, userBodyPhoto } = data;

      // Validate input
      if (!clothingItems || clothingItems.length === 0) {
        throw new functions.https.HttpsError('invalid-argument', 'At least one clothing item is required.');
      }

      // Create system prompt for outfit generation
      const systemPrompt = `You are an AI fashion stylist. Generate a realistic outfit image based on the provided clothing items and background setting. The generated image should show how these specific clothing items would look together on a person in the specified setting.

Clothing items provided:
${clothingItems.map(item => `- ${item.name} (${item.category}, ${item.color})`).join('\n')}

Background setting: ${background}
${userBodyPhoto ? 'Use the provided body photo as reference for body type and fit.' : 'Use a standard fashion model body type.'}

Generate 3 different variations of the outfit in the specified background setting.`;

      // Call Vertex AI Gemini Flash Image Preview
      const model = vertex_ai.preview.getGenerativeModel({
        model: 'gemini-2.5-flash-image-preview',
      });

      const imageUrls: string[] = [];

      // Generate 3 variations
      for (let i = 0; i < 3; i++) {
        const request = {
          contents: [
            {
              role: 'user',
              parts: [
                { text: systemPrompt },
                ...(userBodyPhoto ? [{ 
                  inlineData: { 
                    mimeType: 'image/jpeg', 
                    data: userBodyPhoto 
                  } 
                }] : []),
                ...clothingItems
                  .filter(item => item.imageURL)
                  .map(item => ({
                    inlineData: {
                      mimeType: 'image/jpeg',
                      data: item.imageURL
                    }
                  }))
              ]
            }
          ],
          generationConfig: {
            maxOutputTokens: 8192,
            temperature: 0.7,
            topP: 0.8,
          },
        };

        const streamingResp = await model.generateContentStream(request);
        await streamingResp.response;
        
        // For now, return placeholder URLs as Gemini Flash doesn't generate images directly
        // In production, you would process the response and upload generated images to Cloud Storage
        const imageUrl = `https://storage.googleapis.com/looklab-generated-images/${context.auth.uid}/${Date.now()}_${i}.jpg`;
        imageUrls.push(imageUrl);
      }

      // Store generation record in Firestore
      await admin.firestore().collection('outfit_generations').add({
        userId: context.auth.uid,
        clothingItems: clothingItems.map(item => item.id),
        background,
        imageUrls,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        imageUrls
      };

    } catch (error) {
      console.error('Error generating outfit:', error);
      throw new functions.https.HttpsError('internal', 'Failed to generate outfit');
    }
  });

export const uploadClothingItem = functions
  .runWith({ memory: '512MB' })
  .https
  .onCall(async (data: { imageData: string; name: string; category: string }, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('failed-precondition', 'The function must be called while authenticated.');
    }

    try {
      const { imageData, name, category } = data;
      const userId = context.auth.uid;

      // Upload image to Cloud Storage
      const bucket = admin.storage().bucket();
      const fileName = `clothing_items/${userId}/${Date.now()}_${name.replace(/\s+/g, '_')}.jpg`;
      const file = bucket.file(fileName);

      // Convert base64 to buffer
      const imageBuffer = Buffer.from(imageData, 'base64');
      
      await file.save(imageBuffer, {
        metadata: {
          contentType: 'image/jpeg',
        },
      });

      // Make file publicly readable
      await file.makePublic();

      const publicUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;

      // Save clothing item to Firestore
      const clothingItemRef = await admin.firestore().collection('clothing_items').add({
        userId,
        name,
        category,
        imageURL: publicUrl,
        isFromGallery: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        id: clothingItemRef.id,
        imageURL: publicUrl
      };

    } catch (error) {
      console.error('Error uploading clothing item:', error);
      throw new functions.https.HttpsError('internal', 'Failed to upload clothing item');
    }
  });

export const deleteUserData = functions
  .runWith({ memory: '512MB' })
  .https
  .onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('failed-precondition', 'The function must be called while authenticated.');
    }

    try {
      const userId = context.auth.uid;
      const batch = admin.firestore().batch();

      // Delete user document
      const userRef = admin.firestore().collection('users').doc(userId);
      batch.delete(userRef);

      // Delete user's clothing items
      const clothingItemsSnapshot = await admin.firestore()
        .collection('clothing_items')
        .where('userId', '==', userId)
        .get();

      clothingItemsSnapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });

      // Delete user's looks
      const looksSnapshot = await admin.firestore()
        .collection('looks')
        .where('userId', '==', userId)
        .get();

      looksSnapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });

      // Delete user's outfit generations
      const generationsSnapshot = await admin.firestore()
        .collection('outfit_generations')
        .where('userId', '==', userId)
        .get();

      generationsSnapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });

      await batch.commit();

      // Delete user's storage files
      const bucket = admin.storage().bucket();
      await bucket.deleteFiles({
        prefix: `clothing_items/${userId}/`,
      });

      await bucket.deleteFiles({
        prefix: `generated_outfits/${userId}/`,
      });

      return { success: true };

    } catch (error) {
      console.error('Error deleting user data:', error);
      throw new functions.https.HttpsError('internal', 'Failed to delete user data');
    }
  });