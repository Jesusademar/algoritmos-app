# Lógica difusa para MATLAB

Abre **Lógica difusa** desde el menú o el dashboard. El editor permite construir
sistemas generales Mamdani de tipo 1, con varias entradas y salidas. La inferencia
y la evaluación numérica del sistema se realizan en MATLAB Fuzzy Logic Toolbox.

## Crear un sistema

1. Define el nombre del sistema. Los nombres de sistemas, variables y conjuntos
   comienzan con una letra y usan letras sin tildes, números o `_`. No se admiten
   palabras reservadas (`and`, `or`, `not`, `none`, `if`, `then`). Los nombres de
   variables deben ser únicos entre entradas y salidas; los conjuntos deben tener
   nombres únicos dentro de cada variable, sin distinguir mayúsculas.
2. Añade las variables de entrada y salida, con mínimo menor que máximo.
   Cada variable comienza con los conjuntos triangulares `bajo`, `medio` y `alto`.
3. Edita o añade conjuntos. Las curvas se actualizan con los parámetros:
   - Triangular (`trimf`): `[a b c]`, con `a ≤ b ≤ c` y `a < c`.
   - Trapezoidal (`trapmf`): `[a b c d]`, con `a ≤ b ≤ c ≤ d` y `a < d`.
   - Gaussiana (`gaussmf`): `[sigma centro]`, con `sigma > 0`.
   Usa punto decimal y espacios entre parámetros. Se permiten parámetros fuera
   del rango de la variable. Cambiar el rango conserva los conjuntos existentes.
   Para crear o cambiar la forma de un conjunto, abre **Editar variable** en una
   entrada o salida. Edita un conjunto o pulsa **Añadir conjunto** y selecciona
   **Trapezoidal (trapmf)**. Edita por separado `a` (inicio), `b` y `c`
   (meseta), y `d` (fin). La curva se actualiza mientras escribes. Puedes repetir
   `a = b` o `c = d` para obtener conjuntos con hombro. Los trapezoides se
   seleccionan en las reglas igual que cualquier otro conjunto y se exportan
   a MATLAB como `trapmf`. Pulsa **Guardar conjunto** y después
   **Guardar variable** para aplicar los cambios. Cancelar la edición de la
   variable descarta sus cambios en conjuntos sin alterar las reglas.
4. Añade reglas seleccionando conjuntos para las entradas y salidas. **Y** usa
   mínimo y **O** usa máximo. El peso está entre 0 y 1. **Cualquiera** omite una
   entrada y **Sin efecto** omite una salida; cada regla debe utilizar al menos
   una entrada y una salida.
5. Guarda el diseño como JSON para volver a editarlo con **Cargar diseño JSON**.
   También puedes guardar un borrador sin entradas, salidas o reglas completas.
6. Pulsa **Exportar .fis**, revisa la vista previa y guarda o descarga el archivo.
   La exportación exige un sistema completo y válido.

Al añadir variables, las reglas existentes las ignoran inicialmente. Al eliminar
una variable o un conjunto, el editor confirma cuántas reglas lo utilizan y las
elimina, conservando y ajustando los índices de las demás. Los nombres y rangos
se pueden editar sin perder las reglas. Reemplazar un diseño modificado mediante
carga, ejemplo o nuevo diseño solicita confirmación.

## Ejemplo de ventilación

**Ejemplo de ventilación** carga dos entradas (`temperatura`: 0 a 40 y `humedad`:
0 a 100), una salida (`ventilacion`: 0 a 100) y cuatro reglas ilustrativas:

- Si temperatura es bajo, entonces ventilacion es bajo.
- Si temperatura es medio Y humedad es medio, entonces ventilacion es medio.
- Si temperatura es alto O humedad es alto, entonces ventilacion es alto.
- Si temperatura es medio Y humedad es bajo, entonces ventilacion es medio.

El archivo resultante usa AND `min`, OR `max`, implicación `min`, agregación `max`
y defuzzificación `centroid`. El ejemplo es educativo; ajusta los conjuntos y las
reglas a tu ejercicio.

**Ejemplo trapezoidal** carga el mismo problema con nueve conjuntos `trapmf`
(tres por variable), hombros en los conjuntos bajo y alto y una meseta central.
Sus cuatro reglas cubren los rangos de las entradas. Puedes editarlo, guardar
su JSON y exportar `ventilacion_trapezoidal.fis` para MATLAB.

## Abrir el archivo en MATLAB

Al final de la pantalla hay dos botones:

- **Cargar archivo** abre el explorador para seleccionar un `.fis` de hasta
  2 MB. Abre ese sistema directamente en Fuzzy Logic Designer de MATLAB.
  Cancelar la selección no inicia MATLAB ni modifica el diseño de la página.
