# Frontend Application

Professional web interface for the Image Optimization Pipeline.

## Features

- Drag-and-drop image upload
- File validation (type and size)
- Progress indication
- Processing status display
- Download buttons for all resolutions
- Error handling
- Responsive design (mobile-friendly)
- Professional dark theme

## Technology

- HTML5
- CSS3 (Dark professional theme)
- JavaScript (Vanilla ES6+)
- Fetch API for HTTP requests

## Deployment

### To S3 Static Website

```bash
aws s3 sync . s3://image-pipeline-frontend-sid/
```

### Local Development

Simply open `index.html` in a web browser. For API calls to work, you'll need to update the `API_BASE_URL` in `app.js`.

## Configuration

Edit `app.js` and update:

```javascript
const API_BASE_URL = 'https://your-api-gateway-url/prod';
```

## File Structure

- `index.html` - Main HTML structure
- `styles.css` - Professional dark theme styling
- `app.js` - Frontend logic and API integration

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)
