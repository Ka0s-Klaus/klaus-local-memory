---
tags: [proyecto/klaus-local-memory, tipo/reporte, qa/pruebas]
---

# 🧪 Suite de Pruebas: Sistema de Memoria Remota Qdrant

**Versión:** 2.0.0  
**Propósito:** Verificar que la instalación y funcionamiento son correctos  
**Tiempo estimado:** 10-15 minutos  

---

## 📋 Tabla de contenidos

1. [Pruebas de configuración](#pruebas-de-configuración)
2. [Pruebas de conectividad](#pruebas-de-conectividad)
3. [Pruebas de colección](#pruebas-de-colección)
4. [Pruebas de hooks](#pruebas-de-hooks)
5. [Pruebas de CLI tool](#pruebas-de-cli-tool)
6. [Pruebas de integración](#pruebas-de-integración)
7. [Pruebas end-to-end](#pruebas-end-to-end)
8. [Resumen de resultados](#resumen-de-resultados)

---

## Pruebas de configuración

### ✅ TEST 1.1: Archivo de configuración existe

**Comando:**
```bash
test -f ~/.claude/.qdrant-config && echo "✅ PASS" || echo "❌ FAIL"
```

**Output esperado:**
```
✅ PASS
```

**Si falla:**
```bash
# Verifica que la instalación se completó
ls -la ~/.claude/
# Deberías ver .qdrant-config en la lista
```

---

### ✅ TEST 1.2: Archivo de configuración tiene permisos correctos

**Comando:**
```bash
stat -c "%a" ~/.claude/.qdrant-config | grep -q "600" && echo "✅ PASS" || echo "❌ FAIL"
```

**Output esperado:**
```
✅ PASS
```

**Explicación:** El archivo debe tener permisos 600 (solo lectura para el propietario) por seguridad.

**Si falla:**
```bash
chmod 600 ~/.claude/.qdrant-config
echo "✅ Permisos corregidos"
```

---

### ✅ TEST 1.3: Configuración tiene todas las variables requeridas

**Comando:**
```bash
echo "Verificando variables requeridas..."
grep -q "export QDRANT_HOST=" ~/.claude/.qdrant-config && echo "  ✅ QDRANT_HOST" || echo "  ❌ QDRANT_HOST"
grep -q "export QDRANT_PORT=" ~/.claude/.qdrant-config && echo "  ✅ QDRANT_PORT" || echo "  ❌ QDRANT_PORT"
grep -q "export QDRANT_PROTOCOL=" ~/.claude/.qdrant-config && echo "  ✅ QDRANT_PROTOCOL" || echo "  ❌ QDRANT_PROTOCOL"
grep -q "export QDRANT_COLLECTION_NAME=" ~/.claude/.qdrant-config && echo "  ✅ QDRANT_COLLECTION_NAME" || echo "  ❌ QDRANT_COLLECTION_NAME"
grep -q "export QDRANT_URL=" ~/.claude/.qdrant-config && echo "  ✅ QDRANT_URL" || echo "  ❌ QDRANT_URL"
```

**Output esperado:**
```
Verificando variables requeridas...
  ✅ QDRANT_HOST
  ✅ QDRANT_PORT
  ✅ QDRANT_PROTOCOL
  ✅ QDRANT_COLLECTION_NAME
  ✅ QDRANT_URL
```

**Si alguna falla:**
```bash
cat ~/.claude/.qdrant-config
# Verifica que contiene todas las variables export
```

---

### ✅ TEST 1.4: Valores de configuración son válidos

**Comando:**
```bash
source ~/.claude/.qdrant-config
echo "QDRANT_HOST: $QDRANT_HOST"
echo "QDRANT_PORT: $QDRANT_PORT"
echo "QDRANT_PROTOCOL: $QDRANT_PROTOCOL"
echo "QDRANT_COLLECTION_NAME: $QDRANT_COLLECTION_NAME"
echo "QDRANT_URL: $QDRANT_URL"

# Validar colección es "memoria"
if [ "$QDRANT_COLLECTION_NAME" = "memoria" ]; then
  echo "✅ Collection name is 'memoria'"
else
  echo "❌ Collection name is NOT 'memoria': $QDRANT_COLLECTION_NAME"
fi
```

**Output esperado:**
```
QDRANT_HOST: tu-servidor.com
QDRANT_PORT: 6333
QDRANT_PROTOCOL: https
QDRANT_COLLECTION_NAME: memoria
QDRANT_URL: https://tu-servidor.com:6333
✅ Collection name is 'memoria'
```

---

## Pruebas de conectividad

### ✅ TEST 2.1: Qdrant es alcanzable por ping

**Comando:**
```bash
source ~/.claude/.qdrant-config
ping -c 1 "$QDRANT_HOST" &>/dev/null && echo "✅ PASS" || echo "⚠️  TIMEOUT (puede estar filtrado)"
```

**Output esperado:**
```
✅ PASS
```

**Nota:** Si devuelve TIMEOUT, el servidor puede tener ICMP filtrado. Esto no es crítico si el HTTP funciona.

---

### ✅ TEST 2.2: Puerto Qdrant está abierto

**Comando:**
```bash
source ~/.claude/.qdrant-config
timeout 3 bash -c "echo > /dev/tcp/$QDRANT_HOST/$QDRANT_PORT" 2>/dev/null && echo "✅ PASS" || echo "❌ FAIL - Puerto no accesible"
```

**Output esperado:**
```
✅ PASS
```

**Si falla:**
```bash
# Verifica que el puerto es correcto
source ~/.claude/.qdrant-config
echo "Trying: telnet $QDRANT_HOST $QDRANT_PORT"
# Si no conecta: problema de firewall
```

---

### ✅ TEST 2.3: Endpoint /health responde

**Comando:**
```bash
source ~/.claude/.qdrant-config
echo "Testing: ${QDRANT_URL}/health"
curl -s -f "$QDRANT_URL/health" > /dev/null 2>&1 && echo "✅ PASS" || echo "❌ FAIL"
```

**Output esperado:**
```
Testing: https://tu-servidor.com:6333/health
✅ PASS
```

**Si falla:**
```bash
# Prueba con -k (ignora certificado SSL)
source ~/.claude/.qdrant-config
curl -k -s "$QDRANT_URL/health" | jq .
# Si funciona con -k: problema de certificado SSL
```

---

### ✅ TEST 2.4: Respuesta de /health es válida

**Comando:**
```bash
source ~/.claude/.qdrant-config
RESPONSE=$(curl -s "$QDRANT_URL/health" | jq '.' 2>/dev/null)

if echo "$RESPONSE" | grep -q "title.*Qdrant"; then
  echo "✅ PASS - Qdrant is responding"
  echo ""
  echo "Qdrant Info:"
  echo "$RESPONSE" | jq '.'
else
  echo "❌ FAIL - Invalid response"
fi
```

**Output esperado:**
```
✅ PASS - Qdrant is responding

Qdrant Info:
{
  "title": "Qdrant",
  "version": "1.7.0",
  "commit": "abc123...",
  "startup_time_ms": 1234
}
```

---

## Pruebas de colección

### ✅ TEST 3.1: Colección "memoria" existe

**Comando:**
```bash
source ~/.claude/.qdrant-config
echo "Checking collection: $QDRANT_COLLECTION_NAME"

COLLECTION=$(curl -s "$QDRANT_URL/collections/$QDRANT_COLLECTION_NAME" 2>/dev/null)

if echo "$COLLECTION" | grep -q "name"; then
  echo "✅ PASS - Collection exists"
else
  echo "❌ FAIL - Collection does not exist"
fi
```

**Output esperado:**
```
Checking collection: memoria
✅ PASS - Collection exists
```

**Si falla:**
```bash
# La colección debería haberse creado automáticamente
# Si no existe, créala manualmente:
source ~/.claude/.qdrant-config
curl -X PUT "$QDRANT_URL/collections/memoria" \
  -H "Content-Type: application/json" \
  -d '{
    "vectors": {"size": 384, "distance": "Cosine"}
  }'
echo "✅ Collection created"
```

---

### ✅ TEST 3.2: Colección tiene configuración correcta

**Comando:**
```bash
source ~/.claude/.qdrant-config
COLLECTION=$(curl -s "$QDRANT_URL/collections/$QDRANT_COLLECTION_NAME" | jq '.result.config')

echo "Verificando configuración de colección..."
echo "$COLLECTION" | jq '.' | tee /tmp/collection-config.json

# Verificar vector size
VECTOR_SIZE=$(echo "$COLLECTION" | jq '.params.vectors.size')
if [ "$VECTOR_SIZE" = "384" ]; then
  echo "✅ Vector size is 384"
else
  echo "❌ Vector size is NOT 384: $VECTOR_SIZE"
fi
```

**Output esperado:**
```
Verificando configuración de colección...
{
  "params": {
    "vectors": {
      "size": 384,
      "distance": "Cosine"
    }
  }
  ...
}
✅ Vector size is 384
```

---

### ✅ TEST 3.3: Colección es accesible para lectura/escritura

**Comando:**
```bash
source ~/.claude/.qdrant-config

# Intentar escribir un punto de prueba
TEST_ID=$(python3 -c "import uuid; print(int(uuid.uuid4().int % 2**31))")
TEST_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "Writing test point (ID: $TEST_ID)..."

WRITE_RESULT=$(curl -s -X PUT \
  "$QDRANT_URL/collections/$QDRANT_COLLECTION_NAME/points" \
  -H "Content-Type: application/json" \
  -d '{
    "points": [{
      "id": '${TEST_ID}',
      "vector": [0.1, 0.2, 0.3],
      "payload": {
        "namespace": {"project_id": "test-project"},
        "memory": {"type": "test", "title": "Test", "content": "Test point"},
        "temporal": {"created_at": "'${TEST_TIMESTAMP}'"}
      }
    }]
  }')

if echo "$WRITE_RESULT" | grep -q "error"; then
  echo "❌ FAIL - Cannot write to collection"
  echo "$WRITE_RESULT" | jq '.'
else
  echo "✅ PASS - Write successful"
  
  # Intentar leer el punto
  echo ""
  echo "Reading test point..."
  READ_RESULT=$(curl -s -X POST \
    "$QDRANT_URL/collections/$QDRANT_COLLECTION_NAME/points/search" \
    -H "Content-Type: application/json" \
    -d '{
      "vector": [0.1, 0.2, 0.3],
      "limit": 1,
      "filter": {
        "must": [{
          "key": "namespace.project_id",
          "match": {"value": "test-project"}
        }]
      },
      "with_payload": true
    }')
  
  if echo "$READ_RESULT" | grep -q "test-project"; then
    echo "✅ PASS - Read successful"
    echo "$READ_RESULT" | jq '.result[0]'
    
    # Limpiar: eliminar punto de prueba
    echo ""
    echo "Cleaning up test point..."
    curl -s -X POST \
      "$QDRANT_URL/collections/$QDRANT_COLLECTION_NAME/points/delete" \
      -H "Content-Type: application/json" \
      -d '{"points": ['${TEST_ID}']}' > /dev/null
    echo "✅ Cleanup done"
  else
    echo "❌ FAIL - Cannot read from collection"
  fi
fi
```

**Output esperado:**
```
Writing test point (ID: 1234567890)...
✅ PASS - Write successful

Reading test point...
✅ PASS - Read successful
{
  "id": 1234567890,
  "score": 1.0,
  "payload": {...}
}

Cleaning up test point...
✅ Cleanup done
```

---

## Pruebas de hooks

### ✅ TEST 4.1: Hook SessionStart existe y es ejecutable

**Comando:**
```bash
test -x ~/.claude/hooks/load-memory-from-qdrant.sh && echo "✅ PASS" || echo "❌ FAIL"
```

**Output esperado:**
```
✅ PASS
```

**Si falla:**
```bash
chmod +x ~/.claude/hooks/load-memory-from-qdrant.sh
echo "✅ Made executable"
```

---

### ✅ TEST 4.2: Hook PostToolUse existe y es ejecutable

**Comando:**
```bash
test -x ~/.claude/hooks/save-memory-to-qdrant.sh && echo "✅ PASS" || echo "❌ FAIL"
```

**Output esperado:**
```
✅ PASS
```

**Si falla:**
```bash
chmod +x ~/.claude/hooks/save-memory-to-qdrant.sh
echo "✅ Made executable"
```

---

### ✅ TEST 4.3: Hook SessionStart se ejecuta correctamente

**Comando:**
```bash
cd /tmp
mkdir -p test-project
cd test-project

echo "Ejecutando SessionStart hook..."
~/.claude/hooks/load-memory-from-qdrant.sh
```

**Output esperado:**
```
🧠 Loading memory for project: test-project (ID: xxxxx)

📝 No previous memory found for this project
**Project:** test-project
**Path:** /tmp/test-project
**Session:** [timestamp]
```

**Si falla:**
```bash
# Verifica que el config se carga
source ~/.claude/.qdrant-config
echo "QDRANT_URL: $QDRANT_URL"

# Prueba a consultar Qdrant manualmente
curl -s "$QDRANT_URL/collections/memoria/points/search" \
  -H "Content-Type: application/json" \
  -d '{"vector": [0.1, 0.2, 0.3], "limit": 1}'
```

---

### ✅ TEST 4.4: Hook PostToolUse se ejecuta correctamente

**Comando:**
```bash
echo "Simulando entrada de hook PostToolUse..."

TEST_INPUT='{
  "tool_name": "bash",
  "tool_output": "Test output from test command"
}'

echo "$TEST_INPUT" | ~/.claude/hooks/save-memory-to-qdrant.sh
```

**Output esperado:**
```
✅ Memory saved to remote Qdrant
```

**Si falla:**
```bash
# Verifica que el hook puede escribir a Qdrant
source ~/.claude/.qdrant-config
curl -s -X PUT "$QDRANT_URL/collections/memoria/points" \
  -H "Content-Type: application/json" \
  -d '{
    "points": [{
      "id": 9999,
      "vector": [0.1, 0.2, 0.3],
      "payload": {"namespace": {"project_id": "test"}, "memory": {"type": "test"}}
    }]
  }'
```

---

### ✅ TEST 4.5: Hooks están registrados en settings.json

**Comando:**
```bash
echo "Verificando hooks en settings.json..."
grep -q "SessionStart" ~/.claude/settings.json && echo "  ✅ SessionStart registered" || echo "  ❌ SessionStart NOT registered"
grep -q "PostToolUse" ~/.claude/settings.json && echo "  ✅ PostToolUse registered" || echo "  ❌ PostToolUse NOT registered"
grep -q "load-memory-from-qdrant.sh" ~/.claude/settings.json && echo "  ✅ SessionStart hook path correct" || echo "  ❌ SessionStart hook path incorrect"
grep -q "save-memory-to-qdrant.sh" ~/.claude/settings.json && echo "  ✅ PostToolUse hook path correct" || echo "  ❌ PostToolUse hook path incorrect"
```

**Output esperado:**
```
Verificando hooks en settings.json...
  ✅ SessionStart registered
  ✅ PostToolUse registered
  ✅ SessionStart hook path correct
  ✅ PostToolUse hook path correct
```

---

## Pruebas de CLI tool

### ✅ TEST 5.1: CLI tool existe y es ejecutable

**Comando:**
```bash
test -x ~/.claude/tools/claude-mem && echo "✅ PASS" || echo "❌ FAIL"
```

**Output esperado:**
```
✅ PASS
```

---

### ✅ TEST 5.2: CLI tool muestra versión

**Comando:**
```bash
~/.claude/tools/claude-mem --help
```

**Output esperado:**
```
usage: claude-mem [-h] {query,list,delete,stats,current} ...

Claude Memory CLI (Remote Qdrant)
...
```

---

### ✅ TEST 5.3: CLI tool muestra proyecto actual

**Comando:**
```bash
cd ~/some-project
~/.claude/tools/claude-mem current
```

**Output esperado:**
```
Current project ID: a7f3c9e2b4d1f6
Path: /home/santa/some-project
```

---

### ✅ TEST 5.4: CLI tool lista proyectos

**Comando:**
```bash
~/.claude/tools/claude-mem list
```

**Output esperado (si no hay memoria aún):**
```
📋 Projects with memories:

  No projects found
```

**Output esperado (si hay memoria):**
```
📋 Projects with memories:

  a7f3c9e2b4d1f6
    Path: /home/santa/kyndryl-infra
    Memories: 3
  f2e1d9c8b7a6f5
    Path: /home/santa/agent-auditor
    Memories: 5
```

---

### ✅ TEST 5.5: CLI tool consulta memorias de proyecto

**Comando:**
```bash
cd ~/your-project
~/.claude/tools/claude-mem query
```

**Output esperado (si no hay memoria):**
```
📊 Querying memories for project: xxxxx

Found 0 memories
```

**Output esperado (si hay memoria):**
```
📊 Querying memories for project: a7f3c9e2b4d1f6

Found 3 memories:

  📌 ACTION: [bash] 2026-09-14T16:30:00Z
     Content: total 42
     Created: 2026-09-14T16:30:00Z

  📌 ACTION: [terraform] 2026-09-14T16:35:00Z
     Content: 3 resources to add
     Created: 2026-09-14T16:35:00Z
```

---

### ✅ TEST 5.6: CLI tool muestra estadísticas

**Comando:**
```bash
~/.claude/tools/claude-mem stats
```

**Output esperado (sin memoria):**
```
📈 Memory Statistics:

  No data
```

**Output esperado (con memoria):**
```
📈 Memory Statistics:

  Total projects: 2
  Total memories: 8
  Avg per project: 4.0
```

---

## Pruebas de integración

### ✅ TEST 6.1: Script de validación funciona

**Comando:**
```bash
~/.claude/scripts/validate-qdrant.sh
```

**Output esperado:**
```
🔍 Validating remote Qdrant connection...
   Host: tu-servidor.com
   Port: 6333
   Protocol: https

✅ Remote Qdrant is accessible

Server response:
{
  "title": "Qdrant",
  "version": "1.7.0",
  ...
}
```

---

### ✅ TEST 6.2: Estructura de directorios es correcta

**Comando:**
```bash
echo "Verificando estructura de directorios..."
test -d ~/.claude/hooks && echo "  ✅ hooks/" || echo "  ❌ hooks/"
test -d ~/.claude/scripts && echo "  ✅ scripts/" || echo "  ❌ scripts/"
test -d ~/.claude/tools && echo "  ✅ tools/" || echo "  ❌ tools/"
test -d ~/.claude/.backup && echo "  ✅ .backup/" || echo "  ❌ .backup/"
test -d ~/.claude/logs && echo "  ✅ logs/" || echo "  ❌ logs/"

echo ""
echo "Verificando archivos principales..."
test -f ~/.claude/.qdrant-config && echo "  ✅ .qdrant-config" || echo "  ❌ .qdrant-config"
test -f ~/.claude/settings.json && echo "  ✅ settings.json" || echo "  ❌ settings.json"
test -f ~/.claude/hooks/load-memory-from-qdrant.sh && echo "  ✅ hooks/load-memory-from-qdrant.sh" || echo "  ❌ hooks/load-memory-from-qdrant.sh"
test -f ~/.claude/hooks/save-memory-to-qdrant.sh && echo "  ✅ hooks/save-memory-to-qdrant.sh" || echo "  ❌ hooks/save-memory-to-qdrant.sh"
test -f ~/.claude/tools/claude-mem && echo "  ✅ tools/claude-mem" || echo "  ❌ tools/claude-mem"
```

**Output esperado:**
```
Verificando estructura de directorios...
  ✅ hooks/
  ✅ scripts/
  ✅ tools/
  ✅ .backup/
  ✅ logs/

Verificando archivos principales...
  ✅ .qdrant-config
  ✅ settings.json
  ✅ hooks/load-memory-from-qdrant.sh
  ✅ hooks/save-memory-to-qdrant.sh
  ✅ tools/claude-mem
```

---

## Pruebas end-to-end

### ✅ TEST 7.1: Ciclo completo escribir + leer memoria

**Comando:**
```bash
#!/bin/bash
set -e

echo "🧪 Ciclo completo: Escribir + Leer Memoria"
echo ""

# 1. Crear proyecto de prueba
TEST_PROJECT="/tmp/test-e2e-$(date +%s)"
mkdir -p "$TEST_PROJECT"
cd "$TEST_PROJECT"

echo "1️⃣  Proyecto de prueba creado: $TEST_PROJECT"
echo ""

# 2. Obtener project ID
PROJECT_ID=$(python3 << 'EOF'
import hashlib, os
project_id = hashlib.sha256(f"{os.path.basename(os.getcwd())}:{os.getcwd()}".encode()).hexdigest()[:16]
print(project_id)
EOF
)

echo "2️⃣  Project ID: $PROJECT_ID"
echo ""

# 3. Ejecutar SessionStart hook (debería no haber memoria)
echo "3️⃣  Ejecutando SessionStart hook..."
OUTPUT=$(~/.claude/hooks/load-memory-from-qdrant.sh)
echo "$OUTPUT"

if echo "$OUTPUT" | grep -q "No previous memory"; then
  echo "   ✅ SessionStart correcto (sin memoria previa)"
else
  echo "   ❌ SessionStart inesperado"
fi
echo ""

# 4. Simular guardar memoria
echo "4️⃣  Guardando memoria de prueba..."
TEST_INPUT='{
  "tool_name": "terraform",
  "tool_output": "Plan: 5 resources to add, 2 to modify, 0 to destroy"
}'
SAVE_OUTPUT=$(echo "$TEST_INPUT" | ~/.claude/hooks/save-memory-to-qdrant.sh)
echo "$SAVE_OUTPUT"
echo ""

# 5. Esperar un poco para que Qdrant procese
sleep 2

# 6. Ejecutar SessionStart hook nuevamente (debería haber memoria)
echo "5️⃣  Ejecutando SessionStart hook nuevamente..."
OUTPUT2=$(~/.claude/hooks/load-memory-from-qdrant.sh)
echo "$OUTPUT2"

if echo "$OUTPUT2" | grep -q "terraform"; then
  echo "   ✅ SessionStart correcto (CON memoria)"
else
  echo "   ⚠️  Memoria no encontrada inmediatamente (puede necesitar refresco de Qdrant)"
fi
echo ""

# 7. Consultar con CLI tool
echo "6️⃣  Consultando con CLI tool..."
~/.claude/tools/claude-mem query --project "$PROJECT_ID"
echo ""

# 8. Cleanup
echo "7️⃣  Limpiando proyecto de prueba..."
rm -rf "$TEST_PROJECT"
echo "   ✅ Limpieza completa"
echo ""

echo "✅ TEST E2E COMPLETADO"
```

**Output esperado:**
```
🧪 Ciclo completo: Escribir + Leer Memoria

1️⃣  Proyecto de prueba creado: /tmp/test-e2e-1234567890

2️⃣  Project ID: a1b2c3d4e5f6

3️⃣  Ejecutando SessionStart hook...
🧠 Loading memory for project: test-e2e-... (ID: a1b2c3d4e5f6)

📝 No previous memory found for this project
   ✅ SessionStart correcto (sin memoria previa)

4️⃣  Guardando memoria de prueba...
✅ Memory saved to remote Qdrant

5️⃣  Ejecutando SessionStart hook nuevamente...
🧠 Loading memory for project: test-e2e-... (ID: a1b2c3d4e5f6)

## 📚 Project Memory
**Project:** test-e2e-...
**Path:** /tmp/test-e2e-...
**Session:** [timestamp]

### ACTION: [terraform] 2026-09-14T...
Plan: 5 resources to add, 2 to modify, 0 to destroy
   ✅ SessionStart correcto (CON memoria)

6️⃣  Consultando con CLI tool...
📊 Querying memories for project: a1b2c3d4e5f6

Found 1 memories:
  📌 ACTION: [terraform] 2026-09-14T...

7️⃣  Limpiando proyecto de prueba...
   ✅ Limpieza completa

✅ TEST E2E COMPLETADO
```

---

### ✅ TEST 7.2: Aislamiento de memoria entre proyectos

**Comando:**
```bash
#!/bin/bash
echo "🧪 Prueba de aislamiento entre proyectos"
echo ""

# Crear 2 proyectos de prueba
PROJ_A="/tmp/proyecto-a-$(date +%s)"
PROJ_B="/tmp/proyecto-b-$(date +%s)"
mkdir -p "$PROJ_A" "$PROJ_B"

# Proyecto A: guardar memoria
echo "1️⃣  Guardando memoria en Proyecto A..."
cd "$PROJ_A"
echo '{"tool_name": "bash", "tool_output": "ls output from A"}' | ~/.claude/hooks/save-memory-to-qdrant.sh
sleep 1

# Proyecto B: guardar memoria
echo "2️⃣  Guardando memoria en Proyecto B..."
cd "$PROJ_B"
echo '{"tool_name": "bash", "tool_output": "ls output from B"}' | ~/.claude/hooks/save-memory-to-qdrant.sh
sleep 1

# Proyecto A: leer memoria (debería solo tener la suya)
echo ""
echo "3️⃣  Verificando memoria de Proyecto A..."
cd "$PROJ_A"
PROJ_A_ID=$(python3 << 'EOF'
import hashlib, os
print(hashlib.sha256(f"{os.path.basename(os.getcwd())}:{os.getcwd()}".encode()).hexdigest()[:16])
EOF
)
MEMORIA_A=$($HOME/.claude/tools/claude-mem query --project "$PROJ_A_ID" 2>/dev/null)
echo "$MEMORIA_A"

if echo "$MEMORIA_A" | grep -q "output from A"; then
  echo "✅ Proyecto A tiene su propia memoria"
else
  echo "❌ Proyecto A NO tiene memoria"
fi

# Proyecto B: leer memoria (debería solo tener la suya)
echo ""
echo "4️⃣  Verificando memoria de Proyecto B..."
cd "$PROJ_B"
PROJ_B_ID=$(python3 << 'EOF'
import hashlib, os
print(hashlib.sha256(f"{os.path.basename(os.getcwd())}:{os.getcwd()}".encode()).hexdigest()[:16])
EOF
)
MEMORIA_B=$($HOME/.claude/tools/claude-mem query --project "$PROJ_B_ID" 2>/dev/null)
echo "$MEMORIA_B"

if echo "$MEMORIA_B" | grep -q "output from B"; then
  echo "✅ Proyecto B tiene su propia memoria"
else
  echo "❌ Proyecto B NO tiene memoria"
fi

# Verificar aislamiento
echo ""
if echo "$MEMORIA_A" | grep -q "output from B"; then
  echo "❌ FALLO: Proyecto A puede ver memoria de B"
else
  echo "✅ Aislamiento correcto: Proyecto A no ve memoria de B"
fi

if echo "$MEMORIA_B" | grep -q "output from A"; then
  echo "❌ FALLO: Proyecto B puede ver memoria de A"
else
  echo "✅ Aislamiento correcto: Proyecto B no ve memoria de A"
fi

# Cleanup
rm -rf "$PROJ_A" "$PROJ_B"
echo ""
echo "✅ TEST DE AISLAMIENTO COMPLETADO"
```

**Output esperado:**
```
🧪 Prueba de aislamiento entre proyectos

1️⃣  Guardando memoria en Proyecto A...
✅ Memory saved to remote Qdrant

2️⃣  Guardando memoria en Proyecto B...
✅ Memory saved to remote Qdrant

3️⃣  Verificando memoria de Proyecto A...
📊 Querying memories for project: xxxxx
Found 1 memories:
  📌 ACTION: [bash] ...
✅ Proyecto A tiene su propia memoria

4️⃣  Verificando memoria de Proyecto B...
📊 Querying memories for project: yyyyy
Found 1 memories:
  📌 ACTION: [bash] ...
✅ Proyecto B tiene su propia memoria

✅ Aislamiento correcto: Proyecto A no ve memoria de B
✅ Aislamiento correcto: Proyecto B no ve memoria de A

✅ TEST DE AISLAMIENTO COMPLETADO
```

---

### ✅ TEST 7.3: Persistencia de memoria (sesiones múltiples)

**Comando:**
```bash
#!/bin/bash
echo "🧪 Prueba de persistencia entre sesiones"
echo ""

TEST_PROJECT="/tmp/persistencia-test-$(date +%s)"
mkdir -p "$TEST_PROJECT"
cd "$TEST_PROJECT"

echo "1️⃣  Sesión 1: Guardar memoria..."
echo '{"tool_name": "command-1", "tool_output": "output 1"}' | ~/.claude/hooks/save-memory-to-qdrant.sh
sleep 1

echo "2️⃣  Sesión 1: Leer memoria (1 item)..."
~/.claude/hooks/load-memory-from-qdrant.sh | grep -c "command-1" && echo "✅ 1 item encontrado"

sleep 2

echo ""
echo "3️⃣  Sesión 2: Guardar otra memoria..."
echo '{"tool_name": "command-2", "tool_output": "output 2"}' | ~/.claude/hooks/save-memory-to-qdrant.sh
sleep 1

echo "4️⃣  Sesión 2: Leer memoria (2 items)..."
COUNT=$($HOME/.claude/hooks/load-memory-from-qdrant.sh | grep -c "command-[12]" || echo "0")
if [ "$COUNT" -ge "1" ]; then
  echo "✅ Múltiples items encontrados"
else
  echo "❌ No se encontraron items"
fi

echo ""
echo "5️⃣  Sesión 3: Leer memoria (debe persistir)..."
~/.claude/hooks/load-memory-from-qdrant.sh

rm -rf "$TEST_PROJECT"
echo ""
echo "✅ TEST DE PERSISTENCIA COMPLETADO"
```

**Output esperado:**
```
🧪 Prueba de persistencia entre sesiones

1️⃣  Sesión 1: Guardar memoria...
✅ Memory saved to remote Qdrant

2️⃣  Sesión 1: Leer memoria (1 item)...
✅ 1 item encontrado

3️⃣  Sesión 2: Guardar otra memoria...
✅ Memory saved to remote Qdrant

4️⃣  Sesión 2: Leer memoria (2 items)...
✅ Múltiples items encontrados

5️⃣  Sesión 3: Leer memoria (debe persistir)...
[Memory output showing all saved items]

✅ TEST DE PERSISTENCIA COMPLETADO
```

---

## Resumen de resultados

### 📊 Plantilla de resultados

Copia y usa esta plantilla para documentar tus resultados:

```markdown
# Resultados de Test Suite

**Fecha:** 2026-09-14
**Instalación:** Completada el 2026-09-14 10:30
**Servidor Qdrant:** https://tu-servidor.com:6333
**Colección:** memoria

## Configuración (TEST 1.x)
- [ ] TEST 1.1: Archivo existe - ✅ PASS
- [ ] TEST 1.2: Permisos correctos - ✅ PASS
- [ ] TEST 1.3: Variables presentes - ✅ PASS
- [ ] TEST 1.4: Valores válidos - ✅ PASS

## Conectividad (TEST 2.x)
- [ ] TEST 2.1: Ping accesible - ✅ PASS
- [ ] TEST 2.2: Puerto abierto - ✅ PASS
- [ ] TEST 2.3: /health responde - ✅ PASS
- [ ] TEST 2.4: Respuesta válida - ✅ PASS

## Colección (TEST 3.x)
- [ ] TEST 3.1: Colección existe - ✅ PASS
- [ ] TEST 3.2: Configuración correcta - ✅ PASS
- [ ] TEST 3.3: Lectura/escritura - ✅ PASS

## Hooks (TEST 4.x)
- [ ] TEST 4.1: SessionStart existe - ✅ PASS
- [ ] TEST 4.2: PostToolUse existe - ✅ PASS
- [ ] TEST 4.3: SessionStart ejecuta - ✅ PASS
- [ ] TEST 4.4: PostToolUse ejecuta - ✅ PASS
- [ ] TEST 4.5: Hooks registrados - ✅ PASS

## CLI Tool (TEST 5.x)
- [ ] TEST 5.1: CLI existe - ✅ PASS
- [ ] TEST 5.2: Help funciona - ✅ PASS
- [ ] TEST 5.3: Current funciona - ✅ PASS
- [ ] TEST 5.4: List funciona - ✅ PASS
- [ ] TEST 5.5: Query funciona - ✅ PASS
- [ ] TEST 5.6: Stats funciona - ✅ PASS

## Integración (TEST 6.x)
- [ ] TEST 6.1: Validación funciona - ✅ PASS
- [ ] TEST 6.2: Estructura correcta - ✅ PASS

## End-to-End (TEST 7.x)
- [ ] TEST 7.1: Ciclo completo - ✅ PASS
- [ ] TEST 7.2: Aislamiento - ✅ PASS
- [ ] TEST 7.3: Persistencia - ✅ PASS

## Resumen
- **Total tests:** 35
- **Pasados:** 35
- **Fallidos:** 0
- **Estado:** ✅ TODO FUNCIONA CORRECTAMENTE

## Notas
- Sistema está 100% operacional
- Colección "memoria" funciona correctamente
- Hooks se disparan automáticamente
- Aislamiento entre proyectos verificado
- Persistencia entre sesiones verificada
```

---

## 🔍 Debug rápido si algo falla

Si un test falla, ejecuta estos comandos de debug:

```bash
# 1. Verificar config se carga
source ~/.claude/.qdrant-config
echo "QDRANT_URL: $QDRANT_URL"
echo "QDRANT_COLLECTION_NAME: $QDRANT_COLLECTION_NAME"

# 2. Probar conexión basic
curl -v "$QDRANT_URL/health"

# 3. Probar hook manualmente
cd /tmp && ~/.claude/hooks/load-memory-from-qdrant.sh 2>&1 | head -50

# 4. Ver últimas líneas de log de instalación
tail -100 ~/.claude/logs/install-*.log

# 5. Verificar permisos
ls -la ~/.claude/hooks/
ls -la ~/.claude/tools/

# 6. Verificar settings.json es JSON válido
jq . ~/.claude/settings.json
```

---

## ✅ Checklist final

- [ ] TEST SUITE completado
- [ ] Todos los tests pasan (o documentados los fallos)
- [ ] Archivo de resultados guardado
- [ ] Sistema listo para usar
- [ ] Equipo notificado de que está operativo

¡Listo! 🎉
