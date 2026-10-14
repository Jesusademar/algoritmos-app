# Compartir LogiVerse con un enlace

La app se publica como Flutter Web en GitHub Pages. El docente puede abrirla
en el navegador sin instalar Flutter ni descargar el proyecto.

La publicación está preparada para tu cuenta `Jesusademar` y el repositorio
`algoritmos-app`. GitHub no admite espacios en el nombre del repositorio.

Repositorio que debes crear:
https://github.com/Jesusademar/algoritmos-app

Enlace previsto después de publicarlo:
https://jesusademar.github.io/algoritmos-app/

## Primero: usar tu propio repositorio

1. Iniciar sesión con tu cuenta y abrir [crear algoritmos-app](https://github.com/new?owner=Jesusademar&name=algoritmos-app&visibility=public).
2. Elegir tu usuario en **Owner** y escribir el nombre del repositorio.
3. Elegir **Public** para utilizar GitHub Pages con el plan gratuito.
4. Crear el repositorio vacío, sin añadir README, licencia ni `.gitignore`,
   porque el proyecto ya contiene sus archivos e historial.
5. Copiar el enlace HTTPS del repositorio que acabas de crear.

Antes de subir, cambiar el destino del proyecto usando ese enlace real:

```sh
git remote set-url origin https://github.com/Jesusademar/algoritmos-app.git
git remote -v
```

El destino local ya está configurado. `git remote -v` debe mostrar
`https://github.com/Jesusademar/algoritmos-app.git` para `origin`, tanto en fetch
como en push. Aún debes crear el repositorio en GitHub antes de subir.

Este cambio conserva el código y el historial local. La configuración de Pages
obtiene automáticamente la ruta del nuevo repositorio.

## 1. Activar GitHub Pages

En el repositorio de GitHub:

1. Abrir **Settings**.
2. Seleccionar **Pages** en el menú lateral.
3. En **Build and deployment → Source**, elegir **GitHub Actions**.

Esto requiere acceso de administrador o mantenedor. Si no aparece Settings,
el propietario del repositorio debe activar Pages o conceder ese acceso.

## 2. Subir los cambios

Desde la carpeta del proyecto, en la terminal de VS Code:

```sh
git add -A
git commit -m "Publicar LogiVerse en GitHub Pages"
git push -u origin main
```

El proyecto ya tiene su historial de Git; no hay que volver a ejecutar
`git init`. El remoto `origin` debe apuntar a tu repositorio antes del push.

## 3. Esperar la publicación

1. Abrir la pestaña **Actions** del repositorio.
2. Abrir **Publicar LogiVerse en GitHub Pages**.
3. Esperar a que **Verificar y compilar la app** y **Publicar el sitio** terminen
   en verde.
4. Abrir el enlace del sitio que aparece en el resultado del despliegue o en
   **Settings → Pages**.
5. Probar la app y compartir ese enlace con el docente.

El enlace no estará disponible hasta que termine la primera publicación.
Si algún paso falla, abrirlo dentro de Actions para consultar el mensaje de
error. Después de corregirlo, volver a subir los cambios o usar **Re-run jobs**.

## Actualizar la app

Cada `git push` a `main` vuelve a verificar y publicar la versión nueva.
El enlace para el docente se mantiene.

Si se activó Pages después de subir el archivo, se puede iniciar la publicación
desde **Actions → Publicar LogiVerse en GitHub Pages → Run workflow → main**.

## Configuración incluida

`.github/workflows/deploy-pages.yml` instala Flutter 3.47.0, ejecuta el análisis
y las pruebas, compila la app y publica únicamente `build/web`. Los archivos
generados no se añaden al repositorio: GitHub los crea en cada ejecución.

La ruta base se obtiene de GitHub Pages, de modo que los recursos se resuelven
correctamente bajo la ruta de tu repositorio. La publicación usa la configuración oficial
de Pages y su entorno `github-pages`; no necesita un token personal.

## Referencias

- [Configurar la publicación de GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site)
- [Workflows personalizados para GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages)
- [Publicar una aplicación Flutter Web](https://docs.flutter.dev/deployment/web)
