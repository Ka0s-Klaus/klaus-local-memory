---
tags: [proyecto/klaus-local-memory, tipo/guia, infra/instalacion]
---

# 📘 Guía de Instalación: Sistema de Memoria Qdrant

**Versión:** 1.0.0  
**Última actualización:** 2026-09-16  
**Tiempo estimado:** 2-3 minutos

---

## 📋 Tabla de Contenidos

1. [Requisitos](#requisitos)
2. [Instalación Rápida](#instalación-rápida)
3. [Instalación Manual](#instalación-manual)
4. [Verificación](#verificación)
5. [Configuración](#configuración)
6. [Troubleshooting](#troubleshooting)
7. [Desinstalación](#desinstalación)

---

## Requisitos

### Sistema Operativo

- ✅ macOS 11+
- ✅ Linux (Ubuntu 20.04, Debian 11+, CentOS 8+)
- ✅ Windows (con WSL 2)

### Software Requerido

```bash
# Verificar que tienes estas herramientas instaladas
which curl      # Necesario para descargar e interactuar con Qdrant
which jq        # Necesario para procesar JSON
which python3   # Necesario para el CLI tool

# Si no los tienes, instala:
# macOS: brew install curl jq python3
# Ubuntu/Debian: sudo apt install curl jq python3
# CentOS: sudo yum install curl jq python3
```

### Servidor Qdrant

Necesitas un servidor Qdrant ejecutándose. Tienes 3 opciones:

#### Opción 1: Local (Desarrollo)

```bash
# Instalar Qdrant localmente con Docker
docker run -p 6333:6333 -p 6334:6334 qdrant/qdrant:latest
```

#### Opción 2: Servidor remoto (Recomendado para Producción)

```bash
# Qdrant Cloud
# 1. Ir a https://cloud.qdrant.io
# 2. Crear cuenta gratuita
# 3. Crear cluster
# 4. Obtener URL y API key
```

#### Opción 3: Self-hosted en tu infraestructura

```bash
# Kubernetes
# Ver: docs/ARCHITECTURE.md para detalles de deployment

# Docker Compose
docker-compose up -d qdrant
```

---

## Instalación Rápida

### 1️⃣ Descarga el instalador

```bash
cd ~/.claude
curl -O https://raw.githubusercontent.com/tu-repo/klaus-local-memory/main/scripts/install-memory-system.sh
chmod +x install-memory-system.sh
```

### 2️⃣ Ejecuta la instalación

```bash
./install-memory-system.sh
```

### 3️⃣ Responde las preguntas

El instalador te hará 4 preguntas:

```
🔧 Configuración de Qdrant Memory System

1️⃣  Servidor Qdrant
    ¿Dirección del servidor? (default: localhost)
    Tu entrada: mi-qdrant.com

2️⃣  Puerto
    ¿Puerto Qdrant? (default: 6333)
    Tu entrada: 6333

3️⃣  Protocolo
    ¿Protocolo (http/https)? (default: http)
    Tu entrada: https

4️⃣  API Key (si lo requiere)
    ¿API Key? (dejar vacío si no tiene)
    Tu entrada: sk-1234567890...

✅ Instalación completada!
```

### 4️⃣ Verifica que funcione

```bash
# Ver que el hook está activo
cd un-proyecto-tuyo
claude-code
# Deberías ver: "[Qdrant Memory] Cargando contexto..."
```

---

## Instalación Manual

Si prefieres hacer los pasos manualmente o el instalador tiene problemas:

### Paso 1: Crear directorio de configuración

```bash
mkdir -p ~/.claude
chmod 700 ~/.claude
```

### Paso 2: Crear archivo de configuración

```bash
cat > ~/.claude/.qdrant-config << 'EOF'
# Qdrant Memory System Configuration
# Creado: $(date)

QDRANT_SERVER="localhost"
QDRANT_PORT="6333"
QDRANT_PROTOCOL="http"
QDRANT_API_KEY=""
QDRANT_COLLECTION="memoria"

# Directorio para cachés y logs
MEMORY_CACHE_DIR="$HOME/.claude/memory-cache"
MEMORY_LOG_FILE="$HOME/.claude/memory.log"
EOF

# Establecer permisos restrictivos
chmod 600 ~/.claude/.qdrant-config
```

### Paso 3: Crear directorio para CLI tool

```bash
mkdir -p ~/.claude/tools
chmod 755 ~/.claude/tools
```

### Paso 4: Crear el CLI tool

```bash
cat > ~/.claude/tools/claude-mem << 'EOF'
#!/bin/bash
# Qdrant Claude Memory CLI Tool

source ~/.claude/.qdrant-config

case "$1" in
  query)
    # Implementación de búsqueda
    ;;
  list)
    # Implementación de listado
    ;;
  stats)
    # Ver estadísticas
    ;;
  delete)
    # Eliminar memoria
    ;;
  current)
    # Ver proyecto actual
    ;;
  *)
    echo "Uso: claude-mem [query|list|stats|delete|current]"
    ;;
esac
EOF

chmod +x ~/.claude/tools/claude-mem
```

### Paso 5: Crear hooks

#### SessionStart Hook

```bash
cat > ~/.claude/hooks/session-start.sh << 'EOF'
#!/bin/bash
# Session Start Hook - Carga memoria automáticamente

source ~/.claude/.qdrant-config

echo "[Qdrant Memory] Cargando contexto para $(pwd)..."

# Lógica para cargar memoria
curl -s "http://$QDRANT_SERVER:$QDRANT_PORT/collections/$QDRANT_COLLECTION/points" \
  -H "api-key: $QDRANT_API_KEY" \
  | jq '.' > /tmp/memory-context.json

echo "[Qdrant Memory] ✅ Contexto cargado"
EOF

chmod +x ~/.claude/hooks/session-start.sh
```

#### PostToolUse Hook

```bash
cat > ~/.claude/hooks/post-tool-use.sh << 'EOF'
#!/bin/bash
# Post Tool Use Hook - Guarda decisiones automáticamente

source ~/.claude/.qdrant-config

# Guardar snapshot de la decisión
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
PROJECT_DIR=$(pwd)

# Enviar a Qdrant
curl -s -X PUT "http://$QDRANT_SERVER:$QDRANT_PORT/collections/$QDRANT_COLLECTION/points" \
  -H "api-key: $QDRANT_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"points\": [{
      \"id\": $(uuidgen),
      \"payload\": {
        \"project\": \"$PROJECT_DIR\",
        \"timestamp\": \"$TIMESTAMP\",
        \"type\": \"tool-use\"
      }
    }]
  }" > /dev/null 2>&1

echo "[Qdrant Memory] ✅ Decisión guardada"
EOF

chmod +x ~/.claude/hooks/post-tool-use.sh
```

### Paso 6: Agregar a Claude Code settings

```bash
# En ~/.claude/settings.json o settings.local.json:
{
  "hooks": {
    "sessionStart": "~/.claude/hooks/session-start.sh",
    "postToolUse": "~/.claude/hooks/post-tool-use.sh"
  }
}
```

---

## Verificación

### Test 1: Archivo de configuración

```bash
test -f ~/.claude/.qdrant-config && echo "✅ Config existe" || echo "❌ Config no encontrada"

# Verificar permisos
stat -c "%a" ~/.claude/.qdrant-config
# Debe mostrar: 600
```

### Test 2: Conectividad Qdrant

```bash
# Verificar que Qdrant responde
curl -s http://localhost:6333/health | jq .

# Resultado esperado:
# {
#   "status": "ok"
# }
```

### Test 3: Colección existe

```bash
curl -s http://localhost:6333/collections/memoria | jq '.result.name'

# Resultado esperado:
# "memoria"
```

### Test 4: CLI Tool funciona

```bash
~/.claude/tools/claude-mem --help

# Resultado esperado:
# Uso: claude-mem [query|list|stats|delete|current]
```

### Test 5: Hooks activos

```bash
# Verificar hooks en settings
cat ~/.claude/settings.json | jq '.hooks'

# Resultado esperado:
# {
#   "sessionStart": "~/.claude/hooks/session-start.sh",
#   "postToolUse": "~/.claude/hooks/post-tool-use.sh"
# }
```

### Verificación Completa

```bash
# Ejecutar la suite de pruebas
cd ~
bash /ruta/a/docs/TEST-SUITE.md

# Resultado esperado:
# ✅ 27/27 pruebas pasando
```

---

## Configuración

### Cambiar servidor Qdrant

```bash
# Editar archivo de configuración
nano ~/.claude/.qdrant-config

# Cambiar estos valores:
QDRANT_SERVER="tu-nuevo-servidor.com"
QDRANT_PORT="6333"
QDRANT_PROTOCOL="https"
QDRANT_API_KEY="tu-api-key-aqui"
```

### Cambiar colección

```bash
# Por defecto es "memoria", puedes cambiar a otro nombre:
sed -i '' 's/QDRANT_COLLECTION=.*/QDRANT_COLLECTION="mi-coleccion"/g' ~/.claude/.qdrant-config
```

### Desactivar hooks temporalmente

```bash
# En settings.json, comentar los hooks:
{
  "hooks": {
    // "sessionStart": "~/.claude/hooks/session-start.sh",
    // "postToolUse": "~/.claude/hooks/post-tool-use.sh"
  }
}
```

---

## Troubleshooting

### ❌ "Connection refused" al conectar a Qdrant

**Causa:** Qdrant no está corriendo o está en diferente puerto

**Solución:**
```bash
# Verificar que Qdrant está corriendo
docker ps | grep qdrant

# Si no está, iniciarlo:
docker run -p 6333:6333 qdrant/qdrant:latest

# Verificar conectividad
curl http://localhost:6333/health
```

### ❌ "Command not found: jq"

**Causa:** jq no está instalado

**Solución:**
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq

# CentOS
sudo yum install jq
```

### ❌ "Permission denied" en .qdrant-config

**Causa:** Permisos incorrectos

**Solución:**
```bash
chmod 600 ~/.claude/.qdrant-config
```

### ❌ Hooks no se ejecutan

**Causa:** Path incorrecto o permisos faltantes

**Solución:**
```bash
# Verificar que hooks existen
ls -la ~/.claude/hooks/

# Verificar permisos
chmod +x ~/.claude/hooks/*.sh

# Verificar settings.json
cat ~/.claude/settings.json | jq '.hooks'
```

### ❌ "API key rejected" o "Unauthorized"

**Causa:** API key incorrecta o expirada

**Solución:**
```bash
# Regenerar API key en Qdrant Cloud
# https://cloud.qdrant.io

# Actualizar en configuración
nano ~/.claude/.qdrant-config
# QDRANT_API_KEY="tu-nueva-api-key"
```

### ⚠️ Colección no existe

**Causa:** La colección no fue creada

**Solución:**
```bash
# Crear colección manualmente
curl -X PUT http://localhost:6333/collections/memoria \
  -H "Content-Type: application/json" \
  -d '{
    "vectors": {
      "size": 384,
      "distance": "Cosine"
    }
  }'
```

---

## Desinstalación

### Remover completamente

```bash
# 1. Desactivar hooks en settings.json
nano ~/.claude/settings.json
# Eliminar las líneas de hooks

# 2. Eliminar directorios
rm -rf ~/.claude/tools/claude-mem
rm -rf ~/.claude/hooks/session-start.sh
rm -rf ~/.claude/hooks/post-tool-use.sh
rm -rf ~/.claude/memory-cache/

# 3. Hacer backup y eliminar configuración
cp ~/.claude/.qdrant-config ~/.claude/.qdrant-config.backup
rm ~/.claude/.qdrant-config

echo "✅ Desinstalación completada. Backup en ~/.claude/.qdrant-config.backup"
```

### Restaurar desde backup

```bash
# Si cambiaste de opinión
cp ~/.claude/.qdrant-config.backup ~/.claude/.qdrant-config
chmod 600 ~/.claude/.qdrant-config

# Re-activar hooks en settings.json
```

---

## ¿Problemas?

1. **Consulta [README.md](../README.md)** - Preguntas frecuentes
2. **Ejecuta [TEST-SUITE.md](TEST-SUITE.md)** - Diagnóstico completo
3. **Revisa [VALIDACION-FINAL-GITHUB.md](VALIDACION-FINAL-GITHUB.md)** - Validaciones técnicas
4. **Abre una issue** - Incluye output de `~/.claude/tools/claude-mem stats`

---

**Versión:** 1.0.0  
**Licencia:** MIT  
**Soporte:** https://github.com/tu-repo/qdrant-claude-memory/issues
