#!/bin/bash

################################################################################
# 🚀 INSTALADOR AUTOMÁTICO: Sistema de Memoria Remota Qdrant para Claude Code
#
# Versión: 2.0.0
# Fecha: 2026-09-14
# Colección: "memoria"
#
# Este script automatiza TODA la instalación sin pasos manuales.
# Solo necesita información del servidor Qdrant remoto.
################################################################################

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
COLLECTION_NAME="memoria"
CLAUDE_HOME="$HOME/.claude"
HOOKS_DIR="$CLAUDE_HOME/hooks"
SCRIPTS_DIR="$CLAUDE_HOME/scripts"
TOOLS_DIR="$CLAUDE_HOME/tools"
BACKUP_DIR="$CLAUDE_HOME/.backup"
LOGS_DIR="$CLAUDE_HOME/logs"
CONFIG_FILE="$CLAUDE_HOME/.qdrant-config"
SETTINGS_FILE="$CLAUDE_HOME/settings.json"
INSTALL_LOG="$LOGS_DIR/install-$(date +%s).log"

################################################################################
# FUNCIONES AUXILIARES
################################################################################

log() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$INSTALL_LOG"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$INSTALL_LOG"
}

error() {
    echo -e "${RED}[✗]${NC} $1" | tee -a "$INSTALL_LOG"
}

warning() {
    echo -e "${YELLOW}[⚠]${NC} $1" | tee -a "$INSTALL_LOG"
}

separator() {
    echo "" | tee -a "$INSTALL_LOG"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$INSTALL_LOG"
    echo "" | tee -a "$INSTALL_LOG"
}

################################################################################
# VALIDAR DEPENDENCIAS
################################################################################

validate_dependencies() {
    log "Validando dependencias..."
    
    local deps_ok=true
    
    # Verificar curl
    if ! command -v curl &> /dev/null; then
        error "curl no encontrado. Instala: sudo apt-get install curl"
        deps_ok=false
    else
        success "curl $(curl --version | head -1 | cut -d' ' -f2)"
    fi
    
    # Verificar jq
    if ! command -v jq &> /dev/null; then
        error "jq no encontrado. Instala: sudo apt-get install jq"
        deps_ok=false
    else
        success "jq $(jq --version)"
    fi
    
    # Verificar python3
    if ! command -v python3 &> /dev/null; then
        error "python3 no encontrado. Instala: sudo apt-get install python3"
        deps_ok=false
    else
        success "python3 $(python3 --version | cut -d' ' -f2)"
    fi
    
    if [ "$deps_ok" = false ]; then
        error "Faltan dependencias requeridas"
        exit 1
    fi
}

################################################################################
# OBTENER DATOS DEL USUARIO
################################################################################

get_qdrant_config() {
    separator
    log "Configuración del servidor Qdrant remoto"
    echo ""
    
    # Host
    while true; do
        read -p "$(echo -e ${BLUE}[?]${NC} Hostname/IP del servidor Qdrant: )" QDRANT_HOST
        
        if [ -z "$QDRANT_HOST" ]; then
            error "Hostname no puede estar vacío"
            continue
        fi
        
        # Intenta ping o nslookup
        if ping -c 1 "$QDRANT_HOST" &> /dev/null; then
            success "Servidor $QDRANT_HOST es alcanzable"
            break
        else
            warning "No se puede hacer ping a $QDRANT_HOST (puede estar filtrado)"
            read -p "¿Continuar de todas formas? (s/n): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Ss]$ ]]; then
                break
            fi
        fi
    done
    
    # Puerto (default 6333)
    read -p "$(echo -e ${BLUE}[?]${NC}) Puerto (default 6333): " QDRANT_PORT_INPUT
    QDRANT_PORT="${QDRANT_PORT_INPUT:-6333}"
    echo "   → Puerto: $QDRANT_PORT"
    
    # Protocolo (default https)
    read -p "$(echo -e ${BLUE}[?]${NC}) Protocolo http/https (default https): " QDRANT_PROTOCOL_INPUT
    QDRANT_PROTOCOL="${QDRANT_PROTOCOL_INPUT:-https}"
    
    if [ "$QDRANT_PROTOCOL" != "http" ] && [ "$QDRANT_PROTOCOL" != "https" ]; then
        error "Protocolo debe ser 'http' o 'https'"
        exit 1
    fi
    echo "   → Protocolo: $QDRANT_PROTOCOL"
    
    # API Key (opcional)
    read -p "$(echo -e ${BLUE}[?]${NC}) API Key (dejar vacío si no hay): " QDRANT_API_KEY_INPUT
    QDRANT_API_KEY="${QDRANT_API_KEY_INPUT:-}"
    
    if [ -n "$QDRANT_API_KEY" ]; then
        echo "   → API Key: (configurada)"
    else
        echo "   → API Key: (no configurada)"
    fi
    
    echo ""
}

