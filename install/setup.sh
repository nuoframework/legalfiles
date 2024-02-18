#!/bin/bash
# Author: Pablo Arrabal Espinosa - @nuoframework - pabloarrabal.com - contacto@pabloarrabal.com
# shellcheck disable=SC2116
# shellcheck disable=SC2162
# shellcheck disable=SC2034
# shellcheck disable=SC2164
# shellcheck disable=SC2001
# shellcheck disable=SC2002
# shellcheck disable=SC2086
# Symbols: ✖ | ✔

# Variables Globales

paquetes=("curl" "git" "uuid" "uuid-runtime" "zenity" "pandoc" "texlive" "mariadb-server" "mariadb-server*" "mysql-common") # Declara que paquetes serán necesarios
db_backup_name="default_database.sql" # Ruta del archivo de la BBDD

# Funciones 

function permisos()
{
    usuario_actual=$(whoami)
    if [ "$usuario_actual" != "root" ]; then
        echo -e "[✖] ERROR. Este script debe ser ejecutado por el usuario root."
        exit 1
    fi
}

function dependencias() # Comprueba que las dependencias están instaladas
{
    paquetesnoinstalados=()
    for paquete in "${paquetes[@]}";
    do
        dpkg -s "$paquete" &>/dev/null # Realiza una busqueda del paquete
        if [ "$(echo $?)" == 1 ];
        then
            paquetesnoinstalados+=("$paquete")
        fi
    done

    if [ ${#paquetesnoinstalados[@]} -eq 0 ];
    then
        echo "[✔] Todos los paquetes están instalados"
        return
    fi

    echo "[!] Los siguientes paquetes no están instalados en el sistema (${paquetesnoinstalados[*]})"
    read -p "Eliga una opción: [S(Instalar todos) / D(Dejame Elegir)]: " paquetesop

    case $paquetesop in
        "s"|"S"|"Si"|"Sí"|"Y"|"Yes")
            for paquete in "${paquetesnoinstalados[@]}";
            do
            apt-get install -y "$paquete" &>/dev/null
            if [ ! "$(echo $?)" -eq 0 ];
            then
                echo "[✖] ERROR. El paquete $paquete no se ha podido instalar"
            else
                echo "[✔] El paquete $paquete se ha instalado"
            fi
            done
        ;;
        "d"|"D")
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
                echo -e "[✖] ERROR. Introduzca la opción correcta (S/N)."
                exit 1
                ;;
            esac
        ;;
        *)
            echo -e "[✖] ERROR. No se ha introducido la opción correcta"
            exit 1
        ;;
    esac
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

function createuser()
{
    read -p "Especifica un usuario para la base de datos: " usuario
    read -p "Especifica una contraseña para el usuario: " contrasena
    if [ $db_name == "" ];
    then
        read -p "Especifica el nombre de la base de datos: " db_name
    fi
    sudo mysql -e "create user '$usuario'@'localhost' identified by '$contrasena';" 2>/dev/null
    if [ "$(echo $?)" != 0 ];
    then
        echo -e "\n[!] ERROR. El usuario no se ha creado correctamente\n"
        exit 1
    else
        sudo mysql -e "grant all privileges on $db_name.* to '$usuario'@'localhost';" 2>/dev/null
        if [ "$(echo $?)" != 0 ];
        then
            echo -e "\n[!] ERROR. Los permisos no se han asignado correctamente\n"
            exit 1
        else
            sudo mysql -e "flush privileges;" 2>/dev/null
            if [ "$(echo $?)" != 0 ];
            then
                echo -e "\n[!] ERROR. No se han podido actualizar los privilegios del usuario\n"
                exit 1
            else
                echo -e "\n[✔] Se han realizado correctamente todos los procedimientos\n" 
            fi
        fi
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
    -u, --create-user                Crea un usuario y asigna permisos sobre el nombre de la Base de Datos
    "
}

# ======================================================================================
# ======================================== Code ========================================
# ======================================================================================

case $1 in
    "-d"|"--dependencias")
    permisos
    echo -e "\n[i] Comprobando dependencias...\n"
    dependencias
    echo -e "[✔] Dependencias revisadas\n"
    ;;
    "-b"|"--create-database")
    permisos
    createdatabase
    ;;
    "-t"|"--create-tables")
    permisos
    createtables
    ;;
    "-u"|" --create-user")
    permisos
    createuser
    ;;
    "-c"|"--completa")
    permisos
    dependencias
    while true;
    do

    read -p "Elige una opción:

    [1 - RECOMENDADA] Crear una Base de Datos desde cero      [2] Tengo una Base de Datos

    >>> " opcion2

        case $opcion2 in
            1)
            echo ""
            createdatabase
            createuser
            exit
            ;;
            2)
            echo ""
            createtables
            exit
            ;;
            *)
            echo -e "\n[✖] ERROR. Opción seleccionada no valida.\n"
            ;;
        esac

    done
    ;;
    *)
    echo -e "[✖] ERROR. No has especificado ningun parametro.\n"
    help
    ;;
esac
