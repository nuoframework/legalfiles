#!/bin/bash
# Author: Pablo Arrabal Espinosa - @nuoframework - pabloarrabal.com - contacto@pabloarrabal.com
# shellcheck disable=SC2116
# shellcheck disable=SC2162
# shellcheck disable=SC2034
# shellcheck disable=SC2164
# shellcheck disable=SC2001
# shellcheck disable=SC2002
# Symbols: ✖ | ✔ 

# Variables de configuracion globales

opcion="0"
opcion_paquetes=false # Activa el chequeo de paquetes y su instalación
db_software="mariadb" # Indica si el servicio que utilizas es MariaDB o MySQL
db_host="localhost" # Indica la IP del host en la que está la BBDD
db_puerto="3306" # Indica el Puerto del host en la que está la BBDD
db_usuario="admin" # Usuario de la BBDD
db_name="personal" # Indica el nombre del BBDD
db_backup_name="lastmod.sql" # Ruta del archivo de la BBDD
archivoplantilla="plantilla.tex"

# Funciones

function ver_error()
{
    if [ "$(echo $?)" != 0 ];
    then
        echo "[✖] ERROR. Se ha producido un error al ejecutar comandos, revisa la instalación de dependencias"
        exit 1
    fi
}

function dependencias() # Comprueba que las dependencias están instaladas
{
    sudo ./install/setup.sh -d
}

function bd_estado_check() # Comprueba que el servicio está activo
{
    echo -e "\n[i] Comprobando servicios...\n"
    systemctl is-active --quiet $db_software
    if [ "$(echo $?)" != 0 ];
    then
        echo "[✖] ERROR. El servicio no está activo."
        echo "[i] Activando servicio..."
        sudo systemctl start mysql
        if [ "$(echo $?)" != 0 ];
        then
            echo "[✖] ERROR. No se ha podido activar el servicio"
            exit 1
        else
            echo -e "[✔] Servicio activo\n"
        fi
    else
        echo -e "[✔] Servicio activo\n"
    fi
}

function bd_creds_check() # Comprueba las credenciales de la BBDD
{
    echo -e "[i] Comprobando credenciales de la base de datos...\n"
    mysql -u "$db_usuario" -p -h "$db_host" -e "SELECT 1;" &>/dev/null
    if [ "$(echo $?)" != 0 ];
    then
        echo -e "\n[✖] ERROR. Crendenciales invalidas."
        exit 1
    else
        echo -e "\n[✔] Credenciales validas"
    fi
}

function importbd() # Importa los datos de la ultima BBDD a la actual local
{
    
    mysql -u "$db_usuario" -p personal < $db_backup_name 2>/dev/null
    if [ "$(echo $?)" != 0 ];
    then
        echo -e "\n[✖] ERROR. La importación de la BBDD no se ha realizado correctamente\n"
    else
        echo -e "\n[✔] Base de datos importada correctamente\n"
    fi
}

function exportbd() # Exporta la información al archivo
{
    echo -e "\n[i] Exportando cambios al archivo de respaldo\n"
    mysqldump -u "$db_usuario" -p "$db_name" > lastmod.sql
    if [ "$(echo $?)" != 0 ];
    then
        echo -e "\n[✖] ERROR. Se ha producido un error al exportar los cambios al archivo de respaldo"
        exit 1
    fi
}

function archivo() # Selecciona un archivo y obten datos de el
{
    echo -e "\n[i] A continuación, selecciona un archivo a registrar: \n"
    ruta_archivo=$(zenity --file-selection --title="Selecciona un archivo:" 2>/dev/null)
    nombrecompleto=$(basename "$ruta_archivo")
    md5resume=$(md5sum "$ruta_archivo" | awk '{print$1}' | tr -d '\n')
    sha256resume=$(sha256sum "$ruta_archivo" | awk '{print$1}' | tr -d '\n')
    tipo=$(echo "$nombrecompleto" | grep -o '\.[^.]*$' | awk -F. '{print $2}')
    nombresolo=$(echo "$nombrecompleto" | sed 's/\.[^.]*$//')
    nombre64=$(echo "$nombresolo" | base64)

    sql_query_1="INSERT INTO documents (id, nombre, tipo, md5_hash, sha256_hash, ruta, nombre64) VALUES ('$(uuidgen -r)', '$nombresolo', '$tipo', '$md5resume', '$sha256resume', '$ruta_archivo', '$nombre64');"
}

