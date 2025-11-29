# Image Optimization Pipeline - Architecture Diagram

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              USER / CLIENT                                   │
│                         (Web Browser / Mobile)                               │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │
                                 │ HTTPS
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         FRONTEND APPLICATION                                 │
│                    (S3 Static Website Hosting)                               │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Bucket: image-pipeline-frontend-sid                                 │   │
│  │  URL: http://image-pipeline-frontend-sid.s3-website.ap-south-1...   │   │
│  │                                                                       │   │
│  │  Files:                                                               │   │
│  │  • index.html  (UI Structure)                                        │   │
│  │  • styles.css  (Professional Dark Theme)                             │   │
│  │  • app.js      (Business Logic & API Integration)                    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │
                                 │ REST API Calls
                                 │ (POST, GET)
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          API GATEWAY (REST)                                  │
│                     ID: 38hmfok3uk | Region: ap-south-1                      │
│                                                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  Endpoint 1: POST /generate-upload-url                                │  │
│  │  • Purpose: Generate pre-signed S3 upload URL                         │  │
│  │  • Request: { filename, contentType }                                 │  │
│  │  • Response: { uploadUrl, filename }                                  │  │
│  │  • CORS: Enabled                                                      │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                               │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  Endpoint 2: GET /processed-images/{filename}                         │  │
│  │  • Purpose: Get pre-signed download URLs                              │  │
│  │  • Request: Path parameter (filename)                                 │  │
│  │  • Response: { "1080p": url, "720p": url, "480p": url }              │  │
│  │  • CORS: Enabled                                                      │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
└────────────┬──────────────────────────────────┬─────────────────────────────┘
             │                                  │
             │ Invoke                           │ Invoke
             │                                  │
             ▼                                  ▼
┌──────────────────────────┐      ┌──────────────────────────────────────────┐
│  Lambda Function 1       │      │  Lambda Function 2                       │
│  generate-upload-url     │      │  get-processed-images                    │
│  (Siddhant)              │      │  (Siddhant)                              │
│                          │      │                                          │
│  • Runtime: Python 3.11  │      │  • Runtime: Python 3.11                  │
│  • Memory: 128 MB        │      │  • Memory: 128 MB                        │
│  • Timeout: 10s          │      │  • Timeout: 10s                          │
│                          │      │                                          │
│  Function:               │      │  Function:                               │
│  1. Validate request     │      │  1. Receive filename                     │
│  2. Generate UUID        │      │  2. Check if files exist                 │
│  3. Create pre-signed    │      │  3. Generate pre-signed                  │
│     S3 upload URL        │      │     download URLs (3)                    │
│  4. Return URL           │      │  4. Return URLs                          │
└──────────────────────────┘      └──────────────────────────────────────────┘
             │                                  │
             │ Generate                         │ Generate
             │ Pre-signed URL                   │ Pre-signed URLs
             │                                  │
             ▼                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          AMAZON S3 STORAGE                                   │
