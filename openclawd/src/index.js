const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const compression = require('compression');
const { createLogger, format, transports } = require('winston');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

// Configuração
const PORT = process.env.PORT || 3000;
const LOG_PATH = process.env.ACTIVITY_LOG_PATH || '/logs/activity.log';
const LOG_LEVEL = process.env.LOG_LEVEL || 'info';

// Logger configurado
const logger = createLogger({
  level: LOG_LEVEL,
  format: format.combine(
    format.timestamp(),
    format.errors({ stack: true }),
    format.splat(),
    format.json()
  ),
  defaultMeta: { service: 'openclawd-app' },
  transports: [
    new transports.Console({
      format: format.combine(
        format.colorize(),
        format.simple()
      )
    }),
    new transports.File({ filename: '/logs/error.log', level: 'error' }),
    new transports.File({ filename: '/logs/combined.log' }),
    new transports.File({ filename: LOG_PATH })
  ]
});

// Sistema de rastreamento de atividades
class ActivityTracker {
  constructor() {
    this.activities = [];
    this.maxActivities = 1000;
  }

  log(type, description, metadata = {}) {
    const activity = {
      id: uuidv4(),
      type,
      description,
      metadata,
      timestamp: new Date().toISOString(),
      status: 'running'
    };

    this.activities.push(activity);
    if (this.activities.length > this.maxActivities) {
      this.activities.shift();
    }

    logger.info('Activity logged', activity);
    return activity;
  }

  update(activityId, status, result = {}) {
    const activity = this.activities.find(a => a.id === activityId);
    if (activity) {
      activity.status = status;
      activity.result = result;
      activity.completedAt = new Date().toISOString();
      logger.info('Activity updated', activity);
    }
    return activity;
  }

  getAll() {
    return this.activities;
  }

  getRecent(limit = 50) {
    return this.activities.slice(-limit);
  }

  getByStatus(status) {
    return this.activities.filter(a => a.status === status);
  }

  clear() {
    this.activities = [];
  }
}

const activityTracker = new ActivityTracker();

// Aplicação Express
const app = express();

// Middlewares de segurança
app.use(helmet());
app.use(cors());
app.use(compression());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Logging de requisições
app.use(morgan('combined', {
  stream: { write: message => logger.info(message.trim()) }
}));

// Middleware para rastrear todas as requisições
app.use((req, res, next) => {
  const activityId = activityTracker.log('http_request', `${req.method} ${req.path}`, {
    method: req.method,
    path: req.path,
    ip: req.ip,
    userAgent: req.get('user-agent')
  });

  res.on('finish', () => {
    activityTracker.update(activityId, 'completed', {
      statusCode: res.statusCode
    });
  });

  next();
});

// Rotas

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage()
  });
});

// Status da aplicação
app.get('/status', (req, res) => {
  res.json({
    status: 'running',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    activities: {
      total: activityTracker.activities.length,
      running: activityTracker.getByStatus('running').length,
      completed: activityTracker.getByStatus('completed').length,
      failed: activityTracker.getByStatus('failed').length
    }
  });
});

// API de atividades
app.get('/api/activities', (req, res) => {
  const limit = parseInt(req.query.limit) || 50;
  const status = req.query.status;

  let activities = status
    ? activityTracker.getByStatus(status)
    : activityTracker.getRecent(limit);

  res.json({
    success: true,
    count: activities.length,
    activities
  });
});

app.get('/api/activities/:id', (req, res) => {
  const activity = activityTracker.activities.find(a => a.id === req.params.id);
  if (activity) {
    res.json({ success: true, activity });
  } else {
    res.status(404).json({ success: false, error: 'Activity not found' });
  }
});

// API para criar tarefas/atividades manualmente
app.post('/api/activities', (req, res) => {
  const { type, description, metadata } = req.body;

  if (!type || !description) {
    return res.status(400).json({
      success: false,
      error: 'Type and description are required'
    });
  }

  const activity = activityTracker.log(type, description, metadata);
  res.status(201).json({ success: true, activity });
});

// Atualizar status de atividade
app.patch('/api/activities/:id', (req, res) => {
  const { status, result } = req.body;
  const activity = activityTracker.update(req.params.id, status, result);

  if (activity) {
    res.json({ success: true, activity });
  } else {
    res.status(404).json({ success: false, error: 'Activity not found' });
  }
});

// Limpar atividades antigas
app.delete('/api/activities', (req, res) => {
  activityTracker.clear();
  res.json({ success: true, message: 'Activities cleared' });
});

// API principal do Openclawd
app.post('/api/process', async (req, res) => {
  const { task, data } = req.body;
  const activityId = activityTracker.log('process', `Processing task: ${task}`, { task, data });

  try {
    // Simular processamento (aqui você implementaria a lógica real)
    await new Promise(resolve => setTimeout(resolve, Math.random() * 2000 + 1000));

    const result = {
      taskId: uuidv4(),
      task,
      processed: true,
      timestamp: new Date().toISOString()
    };

    activityTracker.update(activityId, 'completed', result);
    res.json({ success: true, result });
  } catch (error) {
    activityTracker.update(activityId, 'failed', { error: error.message });
    res.status(500).json({ success: false, error: error.message });
  }
});

// Rota 404
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Error handler
app.use((err, req, res, next) => {
  logger.error('Unhandled error', err);
  res.status(500).json({ error: 'Internal server error' });
});

// Simular atividades em background
setInterval(() => {
  const types = ['background_task', 'scheduled_job', 'maintenance'];
  const type = types[Math.floor(Math.random() * types.length)];
  const activityId = activityTracker.log(type, `Executing ${type}`, {
    automatic: true
  });

  setTimeout(() => {
    activityTracker.update(activityId, 'completed', { success: true });
  }, Math.random() * 5000);
}, 15000);

// Iniciar servidor
const server = app.listen(PORT, '0.0.0.0', () => {
  logger.info(`Openclawd server running on port ${PORT}`);
  logger.info(`Environment: ${process.env.NODE_ENV || 'development'}`);
  activityTracker.log('system', 'Openclawd server started', { port: PORT });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM signal received: closing HTTP server');
  activityTracker.log('system', 'Server shutting down', { signal: 'SIGTERM' });
  server.close(() => {
    logger.info('HTTP server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  logger.info('SIGINT signal received: closing HTTP server');
  activityTracker.log('system', 'Server shutting down', { signal: 'SIGINT' });
  server.close(() => {
    logger.info('HTTP server closed');
    process.exit(0);
  });
});

module.exports = app;
