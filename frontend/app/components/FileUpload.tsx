'use client';

import React, { useState } from 'react';

const UploadForm = () => {
  const [file, setFile] = useState<File | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [processedImageUrl, setProcessedImageUrl] = useState<string | null>(
    null
  );

  const handleUpload = async () => {
    if (file) {
      setIsLoading(true);
      try {
        const formData = new FormData();
        formData.append('image', file);
        const response = await fetch(
          'https://backend-service-lwwdaqswoa-uc.a.run.app/upload',
          {
            method: 'POST',
            body: formData,
          }
        );
        const data = await response.json();
        setProcessedImageUrl(data.processedImageUrl);
      } catch (error) {
        console.error('Upload failed:', error);
      } finally {
        setIsLoading(false);
      }
    }
  };

  return (
    <div className="max-w-md mx-auto p-6 bg-white rounded-lg shadow-md">
      <h2 className="text-2xl font-bold mb-4 text-gray-800">
        Upload Your Image
      </h2>
      <p className="text-gray-600 mb-4">Select an image file to upload</p>

      <div className="space-y-4">
        <input
          type="file"
          onChange={(e) => setFile(e.target.files?.[0] || null)}
          className="block w-full text-sm text-gray-500
            file:mr-4 file:py-2 file:px-4
            file:rounded-md file:border-0
            file:text-sm file:font-semibold
            file:bg-blue-50 file:text-blue-700
            hover:file:bg-blue-100"
        />
        <button
          onClick={handleUpload}
          disabled={isLoading}
          className="w-full py-2 px-4 bg-blue-600 text-white font-semibold rounded-lg hover:bg-blue-700 transition duration-200 disabled:bg-blue-400 disabled:cursor-not-allowed"
        >
          {isLoading ? 'Uploading...' : 'Upload Image'}
        </button>
        {file && (
          <p className="text-sm text-gray-600">Selected file: {file.name}</p>
        )}

        {processedImageUrl && (
          <div className="mt-4">
            <p className="text-sm text-gray-600 mb-2">Processed Image:</p>
            <img
              src={processedImageUrl}
              alt="Processed"
              className="max-w-full rounded-lg"
            />
          </div>
        )}
      </div>
    </div>
  );
};

export default UploadForm;