│                                                                               │
│  ┌────────────────────────────────┐    ┌────────────────────────────────┐  │
│  │  INPUT BUCKET                  │    │  OUTPUT BUCKET                 │  │
│  │  image-pipeline-input-sid      │    │  image-pipeline-output-sid     │  │
│  │                                │    │                                │  │
│  │  • Stores original images      │    │  • Stores processed images     │  │
│  │  • Receives uploads via        │    │  • Organized by resolution:    │  │
│  │    pre-signed URLs             │    │    - /1080p/                   │  │
│  │  • Triggers Lambda on upload   │    │    - /720p/                    │  │
│  │  • CORS: Enabled for PUT       │    │    - /480p/                    │  │
│  │                                │    │  • CORS: Enabled for GET       │  │
│  └────────────────┬───────────────┘    └────────────────────────────────┘  │
│                   │                                    ▲                     │
│                   │ S3 Event                           │                     │
│                   │ Notification                       │                     │
│                   │ (ObjectCreated:*)                  │                     │
│                   │                                    │                     │
│                   ▼                                    │                     │
│  ┌────────────────────────────────────────────────────┴──────────────────┐ │
│  │              Lambda Function 3 (Image Processor)                       │ │
│  │              ImageProcessorLambda-Shivam                               │ │
│  │              (Shivam - Fixed by Anshuman)                              │ │
│  │                                                                         │ │
│  │  • Runtime: Python 3.11                                                │ │
│  │  • Memory: 1024 MB                                                     │ │
│  │  • Timeout: 59 seconds                                                 │ │
│  │  • Layer: Pillow (PIL) for image processing                           │ │
│  │                                                                         │ │
│  │  Processing Steps:                                                     │ │
│  │  1. Triggered by S3 event                                              │ │
│  │  2. Download original image from input bucket                          │ │
│  │  3. Open image with PIL                                                │ │
│  │  4. Convert RGBA → RGB (if needed) [Bug Fix by Anshuman]              │ │
│  │  5. Resize to 3 resolutions:                                           │ │
│  │     • 1080p (1920x1080)                                                │ │
│  │     • 720p  (1280x720)                                                 │ │
│  │     • 480p  (854x480)                                                  │ │
│  │  6. Compress with quality 85                                           │ │
│  │  7. Save as JPEG                                                       │ │
│  │  8. Upload to output bucket                                            │ │
│  │  9. Return metadata (compression ratio, processing time)               │ │
│  │                                                                         │ │
│  │  Environment Variables:                                                │ │
│  │  • OUTPUT_BUCKET: image-pipeline-output-sid                            │ │
│  │  • COMPRESSION_QUALITY: 85                                             │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                 │
                                 │ Logs & Metrics
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        AWS CLOUDWATCH                                        │
│                                                                               │
│  • Lambda Execution Logs                                                     │
│  • Processing Time Metrics                                                   │
│  • Error Tracking                                                            │
│  • Performance Monitoring                                                    │
│                                                                               │
│  Log Group: /aws/lambda/ImageProcessorLambda-Shivam                          │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                          IAM ROLES & PERMISSIONS                             │
│                                                                               │
│  Role: Lambda-Image-Processing-Role                                          │
│  ARN: arn:aws:iam::264449293739:role/Lambda-Image-Processing-Role           │
│                                                                               │
│  Permissions:                                                                │
│  • S3:GetObject (input bucket)                                               │
│  • S3:PutObject (output bucket)                                              │
│  • CloudWatch:PutMetricData                                                  │
│  • Logs:CreateLogGroup, CreateLogStream, PutLogEvents                        │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Diagram

### Upload Flow

```
┌──────┐
│ User │
└───┬──┘
    │
    │ 1. Select Image
    ▼
┌────────────┐
│  Frontend  │
└─────┬──────┘
      │
      │ 2. POST /generate-upload-url
      │    { filename, contentType }
      ▼
┌──────────────┐
│ API Gateway  │
└──────┬───────┘
       │
       │ 3. Invoke Lambda
       ▼
┌────────────────────┐
│ generate-upload-   │
│ url Lambda         │
└─────┬──────────────┘
      │
      │ 4. Generate Pre-signed URL
      │    (15 min expiry)
      ▼
┌──────────────┐
│ API Gateway  │
└──────┬───────┘
       │
       │ 5. Return { uploadUrl, filename }
       ▼
┌────────────┐
│  Frontend  │
└─────┬──────┘
      │
      │ 6. PUT request to pre-signed URL
      │    (Direct upload, no API Gateway)
      ▼
┌─────────────────┐
│ S3 Input Bucket │
└─────────────────┘
```

### Processing Flow

```
┌─────────────────┐
│ S3 Input Bucket │
└────────┬────────┘
         │
         │ S3 Event: ObjectCreated:*
         │ (Automatic Trigger)
         ▼
┌──────────────────────┐
│ Image Processor      │
│ Lambda               │
│                      │
│ 1. Download image    │
│ 2. Open with PIL     │
│ 3. Convert RGBA→RGB  │
│ 4. Resize (3x)       │
│ 5. Compress          │
│ 6. Save as JPEG      │
│ 7. Upload (3x)       │
└──────────┬───────────┘
           │
           │ Upload processed images
           ▼
┌──────────────────┐
│ S3 Output Bucket │
│                  │
│ /1080p/image.jpg │
│ /720p/image.jpg  │
│ /480p/image.jpg  │
└──────────────────┘
```

### Download Flow

