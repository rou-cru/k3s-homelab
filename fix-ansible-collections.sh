#!/bin/bash
# Script para limpiar y reinstalar las colecciones de Ansible

echo "Limpiando colecciones de Ansible duplicadas..."

# Limpiar el directorio de colecciones del usuario
if [ -d "$HOME/.ansible/collections" ]; then
    echo "Limpiando $HOME/.ansible/collections..."
    rm -rf "$HOME/.ansible/collections"
fi

# Limpiar el directorio de colecciones del proyecto
if [ -d "collections" ]; then
    echo "Limpiando collections del proyecto..."
    rm -rf "collections"
fi

# Instalar las colecciones desde requirements.yml
echo "Instalando colecciones desde requirements.yml..."
ansible-galaxy collection install -r requirements.yml --force

# Verificar las colecciones instaladas
echo "Colecciones instaladas:"
ansible-galaxy collection list

echo "¡Proceso completado!"