################################################################################
# CREAR ESTRUCTURA DE DIRECTORIOS
################################################################################

create_directories() {
    separator
    log "Creando estructura de directorios..."
    
    mkdir -p "$HOOKS_DIR"
    mkdir -p "$SCRIPTS_DIR"
    mkdir -p "$TOOLS_DIR"
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$LOGS_DIR"
    
    chmod 700 "$CLAUDE_HOME"
    
    success "Directorios creados"
}

################################################################################
# CREAR ARCHIVO DE CONFIGURACIÓN
################################################################################

create_config() {
    separator
    log "Creando archivo de configuración..."
    
    QDRANT_URL="${QDRANT_PROTOCOL}://${QDRANT_HOST}:${QDRANT_PORT}"
    
    cat > "$CONFIG_FILE" << EOF
# Remote Qdrant Configuration
# Generado: $(date)

export QDRANT_HOST="$QDRANT_HOST"
export QDRANT_PORT="$QDRANT_PORT"
export QDRANT_PROTOCOL="$QDRANT_PROTOCOL"
export QDRANT_API_KEY="$QDRANT_API_KEY"
export QDRANT_COLLECTION_NAME="$COLLECTION_NAME"

# Computed (no editar)
export QDRANT_URL="${QDRANT_PROTOCOL}://${QDRANT_HOST}:${QDRANT_PORT}"
EOF
    
    chmod 600 "$CONFIG_FILE"
    
    success "Configuración guardada en $CONFIG_FILE"
    log "Colección: $COLLECTION_NAME"
    log "Servidor: $QDRANT_URL"
}

################################################################################
# VALIDAR CONEXIÓN A QDRANT
################################################################################

validate_qdrant_connection() {
    separator
    log "Validando conexión a Qdrant remoto..."
    log "   Conectando a: $QDRANT_URL"
    echo ""
    
    local max_retries=3
    local retry=0
    
    while [ $retry -lt $max_retries ]; do
        if curl -s -f -m 5 "$QDRANT_URL/health" > /dev/null 2>&1; then
            success "Conexión exitosa a Qdrant"
            
            # Mostrar info del servidor
            log "Información del servidor:"
            curl -s "$QDRANT_URL/health" | jq '.' | tee -a "$INSTALL_LOG"
            
            return 0
        fi
        
        retry=$((retry + 1))
        if [ $retry -lt $max_retries ]; then
            warning "Intento $retry falló. Reintentando..."
            sleep 2
        fi
    done
    
    error "No se puede conectar a Qdrant en $QDRANT_URL"
    error "Verifica:"
    error "  1. El hostname/IP es correcto: $QDRANT_HOST"
    error "  2. El puerto es correcto: $QDRANT_PORT"
    error "  3. El protocolo es correcto: $QDRANT_PROTOCOL"
    error "  4. La conectividad de red es correcta"
    error "  5. Qdrant está corriendo en el servidor remoto"
    
    return 1
}

################################################################################
# CREAR/VERIFICAR COLECCIÓN
################################################################################

