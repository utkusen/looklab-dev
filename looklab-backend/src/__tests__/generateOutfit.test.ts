/**
 * Unit test for generateOutfit callable function.
 * Mocks Firebase Admin and Vertex AI to avoid external calls.
 */

jest.mock('firebase-admin', () => {
  const add = jest.fn(async () => ({}));
  const collection = () => ({ add });
  const firestore = () => ({ collection });

  const makePublic = jest.fn(async () => ({}));
  const save = jest.fn(async () => ({}));
  const file = () => ({ save, makePublic });
  const deleteFiles = jest.fn(async () => ({}));
  const bucket = () => Object.assign({ file, deleteFiles, name: 'mock-bucket' });
  const storage = () => ({ bucket });

  return {
    initializeApp: jest.fn(),
    firestore,
    storage,
    FieldValue: { serverTimestamp: jest.fn(() => 'server-ts') },
  } as any;
});

jest.mock('@google-cloud/vertexai', () => {
  return {
    VertexAI: function () {
      return {
        preview: {
          getGenerativeModel: () => ({
            generateContentStream: async () => ({ response: Promise.resolve() }),
          }),
        },
      };
    },
  };
});

import type { HttpsError } from 'firebase-functions/v2/https';
import { generateOutfit } from '../index';

describe('generateOutfit', () => {
  it('returns success with imageUrls for valid input', async () => {
    const data = {
      clothingItems: [
        { id: 'c1', name: 'T-Shirt', category: 'top', imageURL: 'base64data', color: 'black' },
      ],
      background: 'street style',
      userBodyPhoto: '',
    };

    const context = { auth: { uid: 'user-1' } } as any;

    const res = await (generateOutfit as any)(data, context);
    expect(res.success).toBe(true);
    expect(Array.isArray(res.imageUrls)).toBe(true);
    expect(res.imageUrls.length).toBe(3);
  });

  it('throws HttpsError when unauthenticated', async () => {
    const data = { clothingItems: [], background: '', userBodyPhoto: '' };
    await expect((generateOutfit as any)(data, {})).rejects.toHaveProperty('code');
  });
});