```
┌──────┐
│ User │
└───┬──┘
    │
    │ Wait 5-10 seconds
    ▼
┌────────────┐
│  Frontend  │
└─────┬──────┘
      │
      │ GET /processed-images/{filename}
      ▼
┌──────────────┐
│ API Gateway  │
└──────┬───────┘
       │
       │ Invoke Lambda
       ▼
┌────────────────────┐
│ get-processed-     │
│ images Lambda      │
└─────┬──────────────┘
      │
      │ Generate Pre-signed URLs (3)
      │ (1 hour expiry)
      ▼
┌──────────────┐
│ API Gateway  │
└──────┬───────┘
       │
       │ Return { "1080p": url, "720p": url, "480p": url }
       ▼
┌────────────┐
│  Frontend  │
└─────┬──────┘
      │
      │ Display download buttons
      ▼
┌──────┐
│ User │ Click download
└───┬──┘
    │
    │ Direct download from S3
    │ (No API Gateway)
    ▼
┌──────────────────┐
│ S3 Output Bucket │
└──────────────────┘
```

---

## Component Details

### 1. Frontend (S3 Static Website)
**Owner:** Anshuman  
**Technology:** HTML5, CSS3, JavaScript (Vanilla)  
**Hosting:** Amazon S3 Static Website Hosting  
**URL:** http://image-pipeline-frontend-sid.s3-website.ap-south-1.amazonaws.com

**Features:**
- Drag-and-drop upload
- File validation (type, size)
- Progress indication
- Results display
- Error handling
- Responsive design

---

### 2. API Gateway
**Owner:** Anshuman  
**Type:** REST API  
**ID:** 38hmfok3uk  
**Region:** ap-south-1  
**Stage:** prod

**Endpoints:**
1. `POST /generate-upload-url`
   - Generates pre-signed S3 upload URL
   - Expiry: 15 minutes
   
2. `GET /processed-images/{filename}`
   - Returns pre-signed download URLs
   - Expiry: 1 hour

**Features:**
- CORS enabled
- AWS_PROXY integration
- Lambda invocation permissions

---

### 3. Lambda Functions

#### 3.1 generate-upload-url
**Owner:** Siddhant  
**Runtime:** Python 3.11  
**Memory:** 128 MB  
**Timeout:** 10 seconds

**Purpose:** Generate secure pre-signed URLs for S3 uploads

**Process:**
1. Receive filename and content type
2. Generate UUID prefix
3. Create pre-signed S3 PUT URL
4. Return URL with 15-minute expiry

---

#### 3.2 get-processed-images
**Owner:** Siddhant  
**Runtime:** Python 3.11  
**Memory:** 128 MB  
**Timeout:** 10 seconds

**Purpose:** Generate pre-signed URLs for downloading processed images

**Process:**
1. Receive filename
2. Check if processed files exist
3. Generate 3 pre-signed GET URLs (1080p, 720p, 480p)
4. Return URLs with 1-hour expiry

---

#### 3.3 ImageProcessorLambda-Shivam
**Owner:** Shivam (Fixed by Anshuman)  
**Runtime:** Python 3.11  
**Memory:** 1024 MB  
**Timeout:** 59 seconds  
**Layer:** Pillow 12.0.0

**Purpose:** Process images (resize and compress)

**Process:**
1. Triggered by S3 ObjectCreated event
2. Download original image
3. Open with PIL (Pillow)
4. **Convert RGBA to RGB** (Bug fix by Anshuman)
5. Resize to 3 resolutions maintaining aspect ratio
6. Compress with quality 85
7. Save as JPEG
8. Upload to output bucket
9. Log metrics (time, compression ratio)

**Resolutions:**
- 1080p: 1920x1080 (Full HD)
- 720p: 1280x720 (HD)
- 480p: 854x480 (SD)

**Environment Variables:**
- `OUTPUT_BUCKET`: image-pipeline-output-sid
- `COMPRESSION_QUALITY`: 85

---

### 4. S3 Buckets

#### 4.1 Input Bucket
**Name:** image-pipeline-input-sid  
**Owner:** Siddhant  
**Purpose:** Store original uploaded images

**Configuration:**
- CORS: Enabled for PUT operations
- Event Notification: Triggers Lambda on ObjectCreated
- Encryption: AES-256

---

#### 4.2 Output Bucket
**Name:** image-pipeline-output-sid  
**Owner:** Siddhant  
**Purpose:** Store processed images

**Configuration:**
- CORS: Enabled for GET operations
- Folder Structure:
  - `/1080p/` - Full HD images
  - `/720p/` - HD images
  - `/480p/` - SD images
- Encryption: AES-256