create_or_verify_collection() {
    separator
    log "Verificando/creando colección '$COLLECTION_NAME'..."
    
    source "$CONFIG_FILE"
    
    # Verificar si colección existe
    local collection_check=$(curl -s "$QDRANT_URL/collections/$COLLECTION_NAME" 2>/dev/null || echo "{}")
    
    if echo "$collection_check" | grep -q "name"; then
        success "Colección '$COLLECTION_NAME' ya existe"
        echo "$collection_check" | jq '.' | tee -a "$INSTALL_LOG"
        return 0
    fi
    
    log "Colección '$COLLECTION_NAME' no existe. Creando..."
    
    # Crear colección
    local create_result=$(curl -s -X PUT \
        "$QDRANT_URL/collections/$COLLECTION_NAME" \
        -H "Content-Type: application/json" \
        -d '{
            "vectors": {
                "size": 384,
                "distance": "Cosine"
            }
        }' 2>/dev/null)
    
    echo "$create_result" | jq '.' | tee -a "$INSTALL_LOG"
    
    if echo "$create_result" | grep -q "error"; then
        error "Error creando colección"
        return 1
    fi
    
    success "Colección '$COLLECTION_NAME' creada exitosamente"
    return 0
}

################################################################################
# CREAR SCRIPTS DE VALIDACIÓN
################################################################################

create_validation_script() {
    log "Creando script de validación..."
    
    cat > "$SCRIPTS_DIR/validate-qdrant.sh" << 'SCRIPT_EOF'
#!/bin/bash
set -e

source ~/.claude/.qdrant-config

echo "🔍 Validating remote Qdrant connection..."
echo "   Host: ${QDRANT_HOST}"
echo "   Port: ${QDRANT_PORT}"
echo "   Protocol: ${QDRANT_PROTOCOL}"
echo "   Collection: ${QDRANT_COLLECTION_NAME}"
echo ""

if curl -s -f "${QDRANT_URL}/health" > /dev/null 2>&1; then
    echo "✅ Remote Qdrant is accessible"
    echo ""
    echo "Server response:"
    curl -s "${QDRANT_URL}/health" | jq .
    exit 0
else
    echo "❌ Cannot reach Qdrant at ${QDRANT_URL}"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check QDRANT_HOST: ${QDRANT_HOST}"
    echo "2. Check QDRANT_PORT: ${QDRANT_PORT}"
    echo "3. Check QDRANT_PROTOCOL: ${QDRANT_PROTOCOL}"
    echo "4. Check firewall allows port ${QDRANT_PORT}"
    exit 1
fi
SCRIPT_EOF
    
    chmod +x "$SCRIPTS_DIR/validate-qdrant.sh"
    success "Script de validación creado"
}

################################################################################
# CREAR HOOK SESSIONSTART
################################################################################

create_session_start_hook() {
    log "Creando hook SessionStart..."
    
    cat > "$HOOKS_DIR/load-memory-from-qdrant.sh" << 'HOOK_EOF'
#!/bin/bash
set -e

source ~/.claude/.qdrant-config

# Generar ID único del proyecto
PROJECT_PATH="${PWD}"
PROJECT_NAME=$(basename "$PROJECT_PATH")

PROJECT_ID=$(python3 << 'PYTHON_EOF'
import hashlib
import os

path = os.getcwd()
name = os.path.basename(path)
project_id = hashlib.sha256(f"{name}:{path}".encode()).hexdigest()[:16]
print(project_id)
PYTHON_EOF
)

# Headers
HEADERS="-H 'Content-Type: application/json'"

# Add API key if configured
if [ -n "$QDRANT_API_KEY" ]; then
    HEADERS="$HEADERS -H 'api-key: $QDRANT_API_KEY'"
fi

echo "🧠 Loading memory for project: $PROJECT_NAME (ID: $PROJECT_ID)"
echo ""

# Query remote Qdrant
QUERY_RESULT=$(eval "curl -s -X POST '${QDRANT_URL}/collections/${QDRANT_COLLECTION_NAME}/points/search' $HEADERS -d '{
  \"vector\": [0.1, 0.2, 0.3],
  \"limit\": 15,
  \"filter\": {
    \"must\": [
      {
        \"key\": \"namespace.project_id\",
        \"match\": { \"value\": \"'${PROJECT_ID}'\" }
      }
    ]
  },
  \"with_payload\": true
}'")

