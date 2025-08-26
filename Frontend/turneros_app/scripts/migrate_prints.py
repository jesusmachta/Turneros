#!/usr/bin/env python3
"""
Script para migrar todos los print statements a AppLogger en el proyecto Turneros
"""

import os
import re
import glob

def find_dart_files(directory):
    """Encuentra todos los archivos .dart en el directorio"""
    pattern = os.path.join(directory, '**', '*.dart')
    return glob.glob(pattern, recursive=True)

def add_logger_import(content):
    """Agrega el import del logger si no existe"""
    if "import '../utils/logger.dart';" in content or "import '../../utils/logger.dart';" in content:
        return content
    
    # Buscar el último import
    import_lines = []
    other_lines = []
    found_imports = False
    
    for line in content.split('\n'):
        if line.startswith('import '):
            import_lines.append(line)
            found_imports = True
        elif found_imports and line.strip() == '':
            # Línea vacía después de imports
            import_lines.append("import '../utils/logger.dart';")
            import_lines.append(line)
            other_lines.extend(content.split('\n')[len(import_lines)-1:])
            break
        else:
            if found_imports:
                other_lines.append(line)
            else:
                import_lines.append(line)
    
    if found_imports and not other_lines:
        import_lines.append("import '../utils/logger.dart';")
        return '\n'.join(import_lines)
    
    return '\n'.join(import_lines + other_lines)

def migrate_prints(content):
    """Migra los print statements a AppLogger"""
    
    # Patrones para diferentes tipos de print
    patterns = [
        # Auth related
        (r"print\('🔐[^']*'\);", lambda m: m.group(0).replace("print('🔐", "AppLogger.auth('").replace("');", "');")),
        (r"print\('✅ Autenticación[^']*'\);", lambda m: m.group(0).replace("print('✅ Autenticación", "AppLogger.auth('Autenticación").replace("');", "');")),
        (r"print\('👋[^']*'\);", lambda m: m.group(0).replace("print('👋", "AppLogger.auth('").replace("');", "');")),
        
        # API related
        (r"print\('🌐[^']*'\);", lambda m: m.group(0).replace("print('🌐", "AppLogger.api('").replace("');", "');")),
        (r"print\('📡[^']*'\);", lambda m: m.group(0).replace("print('📡", "AppLogger.api('").replace("');", "');")),
        
        # Firestore related
        (r"print\('🔥[^']*'\);", lambda m: m.group(0).replace("print('🔥", "AppLogger.firestore('").replace("');", "');")),
        
        # Error patterns
        (r"print\('❌[^']*\$e\'\);", lambda m: m.group(0).replace("print('❌", "AppLogger.error('").replace("$e');", "', e);")),
        (r"print\('❌[^']*'\);", lambda m: m.group(0).replace("print('❌", "AppLogger.error('").replace("');", "');")),
        
        # General patterns
        (r"print\('([^']*\$[^']*)'\);", lambda m: f"AppLogger.debug('{m.group(1)}');"),
        (r"print\('([^']*)'\);", lambda m: f"AppLogger.debug('{m.group(1)}');"),
        (r"print\(([^)]+)\);", lambda m: f"AppLogger.debug({m.group(1)});"),
    ]
    
    modified_content = content
    for pattern, replacement in patterns:
        modified_content = re.sub(pattern, replacement, modified_content)
    
    return modified_content

def process_file(file_path):
    """Procesa un archivo individual"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Solo procesar si hay prints
        if 'print(' in content:
            # Agregar import del logger
            content = add_logger_import(content)
            
            # Migrar prints
            content = migrate_prints(content)
            
            # Solo escribir si cambió
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"✅ Migrado: {file_path}")
                return True
    
    except Exception as e:
        print(f"❌ Error procesando {file_path}: {e}")
    
    return False

def main():
    # Directorio base
    base_dir = os.path.join(os.path.dirname(__file__), '..', 'lib')
    
    if not os.path.exists(base_dir):
        print(f"❌ Directorio no encontrado: {base_dir}")
        return
    
    # Encontrar archivos Dart
    dart_files = find_dart_files(base_dir)
    print(f"🔍 Encontrados {len(dart_files)} archivos .dart")
    
    # Procesar archivos
    migrated_count = 0
    for file_path in dart_files:
        if process_file(file_path):
            migrated_count += 1
    
    print(f"\n🎉 Migración completa: {migrated_count} archivos modificados")

if __name__ == "__main__":
    main()
