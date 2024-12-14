const { Storage } = require('@google-cloud/storage');
const sharp = require('sharp');

const storage = new Storage();
const originalBucket = 'image-upload-original-bucket';
const processedBucket = 'image-upload-processed-bucket';

exports.processImage = async (pubSubEvent) => {
  try {
    const message = Buffer.from(pubSubEvent.data, 'base64').toString();
    const eventData = JSON.parse(message);
    const file = eventData.name;

    const originalFile = storage.bucket(originalBucket).file(file);
    const processedFile = storage.bucket(processedBucket).file(file);

    console.log(`Processing file: ${file}`);

    const [buffer] = await originalFile.download();

    const transformedBuffer = await sharp(buffer)
      .resize(300, 300)
      .threshold(128)
      .toBuffer();

    await processedFile.save(transformedBuffer);

    console.log(`Processed image saved to: ${processedBucket}/${file}`);
  } catch (error) {
    console.error(`Error processing image:`, error);
    throw new Error(`Failed to process image: ${error.message}`);
  }
};