# Format output
RESULT_COUNT=$(echo "$QUERY_RESULT" | jq '.result | length' 2>/dev/null || echo "0")

if [ "$RESULT_COUNT" -gt 0 ]; then
    echo "## 📚 Project Memory"
    echo "**Project:** $PROJECT_NAME"
    echo "**Path:** $PROJECT_PATH"
    echo "**Session:** $(date)"
    echo ""
    
    echo "$QUERY_RESULT" | jq -r '.result[] | 
        "\n### \(.payload.memory.type | ascii_upcase): \(.payload.memory.title)\n" +
        "\(.payload.memory.content)\n" +
        "_Created: \(.payload.temporal.created_at)_"' 2>/dev/null || true
else
    echo "📝 No previous memory found for this project"
    echo "**Project:** $PROJECT_NAME"
    echo "**Path:** $PROJECT_PATH"
    echo "**Session:** $(date)"
fi
HOOK_EOF
    
    chmod +x "$HOOKS_DIR/load-memory-from-qdrant.sh"
    success "Hook SessionStart creado"
}

################################################################################
# CREAR HOOK POSTTOOLUSE
################################################################################

create_post_tool_use_hook() {
    log "Creando hook PostToolUse..."
    
    cat > "$HOOKS_DIR/save-memory-to-qdrant.sh" << 'HOOK_EOF'
#!/bin/bash
set -e

source ~/.claude/.qdrant-config

HOOK_INPUT=$(cat)

# Generar Project ID
PROJECT_ID=$(python3 << 'EOF'
import hashlib
import os
project_id = hashlib.sha256(f"{os.path.basename(os.getcwd())}:{os.getcwd()}".encode()).hexdigest()[:16]
print(project_id)
EOF
)

TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name')
TOOL_OUTPUT=$(echo "$HOOK_INPUT" | jq -r '.tool_output // empty' | head -c 500)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
POINT_ID=$(python3 -c "import uuid; print(int(uuid.uuid4().int % 2**31))")

# Headers
HEADERS="-H 'Content-Type: application/json'"
if [ -n "$QDRANT_API_KEY" ]; then
    HEADERS="$HEADERS -H 'api-key: $QDRANT_API_KEY'"
fi

# Save to remote Qdrant
eval "curl -s -X PUT '${QDRANT_URL}/collections/${QDRANT_COLLECTION_NAME}/points' $HEADERS -d '{
  \"points\": [{
    \"id\": '${POINT_ID}',
    \"vector\": [0.1, 0.2, 0.3],
    \"payload\": {
      \"namespace\": {
        \"project_id\": \"'${PROJECT_ID}'\",
        \"project_path\": \"'${PWD}'\"
      },
      \"memory\": {
        \"type\": \"action\",
        \"title\": \"[${TOOL_NAME}] ${TIMESTAMP}\",
        \"content\": \"${TOOL_OUTPUT}\",
        \"severity\": \"medium\"
      },
      \"temporal\": {
        \"created_at\": \"'${TIMESTAMP}'\"
      }
    }
  }]
}'" > /dev/null 2>&1

echo "✅ Memory saved to remote Qdrant"
HOOK_EOF
    
    chmod +x "$HOOKS_DIR/save-memory-to-qdrant.sh"
    success "Hook PostToolUse creado"
}

################################################################################
# CREAR CLI TOOL
################################################################################