---

#### 4.3 Frontend Bucket
**Name:** image-pipeline-frontend-sid  
**Owner:** Siddhant  
**Purpose:** Host static website

**Configuration:**
- Static Website Hosting: Enabled
- Index Document: index.html
- Public Access: Enabled for website hosting

---

### 5. IAM Role
**Name:** Lambda-Image-Processing-Role  
**Owner:** Siddhant  
**ARN:** arn:aws:iam::264449293739:role/Lambda-Image-Processing-Role

**Permissions:**
- S3:GetObject (input bucket)
- S3:PutObject (output bucket)
- CloudWatch:PutMetricData
- Logs:CreateLogGroup
- Logs:CreateLogStream
- Logs:PutLogEvents

---

### 6. CloudWatch
**Purpose:** Monitoring and logging

**Log Groups:**
- `/aws/lambda/ImageProcessorLambda-Shivam`
- `/aws/lambda/generate-upload-url`
- `/aws/lambda/get-processed-images`

**Metrics:**
- Lambda execution duration
- Memory usage
- Error rates
- Processing time

---

## Security Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SECURITY LAYERS                           │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  1. NO AWS CREDENTIALS IN FRONTEND                           │
│     • Pre-signed URLs for all S3 operations                  │
│     • Time-limited access (15 min upload, 1 hour download)   │
│                                                               │
│  2. IAM LEAST PRIVILEGE                                      │
│     • Lambda role has minimal required permissions           │
│     • No public S3 bucket access                             │
│                                                               │
│  3. CORS CONFIGURATION                                       │
│     • Specific methods allowed (PUT for input, GET for output)│
│     • Origin validation                                      │
│                                                               │
│  4. INPUT VALIDATION                                         │
│     • File type validation (images only)                     │
│     • File size limit (50 MB)                                │
│     • Filename sanitization                                  │
│                                                               │
│  5. ENCRYPTION                                               │
│     • S3 buckets encrypted (AES-256)                         │
│     • HTTPS for all API calls                                │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Performance Metrics

### Processing Performance
- **Small images (< 1 MB):** 1-2 seconds
- **Medium images (1-10 MB):** 2-4 seconds
- **Large images (10-50 MB):** 3-6 seconds

### Compression Results
- **Average compression:** 90-98% file size reduction
- **Quality:** Minimal visible degradation
- **Format:** JPEG (quality 85)

### Example Results
- 7 MB → 677 KB (90% reduction, 1.83s)
- 14.4 MB → 222 KB (98% reduction, ~2.5s)
- 175 KB PNG → 90 KB (49% reduction, 0.63s)

---

## Cost Analysis

### AWS Free Tier Usage
- **Lambda:** 1M requests + 400,000 GB-seconds/month
- **S3:** 5 GB storage + 20,000 GET + 2,000 PUT requests
- **API Gateway:** 1M API calls/month (12 months)

### Current Usage
- **Lambda:** ~10 invocations/day
- **S3:** ~100 MB storage
- **API Gateway:** ~20 requests/day
- **Total Cost:** $0.00 (within Free Tier)

---

## Team Contributions

### Anshuman (Team Lead + Frontend)
- ✅ API Gateway setup (2 endpoints)
- ✅ Frontend development (HTML, CSS, JS)
- ✅ Complete integration
- ✅ Bug fix (PNG transparency in Lambda)
- ✅ Testing and documentation

### Shivam (Backend)
- ✅ Image processing Lambda function
- ✅ Resize and compression logic
- ✅ PIL/Pillow integration

### Siddhant (Infrastructure)
- ✅ S3 buckets (3 buckets)
- ✅ IAM roles and permissions
- ✅ Pre-signed URL Lambda functions (2)
- ✅ S3 event trigger configuration
- ✅ CORS configuration

---

## Technology Stack

### Frontend
- HTML5
- CSS3 (Dark Professional Theme)
- JavaScript (ES6+)
- Fetch API

### Backend
- AWS Lambda (Python 3.11)
- Pillow (PIL) for image processing
- Boto3 (AWS SDK)

### Infrastructure
- Amazon S3
- AWS API Gateway
- AWS IAM
- AWS CloudWatch

### Tools
- AWS CLI
- Git
- VS Code

---

**Architecture Version:** 1.0  
**Last Updated:** November 29, 2025  
**Status:** Production Ready ✅
