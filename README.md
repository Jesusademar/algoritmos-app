# LogiVerse Core

Aplicación académica desarrollada con Flutter para representar grafos y
resolver problemas de investigación de operaciones.

## Funcionalidades

- Editor visual de nodos y conexiones.
- Problema de asignación por minimización.
- Problema de asignación por maximización.
- Red de actividades, tiempos tempranos y tardíos, holguras y ruta crítica.
- Importación y exportación de proyectos en formato JSON.
- Ejecución en Android, Windows y navegador web.

## Arquitectura

La aplicación separa la presentación, el dominio de cada algoritmo y los
servicios compartidos:

```text
lib/
├── app/                    # Configuración global y tema
├── features/
│   ├── assignment/domain/  # Solución de asignación
│   └── johnson/domain/     # Cálculo de la red de actividades
├── models/                 # Nodos y conexiones
├── screens/                # Interfaz y editor visual
└── shared/persistence/     # Formato JSON compartido
```

La explicación completa está en
[`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md).

## Ejecutar el proyecto

```powershell
flutter pub get
flutter run -d chrome
```

Para ejecutar las verificaciones:

```powershell
dart analyze lib test
flutter test
flutter build web
```

## Nota sobre Johnson

La pantalla denominada Johnson actualmente implementa una red de actividades
de tipo CPM/PERT. Si la materia exige la regla clásica de Johnson para ordenar
trabajos en dos máquinas, será necesario incorporar esa interfaz y solver como
una funcionalidad diferente.
