// API Configuration
const API_BASE_URL = 'https://38hmfok3uk.execute-api.ap-south-1.amazonaws.com/prod';

// DOM Elements
const uploadArea = document.getElementById('upload-area');
const fileInput = document.getElementById('file-input');
const browseBtn = document.getElementById('browse-btn');
const fileInfo = document.getElementById('file-info');
const uploadBtn = document.getElementById('upload-btn');
const cancelBtn = document.getElementById('cancel-btn');

const uploadSection = document.getElementById('upload-section');
const processingSection = document.getElementById('processing-section');
const resultsSection = document.getElementById('results-section');
const errorSection = document.getElementById('error-section');

const processingMessage = document.getElementById('processing-message');
const progressBar = document.getElementById('progress');

let selectedFile = null;

// Event Listeners
browseBtn.addEventListener('click', () => fileInput.click());
fileInput.addEventListener('change', handleFileSelect);
uploadBtn.addEventListener('click', handleUpload);
cancelBtn.addEventListener('click', resetUpload);
document.getElementById('upload-another-btn').addEventListener('click', resetUpload);
document.getElementById('try-again-btn').addEventListener('click', resetUpload);

// Drag and Drop
uploadArea.addEventListener('dragover', (e) => {
    e.preventDefault();
    uploadArea.classList.add('drag-over');
});

uploadArea.addEventListener('dragleave', () => {
    uploadArea.classList.remove('drag-over');
});

uploadArea.addEventListener('drop', (e) => {
    e.preventDefault();
    uploadArea.classList.remove('drag-over');
    const files = e.dataTransfer.files;
    if (files.length > 0) {
        handleFile(files[0]);
    }
});

uploadArea.addEventListener('click', () => fileInput.click());

// File Selection Handler
function handleFileSelect(e) {
    const file = e.target.files[0];
    if (file) {
        handleFile(file);
    }
}

function handleFile(file) {
    // Validate file type
    if (!file.type.startsWith('image/')) {
        showError('Please select a valid image file (JPEG, PNG, BMP, etc.)');
        return;
    }

    // Validate file size (max 50MB)
    const maxSize = 50 * 1024 * 1024; // 50MB
    if (file.size > maxSize) {
        showError('File size must be less than 50MB');
        return;
    }

    selectedFile = file;
    
    // Display file info
    document.getElementById('filename').textContent = file.name;
    document.getElementById('filesize').textContent = formatFileSize(file.size);
    
    uploadArea.style.display = 'none';
    fileInfo.classList.remove('hidden');
}

// Upload and Process Handler
async function handleUpload() {
    if (!selectedFile) return;

    try {
        // Show processing section
        uploadSection.classList.add('hidden');
        processingSection.classList.remove('hidden');
        errorSection.classList.add('hidden');
        
        // Step 1: Get upload URL
        processingMessage.textContent = 'Getting upload URL...';
        progressBar.style.width = '20%';
        
        const uploadData = await getUploadUrl(selectedFile.name, selectedFile.type);
        const uploadUrl = uploadData.uploadUrl;
        const actualFilename = uploadData.filename; // This includes UUID prefix
        
        // Step 2: Upload to S3
        processingMessage.textContent = 'Uploading image to S3...';
        progressBar.style.width = '40%';
        
        await uploadToS3(uploadUrl, selectedFile);
        
        // Step 3: Wait for processing
        processingMessage.textContent = 'Processing image (resizing and compressing)...';
        progressBar.style.width = '60%';
        
        // Wait based on file size
        const waitTime = calculateWaitTime(selectedFile.size);
        await sleep(waitTime);
        
        // Step 4: Get processed images (with retry logic)
        processingMessage.textContent = 'Retrieving processed images...';
        progressBar.style.width = '80%';
        
        let processedImages = null;
        let retries = 3;
        
        for (let i = 0; i < retries; i++) {
            try {
                processedImages = await getProcessedImages(actualFilename);
                break; // Success, exit retry loop
            } catch (error) {
                if (i < retries - 1) {
                    // Wait a bit longer and retry
                    processingMessage.textContent = `Still processing... (attempt ${i + 2}/${retries})`;
                    await sleep(3000);
                } else {
                    // Final retry failed
                    throw new Error('Processing is taking longer than expected. The image may have failed to process. Please try uploading a JPEG image instead of PNG.');
                }
            }
        }
        
        // Step 5: Display results
        progressBar.style.width = '100%';
        await sleep(500);
        
        displayResults(processedImages, selectedFile);
        
    } catch (error) {
        console.error('Error:', error);
        showError(error.message || 'An error occurred during processing. Please try again with a JPEG image.');
    }
}

