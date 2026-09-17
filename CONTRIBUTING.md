# 🤝 Contribuyendo a Qdrant Memory System

¡Gracias por tu interés en contribuir! Este documento proporciona las directrices y pasos para contribuir al proyecto.

## 📋 Contenidos

- [Código de Conducta](#código-de-conducta)
- [¿Cómo Puedo Contribuir?](#cómo-puedo-contribuir)
- [Reportar Bugs](#reportar-bugs)
- [Sugerir Mejoras](#sugerir-mejoras)
- [Pull Requests](#pull-requests)
- [Desarrollo Local](#desarrollo-local)
- [Guía de Estilo](#guía-de-estilo)
- [Proceso de Revisión](#proceso-de-revisión)

---

## Código de Conducta

Este proyecto y todos los que participan en él se rigen por nuestro Código de Conducta. Al participar, se espera que mantengas este código. Por favor, reporta comportamiento inaceptable a través de issues.

---

## ¿Cómo Puedo Contribuir?

### Reportar Bugs

Los bugs se rastrean como [GitHub issues](https://github.com/username/qdrant-claude-memory/issues).

Cuando reportes un bug, incluye:

- **Resumen claro y descriptivo** del problema
- **Pasos específicos** para reproducir el problema
- **Comportamiento observado** vs **comportamiento esperado**
- **Capturas de pantalla o logs** si es relevante
- **Tu entorno** (OS, versión de Claude Code, etc.)
- **Output de `~/.claude/tools/claude-mem stats`** para contexto

**Ejemplo de reporte:**

```
Título: SessionStart hook no carga memoria en proyectos nuevos

Descripción:
Cuando creo un nuevo proyecto y lo abro en Claude Code, el hook SessionStart 
no carga la memoria automáticamente.

Pasos para reproducir:
1. mkdir test-project
2. cd test-project
3. claude-code
4. Revisar console - no hay output del hook

Comportamiento esperado:
El hook debería imprimir "[Qdrant Memory] Cargando contexto..." 

Environment:
- OS: macOS 14.1
- Claude Code: v1.0.0
- Qdrant: 1.7.0
```

### Sugerir Mejoras

Las sugerencias se rastrean como [GitHub issues](https://github.com/username/qdrant-claude-memory/issues) con etiqueta `enhancement`.

Cuando sugieras una mejora, incluye:

- **Descripción clara** de la mejora
- **Caso de uso** o **escenario de ejemplo**
- **Beneficios** esperados
- **Posibles alternativas** o enfoques

---

## Pull Requests

### Antes de empezar

1. **Fork el repositorio** en tu cuenta de GitHub
2. **Crea una rama** desde `main` con nombre descriptivo:
   ```bash
   git checkout -b feature/mi-nueva-feature
   # o
   git checkout -b fix/corregir-bug-especifico
   ```

### Haciendo cambios

1. **Actualiza el código** en tu rama
2. **Añade/actualiza tests** si es necesario
3. **Ejecuta la suite de pruebas**:
   ```bash
   # Para verificar cambios en install-memory-system.sh
   bash -n install-memory-system.sh
   
   # Para ejecutar tests completos
   bash docs/TEST-SUITE.md
   ```
4. **Actualiza documentación** si es necesario
5. **Asegúrate de que no hay secrets** en el código

### Enviando el PR

1. **Push a tu rama**:
   ```bash
   git push origin feature/mi-nueva-feature
   ```

2. **Abre un Pull Request** con:
   - Título claro y conciso
   - Descripción del cambio
   - Referencia a issues relacionados (si aplica)
   - Checklist de verificación:
     - [ ] Mi código sigue las guías de estilo
     - [ ] He actualizado la documentación
     - [ ] He añadido tests para mis cambios
     - [ ] Todos los tests pasan
     - [ ] No hay secrets hardcoded

**Ejemplo de descripción de PR:**

```
## Descripción

Añade búsqueda semántica a la CLI tool usando embeddings de OpenAI.

Closes #42

## Cambios

- Nuevo comando `claude-mem semantic-search` 
- Integración con OpenAI Embeddings API
- 5 tests nuevos en TEST-SUITE.md
- Documentación actualizada en README.md

## Testing

- [x] Tests locales pasando
- [x] Verificación de seguridad completada
- [x] Sin secrets hardcoded
```

---

## Desarrollo Local

### Configuración inicial

```bash
# Clonar tu fork
git clone https://github.com/tu-usuario/qdrant-claude-memory.git
cd qdrant-claude-memory

# Crear rama de desarrollo
git checkout -b dev

# Configurar remotes
git remote add upstream https://github.com/original-repo/qdrant-claude-memory.git
```

### Ejecutar la suite de pruebas

```bash
# Validar sintaxis de Bash
bash -n scripts/install-memory-system.sh

# Ejecutar todos los tests
cd docs
bash TEST-SUITE.md

# Ver estadísticas de cobertura
~/.claude/tools/claude-mem stats
```

### Testear localmente antes de PR

```bash
# Limpiar instalación anterior (si existe)
rm -rf ~/.claude/.qdrant-config

# Instalar desde tu rama
./scripts/install-memory-system.sh
# Seguir prompts interactivos

# Verificar que funciona
cd some-project
claude-code
# Revisar que el hook se ejecuta
```

---

## Guía de Estilo

### Bash

- Usar `#!/bin/bash` al inicio de scripts
- Usar 2 espacios para indentación
- Nombrar variables en UPPER_CASE
- Nombrar funciones en lower_case
- Siempre usar `"$VAR"` (entre comillas) para variables
- Comentarios en inglés, código en cualquier idioma
- Evitar comandos obsoletos (usar `[[` en lugar de `[`)

**Ejemplo:**

```bash
#!/bin/bash

QDRANT_SERVER="localhost"
QDRANT_PORT="6333"

validate_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file not found"
    return 1
  fi
  return 0
}
```

### YAML

- Usar 2 espacios para indentación
- Mantener consistencia con memoria-system-remote-qdrant.yaml
- Validar con `yamllint` si es posible

### Documentación

- Usar Markdown
- Incluir ejemplos prácticos
- Mantener TOC actualizado
- Actualizar CHANGELOG.md

### Python (si es necesario)

- Seguir PEP 8
- Type hints cuando sea posible
- Docstrings en format Google
- 4 espacios de indentación

---

## Proceso de Revisión

1. **Revisión automática** de CI/CD
2. **Revisión manual** por mantenedores
3. **Tests** deben pasar
4. **Documentación** debe estar actualizada
5. **Feedback** será proporcionado en el PR
6. **Merge** cuando todo esté aprobado

### Qué buscamos

- ✅ Código que sigue las guías de estilo
- ✅ Tests que cubren los cambios
- ✅ Documentación clara y actualizada
- ✅ Commits con mensajes descriptivos
- ✅ Sin secrets o datos sensibles
- ✅ Compatible con v1.0.0 y hacia adelante

---

## Áreas Donde Necesitamos Ayuda

### 🎯 High Impact

- [ ] Implementar embeddings semánticos (v1.1)
- [ ] Crear dashboard web (v2.0)
- [ ] Añadir MCP Server (v2.0)

### 📚 Documentación

- [ ] Guías de troubleshooting en más idiomas
- [ ] Ejemplos de uso avanzado
- [ ] Video tutorial de instalación

### 🧪 Testing

- [ ] Expand TEST-SUITE.md
- [ ] Automated CI/CD tests
- [ ] Load testing

### 💬 Community

- [ ] Responder issues
- [ ] Ayudar a nuevos usuarios
- [ ] Compartir feedback

---

## Preguntas?

- 📖 Lee el [README.md](README.md)
- 📘 Revisa [INSTALL.md](docs/INSTALL.md)
- 🧪 Consulta [TEST-SUITE.md](docs/TEST-SUITE.md)
- 📝 Abre una [discussion](https://github.com/username/qdrant-claude-memory/discussions)

---

## Licencia

Al contribuir, aceptas que tus contribuciones se licencien bajo la misma [MIT License](LICENSE) que el proyecto.

---

**¡Gracias por contribuir! 🙏**
