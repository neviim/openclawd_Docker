#!/usr/bin/env python3
"""
Cliente Python para API Openclawd
Uso: python3 python_client.py <servidor>
Exemplo: python3 python_client.py 192.168.1.100
"""

import sys
import requests
from datetime import datetime
import json

class OpenclawdClient:
    def __init__(self, server, username=None, password=None):
        """
        Inicializa o cliente Openclawd

        Args:
            server: IP ou hostname do servidor (ex: 192.168.1.100)
            username: Usuário para autenticação (opcional)
            password: Senha para autenticação (opcional)
        """
        self.base_url = f"http://{server}"
        self.auth = (username, password) if username and password else None

    def health_check(self):
        """Verifica se o servidor está saudável"""
        response = requests.get(f"{self.base_url}/health", auth=self.auth)
        return response.json()

    def get_status(self):
        """Obtém status do sistema"""
        response = requests.get(f"{self.base_url}/status", auth=self.auth)
        return response.json()

    def list_activities(self, limit=50, status=None):
        """
        Lista atividades

        Args:
            limit: Número máximo de atividades
            status: Filtrar por status (pending, running, completed, failed)
        """
        params = {"limit": limit}
        if status:
            params["status"] = status

        response = requests.get(
            f"{self.base_url}/api/activities",
            params=params,
            auth=self.auth
        )
        return response.json()

    def get_activity(self, activity_id):
        """Obtém uma atividade específica"""
        response = requests.get(
            f"{self.base_url}/api/activities/{activity_id}",
            auth=self.auth
        )
        return response.json()

    def create_activity(self, activity_type, description, metadata=None):
        """
        Cria uma nova atividade

        Args:
            activity_type: Tipo da atividade
            description: Descrição da atividade
            metadata: Metadados adicionais (dict)
        """
        data = {
            "type": activity_type,
            "description": description,
            "metadata": metadata or {}
        }

        response = requests.post(
            f"{self.base_url}/api/activities",
            json=data,
            auth=self.auth
        )
        return response.json()

    def update_activity(self, activity_id, status, result=None):
        """
        Atualiza status de uma atividade

        Args:
            activity_id: ID da atividade
            status: Novo status (running, completed, failed)
            result: Resultado da atividade (dict)
        """
        data = {
            "status": status,
            "result": result or {}
        }

        response = requests.patch(
            f"{self.base_url}/api/activities/{activity_id}",
            json=data,
            auth=self.auth
        )
        return response.json()

    def process_task(self, task_name, data):
        """
        Processa uma tarefa

        Args:
            task_name: Nome da tarefa
            data: Dados para processar (dict)
        """
        payload = {
            "task": task_name,
            "data": data
        }

        response = requests.post(
            f"{self.base_url}/api/process",
            json=payload,
            auth=self.auth
        )
        return response.json()


def main():
    # Configuração
    server = sys.argv[1] if len(sys.argv) > 1 else "localhost"

    # Descomentar para usar autenticação
    # username = "admin"
    # password = "senha"
    # client = OpenclawdClient(server, username, password)

    client = OpenclawdClient(server)

    print("=" * 60)
    print("Cliente Python - Openclawd API")
    print(f"Servidor: {server}")
    print("=" * 60)
    print()

    # 1. Health Check
    print("1. Health Check...")
    try:
        health = client.health_check()
        print(f"   ✓ Status: {health.get('status')}")
        print()
    except Exception as e:
        print(f"   ✗ Erro: {e}")
        return

    # 2. Status do Sistema
    print("2. Status do Sistema...")
    try:
        status = client.get_status()
        print(f"   Status: {status.get('status')}")
        print(f"   Versão: {status.get('version')}")
        if 'activities' in status:
            acts = status['activities']
            print(f"   Atividades:")
            print(f"     - Total: {acts.get('total', 0)}")
            print(f"     - Em Progresso: {acts.get('running', 0)}")
            print(f"     - Concluídas: {acts.get('completed', 0)}")
        print()
    except Exception as e:
        print(f"   ✗ Erro: {e}")

    # 3. Listar Atividades
    print("3. Listar Atividades Recentes...")
    try:
        result = client.list_activities(limit=5)
        if result.get('success'):
            activities = result.get('activities', [])
            print(f"   Total: {result.get('count', 0)}")
            for act in activities[:3]:
                print(f"   - [{act.get('type')}] {act.get('description')}")
                print(f"     Status: {act.get('status')} | ID: {act.get('id', '')[:8]}")
        print()
    except Exception as e:
        print(f"   ✗ Erro: {e}")

    # 4. Criar Nova Atividade
    print("4. Criar Nova Atividade...")
    try:
        result = client.create_activity(
            activity_type="python_test",
            description=f"Teste via Python - {datetime.now().isoformat()}",
            metadata={
                "language": "python",
                "client": "python_client.py",
                "timestamp": datetime.now().isoformat()
            }
        )

        if result.get('success'):
            activity = result.get('activity', {})
            print(f"   ✓ Atividade criada!")
            print(f"     ID: {activity.get('id')}")
            print(f"     Tipo: {activity.get('type')}")
            print(f"     Status: {activity.get('status')}")
        print()
    except Exception as e:
        print(f"   ✗ Erro: {e}")

    # 5. Processar Tarefa
    print("5. Processar Tarefa...")
    try:
        result = client.process_task(
            task_name="python_processing",
            data={
                "operation": "test",
                "timestamp": datetime.now().isoformat(),
                "values": [1, 2, 3, 4, 5]
            }
        )

        if result.get('success'):
            print(f"   ✓ Tarefa processada!")
            print(f"     Task ID: {result.get('result', {}).get('taskId', '')[:8]}...")
        print()
    except Exception as e:
        print(f"   ✗ Erro: {e}")

    print("=" * 60)
    print("Teste concluído!")
    print(f"Dashboard: http://{server}")
    print("=" * 60)


if __name__ == "__main__":
    main()