create_cli_tool() {
    log "Creando herramienta CLI..."
    
    cat > "$TOOLS_DIR/claude-mem" << 'CLIEOF'
#!/usr/bin/env python3
"""Claude Memory CLI - Query and manage memories in remote Qdrant"""
import argparse
import requests
import json
import os
import hashlib
from pathlib import Path

# Load config
config_file = Path.home() / ".claude" / ".qdrant-config"
if not config_file.exists():
    print("❌ Config not found: ~/.claude/.qdrant-config")
    exit(1)

config = {}
with open(config_file) as f:
    for line in f:
        if line.startswith("export "):
            key, value = line.replace("export ", "").split("=", 1)
            config[key] = value.strip().strip('"')

QDRANT_URL = config.get("QDRANT_URL", "http://localhost:6333")
QDRANT_COLLECTION = config.get("QDRANT_COLLECTION_NAME", "memoria")
QDRANT_API_KEY = config.get("QDRANT_API_KEY", "")

headers = {"Content-Type": "application/json"}
if QDRANT_API_KEY:
    headers["api-key"] = QDRANT_API_KEY

def get_project_id(project_path=None):
    """Generate project ID from current or specified path"""
    if project_path is None:
        project_path = os.getcwd()
    name = os.path.basename(project_path)
    project_id = hashlib.sha256(f"{name}:{project_path}".encode()).hexdigest()[:16]
    return project_id

def query_memory(project_id, limit=10):
    """Query memories for a specific project"""
    try:
        result = requests.post(
            f"{QDRANT_URL}/collections/{QDRANT_COLLECTION}/points/search",
            json={
                "vector": [0.1] * 384,
                "limit": limit,
                "filter": {"must": [{"key": "namespace.project_id", "match": {"value": project_id}}]},
                "with_payload": True
            },
            headers=headers,
            timeout=10
        )
        return result.json()
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

def list_projects():
    """List all projects with memories"""
    try:
        result = requests.post(
            f"{QDRANT_URL}/collections/{QDRANT_COLLECTION}/points/search",
            json={"vector": [0.1] * 384, "limit": 10000, "with_payload": True},
            headers=headers,
            timeout=30
        )
        projects = {}
        for point in result.json().get("result", []):
            project_id = point["payload"]["namespace"]["project_id"]
            project_path = point["payload"]["namespace"]["project_path"]
            if project_id not in projects:
                projects[project_id] = {"path": project_path, "count": 0}
            projects[project_id]["count"] += 1
        return projects
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

def delete_project_memory(project_id):
    """Delete all memories for a project"""
    try:
        result = requests.post(
            f"{QDRANT_URL}/collections/{QDRANT_COLLECTION}/points/delete",
            json={"filter": {"must": [{"key": "namespace.project_id", "match": {"value": project_id}}]}},
            headers=headers,
            timeout=10
        )
        return result.json()
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

def main():
    parser = argparse.ArgumentParser(description="Claude Memory CLI (Remote Qdrant)")
    subparsers = parser.add_subparsers(dest="command")

    query_parser = subparsers.add_parser("query", help="Query memories for a project")
    query_parser.add_argument("--project", help="Project ID (default: current project)")
    query_parser.add_argument("--limit", type=int, default=10, help="Number of results")

    subparsers.add_parser("list", help="List all projects with memories")

    delete_parser = subparsers.add_parser("delete", help="Delete all memories for a project")
    delete_parser.add_argument("--project", required=True, help="Project ID to delete")

    subparsers.add_parser("stats", help="Show memory statistics")
    subparsers.add_parser("current", help="Show current project ID")

    args = parser.parse_args()

    if args.command == "query":
        project_id = args.project or get_project_id()
        print(f"📊 Querying memories for project: {project_id}\n")

        result = query_memory(project_id, args.limit)
        if result:
            count = len(result.get("result", []))
            print(f"Found {count} memories:\n")

            for point in result.get("result", []):
                payload = point["payload"]
                memory = payload["memory"]
                temporal = payload["temporal"]

                print(f"  📌 {memory['type'].upper()}: {memory['title']}")
                print(f"     Content: {memory['content'][:80]}...")
                print(f"     Created: {temporal['created_at']}")
                print()

    elif args.command == "list":
        print("📋 Projects with memories:\n")
        projects = list_projects()

        if projects:
            for project_id, info in sorted(projects.items()):
                print(f"  {project_id}")
                print(f"    Path: {info['path']}")
                print(f"    Memories: {info['count']}")
                print()
        else:
            print("  No projects found")

    elif args.command == "delete":
        print(f"🗑️  Deleting memories for project: {args.project}")
        result = delete_project_memory(args.project)
        if result:
            print("✅ Memories deleted")

    elif args.command == "current":
        project_id = get_project_id()
        print(f"Current project ID: {project_id}")
        print(f"Path: {os.getcwd()}")

    elif args.command == "stats":
        print("📈 Memory Statistics:\n")
        projects = list_projects()

        if projects:
            total_memories = sum(p["count"] for p in projects.values())
            total_projects = len(projects)
            avg_per_project = total_memories / total_projects if total_projects > 0 else 0

            print(f"  Total projects: {total_projects}")
            print(f"  Total memories: {total_memories}")
            print(f"  Avg per project: {avg_per_project:.1f}")
        else:
            print("  No data")

    else:
        parser.print_help()

if __name__ == "__main__":
    main()
CLIEOF
    
    chmod +x "$TOOLS_DIR/claude-mem"
    success "CLI tool creado"
}