- **Abrir MATLAB** inicia MATLAB directamente en Fuzzy Logic Designer, sin
  cargar un archivo. Para abrir el diseño actual, primero exporta su `.fis`
  y selecciónalo con **Cargar archivo**.

Para usar estos botones, cada integrante debe correr la app en la computadora
que tiene MATLAB. **No hay que editar rutas en el código**: el proyecto puede estar
en cualquier carpeta y el servidor busca MATLAB automáticamente.

### 1. Requisitos de cada computadora

| Programa | Detalle |
| --- | --- |
| MATLAB | Con **Fuzzy Logic Toolbox** y licencia activa. Ábrelo una vez a mano para activarlo. |
| Python | 3.7 o superior, sin paquetes adicionales. En Windows marca **Add python.exe to PATH**. |
| Flutter | La versión indicada por `pubspec.yaml`. |

### 2. Ejecutar desde la raíz del proyecto

Windows (PowerShell):

```powershell
flutter pub get
flutter build web --base-href /
py tools/local_matlab_server.py
```

macOS o Linux:

```sh
flutter pub get
flutter build web --base-href /
python3 tools/local_matlab_server.py
```

Deja la terminal abierta y entra a `http://localhost:4187`. La terminal muestra la
ruta de MATLAB detectada. Los botones no funcionan desde GitHub Pages ni con
`flutter run`.

### 3. Qué cambia según la máquina

| Situación | Qué hacer |
| --- | --- |
| Terminal: `MATLAB: no encontrado` | Define `MATLAB_CMD` en esa terminal e inicia el servidor otra vez. Cambia `R2026b` por tu versión. |
| Windows | `$env:MATLAB_CMD = "C:Program FilesMATLABR2026binmatlab.exe"` |
| macOS | `export MATLAB_CMD="/Applications/MATLAB_R2026b.app"` |
| Linux | `export MATLAB_CMD="/usr/local/MATLAB/R2026b/bin/matlab"` |
| Puerto 4187 ocupado | Agrega `--port 4188` y abre `http://localhost:4188`. |
| `py` no se reconoce | Reinstala Python con **Add python.exe to PATH** y abre otra terminal. |
| Cambiaste código Flutter | Repite `flutter build web --base-href /`. |
| MATLAB pide licencia | Actívalo y ejecuta `ver` para confirmar Fuzzy Logic Toolbox. |

MATLAB se busca en este orden: `--matlab`, `MATLAB_CMD`, `PATH` y las carpetas de
instalación habituales de cada sistema. Si hay varias versiones, usa la más reciente.
El servidor conserva una copia del archivo seleccionado y el registro de MATLAB en
`~/.cache/logiverse/matlab/`. Puedes borrar esas carpetas después de cerrar MATLAB.
En una sesión Linux Wayland usa XWayland solo para el proceso de MATLAB.

La conexión funciona con este servidor local; la versión de GitHub Pages y un
servidor estático común permiten exportar archivos, pero no iniciar MATLAB.
El navegador envía únicamente el `.fis` elegido al servidor de la misma página,
que escucha en `127.0.0.1`. No es necesario un servicio en Internet.

También puedes abrirlo manualmente:

Con Fuzzy Logic Toolbox instalado, sitúa `ventilacion.fis` en la carpeta de
trabajo de MATLAB y ejecuta:

```matlab
fis = readfis("ventilacion.fis");
fuzzyLogicDesigner(fis);
salida = evalfis(fis, [30 70]); % temperatura, humedad, en ese orden
```

Para otros diseños, sustituye el nombre del archivo y usa una columna por entrada
en el mismo orden del editor. También puedes abrir el archivo desde la opción
**Open Fuzzy Inference System from File** de Fuzzy Logic Designer.

El `.fis` es el archivo de intercambio para MATLAB. El JSON es un documento de
LogiVerse (`format: logiverse-fuzzy`, versión 1) que conserva el diseño editable;
no se carga con `readfis`. El editor no importa archivos `.fis`, sistemas Sugeno,
sistemas de tipo 2 ni funciones personalizadas.

Referencias oficiales: [readfis](https://www.mathworks.com/help/fuzzy/readfis.html),
[Fuzzy Logic Designer](https://www.mathworks.com/help/fuzzy/fuzzylogicdesigner-app.html),
[trimf](https://www.mathworks.com/help/fuzzy/trimf.html),
[trapmf](https://www.mathworks.com/help/fuzzy/trapmf.html),
[gaussmf](https://www.mathworks.com/help/fuzzy/gaussmf.html) y
[reglas numéricas](https://www.mathworks.com/help/fuzzy/fisrule.html).
