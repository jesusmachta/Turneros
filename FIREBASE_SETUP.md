# 🔥 Firebase Configuration Setup

## ✅ Configuración Completada

Se ha configurado exitosamente Firebase para tu aplicación **Turneros** con soporte para web y Android.

### 📱 Apps Configuradas

1. **Web App**: `Turneros`
   - Dominio principal: https://turneros.web.app/
   - Dominio alternativo: https://turneros.firebaseapp.com/
   - App ID: `1:228344336816:web:88b5b4e288da8b46c50675`

2. **Android App**: `turneros_app (Android)`
   - Package Name: `com.turneros.turneros_app`
   - App ID: `1:228344336816:android:60ac2a2b60243a34c50675`

## 🚀 GitHub Actions Setup

Se ha creado un workflow automático en `.github/workflows/firebase-deploy.yml` que:

- ✅ Ejecuta en push a `main` y pull requests
- ✅ Instala Flutter y dependencias
- ✅ Ejecuta análisis de código y tests
- ✅ Compila la aplicación web
- ✅ Despliega automáticamente a Firebase Hosting
- ✅ Comenta en PRs con el estado del deployment

### 🔐 Configuración de Secrets Requerida

Para que GitHub Actions funcione, necesitas configurar el secret `FIREBASE_TOKEN`:

#### Paso 1: Obtener Firebase Token
```bash
# Instalar Firebase CLI (si no lo tienes)
npm install -g firebase-tools

# Login en Firebase
firebase login

# Generar token para CI
firebase login:ci
```

#### Paso 2: Configurar Secret en GitHub
1. Ve a tu repositorio en GitHub
2. Navega a **Settings** > **Secrets and variables** > **Actions**
3. Haz clic en **New repository secret**
4. Nombre: `FIREBASE_TOKEN`
5. Valor: El token generado en el paso anterior
6. Guarda el secret

## 📁 Archivos Modificados/Creados

### ✅ Archivos Actualizados:
- `lib/firebase_options.dart` - Configuración web actualizada
- `firebase.json` - Configuración de hosting añadida
- `web/index.html` - SDK de Firebase web integrado

### ✅ Archivos Creados:
- `.github/workflows/firebase-deploy.yml` - GitHub Actions workflow

### ✅ Verificados:
- `android/app/google-services.json` - Configuración Android correcta
- `android/app/build.gradle.kts` - Package name correcto

## 🛠️ Comandos para Development

### Flutter Web
```bash
cd Frontend/turneros_app

# Desarrollo local
flutter run -d web

# Build para producción
flutter build web --release
```

### Firebase Hosting
```bash
cd Frontend/turneros_app

# Servir localmente
firebase serve --only hosting

# Deploy manual
firebase deploy --only hosting --project farmaturnos
```

### Android
```bash
cd Frontend/turneros_app

# Desarrollo
flutter run -d android

# Build para producción
flutter build apk --release
```

## 🔧 Configuración de Dominios

Los siguientes dominios están configurados para tu app web:
- **Principal**: https://turneros.web.app/
- **Secundario**: https://turneros.firebaseapp.com/

Ambos dominios apuntarán a la misma aplicación web desplegada.

## 📊 Monitoreo y Analytics

- **Firebase Console**: https://console.firebase.google.com/project/farmaturnos
- **Analytics**: Configurado con `measurementId: G-WZ87JKNHDX`
- **Project ID**: `farmaturnos`

## 🎯 Próximos Pasos

1. **Configurar el secret** `FIREBASE_TOKEN` en GitHub
2. **Hacer push** a la rama `main` para activar el primer deployment
3. **Verificar** que el deployment sea exitoso en GitHub Actions
4. **Acceder** a https://turneros.web.app/ para ver tu app live

## 🔒 Security Notes

- Las reglas de Firestore deben estar configuradas apropiadamente
- El Firebase Admin SDK key debe mantenerse seguro y no commiterse al repositorio
- Solo usuarios autenticados deberían tener acceso a los datos

## 🎉 ¡Todo Listo!

Tu aplicación Turneros ahora está completamente configurada para:
- ✅ Deployments automáticos con GitHub Actions
- ✅ Hosting web en Firebase
- ✅ Aplicación Android conectada a Firebase
- ✅ Analytics y monitoreo integrados

¡Solo falta configurar el secret de GitHub y hacer tu primer deployment! 🚀
