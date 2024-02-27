<a name="readme-top"></a>
<h1 align="center" id="title">Legal Files</h1>

<p align="center"><img src="https://socialify.git.ci/nuoframework/legalfiles/image?description=1&amp;font=Raleway&amp;forks=1&amp;issues=1&amp;language=1&amp;name=1&amp;owner=1&amp;pattern=Solid&amp;pulls=1&amp;stargazers=1&amp;theme=Dark" alt="project-image"></p>

<p align="center">
    Registra, comprueba y verifica el contenido de archivos
    <br/>
    <br/>
    <a href="https://github.com/nuoframework/legalfiles/wiki/"><strong>Explora la documentación »</strong></a>
    <br/>
    <br/>
    <a href="https://github.com/nuoframework/legalfiles">Ver una Demo</a>
    •
    <a href="https://github.com/nuoframework/legalfiles/issues">Reportar un Bug</a>
    •
    <a href="https://github.com/nuoframework/legalfiles/issues">Solicitar una función</a>
  </p>
</p>

![Downloads](https://img.shields.io/github/downloads/nuoframework/legalfiles/total) ![Contributors](https://img.shields.io/github/contributors/nuoframework/legalfiles?color=dark-green) ![Forks](https://img.shields.io/github/forks/nuoframework/legalfiles?style=social) ![Stargazers](https://img.shields.io/github/stars/nuoframework/legalfiles?style=social) ![Issues](https://img.shields.io/github/issues/nuoframework/legalfiles) ![License](https://img.shields.io/github/license/nuoframework/legalfiles) 

## Contenidos

<ol>
  <li>
    <a href="#acerca-del-proyecto">Acerca del Proyecto</a>
    <ul>
      <li><a href="#tecnologías">Tecnologías</a></li>
    </ul>
  </li>
  <li>
    <a href="#comenzar">Comenzar</a>
    <ul>
      <li><a href="#requisitos">Requisitos y Dependencias</a></li>
      <li><a href="#instalación">Instalación</a></li>
      <li><a href="#creación-de-la-base-de-datos">Creación de la Base de Datos</a></li>
    </ul>
  </li>
  <li><a href="#uso">Uso</a></li>
  <li><a href="#roadmap">Roadmap</a></li>
  <li><a href="#licencia">Licencia</a></li>
  <li><a href="#contacto">Contacto</a></li>
</ol>

# Acerca del Proyecto

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam dui orci, fringilla vel finibus ut, molestie vitae lectus. Nunc at ultrices nibh. Donec consequat felis urna, ac vehicula ante laoreet ac. Maecenas in pretium ex, a vehicula nisi. Suspendisse potenti. Fusce massa nibh, porta vel orci eget, porttitor malesuada justo.

## Tecnologías

![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white) ![MySQL](https://img.shields.io/badge/mysql-%2300f.svg?style=for-the-badge&logo=mysql&logoColor=white) ![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=for-the-badge&logo=mariadb&logoColor=white) ![Git](https://img.shields.io/badge/git-%23F05033.svg?style=for-the-badge&logo=git&logoColor=white) ![GitHub](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white) ![Visual Studio Code](https://img.shields.io/badge/Visual%20Studio%20Code-0078d7.svg?style=for-the-badge&logo=visual-studio-code&logoColor=white)


# Comenzar

Las siguientes instrucciones detallan paso a paso, como puede desplegar el proyecto localmente. Puede seguir las instucciones acompañadas del siguiente video.

[![Video](https://img.youtube.com/vi/YUuwzdE-rcQ/maxresdefault.jpg)](https://youtu.be/YUuwzdE-rcQ)

<iframe width="560" height="315" src="https://www.youtube.com/embed/YUuwzdE-rcQ?si=ea-kOkkRcdteRiFu" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>

## Requisitos y dependencias

Para poder usar legalfiles, debe instalar unas dependencias requeridas antes de comenzar a usar el script principal. Existen dos maneras de instalar las dependencias:

1. Instala todas las dependencias manualmente

```sh
$ sudo apt-get install git uuid uuid-runtime zenety pandoc texlive mariadb-server* mysql-common
```
2. Instala las dependencias automaticamente ![Recomendado](https://img.shields.io/badge/%E2%9C%94%20Recomendado-61a31f)


> [!IMPORTANT]
> Debes tener `git` instalado (`sudo apt-get install git -y`)

```sh
$ git clone https://github.com/nuoframework/legalfiles.git && cd legalfiles
$ chmod -R +x script.sh install/setup.sh
$ sudo ./install/setup.sh -d
```

### Creación de la Base de datos

Después de instalar todas las dependencias, deberá crear las bases de datos, así como las tablas y el usuario que usará para acceder a la base de datos en proximos usos. Para ello, debe seguir los siguientes pasos:

1. Clona el repositorio

> [!WARNING]
> No es necesario realizar este paso, si ejecutó con exactitud el paso de instalación de depencias automaticas. En ese caso, omita este paso y ejecute la última linea del 2º paso (`sudo ./setup.sh -c`)

```sh
$ git clone https://github.com/nuoframework/legalfiles.git && cd legalfiles
```

2. Ejecuta el script de instalación

```sh
$ cd install
$ sudo ./setup.sh -c
```

<p align="right">(<a href="#readme-top">volver arriba</a>)</p>

# Uso

Para poder usar la herramienta, deberas ejecutar el Shell Script:

> [!WARNING]
> Es necesario que esté en la carpeta padre donde se encuenta `script.sh`, si está en la carpeta "install", ejecute `cd ..` para volver a la carpeta padre.

```sh
./script.sh --help
```

> [!TIP]  
> Puedes consultar la [documentación](https://github.com/nuoframework/legalfiles/wiki/) para ver más usos.

<p align="right">(<a href="#readme-top">volver arriba</a>)</p>

# Roadmap

- [ ] Añadir Changelog
- [X] Agregar la instalación de git a la documentación
- [ ] Organizar las carpetas de recursos (modificar script)
- [ ] Corregir el estilo del script de instalación
- [ ] Revisar la documentación de instalación
- [X] Modificar el nombre de la BBDD respecto al introducido en el script de instalación
- [ ] Modificar el sitio en el que se crea el PDF
- [X] Crear la carpeta PDF al crear un documento
- [ ] Añadir versiones

Mira los [asuntos pendientes](https://github.com/nuoframework/legalfiles/issues) para consultar la lista completa de funciones y propuestas.

<p align="right">(<a href="#readme-top">volver arriba</a>)</p>
