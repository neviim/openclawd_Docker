const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const axios = require('axios');
const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');

// Configuração
const PORT = process.env.PORT || 8080;
const OPENCLAWD_HOST = process.env.OPENCLAWD_HOST || 'openclawd';
const OPENCLAWD_PORT = process.env.OPENCLAWD_PORT || 3000;
const MONITOR_INTERVAL = parseInt(process.env.MONITOR_INTERVAL) || 5000;
const DB_PATH = process.env.DB_PATH || '/data/kanban.db';

const OPENCLAWD_URL = `http://${OPENCLAWD_HOST}:${OPENCLAWD_PORT}`;

// Inicializar banco de dados
const db = new Database(DB_PATH);
db.pragma('journal_mode = WAL');

// Criar tabelas
db.exec(`
  CREATE TABLE IF NOT EXISTS activities (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,
    description TEXT NOT NULL,
    metadata TEXT,
    status TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    completedAt TEXT,
    result TEXT,
    column_position INTEGER DEFAULT 0
  );

  CREATE TABLE IF NOT EXISTS kanban_columns (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    position INTEGER NOT NULL,
    color TEXT
  );

  CREATE TABLE IF NOT EXISTS system_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT NOT NULL,
    metric_name TEXT NOT NULL,
    metric_value REAL NOT NULL,
    metadata TEXT
  );

  CREATE INDEX IF NOT EXISTS idx_activities_status ON activities(status);
  CREATE INDEX IF NOT EXISTS idx_activities_timestamp ON activities(timestamp DESC);
  CREATE INDEX IF NOT EXISTS idx_metrics_timestamp ON system_metrics(timestamp DESC);
`);

// Inicializar colunas do Kanban
const initColumns = db.prepare(`
  INSERT OR IGNORE INTO kanban_columns (name, position, color) VALUES (?, ?, ?)
`);

const columns = [
  { name: 'Pendente', position: 0, color: '#94a3b8' },
  { name: 'Em Progresso', position: 1, color: '#3b82f6' },
  { name: 'Concluído', position: 2, color: '#22c55e' },
  { name: 'Falhou', position: 3, color: '#ef4444' }
];

columns.forEach(col => {
  initColumns.run(col.name, col.position, col.color);
});

// Express app
const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// WebSocket connections
const clients = new Set();

wss.on('connection', (ws) => {
  clients.add(ws);
  console.log('New WebSocket client connected. Total:', clients.size);

  ws.on('close', () => {
    clients.delete(ws);
    console.log('WebSocket client disconnected. Total:', clients.size);
  });

  // Enviar estado inicial
  sendUpdate(ws);
});

// Broadcast para todos os clientes
function broadcast(data) {
  const message = JSON.stringify(data);
  clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  });
}

// Enviar atualização para um cliente específico
function sendUpdate(ws) {
  const activities = db.prepare('SELECT * FROM activities ORDER BY timestamp DESC LIMIT 100').all();
  const columns = db.prepare('SELECT * FROM kanban_columns ORDER BY position').all();
  const stats = getStats();

  const data = {
    type: 'full_update',
    activities,
    columns,
    stats,
    timestamp: new Date().toISOString()
  };

  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(data));
  }
}

// Obter estatísticas
function getStats() {
  const totalActivities = db.prepare('SELECT COUNT(*) as count FROM activities').get();
  const byStatus = db.prepare(`
    SELECT status, COUNT(*) as count
    FROM activities
    GROUP BY status
  `).all();

  const recentMetrics = db.prepare(`
    SELECT metric_name, AVG(metric_value) as avg_value
    FROM system_metrics
    WHERE timestamp > datetime('now', '-1 hour')
    GROUP BY metric_name
  `).all();

  return {
    total: totalActivities.count,
    byStatus: byStatus.reduce((acc, item) => {
      acc[item.status] = item.count;
      return acc;
    }, {}),
    metrics: recentMetrics.reduce((acc, item) => {
      acc[item.metric_name] = item.avg_value;
      return acc;
    }, {})
  };
}

