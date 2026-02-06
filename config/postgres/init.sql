-- Inicialização do banco de dados Openclawd Monitor

-- Criar extensões
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Tabela de atividades históricas
CREATE TABLE IF NOT EXISTS activity_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    activity_id TEXT NOT NULL,
    activity_type TEXT NOT NULL,
    description TEXT NOT NULL,
    metadata JSONB,
    status TEXT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ,
    result JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela de métricas de sistema
CREATE TABLE IF NOT EXISTS system_metrics (
    id SERIAL PRIMARY KEY,
    metric_name TEXT NOT NULL,
    metric_value DOUBLE PRECISION NOT NULL,
    metadata JSONB,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tabela de eventos de sistema
CREATE TABLE IF NOT EXISTS system_events (
    id SERIAL PRIMARY KEY,
    event_type TEXT NOT NULL,
    severity TEXT NOT NULL,
    message TEXT NOT NULL,
    details JSONB,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_activity_history_timestamp ON activity_history(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_activity_history_status ON activity_history(status);
CREATE INDEX IF NOT EXISTS idx_activity_history_type ON activity_history(activity_type);
CREATE INDEX IF NOT EXISTS idx_system_metrics_timestamp ON system_metrics(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_system_metrics_name ON system_metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_system_events_timestamp ON system_events(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_system_events_type ON system_events(event_type);

-- Função para limpar dados antigos
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS void AS $$
BEGIN
    -- Manter apenas últimos 30 dias de histórico
    DELETE FROM activity_history WHERE timestamp < NOW() - INTERVAL '30 days';
    DELETE FROM system_metrics WHERE timestamp < NOW() - INTERVAL '30 days';
    DELETE FROM system_events WHERE timestamp < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- View para estatísticas
CREATE OR REPLACE VIEW activity_stats AS
SELECT
    DATE(timestamp) as date,
    activity_type,
    status,
    COUNT(*) as count,
    AVG(EXTRACT(EPOCH FROM (completed_at - timestamp))) as avg_duration_seconds
FROM activity_history
WHERE completed_at IS NOT NULL
GROUP BY DATE(timestamp), activity_type, status;

-- Permissões
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO openclawd;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO openclawd;

-- Log de inicialização
INSERT INTO system_events (event_type, severity, message, details)
VALUES ('database_init', 'info', 'Database initialized successfully', '{"version": "1.0.0"}'::jsonb);
