#!/bin/bash

set -e

# Comprobar que Apache está instalado
if ! dpkg -s apache2 >/dev/null 2>&1; then
    echo "Error: Apache no está instalado."
    echo "Ejecuta primero install_apache.sh."
    exit 1
fi

# Cargar variables del archivo .env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: No se encuentra el archivo .env."
    exit 1
fi

source "$ENV_FILE"

# Comprobar variables necesarias
if [ -z "$DOMAIN" ] || [ -z "$ELASTIC_IP" ] || \
   [ -z "$COUNTRY" ] || [ -z "$STATE" ] || \
   [ -z "$LOCALITY" ] || [ -z "$ORGANIZATION" ] || \
   [ -z "$ORGANIZATIONAL_UNIT" ] || [ -z "$COMMON_NAME" ] || \
   [ -z "$EMAIL" ] || [ -z "$CERT_DAYS" ] || \
   [ -z "$CERT_KEY" ] || [ -z "$CERT_FILE" ]; then
    echo "Error: Faltan variables en el archivo .env."
    exit 1
fi

echo "Generando certificado autofirmado..."

# Crear certificado y clave privada
sudo openssl req -x509 -nodes -days "$CERT_DAYS" \
-newkey rsa:2048 \
-keyout "$CERT_KEY" \
-out "$CERT_FILE" \
-subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/CN=$COMMON_NAME/emailAddress=$EMAIL" \
-addext "subjectAltName=DNS:$DOMAIN,IP:$ELASTIC_IP"

# Permisos de seguridad
sudo chmod 600 "$CERT_KEY"
sudo chmod 644 "$CERT_FILE"

# Copiar configuraciones de Apache
sudo cp "$SCRIPT_DIR/../conf/000-default.conf" /etc/apache2/sites-available/000-default.conf
sudo cp "$SCRIPT_DIR/../conf/practica-https-ssl.conf" /etc/apache2/sites-available/practica-https-ssl.conf

# Sustituir el dominio en las configuraciones
sudo sed -i "s/practica-https.test/$DOMAIN/g" /etc/apache2/sites-available/000-default.conf
sudo sed -i "s/practica-https.test/$DOMAIN/g" /etc/apache2/sites-available/practica-https-ssl.conf

# Habilitar módulos y sitio HTTPS
sudo a2enmod ssl rewrite
sudo a2ensite practica-https-ssl.conf

# Comprobar configuración antes de reiniciar
sudo apache2ctl configtest

# Reiniciar Apache
sudo systemctl restart apache2

echo "Certificado y configuración HTTPS instalados correctamente."
