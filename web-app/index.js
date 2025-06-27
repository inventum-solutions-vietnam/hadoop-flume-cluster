import { Hono } from 'hono';
import fetch from 'node-fetch';
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { serve } from '@hono/node-server';
import { Buffer } from 'buffer';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = new Hono();

// Flume agent configuration
const FLUME_AGENT_URL = 'http://localhost:44444';
const FLUME_AGENT_HOST = process.env.FLUME_HOST || 'localhost';
const FLUME_AGENT_PORT = process.env.FLUME_PORT || '44444';

// Serve static files
app.get('/', async (c) => {
  try {
    const htmlPath = join(__dirname, 'public', 'index.html');
    const html = readFileSync(htmlPath, 'utf-8');
    return c.html(html);
  } catch (error) {
    console.error('Error serving index.html:', error);
    return c.text('Error loading page', 500);
  }
});

// Helper function to send data to Flume agent
async function sendToFlume(data, eventType = 'user_interaction') {
  try {
    const timestamp = new Date().toISOString();
    const eventPayload = {
      timestamp,
      eventType,
      data,
      source: 'web-app',
      userAgent: data.userAgent || 'unknown'
    };
    // Flume expects a JSON array of events with base64-encoded body
    const flumeEvent = [{
      headers: {
        eventType,
        source: 'web-app',
        userAgent: data.userAgent || 'unknown',
        timestamp
      },
      body: Buffer.from(JSON.stringify(eventPayload)).toString('base64')
    }];

    const response = await fetch(`http://${FLUME_AGENT_HOST}:${FLUME_AGENT_PORT}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(flumeEvent)
    });

    if (!response.ok) {
      throw new Error(`Flume agent responded with status: ${response.status}`);
    }

    console.log(`Successfully sent ${eventType} to Flume agent`);
    return { success: true, message: 'Data sent to Flume agent' };
  } catch (error) {
    console.error('Error sending data to Flume agent:', error);
    return { success: false, error: error.message };
  }
}

// API endpoint to handle form submissions
app.post('/api/submit', async (c) => {
  try {
    const body = await c.req.json();
    
    // Log the user interaction
    const logResult = await sendToFlume(body, 'user_interaction');
    
    if (logResult.success) {
      return c.json({ 
        success: true, 
        message: 'Form submitted successfully and logged to Flume',
        timestamp: new Date().toISOString()
      });
    } else {
      return c.json({ 
        success: false, 
        message: 'Form submitted but failed to log to Flume',
        error: logResult.error 
      }, 500);
    }
  } catch (error) {
    console.error('Error processing form submission:', error);
    return c.json({ 
      success: false, 
      message: 'Error processing form submission',
      error: error.message 
    }, 500);
  }
});

// API endpoint to send backend logs
app.post('/api/log', async (c) => {
  try {
    const body = await c.req.json();
    
    // Send backend log to Flume
    const logResult = await sendToFlume(body, 'backend_log');
    
    if (logResult.success) {
      return c.json({ 
        success: true, 
        message: 'Log sent to Flume agent',
        timestamp: new Date().toISOString()
      });
    } else {
      return c.json({ 
        success: false, 
        message: 'Failed to send log to Flume',
        error: logResult.error 
      }, 500);
    }
  } catch (error) {
    console.error('Error sending log:', error);
    return c.json({ 
      success: false, 
      message: 'Error sending log',
      error: error.message 
    }, 500);
  }
});

// Health check endpoint
app.get('/api/health', (c) => {
  return c.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    flumeAgent: `${FLUME_AGENT_HOST}:${FLUME_AGENT_PORT}`
  });
});

// Test endpoint to send a sample log
app.post('/api/test-log', async (c) => {
  try {
    const testData = {
      level: 'INFO',
      message: 'Test log message from web app',
      component: 'test-endpoint',
      userAgent: c.req.header('User-Agent') || 'unknown'
    };
    
    const logResult = await sendToFlume(testData, 'test_log');
    
    return c.json({
      success: logResult.success,
      message: logResult.success ? 'Test log sent successfully' : 'Failed to send test log',
      error: logResult.error
    });
  } catch (error) {
    return c.json({ 
      success: false, 
      message: 'Error sending test log',
      error: error.message 
    }, 500);
  }
});

const port = process.env.PORT || 3000;
console.log(`🚀 Web app starting on port ${port}`);
console.log(`📊 Flume agent configured at ${FLUME_AGENT_HOST}:${FLUME_AGENT_PORT}`);

serve({
  fetch: app.fetch,
  port
}); 