// API Functions
async function getUploadUrl(filename, contentType) {
    const response = await fetch(`${API_BASE_URL}/generate-upload-url`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            filename: filename,
            contentType: contentType
        })
    });

    if (!response.ok) {
        throw new Error('Failed to get upload URL');
    }

    const data = await response.json();
    return data; // Return full response including filename with UUID
}

async function uploadToS3(uploadUrl, file) {
    const response = await fetch(uploadUrl, {
        method: 'PUT',
        headers: {
            'Content-Type': file.type
        },
        body: file
    });

    if (!response.ok) {
        throw new Error('Failed to upload image to S3');
    }
}

async function getProcessedImages(filename) {
    const response = await fetch(`${API_BASE_URL}/processed-images/${encodeURIComponent(filename)}`);

    if (!response.ok) {
        throw new Error('Failed to retrieve processed images');
    }

    const data = await response.json();
    return data;
}

// Display Results
function displayResults(processedImages, originalFile) {
    processingSection.classList.add('hidden');
    resultsSection.classList.remove('hidden');

    // Display original filename
    document.getElementById('original-filename').textContent = originalFile.name;

    // Note: Since we don't get processing time and compression ratio from the API response,
    // we'll estimate based on file size
    const estimatedTime = calculateWaitTime(originalFile.size) / 1000;
    document.getElementById('processing-time').textContent = `~${estimatedTime} seconds`;
    document.getElementById('compression-ratio').textContent = 'Optimized for web';

    // Set download links
    if (processedImages['1080p']) {
        document.getElementById('download-1080p').href = processedImages['1080p'];
        document.getElementById('size-1080p').textContent = '1080p Resolution';
    }

    if (processedImages['720p']) {
        document.getElementById('download-720p').href = processedImages['720p'];
        document.getElementById('size-720p').textContent = '720p Resolution';
    }

    if (processedImages['480p']) {
        document.getElementById('download-480p').href = processedImages['480p'];
        document.getElementById('size-480p').textContent = '480p Resolution';
    }
}

// Error Handler
function showError(message) {
    uploadSection.classList.add('hidden');
    processingSection.classList.add('hidden');
    resultsSection.classList.add('hidden');
    errorSection.classList.remove('hidden');
    
    document.getElementById('error-message').textContent = message;
}

// Reset Upload
function resetUpload() {
    selectedFile = null;
    fileInput.value = '';
    
    uploadSection.classList.remove('hidden');
    processingSection.classList.add('hidden');
    resultsSection.classList.add('hidden');
    errorSection.classList.add('hidden');
    
    uploadArea.style.display = 'block';
    fileInfo.classList.add('hidden');
    
    progressBar.style.width = '0%';
}

// Utility Functions
function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
}

function calculateWaitTime(fileSize) {
    // Based on testing results:
    // Small (< 1MB): 2 seconds
    // Medium (1-10MB): 4 seconds
    // Large (10-50MB): 6 seconds
    const mb = fileSize / (1024 * 1024);
    if (mb < 1) return 2000;
    if (mb < 10) return 4000;
    return 6000;
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

// Initialize
console.log('Image Optimization Pipeline initialized');
console.log('API Base URL:', API_BASE_URL);
