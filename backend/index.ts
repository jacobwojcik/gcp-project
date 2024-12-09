import express from 'express';
import multer from 'multer';
import { Storage } from '@google-cloud/storage';
import cors from 'cors';

const app = express();
const port = process.env.PORT || 8080;


app.use(cors());


const storage = new Storage({
  keyFilename: './gcp-key.json', 
  projectId: process.env.PROJECT_ID,
});

const bucketName = 'image-upload-original-bucket'; 
const upload = multer({ storage: multer.memoryStorage() });

app.post('/upload', upload.single('image'), async (req, res) => {
  const file = req.file;
  if (!file) {
    res.status(400).send('No file uploaded.');
    return;
  }

  try {
    const bucket = storage.bucket(bucketName);
    const blob = bucket.file(file.originalname);
    const blobStream = blob.createWriteStream({
      resumable: false,
      metadata: {
        contentType: file.mimetype,
      }
    });

    blobStream.on('error', (error) => {
      console.error('Upload error:', error);
      res.status(500).send('Unable to upload image');
    });

    blobStream.on('finish', async () => {
        const processedImageUrl = await pollForProcessedImage(file.originalname, storage);
  
        res.status(200).json({
          message: 'File uploaded successfully',
          processedImageUrl: processedImageUrl,
        });
      });

    blobStream.end(file.buffer);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).send('Server error');
  }
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});


const pollForProcessedImage = async (fileName: string, storage: Storage, timeout: number = 30000) => {
    const start = Date.now();
    const processedBucket = storage.bucket('image-upload-processed-bucket');
  
    while (Date.now() - start < timeout) {
      try {
        const processedFile = processedBucket.file(fileName);
        const [exists] = await processedFile.exists();
  
        if (exists) {
            const [signedUrl] = await processedFile.getSignedUrl({
              version: 'v4',
              action: 'read',
              expires: Date.now() + 3600 * 1000, // 1 hour from now
            });
            return signedUrl;
          }
  
        await new Promise(resolve => setTimeout(resolve, 1000));
      } catch (error) {
        console.error('Error checking processed image:', error);
        throw new Error('Error during polling for processed image');
      }
    }
  
    throw new Error('Timed out waiting for processed image');
  };