function escritura() # Escribe un archivo en la BBDD y hace comprobaciones
{
    mysql -h $db_host -P $db_puerto -u $db_usuario -p $db_name -e "$sql_query_1" 2>/dev/null
    if [ "$(echo $?)" != 0 ];
    then
        echo -e "\n[✖] ERROR. Se ha producido un error al escribir el archivo en la BBDD\n"
        
        read -p "¿Quiere revisar la BBDD en busca de otros registros? [S/N]: " opcion3
        
        case $opcion3 in
            "S"|"s"|"y"|"Y")
            echo ""
            mysql -h $db_host -P $db_puerto -u $db_usuario -p $db_name -e "SELECT nombre, created_at, tipo FROM documents WHERE md5_hash = '$md5resume' AND sha256_hash = '$sha256resume'" > output.txt
            cat output.txt | tail -n +2 | sed 's/  */\t/g' > outputclean.txt
            if [ -s outputclean.txt ];
            then
                echo ""
                while IFS=$'\t' read -r nombre fecha hora tipo
                do
                    echo "[✔] El archivo $nombrecompleto se ha registrado en la BBDD el $fecha a las $hora como $tipo"
                done < outputclean.txt
                echo ""
            fi
            ;;
            "N"|"n")
            echo "[i] Saliendo sin exportar cambios..."
            exit 0
            ;;
            *)
            echo "[✖] ERROR. No ha elegido la opción correcta"
            exit 1
            ;;
        esac 
    fi
    
    echo ""
    read -p "¿Quiere exportar los cambios a la BBDD? [S/N]: " opcion4
    echo ""

    case $opcion4 in
        "S"|"s"|"y"|"Y") 
        exportbd
        ;;
        "N"|"n")
        echo "[i] Saliendo sin exportar cambios..."
        exit 0
        ;;
        *)
        echo "[✖] ERROR. No ha elegido la opción correcta"
        exit 1
        ;;
    esac
    
}

