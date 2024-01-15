#!/bin/bash
# Author: Pablo Arrabal Espinosa - @nuoframework - pabloarrabal.com - contacto@pabloarrabal.com
# Symbols: ✖ | ✔

# Variables Globales

paquetes=("curl" "git" "uuid" "uuid-runtime" "zenity" "pandoc" "texlive" "mariadb-server" "mariadb-server*" "mysql-common") # Declara que paquetes serán necesarios
db_backup_name="default_database.sql" # Ruta del archivo de la BBDD
bucle=true

# Funciones

function permisos()
{
    usuario_actual=$(whoami)
    if [ "$usuario_actual" != "root" ]; then
        echo -e "[✖] ERROR. Este script debe ser ejecutado por el usuario root.\n"
        help
        exit 1
    fi
}

function dependencias() # Comprueba que las dependencias están instaladas
{
    for paquete in "${paquetes[@]}";
    do
        dpkg -s "$paquete" &>/dev/null # Realiza una busqueda del paquete
        if [ "$(echo $?)" == 1 ];
        then
            echo -e "[!] Paquete $paquete no encontrado\n"
            read -p "[*]¿Quieres que se instale el paquete $paquete? [S/N]: " opcion
            
            case $opcion in
                "Y"|"y"|"S"|"s")
                    sudo apt install "$paquete" -y &>/dev/null
                ;;
                "N"|"n") 
                    echo -e -n "\n[i] Saltar la instalación de algun paquete puede ocasionar problemas en el script"
                ;;
                *) 
                    echo -e "[✖] ERROR. Introduzca la opción correcta [S/N]."
                    exit 1
                ;;
            esac
        fi
    done
}

function createdatabase()
{
    read -p "¿Cual va a ser el nombre de la BBDD?: " db_name
    sudo mysql -e "CREATE DATABASE $db_name;" 2>/dev/null
    if [ "$(echo $?)" != 0 ];
    then
        echo -e "\n[!] ERROR. La creación de la BBDD no se ha realizado correctamente\n"
    else
        echo -e "\n[+] Base de datos creada correctamente\n"
        sudo mysql -p $db_name < $db_backup_name 2>/dev/null
        if [ "$(echo $?)" != 0 ];
        then
            echo -e "\n[!] ERROR. La creación de las tablas no se ha realizado correctamente\n"
        else
            echo -e "\n[+] Tablas creadas correctamente\n"
        fi
    fi
}

function createtables()
{
    read -p "¿Cual es el nombre de la BBDD?: " db_name
    sudo mysql -p $db_name < $db_backup_name 2>/dev/null
    if [ "$(echo $?)" != 0 ];
    then
        echo -e "\n[!] ERROR. La creación de la BBDD no se ha realizado correctamente\n"
    else
        echo -e "\n[+] Tablas creadas correctamente\n"
    fi
}

function help()
{
    echo "
    uso: ./setup.sh opciones
    opciones:
    
    -c, --completa                   [RECOMENDADA] Realiza la instalación completa con ayuda 
    -d, --dependencias               Comprueba e instala las dependencias necesarias
    -b, --create-database            Crea la Base de Datos junto con las tablas necesarias
    -t, --create-tables              Crea las tablas en una Base de Datos ya existente
    "
}

# ======================================================================================
# ======================================== Code ========================================
# ======================================================================================

permisos

case $1 in
    "-d"|"--dependencias")
    echo -e "\n[i] Comprobando dependencias...\n"
    dependencias
    echo -e "[✔] Dependencias revisadas\n"
    ;;
    "-b"|"--create-database")
    createdatabase
    ;;
    "-t"|"--create-tables")
    createtables
    ;;
    "-c"|"--completa")
    dependencias
    while [ $bucle == true ];
    do

    read -p "Elige una opción:

    [1 - RECOMENDADA] Crear una Base de Datos desde cero      [2] Tengo una Base de Datos

    >>> " opcion2

        case $opcion2 in
            1)
            echo ""
            createdatabase
            bucle=false
            ;;
            2)
            echo ""
            createtables
            bucle=false
            ;;
            *)
            echo -e "\n[✖] ERROR. Opción seleccionada no valida.\n"
            bucle=true
            ;;
        esac

    done
    ;;
    *)
    echo -e "[✖] ERROR. No has especificado ningun parametro.\n"
    help
    ;;
esac