################################################################################
# ACTUALIZAR settings.json
################################################################################

update_settings_json() {
    separator
    log "Actualizando ~/.claude/settings.json..."
    
    # Hacer backup
    if [ -f "$SETTINGS_FILE" ]; then
        cp "$SETTINGS_FILE" "$BACKUP_DIR/settings.json.$(date +%s)"
        log "Backup creado: $BACKUP_DIR/settings.json.*"
    fi
    
    # Crear o actualizar settings.json
    if [ ! -f "$SETTINGS_FILE" ]; then
        log "Creando settings.json (no existía)"
        cat > "$SETTINGS_FILE" << 'EOF'
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/load-memory-from-qdrant.sh",
            "timeout": 30
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/save-memory-to-qdrant.sh",
            "timeout": 10,
            "async": true
          }
        ]
      }
    ]
  }
}
EOF
    else
        log "Mergeando con settings.json existente..."
        
        # Usar jq para mergear
        jq '.hooks.SessionStart = [{
          "hooks": [{
            "type": "command",
            "command": "$HOME/.claude/hooks/load-memory-from-qdrant.sh",
            "timeout": 30
          }]
        }] | .hooks.PostToolUse = [{
          "matcher": "",
          "hooks": [{
            "type": "command",
            "command": "$HOME/.claude/hooks/save-memory-to-qdrant.sh",
            "timeout": 10,
            "async": true
          }]
        }]' "$BACKUP_DIR/settings.json.$(ls -t $BACKUP_DIR/settings.json.* 2>/dev/null | head -1 | xargs basename)" > "$SETTINGS_FILE.tmp"
        
        mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    fi
    
    success "settings.json actualizado"
}

################################################################################
# EJECUTAR VALIDACIONES
################################################################################

run_validations() {
    separator
    log "Ejecutando validaciones finales..."
    echo ""
    
    local validation_ok=true
    
    # 1. Config existe
    if [ -f "$CONFIG_FILE" ]; then
        success "Config file: $CONFIG_FILE"
    else
        error "Config file not found: $CONFIG_FILE"
        validation_ok=false
    fi
    
    # 2. Hooks son ejecutables
    if [ -x "$HOOKS_DIR/load-memory-from-qdrant.sh" ]; then
        success "SessionStart hook is executable"
    else
        error "SessionStart hook not executable"
        validation_ok=false
    fi
    
    if [ -x "$HOOKS_DIR/save-memory-to-qdrant.sh" ]; then
        success "PostToolUse hook is executable"
    else
        error "PostToolUse hook not executable"
        validation_ok=false
    fi
    
    # 3. Settings tiene hooks
    if grep -q "SessionStart" "$SETTINGS_FILE"; then
        success "SessionStart hook registered in settings.json"
    else
        error "SessionStart hook NOT registered in settings.json"
        validation_ok=false
    fi
    
    if grep -q "PostToolUse" "$SETTINGS_FILE"; then
        success "PostToolUse hook registered in settings.json"
    else
        error "PostToolUse hook NOT registered in settings.json"
        validation_ok=false
    fi
    
    # 4. CLI existe
    if [ -x "$TOOLS_DIR/claude-mem" ]; then
        success "CLI tool is executable"
    else
        error "CLI tool not executable"
        validation_ok=false
    fi
    
    # 5. Conexión a Qdrant
    if source "$CONFIG_FILE" && curl -s "$QDRANT_URL/health" | grep -q "title"; then
        success "Qdrant is accessible"
    else
        error "Qdrant is NOT accessible"
        validation_ok=false
    fi
    
    # 6. Colección existe
    if source "$CONFIG_FILE" && curl -s "$QDRANT_URL/collections/$COLLECTION_NAME" | grep -q "name"; then
        success "Collection '$COLLECTION_NAME' exists"
    else
        error "Collection '$COLLECTION_NAME' does NOT exist"
        validation_ok=false
    fi
    
    echo ""
    
    if [ "$validation_ok" = false ]; then
        error "Algunas validaciones fallaron. Revisa los errores arriba."
        return 1
    fi
    
    success "¡Todas las validaciones pasaron!"
    return 0
}