function generapdf() # Genera un PDF certificador
{
    rm -f temporal*
    
    read -p "Introduce el nombre del archivo sin la extensión: " solonombre
    read -p "Introduce la extensión: " soloextension
    echo ""
    mysql -h $db_host -P $db_puerto -u $db_usuario -p $db_name -e "SELECT nombre64, md5_hash, sha256_hash FROM documents WHERE nombre = '$solonombre' AND tipo = '$soloextension'" > out.txt
    cat out.txt | tail -n +2 | sed 's/  */\t/g' > outclean.txt
    if [ -s outclean.txt ];
    then
        echo ""
        while IFS=$'\t' read -r nombre64d md5resume sha256resumen
        do
            nombre64dd=$(echo "$nombre64d" | base64 -d)
            cat $archivoplantilla | sed -e "s/nombredocumento/$nombre64dd/g; s/00000000000000000000000000000001/$md5resume/g; s/0000000000000000000000000000000000000000000000000000000000000002/$sha256resumen/g; s/nombrereal/$nombrereal/g; s/ciudadfir/$ciudadfir/g; s/dni/$dni/g; s/fechafirma/$(date +'%d de %B de %Y')/g" > temporal.tex
        done < outclean.txt
        echo ""
        echo -e "[i] Creando documento PDF..."
        pdflatex -interaction=batchmode -output-directory=pdf/ -jobname=documento temporal.tex
        if [ -f pdf/documento.pdf ];
        then
            read -p "[*] Introduce el nombre del archivo sin la extensión: " nombrearchivo
            mv pdf/documento.pdf "pdf/$nombrearchivo.pdf"
            echo -e "[✔] Documento PDF creado correctamente"
        fi

        rm -f *.txt
        rm pdf/*.aux
        rm pdf/*.log
        rm temporal.tex
    fi
    


}

function incio() # Muestra un texto de inicio 
{
    echo -e "
            

           _                     _   _____ _ _           
          | |    ___  __ _  __ _| | |  ___(_) | ___  ___ 
          | |   / _ \/ _  |/ _  | | | |_  | | |/ _ \/ __|
          | |__|  __/ (_| | (_| | | |  _| | | |  __/\__ \ 
          |_____\___|\__, |\__,_|_| |_|   |_|_|\___||___/
                     |___/                               
          


    @nuoframework - pabloarrabal.com - contacto@pabloarrabal.com
    "
    
    if [ -f output.txt ];
    then
        echo "" > output.txt
    elif [ -f outputclean.txt ];
    then 
        echo "" > outputclean.txt
    fi
}

function ayuda()
{
    echo "
    uso: ./script.sh opciones
    opciones:
    
    -i, --importarbd                 Aplica los cambios del archivo SQL a la BBDD local
    -e  --exportarbd                 Aplica los cambios de la BBDD local al archivo SQL
    -g, --generarpdf    nombrepdf    Genera un PDF de un registro
    -r, --registrar                  Registra un nuevo archivo
    "
}

function integridad()
{
    base64_plantillatex="JSBPcHRpb25zIGZvciBwYWNrYWdlcyBsb2FkZWQgZWxzZXdoZXJlClxQYXNzT3B0aW9uc1RvUGFja2FnZXt1bmljb2RlfXtoeXBlcnJlZn0KXFBhc3NPcHRpb25zVG9QYWNrYWdle2h5cGhlbnN9e3VybH0KJQpcZG9jdW1lbnRjbGFzc1sKXXthcnRpY2xlfQpcdXNlcGFja2FnZXthbXNtYXRoLGFtc3N5bWJ9Clx1c2VwYWNrYWdle2lmdGV4fQpcaWZQREZUZVgKICBcdXNlcGFja2FnZVtUMV17Zm9udGVuY30KICBcdXNlcGFja2FnZVt1dGY4XXtpbnB1dGVuY30KICBcdXNlcGFja2FnZXt0ZXh0Y29tcH0gJSBwcm92aWRlIGV1cm8gYW5kIG90aGVyIHN5bWJvbHMKXGVsc2UgJSBpZiBsdWF0ZXggb3IgeGV0ZXgKICBcdXNlcGFja2FnZXt1bmljb2RlLW1hdGh9ICUgdGhpcyBhbHNvIGxvYWRzIGZvbnRzcGVjCiAgXGRlZmF1bHRmb250ZmVhdHVyZXN7U2NhbGU9TWF0Y2hMb3dlcmNhc2V9CiAgXGRlZmF1bHRmb250ZmVhdHVyZXNbXHJtZmFtaWx5XXtMaWdhdHVyZXM9VGVYLFNjYWxlPTF9ClxmaQpcdXNlcGFja2FnZXtsbW9kZXJufQpcaWZQREZUZVhcZWxzZQogICUgeGV0ZXgvbHVhdGV4IGZvbnQgc2VsZWN0aW9uClxmaQolIFVzZSB1cHF1b3RlIGlmIGF2YWlsYWJsZSwgZm9yIHN0cmFpZ2h0IHF1b3RlcyBpbiB2ZXJiYXRpbSBlbnZpcm9ubWVudHMKXElmRmlsZUV4aXN0c3t1cHF1b3RlLnN0eX17XHVzZXBhY2thZ2V7dXBxdW90ZX19e30KXElmRmlsZUV4aXN0c3ttaWNyb3R5cGUuc3R5fXslIHVzZSBtaWNyb3R5cGUgaWYgYXZhaWxhYmxlCiAgXHVzZXBhY2thZ2VbXXttaWNyb3R5cGV9CiAgXFVzZU1pY3JvdHlwZVNldFtwcm90cnVzaW9uXXtiYXNpY21hdGh9ICUgZGlzYWJsZSBwcm90cnVzaW9uIGZvciB0dCBmb250cwp9e30KXG1ha2VhdGxldHRlcgpcQGlmdW5kZWZpbmVke0tPTUFDbGFzc05hbWV9eyUgaWYgbm9uLUtPTUEgY2xhc3MKICBcSWZGaWxlRXhpc3Rze3BhcnNraXAuc3R5fXslCiAgICBcdXNlcGFja2FnZXtwYXJza2lwfQogIH17JSBlbHNlCiAgICBcc2V0bGVuZ3Roe1xwYXJpbmRlbnR9ezBwdH0KICAgIFxzZXRsZW5ndGh7XHBhcnNraXB9ezZwdCBwbHVzIDJwdCBtaW51cyAxcHR9fQp9eyUgaWYgS09NQSBjbGFzcwogIFxLT01Bb3B0aW9uc3twYXJza2lwPWhhbGZ9fQpcbWFrZWF0b3RoZXIKXHVzZXBhY2thZ2V7eGNvbG9yfQpcc2V0bGVuZ3Roe1xlbWVyZ2VuY3lzdHJldGNofXszZW19ICUgcHJldmVudCBvdmVyZnVsbCBsaW5lcwpccHJvdmlkZWNvbW1hbmR7XHRpZ2h0bGlzdH17JQogIFxzZXRsZW5ndGh7XGl0ZW1zZXB9ezBwdH1cc2V0bGVuZ3Roe1xwYXJza2lwfXswcHR9fQpcc2V0Y291bnRlcntzZWNudW1kZXB0aH17LVxtYXhkaW1lbn0gJSByZW1vdmUgc2VjdGlvbiBudW1iZXJpbmcKXGlmTHVhVGVYCiAgXHVzZXBhY2thZ2V7c2Vsbm9saWd9ICAlIGRpc2FibGUgaWxsZWdhbCBsaWdhdHVyZXMKXGZpClxJZkZpbGVFeGlzdHN7Ym9va21hcmsuc3R5fXtcdXNlcGFja2FnZXtib29rbWFya319e1x1c2VwYWNrYWdle2h5cGVycmVmfX0KXElmRmlsZUV4aXN0c3t4dXJsLnN0eX17XHVzZXBhY2thZ2V7eHVybH19e30gJSBhZGQgVVJMIGxpbmUgYnJlYWtzIGlmIGF2YWlsYWJsZQpcdXJsc3R5bGV7c2FtZX0KXGh5cGVyc2V0dXB7CiAgaGlkZWxpbmtzLAogIHBkZmNyZWF0b3I9e0xhVGVYIHZpYSBwYW5kb2N9fQoKXGF1dGhvcnt9ClxkYXRle30KClxiZWdpbntkb2N1bWVudH0KClxoeXBlcnRhcmdldHtkZWNsYXJhY2l1eGYzbi1kZS12YWxpZGV6LWRvY3VtZW50YWx9eyUKXHNlY3Rpb257XHRleG9ycGRmc3RyaW5ne1x0ZXh0YmZ7RGVjbGFyYWNpw7NuIGRlIFZhbGlkZXoKRG9jdW1lbnRhbH19e0RlY2xhcmFjacOzbiBkZSBWYWxpZGV6IERvY3VtZW50YWx9fVxsYWJlbHtkZWNsYXJhY2l1eGYzbi1kZS12YWxpZGV6LWRvY3VtZW50YWx9fQoKWW8sIFxlbXBoe1x0ZXh0YmZ7bm9tYnJlcmVhbH19LCBwb3J0YWRvciBkZWwgZG9jdW1lbnRvIGRlIGlkZW50aWRhZApcZW1waHtcdGV4dGJme2RuaX19LCBoYWdvIGNvbnN0YXIgcG9yIGxhIHByZXNlbnRlIHF1ZSBlbCBkb2N1bWVudG8KYWRqdW50bywgdGl0dWxhZG8gIm5vbWJyZWRvY3VtZW50byIsIGVzIHbDoWxpZG8geSBhdXTDqW50aWNvLCB5YSBxdWUKY29uY3VlcmRhIGNvbiBsYSBmdW5jacOzbiBoYXNoIHF1ZSBmdWUgcmVnaXN0cmFkYSBlbiBsYSBmZWNoYSBkZSBzdQpjcmVhY2nDs24uCgpFc3RlIGRvY3VtZW50byBoYSBzaWRvIGN1aWRhZG9zYW1lbnRlIGNvbXBhcmFkbyBjb24gbG9zIHJlZ2lzdHJvcyBkZQpyZXPDum1lbmVzIHkgaGFzaGVzIGFsbWFjZW5hZG9zIGVuIGxhIGZlY2hhIGRlIHN1IGNyZWFjacOzbiwgZ2FyYW50aXphbmRvCmFzw60gc3UgaW50ZWdyaWRhZCB5IGF1dGVudGljaWRhZC4gTG9zIGhhc2hlcyBkZWwgZG9jdW1lbnRvLCBxdWUgc29uOgoKTUQ1OiAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMQoKU0hBMjU2OiAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAyCgpDb2luY2lkZW4gY29uIGxvcyBoYXNoZXMgcXVlIHNlIHJlZ2lzdHJhcm9uIGVuIGxhIGJhc2UgZGUgZGF0b3MgZWwgZMOtYQpkZSBsYSBjcmVhY2nDs24gZGVsIGRvY3VtZW50by4KCkFkaWNpb25hbG1lbnRlLCBtZSBwZXJtaXRvIGluZm9ybWFyIHF1ZSBlbCBwcmVzZW50ZSBkb2N1bWVudG8gY3VlbnRhIGNvbgpsYSB2YWxpZGV6IGxlZ2FsIGZ1bmRhbWVudGFkYSBlbiBlbCBFc3F1ZW1hIE5hY2lvbmFsIGRlIFNlZ3VyaWRhZCAoRU5TKSwKcXVlIGVzIGVsIG1hcmNvIGRlIHJlZmVyZW5jaWEgcGFyYSBsYSBzZWd1cmlkYWQgZGUgbGEgaW5mb3JtYWNpw7NuIGVuIGxhcwpBZG1pbmlzdHJhY2lvbmVzIFDDumJsaWNhcyBlc3Bhw7FvbGFzLiBFbCBFTlMgZXN0YWJsZWNlLCBlbiBzdSBhcGFydGFkbwo3LjMuMiwgcXVlICJcZW1waHtsYSBhdXRlbnRpY2lkYWQgZGUgbG9zIGRvY3VtZW50b3MgZWxlY3Ryw7NuaWNvcyBzZQpwb2Ryw6EgYWNyZWRpdGFyIG1lZGlhbnRlIGxhIHZlcmlmaWNhY2nDs24gZGUgbG9zIGhhc2hlcyBkZWwgZG9jdW1lbnRvCmVsZWN0csOzbmljb30iLgoKTGEgcHJlc2VudGUgZGVjbGFyYWNpw7NuIHRpZW5lIGNvbW8gb2JqZXRpdm8gcmF0aWZpY2FyIGxhIHZhbGlkZXogeQphdXRlbnRpY2lkYWQgZGVsIGRvY3VtZW50byBtZW5jaW9uYWRvLCBhc8OtIGNvbW8gYXNlZ3VyYXIgc3UKcmVjb25vY2ltaWVudG8gbGVnYWwgZW4gZWwgw6FtYml0byBuYWNpb25hbC4KCkVuIHRlc3RpbW9uaW8gZGUgbG8gY3VhbCwgZmlybW8gbGEgcHJlc2VudGUgZGVjbGFyYWNpw7NuIGVuIGNpdWRhZGZpciwgYQpmZWNoYWZpcm1hLgoKRG9jdW1lbnRvIGdlbmVyYWRvIHBvcgpcaHJlZntodHRwczovL2dpdGh1Yi5jb20vbnVvZnJhbWV3b3JrL2xlZ2FsZmlsZXN9e2xlZ2FsZmlsZXN9IGJ5Cm51b2ZyYW1ld29yawoKXGVuZHtkb2N1bWVudH0K"
    base64_defaultdatabasesql="LS0gTWFyaWFEQiBkdW1wIDEwLjE5ICBEaXN0cmliIDEwLjExLjYtTWFyaWFEQiwgZm9yIGRlYmlhbi1saW51eC1nbnUgKHg4Nl82NCkKLS0KLS0gSG9zdDogbG9jYWxob3N0ICAgIERhdGFiYXNlOiBwZXJzb25hbAotLSAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KLS0gU2VydmVyIHZlcnNpb24JMTAuMTEuNi1NYXJpYURCLTEKCi8qITQwMTAxIFNFVCBAT0xEX0NIQVJBQ1RFUl9TRVRfQ0xJRU5UPUBAQ0hBUkFDVEVSX1NFVF9DTElFTlQgKi87Ci8qITQwMTAxIFNFVCBAT0xEX0NIQVJBQ1RFUl9TRVRfUkVTVUxUUz1AQENIQVJBQ1RFUl9TRVRfUkVTVUxUUyAqLzsKLyohNDAxMDEgU0VUIEBPTERfQ09MTEFUSU9OX0NPTk5FQ1RJT049QEBDT0xMQVRJT05fQ09OTkVDVElPTiAqLzsKLyohNDAxMDEgU0VUIE5BTUVTIHV0ZjhtYjQgKi87Ci8qITQwMTAzIFNFVCBAT0xEX1RJTUVfWk9ORT1AQFRJTUVfWk9ORSAqLzsKLyohNDAxMDMgU0VUIFRJTUVfWk9ORT0nKzAwOjAwJyAqLzsKLyohNDAwMTQgU0VUIEBPTERfVU5JUVVFX0NIRUNLUz1AQFVOSVFVRV9DSEVDS1MsIFVOSVFVRV9DSEVDS1M9MCAqLzsKLyohNDAwMTQgU0VUIEBPTERfRk9SRUlHTl9LRVlfQ0hFQ0tTPUBARk9SRUlHTl9LRVlfQ0hFQ0tTLCBGT1JFSUdOX0tFWV9DSEVDS1M9MCAqLzsKLyohNDAxMDEgU0VUIEBPTERfU1FMX01PREU9QEBTUUxfTU9ERSwgU1FMX01PREU9J05PX0FVVE9fVkFMVUVfT05fWkVSTycgKi87Ci8qITQwMTExIFNFVCBAT0xEX1NRTF9OT1RFUz1AQFNRTF9OT1RFUywgU1FMX05PVEVTPTAgKi87CgotLQotLSBUYWJsZSBzdHJ1Y3R1cmUgZm9yIHRhYmxlIGBkb2N1bWVudHNgCi0tCgpEUk9QIFRBQkxFIElGIEVYSVNUUyBgZG9jdW1lbnRzYDsKLyohNDAxMDEgU0VUIEBzYXZlZF9jc19jbGllbnQgICAgID0gQEBjaGFyYWN0ZXJfc2V0X2NsaWVudCAqLzsKLyohNDAxMDEgU0VUIGNoYXJhY3Rlcl9zZXRfY2xpZW50ID0gdXRmOCAqLzsKQ1JFQVRFIFRBQkxFIGBkb2N1bWVudHNgICgKICBgaWRgIHZhcmNoYXIoMzYpIE5PVCBOVUxMLAogIGBub21icmVgIHZhcmNoYXIoMjU1KSBOT1QgTlVMTCwKICBgdGlwb2AgdmFyY2hhcig0KSBOT1QgTlVMTCwKICBgY3JlYXRlZF9hdGAgdGltZXN0YW1wIE5PVCBOVUxMIERFRkFVTFQgY3VycmVudF90aW1lc3RhbXAoKSwKICBgbWQ1X2hhc2hgIGNoYXIoMzIpIE5PVCBOVUxMLAogIGBzaGEyNTZfaGFzaGAgY2hhcig2NCkgTk9UIE5VTEwsCiAgYHJ1dGFgIHRleHQgTk9UIE5VTEwsCiAgUFJJTUFSWSBLRVkgKGBpZGApLAogIFVOSVFVRSBLRVkgYHVuaXF1ZV9tZDVfaGFzaGAgKGBtZDVfaGFzaGApLAogIFVOSVFVRSBLRVkgYHVuaXF1ZV9zaGEyNTZfaGFzaGAgKGBzaGEyNTZfaGFzaGApCikgRU5HSU5FPUlubm9EQiBERUZBVUxUIENIQVJTRVQ9dXRmOG1iNCBDT0xMQVRFPXV0ZjhtYjRfZ2VuZXJhbF9jaTsKLyohNDAxMDEgU0VUIGNoYXJhY3Rlcl9zZXRfY2xpZW50ID0gQHNhdmVkX2NzX2NsaWVudCAqLzsKCi0tCi0tIER1bXBpbmcgZGF0YSBmb3IgdGFibGUgYGRvY3VtZW50c2AKLS0KCkxPQ0sgVEFCTEVTIGBkb2N1bWVudHNgIFdSSVRFOwovKiE0MDAwMCBBTFRFUiBUQUJMRSBgZG9jdW1lbnRzYCBESVNBQkxFIEtFWVMgKi87Ci8qITQwMDAwIEFMVEVSIFRBQkxFIGBkb2N1bWVudHNgIEVOQUJMRSBLRVlTICovOwpVTkxPQ0sgVEFCTEVTOwovKiE0MDEwMyBTRVQgVElNRV9aT05FPUBPTERfVElNRV9aT05FICovOwoKLyohNDAxMDEgU0VUIFNRTF9NT0RFPUBPTERfU1FMX01PREUgKi87Ci8qITQwMDE0IFNFVCBGT1JFSUdOX0tFWV9DSEVDS1M9QE9MRF9GT1JFSUdOX0tFWV9DSEVDS1MgKi87Ci8qITQwMDE0IFNFVCBVTklRVUVfQ0hFQ0tTPUBPTERfVU5JUVVFX0NIRUNLUyAqLzsKLyohNDAxMDEgU0VUIENIQVJBQ1RFUl9TRVRfQ0xJRU5UPUBPTERfQ0hBUkFDVEVSX1NFVF9DTElFTlQgKi87Ci8qITQwMTAxIFNFVCBDSEFSQUNURVJfU0VUX1JFU1VMVFM9QE9MRF9DSEFSQUNURVJfU0VUX1JFU1VMVFMgKi87Ci8qITQwMTAxIFNFVCBDT0xMQVRJT05fQ09OTkVDVElPTj1AT0xEX0NPTExBVElPTl9DT05ORUNUSU9OICovOwovKiE0MDExMSBTRVQgU1FMX05PVEVTPUBPTERfU1FMX05PVEVTICovOwoKLS0gRHVtcCBjb21wbGV0ZWQgb24gMjAyNC0wMS0xNSAxNDo1NTo1Mgo="
    if [ ! -f install/default_database.sql ];
    then
        if [ -d install/ ];
        then
            echo "$base64_defaultdatabasesql" | base64 -d > install/default_database.sql
        fi    
    elif [ ! -f $archivoplantilla ];
    then
        echo "$base64_plantillatex" | base64 -d > plantilla.tex
    fi
}

# ======================================================================================
# ======================================== Code ========================================
# ======================================================================================


incio

if [ $opcion_paquetes == true ]; # Comprueba que la opción para verificar e instalar paquetes esté activada
then 
    dependencias
    sleep 2
fi

integridad

case $1 in
    "-i"|"--importarbd")
    bd_estado_check # Comprueba que el servicio está activo
    bd_creds_check # Comprueba que las credenciales son válidas
    importbd
    exit 0
    ;;
    "-g"|"--generarpdf")
    bd_estado_check # Comprueba que el servicio está activo
    bd_creds_check # Comprueba que las credenciales son válidas
    read -p "[*] Escribe tu nombre real: " nombrereal
    read -p "[*] Escribe tu número de D.N.I: " dni
    read -p "[*] Escribe la ciudad de firma: " ciudadfir
    generapdf *
    exit 0
    ;;
    "-h"|"--help")
    ayuda
    exit 0
    ;;
    "-e"|"--exportarbd")
    bd_estado_check # Comprueba que el servicio está activo
    bd_creds_check # Comprueba que las credenciales son válidas
    exportbd
    exit 0
    ;;
    "-r"|"--registrar")
    bd_estado_check # Comprueba que el servicio está activo
    bd_creds_check # Comprueba que las credenciales son válidas
    archivo
    echo -e "[i] Se va a realizar la escritura en la BBDD del fichero \"$nombrecompleto\".\n\t[i] Cancelar operacion: CTRL + C\n"
    sleep 4
    escritura
    exit 0
    ;;
    *) 
    echo -e "[✖] ERROR. La opción seleccionada no es correcta"
    ;;
esac