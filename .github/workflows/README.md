# GitHub Actions para Turneros

Este directorio contiene los workflows de GitHub Actions para automatización del proyecto Turneros.

## 🔄 Workflows Configurados

### 1. Firebase Hosting Deploy (Producción)
**Archivo**: `firebase-hosting-merge.yml`
- **Trigger**: Push a branch `main` con cambios en `Frontend/turneros_app/`
- **Acción**: Build y deploy automático a Firebase Hosting
- **URL**: https://turneros.web.app/

### 2. Firebase Hosting Preview (Pull Requests)
**Archivo**: `firebase-hosting-pull-request.yml`
- **Trigger**: Pull Requests
- **Acción**: Deploy a preview channel para testing

### 3. Monitoreo del Proyecto
**Archivo**: `project-status.yml`
- **Trigger**: Cada 6 horas + push/PR
- **Funciones**:
  - Análisis de código Flutter
  - Análisis de código Python (Backend)
  - Health check del hosting
  - Métricas del proyecto
  - Escaneo de seguridad

### 4. Monitoreo de Firebase
**Archivo**: `firebase-monitoring.yml`
- **Trigger**: Cada hora (8 AM - 8 PM UTC)
- **Funciones**:
  - Status de Firebase Hosting
  - Métricas de performance
  - Verificación de certificado SSL
  - Monitoreo de uptime
  - Reportes de estado

## 🔧 Configuración Requerida

### Secrets de GitHub
Para que los workflows funcionen correctamente, necesitas configurar estos secrets en tu repositorio de GitHub:

1. `FIREBASE_SERVICE_ACCOUNT_FARMATURNOS`: Service account key de Firebase
   - Ve a Firebase Console > Project Settings > Service Accounts
   - Genera una nueva clave privada
   - Copia el contenido del JSON y agrégalo como secret

### Permisos Requeridos
- Los workflows necesitan permisos de lectura/escritura en el repositorio
- GitHub Actions debe estar habilitado en el repositorio

## 📊 Badges de Estado

Puedes agregar estos badges a tu README principal:

```markdown
[![Firebase Hosting](https://github.com/TU_USUARIO/TU_REPO/actions/workflows/firebase-hosting-merge.yml/badge.svg)](https://github.com/TU_USUARIO/TU_REPO/actions/workflows/firebase-hosting-merge.yml)

[![Project Status](https://github.com/TU_USUARIO/TU_REPO/actions/workflows/project-status.yml/badge.svg)](https://github.com/TU_USUARIO/TU_REPO/actions/workflows/project-status.yml)

[![Firebase Monitoring](https://github.com/TU_USUARIO/TU_REPO/actions/workflows/firebase-monitoring.yml/badge.svg)](https://github.com/TU_USUARIO/TU_REPO/actions/workflows/firebase-monitoring.yml)
```

## 🚀 Deployment Process

1. **Desarrollo**: Trabaja en una rama feature
2. **Pull Request**: Crea PR → trigger preview deployment
3. **Review**: Revisa changes en la preview URL
4. **Merge**: Merge a main → deploy automático a producción

## 📱 Configuración de Firebase

### Web App Configuration
```javascript
const firebaseConfig = {
  apiKey: "AIzaSyC5z1BqnClJ6puVr6z2saJp3e0u1RgHGQI",
  authDomain: "farmaturnos.firebaseapp.com", 
  projectId: "farmaturnos",
  storageBucket: "farmaturnos.firebasestorage.app",
  messagingSenderId: "228344336816",
  appId: "1:228344336816:web:88b5b4e288da8b46c50675",
  measurementId: "G-WZ87JKNHDX"
};
```

### Hosting URL
- **Producción**: https://turneros.web.app/
- **Preview**: URLs generadas automáticamente para PRs

## 🔍 Monitoreo y Alertas

Los workflows incluyen:
- ✅ Health checks automáticos
- 📊 Métricas de performance
- 🔒 Verificación de SSL
- ⏰ Monitoreo de uptime
- 📈 Análisis de código continuo

## 🛠️ Troubleshooting

### Si el deploy falla:
1. Verifica que `FIREBASE_SERVICE_ACCOUNT_FARMATURNOS` esté configurado
2. Confirma que la app Flutter compile sin errores
3. Revisa los logs del workflow en GitHub Actions

### Si el monitoreo falla:
1. Verifica que https://turneros.web.app/ sea accesible
2. Confirma la configuración de Firebase Hosting
3. Revisa los permisos del service account