################################################################################
# MOSTRAR RESUMEN FINAL
################################################################################

show_summary() {
    separator
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║   ✨ INSTALACIÓN COMPLETADA EXITOSAMENTE ✨                   ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    echo "📊 CONFIGURACIÓN:"
    echo "   Servidor: $QDRANT_URL"
    echo "   Colección: $COLLECTION_NAME"
    echo "   Config: $CONFIG_FILE"
    echo ""
    
    echo "📁 ARCHIVOS CREADOS:"
    echo "   • Hooks: $HOOKS_DIR/"
    echo "   • Scripts: $SCRIPTS_DIR/"
    echo "   • Tools: $TOOLS_DIR/"
    echo ""
    
    echo "🚀 PRÓXIMOS PASOS:"
    echo ""
    echo "   1. Inicia una nueva sesión de Claude Code:"
    echo "      $ cd ~/tu-proyecto"
    echo "      $ claude-code"
    echo ""
    echo "   2. El hook SessionStart se ejecutará automáticamente"
    echo "      y mostrará la memoria del proyecto (si existe)"
    echo ""
    echo "   3. Cuando ejecutes comandos, PostToolUse guardará"
    echo "      automáticamente en Qdrant remoto"
    echo ""
    echo "   4. Consulta la memoria con:"
    echo "      $ ~/.claude/tools/claude-mem query"
    echo "      $ ~/.claude/tools/claude-mem list"
    echo "      $ ~/.claude/tools/claude-mem current"
    echo ""
    
    echo "📝 LOG DE INSTALACIÓN:"
    echo "   $INSTALL_LOG"
    echo ""
    
    echo "❓ AYUDA:"
    echo "   • Validar conexión: ~/.claude/scripts/validate-qdrant.sh"
    echo "   • Probar hook manual: ~/.claude/hooks/load-memory-from-qdrant.sh"
    echo "   • Ver config: cat ~/.claude/.qdrant-config"
    echo ""
}

################################################################################
# MAIN - FLUJO PRINCIPAL
################################################################################

main() {
    clear
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  🚀 INSTALADOR: Sistema de Memoria Remota Qdrant              ║"
    echo "║  Versión 2.0.0 | Colección: memoria                          ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Crear archivo de log
    mkdir -p "$LOGS_DIR"
    
    log "Iniciando instalación..."
    log "Inicio: $(date)"
    
    # Paso 1: Validar dependencias
    log ""
    separator
    validate_dependencies || exit 1
    
    # Paso 2: Obtener datos del usuario
    get_qdrant_config
    
    # Paso 3: Crear directorios
    separator
    create_directories
    
    # Paso 4: Crear config
    separator
    create_config
    
    # Paso 5: Validar conexión
    separator
    validate_qdrant_connection || exit 1
    
    # Paso 6: Crear/verificar colección
    separator
    create_or_verify_collection || exit 1
    
    # Paso 7: Crear script de validación
    separator
    create_validation_script
    
    # Paso 8: Crear hooks
    separator
    log "Desplegando hooks..."
    create_session_start_hook
    create_post_tool_use_hook
    echo ""
    
    # Paso 9: Crear CLI tool
    separator
    create_cli_tool
    
    # Paso 10: Actualizar settings.json
    separator
    update_settings_json
    
    # Paso 11: Validaciones finales
    run_validations || exit 1
    
    # Resumen final
    show_summary
    
    log "Fin: $(date)"
    success "Instalación completada. Log: $INSTALL_LOG"
}

# Ejecutar main
main
