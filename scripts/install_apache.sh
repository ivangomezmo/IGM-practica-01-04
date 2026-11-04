#!/bin/bash

set -e

# Instalar Apache si no está instalado

if dpkg -s apache2 >/dev/null 2>&1; then
    echo "Apache ya está instalado."
    exit 0
fi

echo "Instalando Apache..."

sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y apache2

# Habilitar y arrancar Apache
sudo systemctl enable apache2
sudo systemctl start apache2

echo "Apache se ha instalado correctamente."