// Monitor do Openclawd
async function monitorOpenclawd() {
  try {
    // Buscar atividades do Openclawd
    const response = await axios.get(`${OPENCLAWD_URL}/api/activities?limit=100`, {
      timeout: 5000
    });

    if (response.data.success) {
      const activities = response.data.activities;

      // Inserir/atualizar atividades no banco
      const upsert = db.prepare(`
        INSERT OR REPLACE INTO activities
        (id, type, description, metadata, status, timestamp, completedAt, result, column_position)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      `);

      const transaction = db.transaction((activities) => {
        for (const activity of activities) {
          const columnPosition = getColumnPosition(activity.status);
          upsert.run(
            activity.id,
            activity.type,
            activity.description,
            JSON.stringify(activity.metadata || {}),
            activity.status,
            activity.timestamp,
            activity.completedAt || null,
            JSON.stringify(activity.result || {}),
            columnPosition
          );
        }
      });

      transaction(activities);

      // Buscar métricas de sistema
      const statusResponse = await axios.get(`${OPENCLAWD_URL}/status`, {
        timeout: 5000
      });

      if (statusResponse.data) {
        saveMetrics(statusResponse.data);
      }

      // Notificar clientes WebSocket
      broadcast({
        type: 'update',
        activities: activities.length,
        timestamp: new Date().toISOString()
      });

      return true;
    }
  } catch (error) {
    console.error('Error monitoring Openclawd:', error.message);
    return false;
  }
}

// Mapear status para posição de coluna
function getColumnPosition(status) {
  const mapping = {
    'pending': 0,
    'running': 1,
    'in_progress': 1,
    'completed': 2,
    'success': 2,
    'failed': 3,
    'error': 3
  };
  return mapping[status] || 0;
}

// Salvar métricas do sistema
function saveMetrics(data) {
  const insert = db.prepare(`
    INSERT INTO system_metrics (timestamp, metric_name, metric_value, metadata)
    VALUES (?, ?, ?, ?)
  `);

  const timestamp = new Date().toISOString();

  if (data.uptime !== undefined) {
    insert.run(timestamp, 'uptime', data.uptime, null);
  }

  if (data.memory) {
    insert.run(timestamp, 'memory_heap_used', data.memory.heapUsed / 1024 / 1024, null);
    insert.run(timestamp, 'memory_heap_total', data.memory.heapTotal / 1024 / 1024, null);
  }

  if (data.activities) {
    insert.run(timestamp, 'activities_total', data.activities.total, null);
    insert.run(timestamp, 'activities_running', data.activities.running, null);
    insert.run(timestamp, 'activities_completed', data.activities.completed, null);
    insert.run(timestamp, 'activities_failed', data.activities.failed, null);
  }
}

// Rotas da API

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.get('/api/activities', (req, res) => {
  const limit = parseInt(req.query.limit) || 100;
  const status = req.query.status;

  let query = 'SELECT * FROM activities';
  const params = [];

  if (status) {
    query += ' WHERE status = ?';
    params.push(status);
  }

  query += ' ORDER BY timestamp DESC LIMIT ?';
  params.push(limit);

  const activities = db.prepare(query).all(...params);
  res.json({
    success: true,
    count: activities.length,
    activities: activities.map(a => ({
      ...a,
      metadata: JSON.parse(a.metadata || '{}'),
      result: a.result ? JSON.parse(a.result) : null
    }))
  });
});

app.get('/api/columns', (req, res) => {
  const columns = db.prepare('SELECT * FROM kanban_columns ORDER BY position').all();
  res.json({ success: true, columns });
});

app.get('/api/kanban', (req, res) => {
  const columns = db.prepare('SELECT * FROM kanban_columns ORDER BY position').all();
  const activities = db.prepare('SELECT * FROM activities ORDER BY timestamp DESC').all();

  const kanban = columns.map(col => ({
    ...col,
    activities: activities.filter(a => a.column_position === col.position).map(a => ({
      ...a,
      metadata: JSON.parse(a.metadata || '{}'),
      result: a.result ? JSON.parse(a.result) : null
    }))
  }));

  res.json({ success: true, kanban });
});

app.get('/api/stats', (req, res) => {
  const stats = getStats();
  res.json({ success: true, stats });
});

app.get('/api/metrics', (req, res) => {
  const hours = parseInt(req.query.hours) || 24;
  const metrics = db.prepare(`
    SELECT *
    FROM system_metrics
    WHERE timestamp > datetime('now', '-${hours} hours')
    ORDER BY timestamp DESC
  `).all();

  res.json({ success: true, count: metrics.length, metrics });
});

// Rota principal - serve o dashboard
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Iniciar monitoramento
setInterval(monitorOpenclawd, MONITOR_INTERVAL);

// Primeira execução imediata
setTimeout(monitorOpenclawd, 2000);

// Iniciar servidor
server.listen(PORT, '0.0.0.0', () => {
  console.log(`Kanban Monitor running on port ${PORT}`);
  console.log(`Monitoring Openclawd at ${OPENCLAWD_URL}`);
  console.log(`WebSocket server ready`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, closing connections...');
  wss.close(() => {
    db.close();
    server.close(() => {
      process.exit(0);
    });
  });
});
