#!/usr/bin/env node
/**
 * Cliente Node.js para API Openclawd
 * Uso: node nodejs_client.js <servidor>
 * Exemplo: node nodejs_client.js 192.168.1.100
 */

const https = require('https');
const http = require('http');

class OpenclawdClient {
    constructor(server, username = null, password = null) {
        this.baseUrl = `http://${server}`;
        this.auth = username && password ?
            `Basic ${Buffer.from(`${username}:${password}`).toString('base64')}` :
            null;
    }

    async request(method, path, data = null) {
        return new Promise((resolve, reject) => {
            const url = new URL(path, this.baseUrl);
            const options = {
                method,
                headers: {
                    'Content-Type': 'application/json'
                }
            };

            if (this.auth) {
                options.headers['Authorization'] = this.auth;
            }

            const client = url.protocol === 'https:' ? https : http;

            const req = client.request(url, options, (res) => {
                let body = '';

                res.on('data', (chunk) => {
                    body += chunk;
                });

                res.on('end', () => {
                    try {
                        resolve(JSON.parse(body));
                    } catch (e) {
                        resolve(body);
                    }
                });
            });

            req.on('error', reject);

            if (data) {
                req.write(JSON.stringify(data));
            }

            req.end();
        });
    }

    async healthCheck() {
        return this.request('GET', '/health');
    }

    async getStatus() {
        return this.request('GET', '/status');
    }

    async listActivities(limit = 50, status = null) {
        const params = new URLSearchParams({ limit });
        if (status) params.append('status', status);
        return this.request('GET', `/api/activities?${params}`);
    }

    async getActivity(activityId) {
        return this.request('GET', `/api/activities/${activityId}`);
    }

    async createActivity(type, description, metadata = {}) {
        return this.request('POST', '/api/activities', {
            type,
            description,
            metadata
        });
    }

    async updateActivity(activityId, status, result = {}) {
        return this.request('PATCH', `/api/activities/${activityId}`, {
            status,
            result
        });
    }

    async processTask(taskName, data) {
        return this.request('POST', '/api/process', {
            task: taskName,
            data
        });
    }
}

async function main() {
    const server = process.argv[2] || 'localhost';

    // Descomentar para usar autenticação
    // const client = new OpenclawdClient(server, 'admin', 'senha');
    const client = new OpenclawdClient(server);

    console.log('='.repeat(60));
    console.log('Cliente Node.js - Openclawd API');
    console.log(`Servidor: ${server}`);
    console.log('='.repeat(60));
    console.log();

    try {
        // 1. Health Check
        console.log('1. Health Check...');
        const health = await client.healthCheck();
        console.log(`   ✓ Status: ${health.status}`);
        console.log();

        // 2. Status do Sistema
        console.log('2. Status do Sistema...');
        const status = await client.getStatus();
        console.log(`   Status: ${status.status}`);
        console.log(`   Versão: ${status.version}`);
        if (status.activities) {
            console.log('   Atividades:');
            console.log(`     - Total: ${status.activities.total || 0}`);
            console.log(`     - Em Progresso: ${status.activities.running || 0}`);
            console.log(`     - Concluídas: ${status.activities.completed || 0}`);
        }
        console.log();

        // 3. Listar Atividades
        console.log('3. Listar Atividades Recentes...');
        const activitiesResult = await client.listActivities(5);
        if (activitiesResult.success) {
            console.log(`   Total: ${activitiesResult.count}`);
            activitiesResult.activities.slice(0, 3).forEach(act => {
                console.log(`   - [${act.type}] ${act.description}`);
                console.log(`     Status: ${act.status} | ID: ${act.id.substring(0, 8)}`);
            });
        }
        console.log();

        // 4. Criar Nova Atividade
        console.log('4. Criar Nova Atividade...');
        const newActivity = await client.createActivity(
            'nodejs_test',
            `Teste via Node.js - ${new Date().toISOString()}`,
            {
                language: 'javascript',
                runtime: 'nodejs',
                client: 'nodejs_client.js',
                timestamp: new Date().toISOString()
            }
        );

        if (newActivity.success) {
            console.log('   ✓ Atividade criada!');
            console.log(`     ID: ${newActivity.activity.id}`);
            console.log(`     Tipo: ${newActivity.activity.type}`);
            console.log(`     Status: ${newActivity.activity.status}`);
        }
        console.log();

        // 5. Processar Tarefa
        console.log('5. Processar Tarefa...');
        const taskResult = await client.processTask(
            'nodejs_processing',
            {
                operation: 'test',
                timestamp: new Date().toISOString(),
                values: [1, 2, 3, 4, 5]
            }
        );

        if (taskResult.success) {
            console.log('   ✓ Tarefa processada!');
            console.log(`     Task ID: ${taskResult.result.taskId.substring(0, 8)}...`);
        }
        console.log();

        console.log('='.repeat(60));
        console.log('Teste concluído!');
        console.log(`Dashboard: http://${server}`);
        console.log('='.repeat(60));

    } catch (error) {
        console.error('Erro:', error.message);
        process.exit(1);
    }
}

// Executar se for o script principal
if (require.main === module) {
    main();
}

module.exports = OpenclawdClient;
