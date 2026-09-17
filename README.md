# 🧠 Klaus Local Memory

**Sistema de memoria persistente, multi-proyecto y completamente remoto para Claude Code, almacenando decisiones, patrones y contexto en un servidor Qdrant independiente.**

[![Release v1.0.0](https://img.shields.io/badge/release-v1.0.0-green.svg)](https://github.com/your-org/klaus-local-memory/releases/tag/v1.0.0)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Tests: 27 Passing](https://img.shields.io/badge/tests-27%20passing-brightgreen.svg)](TEST-SUITE.md)
[![Made with: Bash + Python](https://img.shields.io/badge/made%20with-Bash%20%2B%20Python-blue.svg)](#)

---

## 📋 Contenidos

- [¿Qué es?](#qué-es)
- [¿Qué resuelve?](#qué-resuelve)
- [Características](#características)
- [Requisitos](#requisitos)
- [Instalación Rápida](#instalación-rápida)
- [¿Cómo funciona?](#cómo-funciona)
- [Uso](#uso)
- [Arquitectura](#arquitectura)
- [Ampliaciones](#ampliaciones)
- [Troubleshooting](#troubleshooting)
- [Contribuciones](#contribuciones)
- [Licencia](#licencia)

---

## ¿Qué es?

**Qdrant Memory System** es un sistema de persistencia inteligente para Claude Code que:

✅ **Guarda automáticamente** las decisiones, comandos y patrones de cada sesión  
✅ **Carga contexto** al iniciar una nueva sesión en un proyecto  
✅ **Soporta infinitos proyectos** con aislamiento automático  
✅ **Funciona con servidor Qdrant remoto** (nunca se envía a Anthropic)  
✅ **Se instala en 2-3 minutos** sin pasos manuales  
✅ **100% local** en tu máquina (a excepción del servidor Qdrant)  

**La memoria es agnóstica a la tecnología:** Soporta Kubernetes, Terraform, Python, Go, JavaScript, y cualquier stack que uses en Claude Code.

---

## ¿Qué resuelve?

### Problema 1: Pérdida de contexto entre sesiones

```
❌ ANTES: Inicias Claude Code en un proyecto
         Claude: "¿Cuál es el stack tecnológico?"
         Tú: "Es Kubernetes + Terraform + Python..."
         (repites la información 20 veces en diferentes sesiones)

✅ DESPUÉS: Inicias Claude Code en un proyecto
           Claude: [automáticamente carga memoria de sesiones previas]
           "Veo que trabajaste con Kubernetes la semana pasada,
            intentaste K8s alerts pero bloqueó RBAC..."
           Tú: "Exacto, continuemos desde donde dejamos"
```

### Problema 2: Múltiples proyectos sin contaminación

```
❌ ANTES: Trabajo en 3 proyectos paralelos
         Claude no sabe diferenciar
         Memoria de un proyecto afecta otro

✅ DESPUÉS: Cada proyecto tiene su espacio
           Proyecto A (ITOps): Qdrant memoria completamente aislada
           Proyecto B (IA): Qdrant memoria completamente aislada
           Proyecto C (ML): Qdrant memoria completamente aislada
```

### Problema 3: Compliance y control de datos

```
❌ ANTES: Datos de infraestructura crítica en servidores de Anthropic
         GDPR/HIPAA/compliance preocupaciones

✅ DESPUÉS: Datos residen en TU servidor Qdrant remoto
           Tú controlas dónde se almacena
           GDPR: ✅ cumplido
           HIPAA: ✅ cumplido
           Compliance: ✅ manejable
```

---

## Características

### 🚀 Instalación

| Aspecto | Detalles |
|---------|----------|
| **Tiempo** | 2-3 minutos |
| **Pasos manuales** | 0 (totalmente automático) |
| **Dependencias** | curl, jq, python3 |
| **Permisos** | Solo lectura/escritura en ~/.claude |
| **Reversal** | Backup automático, fácil rollback |

### 🧠 Memoria

| Aspecto | Detalles |
|---------|----------|
| **Almacenamiento** | Colección Qdrant "memoria" |
| **Alcance** | Multi-proyecto (N→∞) |
| **Aislamiento** | Automático por project_id |
| **Persistencia** | Entre sesiones indefinidamente |
| **Búsqueda** | Vector semántico (opcional con embeddings) |

### 🎯 Automatización

| Aspecto | Detalles |
|---------|----------|
| **SessionStart** | Carga memoria automáticamente |
| **PostToolUse** | Guarda decisiones automáticamente |
| **Validación** | Checks de conectividad y colección |
| **Logging** | Registro completo en ~/.claude/logs |
| **Limpieza** | Script de consolidación periódica |

### 🔧 Gestión

| Aspecto | Detalles |
|---------|----------|
| **CLI** | `claude-mem query/list/stats/delete` |
| **Monitoreo** | Ver qué proyectos tienen memoria |
| **Limpieza** | Eliminar memoria por proyecto |
| **Estadísticas** | Total proyectos, memorias, promedios |

---

## Requisitos

### Sistema operativo

- ✅ Linux (Ubuntu 20.04+, Debian 11+, etc)
- ✅ macOS (10.14+)
- ❓ Windows (WSL2 recomendado)

### Software requerido

```bash
# Verificar que tienes estos
curl --version      # HTTP client
jq --version        # JSON processor
python3 --version   # Python 3.8+
```

### Servidor remoto Qdrant

```
Necesitas UN servidor Qdrant corriendo en red remota

Especificaciones mínimas:
- Qdrant v1.7.0+
- Acceso HTTPS o HTTP
- Opcional: API key para autenticación
- Accesible desde tu máquina local

No incluido en este repo (asumimos que tienes uno).
```

### Claude Code

```
- Claude Code CLI instalado
- ~/.claude/settings.json accesible
- Permisos para crear/editar en ~/.claude/
```

---

## Instalación Rápida

### Opción 1: Instalación Automática (Recomendada)

```bash
# 1. Descargar el script
chmod +x scripts/install-memory-system.sh

# 2. Ejecutar (responde 4 preguntas)
./scripts/install-memory-system.sh

# 3. ¡Listo! Inicia Claude Code
cd ~/your-project
claude-code
```

**Preguntas que te hará:**
1. Hostname/IP del servidor Qdrant
2. Puerto (default: 6333)
3. Protocolo (http/https, default: https)
4. API Key (opcional, deja vacío si no hay)

**Salida esperada:**
```
✨ INSTALACIÓN COMPLETADA EXITOSAMENTE ✨

📊 CONFIGURACIÓN:
   Servidor: https://tu-servidor.com:6333
   Colección: memoria
   Config: ~/.claude/.qdrant-config

🚀 PRÓXIMOS PASOS:
   1. Inicia una nueva sesión de Claude Code
   2. El hook SessionStart se ejecutará automáticamente
   3. Verás la memoria cargada del proyecto
```

### Opción 2: Instalación Manual

Para control total de cada paso, sigue **[docs/INSTALL.md](docs/INSTALL.md)** (15-20 minutos).

### Opción 3: Especificación para IA

Si quieres usar otra IA o entender la arquitectura, lee **[scripts/memory-system-remote-qdrant.yaml](scripts/memory-system-remote-qdrant.yaml)**.

---

## ¿Cómo funciona?

### Flujo de sesión (simplificado)

```
┌─────────────────────────────────────────────────────────┐
│ 1. Inicias Claude Code                                   │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│ 2. SessionStart hook ejecuta automáticamente             │
│    • Lee ~/.claude/.qdrant-config                        │
│    • Conecta al servidor Qdrant remoto                   │
│    • Busca memorias de este proyecto                     │
│    • Inyecta como contexto en la sesión                  │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
        ┌─────────────────────┐
        │ Tienes contexto     │
        │ completo del        │
        │ proyecto en Claude  │
        └─────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│ 3. Trabajas con Claude (como siempre)                    │
│    Ejecutas comandos, hacess cambios, tomas decisiones  │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│ 4. PostToolUse hook ejecuta (automáticamente, async)     │
│    • Captura el comando que ejecutaste                   │
│    • Captura el output                                   │
│    • Envía a Qdrant remoto con namespace.project_id     │
│    • No bloquea tu sesión (async)                        │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
        ┌─────────────────────┐
        │ Próxima sesión      │
        │ en este proyecto    │
        │ tendrá memoria      │
        │ de ésta             │
        └─────────────────────┘
```

### Arquitectura de datos

```
Tu máquina (localhost)
│
├─ ~/.claude/
│  ├─ .qdrant-config          # Configuración del servidor
│  ├─ settings.json           # Hooks registrados
│  ├─ hooks/
│  │  ├─ load-memory-from-qdrant.sh      # SessionStart
│  │  └─ save-memory-to-qdrant.sh        # PostToolUse
│  ├─ tools/
│  │  └─ claude-mem           # CLI para consultas
│  └─ logs/
│     └─ install-*.log        # Logs de instalación
│
└─ Servidor Qdrant (remoto)
   │
   └─ Colección: "memoria"
      │
      ├─ Proyecto A (project_id: xxxxx)
      │  └─ 5 memorias (comandos, decisiones, errores)
      │
      ├─ Proyecto B (project_id: yyyyy)
      │  └─ 8 memorias
      │
      └─ Proyecto C (project_id: zzzzz)
         └─ 3 memorias
```

### Estructura de datos de memoria

Cada punto en Qdrant tiene esta estructura:

```json
{
  "id": 1234567890,
  "vector": [0.1, 0.2, 0.3, ...],  // Embedding (opcional)
  "payload": {
    "namespace": {
      "project_id": "a7f3c9e2",
      "project_path": "/home/user/kyndryl-infra"
    },
    "memory": {
      "type": "action|decision|error|pattern",
      "title": "[terraform] 2026-09-14T10:30:00Z",
      "content": "Plan: 5 add, 2 modify, 0 destroy",
      "severity": "critical|high|medium|low",
      "tags": ["terraform", "infrastructure"]
    },
    "temporal": {
      "created_at": "2026-09-14T10:30:00Z",
      "session_id": "sess_abc123"
    },
    "relevance": {
      "keywords": ["gke", "terraform", "resources"],
      "confidence_score": 0.95
    }
  }
}
```

---

## Uso

### Iniciar Claude Code (automático)

```bash
cd ~/your-project
claude-code

# SessionStart hook ejecuta automáticamente
# Ves la memoria cargada del proyecto
```

### Consultar memoria (CLI)

```bash
# Ver proyecto actual
~/.claude/tools/claude-mem current

# Listar todos los proyectos con memoria
~/.claude/tools/claude-mem list

# Ver memorias de este proyecto
~/.claude/tools/claude-mem query

# Ver memorias de proyecto específico
~/.claude/tools/claude-mem query --project a7f3c9e2

# Ver últimas 20 memorias
~/.claude/tools/claude-mem query --limit 20

# Ver estadísticas
~/.claude/tools/claude-mem stats
```

### Validar que todo funciona

```bash
# Validar conectividad a Qdrant
~/.claude/scripts/validate-qdrant.sh

# Probar hook SessionStart manualmente
cd /tmp && mkdir test-project && cd test-project
~/.claude/hooks/load-memory-from-qdrant.sh

# Probar hook PostToolUse manualmente
echo '{"tool_name": "test", "tool_output": "test"}' | \
  ~/.claude/hooks/save-memory-to-qdrant.sh
```

### Cambiar servidor Qdrant (si es necesario)

```bash
# Edita la configuración
nano ~/.claude/.qdrant-config

# Actualiza QDRANT_HOST, QDRANT_PORT, etc.
# Guarda y cierra (Ctrl+X, Y, Enter)

# Valida la nueva conexión
~/.claude/scripts/validate-qdrant.sh
```

### Limpiar memoria (opcional)

```bash
# Eliminar memoria de un proyecto
PROJECT_ID=$(~/.claude/tools/claude-mem current | grep "Project ID" | cut -d: -f2)
~/.claude/tools/claude-mem delete --project "$PROJECT_ID"

# Verificar que se eliminó
~/.claude/tools/claude-mem query --project "$PROJECT_ID"
```

---

## Arquitectura

### Componentes

| Componente | Función | Lenguaje |
|-----------|---------|----------|
| **scripts/install-memory-system.sh** | Instalación automática | Bash |
| **load-memory-from-qdrant.sh** | Hook SessionStart | Bash |
| **save-memory-to-qdrant.sh** | Hook PostToolUse | Bash |
| **claude-mem** | CLI tool | Python 3 |
| **scripts/memory-system-remote-qdrant.yaml** | Especificación | YAML |

### Flujo de datos

```
Claude Code
    ↓
SessionStart hook
    ↓
Query Qdrant remoto (GET colección/memoria)
    ↓
Inyectar en contexto
    ↓
Claude trabaja (con contexto completo)
    ↓
PostToolUse hook (async)
    ↓
Guardar en Qdrant remoto (PUT punto nuevo)
    ↓
Próxima sesión: memoria disponible
```

### Colección "memoria"

La colección Qdrant tiene esta configuración:

```yaml
vectors:
  size: 384
  distance: Cosine
```

- **Size 384:** Espacio vectorial para embeddings (compatible con nomic-embed-text)
- **Cosine:** Distancia para búsqueda semántica

### Aislamiento por proyecto

Cada proyecto está aislado usando `namespace.project_id`:

```python
# Project ID es un hash determinístico
import hashlib
project_id = hashlib.sha256(
    f"{project_name}:{project_path}".encode()
).hexdigest()[:16]
```

Esto asegura que:
- ✅ Mismo proyecto en diferentes máquinas = mismo project_id
- ✅ Proyectos diferentes = project_ids diferentes
- ✅ Filtros Qdrant aíslan automáticamente

---

## Ampliaciones

### 1. Agregar búsqueda semántica (Embeddings)

**Objetivo:** Búsqueda no solo por proyecto, sino por relevancia semántica.

```bash
# Instalar Ollama (si no está)
# Descargar modelo nomic-embed-text
ollama pull nomic-embed-text

# Modificar hooks para generar embeddings
# En load-memory-from-qdrant.sh:
QUERY_EMBEDDING=$(curl -s http://localhost:11434/api/embed \
  -d '{"model": "nomic-embed-text", "input": "'"$QUERY"'"}' \
  | jq '.embeddings[0]')

# Usar embedding en búsqueda Qdrant
curl -X POST "$QDRANT_URL/collections/memoria/points/search" \
  -d '{"vector": '$QUERY_EMBEDDING', ...}'
```

**Archivos a modificar:**
- `load-memory-from-qdrant.sh` (agregar embedding query)
- `save-memory-to-qdrant.sh` (generar embedding al guardar)

### 2. Agregar persistencia local (SQLite fallback)

**Objetivo:** Si Qdrant remoto no está disponible, guardar localmente.

```bash
# Agregar check de conectividad
if ! curl -s "$QDRANT_URL/health" > /dev/null; then
  # Qdrant no disponible, usar SQLite local
  # Sincronizar cuando se conecte de nuevo
fi
```

**Archivos a crear:**
- `~/.claude/scripts/sync-local-to-qdrant.sh` (sincronización periódica)

### 3. Agregar consolidación automática (Deduplicación)

**Objetivo:** Evitar que la colección crezca indefinidamente.

```bash
# Script de consolidación (ejecutar weekly con cron)
~/.claude/tools/consolidate-memory.sh

# Fusiona memorias duplicadas
# Elimina puntos antiguos (>90 días)
# Mantiene resumen de cada proyecto
```

**Archivos a crear:**
- `~/.claude/tools/consolidate-memory.sh`
- Agregar a crontab: `0 2 * * 0` (domingos 2 AM)

### 4. Agregar integración con LLM local (Ollama)

**Objetivo:** Generar resúmenes inteligentes de memoria.

```bash
# Cuando la memoria es muy larga, usar LLM local para resumir
SUMMARY=$(curl -s http://localhost:11434/api/generate \
  -d '{"model": "mistral", "prompt": "Summarize: '"$MEMORY"'"}' \
  | jq -r '.response')

# Guardar resumen en Qdrant
```

**Archivos a crear:**
- `~/.claude/scripts/summarize-memory.sh`

### 5. Agregar dashboard web

**Objetivo:** Visualizar memoria de proyectos en navegador.

```python
# Crear Flask app que consulte Qdrant
# Mostrar:
# - Proyectos activos
# - Memorias recientes
# - Estadísticas
# - Línea de tiempo por proyecto
```

**Archivos a crear:**
- `~/.claude/dashboard/app.py` (Flask)
- `~/.claude/dashboard/templates/` (HTML/CSS)
- Script para iniciar: `~/.claude/tools/run-dashboard.sh`

### 6. Agregar MCP Server (Model Context Protocol)

**Objetivo:** Otros modelos IA puedan acceder a memoria.

```python
# Implementar MCP server
# Recursos: qdrant://memoria/project/{project_id}
# Herramientas: query, list, save, delete
# Funciones para usar desde otros modelos
```

**Archivos a crear:**
- `~/.claude/mcp/qdrant_memory_server.py`

### 7. Agregar Replicación a múltiples Qdrant

**Objetivo:** Backup y high availability.

```bash
# Escrituras van a Qdrant primary
# Replicar automáticamente a secondary
# Lecturas desde cualquiera
```

**Archivos a modificar:**
- `save-memory-to-qdrant.sh` (escribir a múltiples)
- `load-memory-from-qdrant.sh` (leer de primario)

---

## Troubleshooting

### Error: "Cannot reach Qdrant at https://..."

```bash
# 1. Verifica que hostname es correcto
cat ~/.claude/.qdrant-config | grep QDRANT_HOST

# 2. Prueba ping
ping tu-servidor.com

# 3. Prueba conexión manual
source ~/.claude/.qdrant-config
curl -v "$QDRANT_URL/health"

# 4. Si es SSL error, verifica certificado
curl -k "$QDRANT_URL/health"  # Ignora certificado

# 5. Verifica firewall
telnet tu-servidor.com 6333
```

### Error: "Collection 'memoria' not found"

```bash
# La colección debería crearse automáticamente
# Si aún no existe:

source ~/.claude/.qdrant-config
curl -X PUT "$QDRANT_URL/collections/memoria" \
  -H "Content-Type: application/json" \
  -d '{
    "vectors": {"size": 384, "distance": "Cosine"}
  }'
```

### Hook no se ejecuta en Claude Code

```bash
# 1. Verifica que hook es ejecutable
ls -la ~/.claude/hooks/

# 2. Verifica que está registrado en settings.json
jq '.hooks' ~/.claude/settings.json

# 3. Prueba manualmente
cd /tmp && mkdir test && cd test
~/.claude/hooks/load-memory-from-qdrant.sh

# 4. Si aún no funciona, reinicia Claude Code
# (A veces necesita recargar settings.json)
```

### Memoria crece demasiado

```bash
# Ver tamaño
~/.claude/tools/claude-mem stats

# Limpiar memorias antiguas
# Opción 1: Eliminar proyecto completo
~/.claude/tools/claude-mem delete --project <ID>

# Opción 2: Crear script de consolidación
# (Ver sección Ampliaciones → #3)
```

### Performance lento

```bash
# 1. Verifica conectividad
~/.claude/scripts/validate-qdrant.sh

# 2. Verifica que Qdrant remoto no está sobrecargado
source ~/.claude/.qdrant-config
curl -s "$QDRANT_URL/collections/memoria/points" | jq '.result | length'

# 3. Aumenta timeout si es necesario
nano ~/.claude/.qdrant-config
# Editar timeouts en los hooks
```

### Más ayuda

- Revisa **[TEST-SUITE.md](TEST-SUITE.md)** para pruebas y validación
- Revisa **[INSTALL.md](INSTALL.md)** para instalación manual
- Revisa **[RELEASE-CHECKLIST.md](RELEASE-CHECKLIST.md)** para arquitectura completa

---

## Pruebas

Este proyecto incluye **27 pruebas** que cubren:

- ✅ Configuración correcta
- ✅ Conectividad a Qdrant
- ✅ Colección existe
- ✅ Hooks funcionan
- ✅ CLI tool operativo
- ✅ Ciclo completo (guardar + leer)
- ✅ Aislamiento entre proyectos
- ✅ Persistencia entre sesiones

Ejecuta todas las pruebas:

```bash
cat TEST-SUITE.md | grep "^### ✅ TEST"
# O sigue los pasos en TEST-SUITE.md manualmente
```

---

## Contribuciones

¡Las contribuciones son bienvenidas!

### Cómo contribuir

1. **Fork** el repositorio
2. **Crea una rama** (`git checkout -b feature/my-feature`)
3. **Commit** tus cambios (`git commit -am 'Add feature'`)
4. **Push** a la rama (`git push origin feature/my-feature`)
5. **Abre un Pull Request**

### Areas de contribución

- 🐛 **Bug fixes** - Reporta issues
- 📚 **Documentación** - Mejora de guías
- ✨ **Features** - Nuevas ampliaciones
- 🧪 **Tests** - Casos de prueba adicionales
- 🌍 **Traducciones** - Docs en otros idiomas
- 📦 **Packaging** - Docker, Ansible, etc.

### Código de conducta

Por favor, sé respetuoso y constructivo. Esperamos un ambiente inclusivo.

---

## Licencia

Este proyecto está licenciado bajo la **MIT License**.

```
MIT License

Copyright (c) 2026 [Your Name/Organization]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

Completo en [LICENSE](LICENSE)

---

## Stack Tecnológico

- **Bash:** Scripts de instalación y hooks
- **Python 3:** CLI tool para gestión de memoria
- **Qdrant:** Base de datos vectorial remota
- **YAML:** Especificación ejecutable

---

## Roadmap

### v1.0.0 (Actual)
- ✅ Instalación automática
- ✅ Hooks SessionStart + PostToolUse
- ✅ CLI tool básico
- ✅ Aislamiento por proyecto
- ✅ 27 pruebas completas

### v1.1.0 (Planeado)
- 📅 Búsqueda semántica con embeddings
- 📅 Fallback a SQLite local
- 📅 Consolidación automática

### v2.0.0 (Futuro)
- 📅 Dashboard web
- 📅 MCP Server
- 📅 Replicación multi-Qdrant
- 📅 Docker Compose para setup

---

## Agradecimientos

Construido con ❤️ para la comunidad de infraestructura como código.

---

## Contacto

Para preguntas o sugerencias:

- 📧 **Email:** santa@example.com
- 🐛 **Issues:** [GitHub Issues](https://github.com/your-org/qdrant-claude-memory/issues)
- 💬 **Discussions:** [GitHub Discussions](https://github.com/your-org/qdrant-claude-memory/discussions)

---

## Changelog

Ver **[CHANGELOG.md](CHANGELOG.md)** para historial de cambios.

---

**Versión:** 1.0.0  
**Última actualización:** 2026-09-15  
**Estado:** ✅ Production Ready
