# Flume Web App

A simple Hono.js web application that captures user interactions and backend logs, then sends them to an Apache Flume agent via HTTP for storage in HDFS.

## Features

- 📝 **User Interaction Form**: Collect user data and interactions
- 📊 **Backend Logging**: Send application logs to Flume agent
- 🔍 **Health Monitoring**: Check system and Flume agent status
- 🎨 **Modern UI**: Beautiful, responsive interface
- 🔄 **Real-time Feedback**: Live status updates and loading indicators

## Prerequisites

- Node.js 18+ 
- Running Hadoop cluster with Flume agent
- Docker (if using the provided Hadoop cluster)

## Quick Start

### 1. Install Dependencies

```bash
cd web-app
npm install
```

### 2. Start the Web Application

```bash
# Development mode with auto-reload
npm run dev

# Production mode
npm start
```

The web app will be available at `http://localhost:3000`

### 3. Ensure Flume Agent is Running

Make sure your Flume agent is running and accessible. If using the provided Docker setup:

```bash
# From the root directory
./start-cluster.sh
```

## Configuration

### Environment Variables

You can configure the Flume agent connection using environment variables:

```bash
# Flume agent host (default: localhost)
export FLUME_HOST=your-flume-host

# Flume agent port (default: 44444)
export FLUME_PORT=44444

# Web app port (default: 3000)
export PORT=3000
```

### Flume Agent Integration

The web app sends data to the Flume agent in the following format:

```json
{
  "timestamp": "2024-01-15T10:30:00.000Z",
  "eventType": "user_interaction|backend_log|test_log",
  "data": {
    // Form data or log data
  },
  "source": "web-app",
  "userAgent": "Mozilla/5.0..."
}
```

## API Endpoints

### POST `/api/submit`
Submit user interaction form data to Flume agent.

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "action": "form_submit",
  "message": "User submitted contact form",
  "priority": "medium"
}
```

### POST `/api/log`
Send backend log messages to Flume agent.

**Request Body:**
```json
{
  "level": "INFO",
  "message": "Application started",
  "component": "server",
  "details": {}
}
```

### POST `/api/test-log`
Send a test log message to verify Flume agent connectivity.

### GET `/api/health`
Check the health status of the web app and Flume agent connection.

## Usage Examples

### 1. Submit User Interaction

Fill out the form on the web interface and click "Submit Form". The data will be sent to the Flume agent and stored in HDFS.

### 2. Send Backend Logs

Use the "Test Backend Log" button to send a test log message, or integrate the `/api/log` endpoint into your application:

```javascript
// Example: Send application error log
fetch('/api/log', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    level: 'ERROR',
    message: 'Database connection failed',
    component: 'database',
    details: { errorCode: 'DB001' }
  })
});
```

### 3. Monitor Health

Click "Check Health" to verify the connection to the Flume agent and overall system status.

## Data Flow

1. **User Interaction**: User fills out form → Data sent to `/api/submit` → Forwarded to Flume agent
2. **Backend Logging**: Application logs → Sent to `/api/log` → Forwarded to Flume agent  
3. **Flume Processing**: Flume agent receives data → Stores in HDFS with timestamp-based partitioning
4. **Data Storage**: Events stored in `hdfs://hadoop-master:9000/flume/events/YYYY-MM-DD/HH/`

## Troubleshooting

### Flume Agent Connection Issues

1. **Check if Flume agent is running:**
   ```bash
   curl http://localhost:44444
   ```

2. **Verify Docker containers:**
   ```bash
   docker ps | grep flume
   ```

3. **Check Flume logs:**
   ```bash
   docker logs flume-agent
   ```

### Web App Issues

1. **Check web app logs:**
   ```bash
   npm start
   ```

2. **Verify port availability:**
   ```bash
   lsof -i :3000
   ```

3. **Test API endpoints:**
   ```bash
   curl http://localhost:3000/api/health
   ```

## Development

### Project Structure

```
web-app/
├── index.js          # Main Hono.js application
├── package.json      # Dependencies and scripts
├── public/
│   └── index.html    # Web interface
└── README.md         # This file
```

### Adding New Features

1. **New API Endpoints**: Add routes in `index.js`
2. **UI Changes**: Modify `public/index.html`
3. **Flume Integration**: Update the `sendToFlume()` function

### Testing

```bash
# Test the web app locally
npm run dev

# Test Flume integration
curl -X POST http://localhost:3000/api/test-log

# Test form submission
curl -X POST http://localhost:3000/api/submit \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com","action":"test"}'
```

## Integration with Hadoop Cluster

This web app is designed to work with the provided Hadoop cluster Docker setup. The Flume agent is configured to:

- Accept HTTP requests on port 44444
- Store events in HDFS with daily/hourly partitioning
- Use memory channel for buffering
- Write events as text files

## License

MIT License - see the main project README for details. 