# Image Optimization Pipeline

A serverless image processing pipeline built on AWS that automatically optimizes and resizes high-resolution images for web use.

![Status](https://img.shields.io/badge/status-production-green)
![AWS](https://img.shields.io/badge/AWS-Lambda%20%7C%20S3%20%7C%20API%20Gateway-orange)
![Python](https://img.shields.io/badge/python-3.11-blue)




https://github.com/user-attachments/assets/285b102d-56ad-4823-ab6a-4d55efba47cd


## 🎯 Overview

This project provides an automated solution for image optimization, perfect for CMS systems, portfolios, blogs, and e-commerce platforms. Upload high-resolution images and receive optimized versions in multiple resolutions (1080p, 720p, 480p) with 90-98% file size reduction.

## ✨ Features

- **Automated Processing**: Upload triggers automatic resizing and compression
- **Multiple Resolutions**: Generates 1080p, 720p, and 480p versions
- **High Compression**: 90-98% file size reduction with minimal quality loss
- **Fast Processing**: 0.6-6 seconds depending on image size
- **Secure**: Pre-signed URLs, no exposed AWS credentials
- **Professional UI**: Modern dark theme with drag-and-drop upload
- **Cost-Effective**: $0 cost (within AWS Free Tier)

## 🏗️ Architecture

<img width="1439" height="806" alt="IOP" src="https://github.com/user-attachments/assets/95ab1aab-5a3b-4fa9-9ac6-7663ea5163ca" />


## 🚀 Live Demo

http://image-pipeline-frontend-anshuman.s3-website.ap-south-1.amazonaws.com/

## 📊 Performance

- **Compression**: 90-98% file size reduction
- **Processing Time**: 0.6-6 seconds
- **Quality**: Minimal visible degradation
- **Formats Supported**: JPEG, PNG, BMP, TIFF, GIF

### Example Results

| Original Size | Processed Size | Reduction | Time |
|---------------|----------------|-----------|------|
| 6.7 MB | 677 KB | 90% | 1.83s |
| 14.4 MB | 222 KB | 98% | 2.5s |
| 175 KB | 90 KB | 49% | 0.63s |

## 🛠️ Technology Stack

### Frontend
- HTML5, CSS3, JavaScript (Vanilla)
- S3 Static Website Hosting

### Backend
- AWS Lambda (Python 3.11)
- Pillow (PIL) for image processing
- Boto3 (AWS SDK)

### Infrastructure
- Amazon S3 (Storage)
- AWS API Gateway (REST API)
- AWS IAM (Security)
- AWS CloudWatch (Monitoring)

## 📁 Project Structure

```
image-optimization-pipeline/
├── frontend/                    # Web application
│   ├── index.html              # Main HTML
│   ├── styles.css              # Professional dark theme
│   └── app.js                  # Frontend logic
├── lambda-functions/           # AWS Lambda functions
│   ├── image-processor/        # Main processing Lambda
│   ├── generate-upload-url/    # Pre-signed URL generator
│   └── get-processed-images/   # Download URL generator
├── docs/                       # Documentation
│   ├── architecture/           # System design
│   ├── implementation/         # Implementation details
│   └── testing/                # Test results
└── scripts/                    # Deployment scripts
```

## 🚀 Deployment

### Prerequisites
- AWS Account
- AWS CLI configured
- Python 3.11

### Quick Start

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/image-optimization-pipeline.git
cd image-optimization-pipeline
```

2. **Deploy Lambda Functions**
```bash
# Deploy image processor
cd lambda-functions/image-processor
zip -r function.zip .
aws lambda update-function-code --function-name ImageProcessorLambda --zip-file fileb://function.zip

# Deploy other Lambda functions similarly
```

3. **Deploy Frontend**
```bash
cd frontend
aws s3 sync . s3://your-frontend-bucket/
```

4. **Configure API Gateway**
- See [Implementation Guide](docs/implementation/IMPLEMENTATION_LOG.md)

## 📖 Documentation

- [Architecture Diagram](docs/architecture/ARCHITECTURE_DIAGRAM.md) - System design and data flow
- [Implementation Log](docs/implementation/IMPLEMENTATION_LOG.md) - Step-by-step implementation
- [Presentation Document](docs/implementation/PRESENTATION_DOCUMENT.md) - Complete project overview
- [Bug Fix Documentation](docs/implementation/BUG_FIX_IMPLEMENTATION.md) - PNG transparency fix
- [Testing Results](docs/testing/Before_After_Comparison_Report.md) - Performance analysis
- [Test Data](docs/testing/Complete_Testing_Results.md) - Detailed test results

## 🔒 Security

- IAM roles with least-privilege access
- Pre-signed URLs with time expiration
- No AWS credentials in frontend
- CORS configuration
- S3 bucket encryption (AES-256)

## 💰 Cost Analysis

**Current Usage**: $0.00 (within AWS Free Tier)

**AWS Free Tier Limits**:
- Lambda: 1M requests + 400,000 GB-seconds/month
- S3: 5 GB storage + 20,000 GET + 2,000 PUT requests
- API Gateway: 1M API calls/month

**Projected Cost** (10,000 images/month): ~$3.15/month

## 👥 Team

- **Anshuman** - Team Lead + Frontend Developer
  - API Gateway setup
  - Frontend development
  - Integration and testing
  - Bug fix (PNG transparency)
  
- **Shivam** - Backend Developer
  - Image processing Lambda
  - Resize and compression logic
  
- **Siddhant** - Infrastructure Specialist
  - S3 buckets configuration
  - IAM roles and permissions
  - Pre-signed URL Lambda functions

## 🐛 Known Issues

- None currently

## 🔄 Future Enhancements

- [ ] WebP format conversion
- [ ] Watermarking support
- [ ] Custom resolution selection
- [ ] Batch processing
- [ ] AWS Cognito authentication
- [ ] Real-time progress updates

## 📝 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- AWS for providing excellent cloud services
- Pillow library for image processing capabilities
- The open-source community

## 📧 Contact

For questions or feedback, please open an issue on GitHub.

---

**Built with ❤️ using AWS Serverless Architecture**
