import express from 'express';
import multer from 'multer';
import { Storage } from '@google-cloud/storage';
import cors from 'cors';
import { Logging } from '@google-cloud/logging';
import { MetricServiceClient } from '@google-cloud/monitoring';

const app = express();
const port = process.env.PORT || 8080;
const logging = new Logging({projectId: 'gcp-project-444216'});
const log = logging.log('image-processing-log');

const metricClient = new MetricServiceClient();
const projectId = 'gcp-project-444216';

async function writeCustomLog(severity: string, message: string, metadata: any = {}) {
  const entry = log.entry({
    severity: severity,
    resource: {
      type: 'cloud_run_revision',
      labels: {
        service_name: 'backend-service',
        revision_name: process.env.K_REVISION || 'unknown'
      }
    },
    labels: {
      application: 'image-processor',
    },
    ...metadata
  }, message);

  await log.write(entry);
}

async function createCustomMetric(value: number, metricType: string, labels: Record<string, string> = {}) {
  const projectName = metricClient.projectPath(projectId);

  const timeSeriesData = {
    metric: {
      type: `custom.googleapis.com/${metricType}`,
      labels: labels,
    },
    resource: {
      type: 'generic_task',
      labels: {
        project_id: projectId,
        location: process.env.CLOUD_RUN_LOCATION || 'us-central1',
        namespace: 'image-processor',
        job: 'backend-service',
        task_id: process.env.K_REVISION || 'unknown'
      },
    },
    points: [
      {
        interval: {
          endTime: {
            seconds: Date.now() / 1000,
          },
        },
        value: {
          doubleValue: value,
        },
      },
    ],
  };

  const request = {
    name: projectName,
    timeSeries: [timeSeriesData],
  };

  try {
    await metricClient.createTimeSeries(request);
    console.log(`Metric ${metricType} created successfully`);
  } catch (error) {
    console.error('Error creating metric:', error);
    throw error;
  }
}

app.use(cors());

const storage = new Storage({
  keyFilename: './gcp-key.json', 
  projectId: 'gcp-project-444216'  
});

const bucketName = 'image-upload-original-bucket'; 
const upload = multer({ storage: multer.memoryStorage() });

app.post('/upload', upload.single('image'), async (req, res) => {
  const file = req.file;
  if (!file) {
    await writeCustomLog('ERROR', 'Upload attempt with no file');
    res.status(400).send('No file uploaded.');
    return;
  }

  try {
    await writeCustomLog('INFO', 'Starting image upload', {
      fileName: file.originalname,
      fileSize: file.size,
      mimeType: file.mimetype
    });

    await createCustomMetric(
      file.size, 
      'image_processing/upload_size_bytes',
      { filename: file.originalname }
    );

    const bucket = storage.bucket(bucketName);
    const blob = bucket.file(file.originalname);
    const blobStream = blob.createWriteStream({
      resumable: false,
      metadata: {
        contentType: file.mimetype,
      }
    });

    blobStream.on('error', async (error) => {
      await writeCustomLog('ERROR', 'Upload error', { error: error.message });
      console.error('Upload error:', error);
      res.status(500).send('Unable to upload image');
    });

    blobStream.on('finish', async () => {
      await writeCustomLog('INFO', 'Image upload successful', {
        fileName: file.originalname,
        bucket: bucketName
      });
      
      await createCustomMetric(1, 'image_processing/successful_uploads');
      
      const processedImageUrl = await pollForProcessedImage(file.originalname, storage);
  
      res.status(200).json({
        message: 'File uploaded successfully',
        processedImageUrl: processedImageUrl,
      });
    });

    blobStream.end(file.buffer);
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    await writeCustomLog('ERROR', 'Server error', { error: errorMessage });
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