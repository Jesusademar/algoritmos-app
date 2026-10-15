class ManualSection {
  const ManualSection(this.title, this.body);
  final String title;
  final String body;
}

enum AlgorithmManual {
  graph(
    'Grafos',
    'Construye una red de nodos y relaciones. La matriz y los grados te ayudan a interpretar su estructura.',
    [
      ManualSection(
        'Crear el grafo',
        'Toca o haz clic en una zona vacía del lienzo. Escribe una etiqueta reconocible, por ejemplo A, B o Almacén. Repite la operación para los demás nodos.',
      ),
      ManualSection(
        'Conectar nodos',
        'Selecciona primero el origen y luego el destino. Define el peso y el tipo de conexión: Unidireccional tiene sentido; Sin dirección representa una relación entre ambos extremos. El peso vacío se guarda como cero.',
      ),
      ManualSection(
        'Acomodar, editar y eliminar',
        'Arrastra los nodos para ordenar el dibujo. En computadora usa clic derecho sobre un nodo o conexión; en pantalla táctil utiliza pulsación larga. También puedes abrir las opciones con doble clic. Cambia etiquetas o pesos, o elimina el elemento.',
      ),
      ManualSection(
        'Leer la matriz y los grados',
        'Pulsa Mostrar matriz. La fila identifica el origen y la columna, el destino. En una conexión sin dirección se refleja el vínculo en ambos sentidos. Revisa también los grados y el grado máximo. Para distinguir una conexión de peso cero de una celda sin conexión, consulta el lienzo.',
      ),
      ManualSection(
        'Ejemplo para practicar',
        'Crea A, B y C. Conecta A a B con peso 4 y B a C con peso 7. Abre la matriz y busca esas posiciones. Cambia A–B a Sin dirección y observa qué cambia en la matriz y en los grados.',
      ),
      ManualSection(
        'Guardar y cargar',
        'Abre Más opciones > Guardar, escribe un nombre y confirma el JSON. En navegador se descarga; en la aplicación nativa puedes elegir dónde guardarlo. Para recuperarlo usa Cargar y selecciona ese JSON. Guarda tu ejercicio antes de sustituirlo por otro.',
      ),
      ManualSection(
        'Resolver dudas y empezar de nuevo',
        'Si una conexión no aparece donde esperas, comprueba qué nodo seleccionaste primero y su dirección. Si la matriz no se ve, pulsa Mostrar matriz. Usa Limpiar para comenzar otro ejercicio; guarda antes los datos que quieras conservar.',
      ),
    ],
  ),
  assignment(
    'Asignación',
    'Relaciona cada recurso con una tarea y busca el costo mínimo o máximo de una asignación completa.',
    [
      ManualSection(
        'Preparar orígenes y destinos',
        'Crea recursos a la izquierda y tareas a la derecha. La separación horizontal determina los grupos de la matriz: comprueba sus encabezados con Mostrar matriz. Mover un nodo de lado puede cambiar su grupo y obliga a recalcular.',
      ),
      ManualSection(
        'Ingresar costos y rutas',
        'Toca un recurso y después una tarea; escribe el costo de esa pareja. Repite para las parejas permitidas. No se permiten bucles sobre el mismo nodo. Una ruta ausente está prohibida: no equivale a una ruta de costo cero.',
      ),
      ManualSection(
        'Matrices rectangulares',
        'Puedes tener diferente cantidad de recursos y tareas. Se completan filas o columnas ficticias de costo cero hasta obtener una matriz cuadrada. Una pareja ficticia representa un recurso sin tarea o una tarea sin recurso real; no es una asignación real adicional.',
      ),
      ManualSection(
        'Elegir el objetivo y calcular',
        'Abre Mostrar matriz, elige Minimizar o Maximizar y pulsa Calcular Asignación Óptima. El resultado usa cada fila y columna una sola vez. Si las rutas disponibles no permiten cubrir la matriz, añade o corrige conexiones y vuelve a calcular.',
      ),
      ManualSection(
        'Ver procedimiento matemático',
        'Después de calcular se habilita Ver procedimiento matemático. Consulta la matriz, la función objetivo, las alternativas evaluadas, la elección del mejor valor y la suma final. Este módulo busca entre asignaciones completas. Si el registro resume alternativas, la selección sigue considerando todas las evaluadas.',
      ),
      ManualSection(
        'Ejemplo y comprobación',
        'Usa dos recursos A y B, dos tareas X e Y y costos A–X=4, A–Y=1, B–X=2, B–Y=5. Minimizar elige A–Y y B–X: 1+2=3. Maximizar elige A–X y B–Y: 4+5=9. Verifica que ninguna tarea se repita.',
      ),
      ManualSection(
        'Editar y recalcular',
        'Arrastra nodos para acomodarlos. Usa clic derecho, doble clic o pulsación larga para editar o eliminar. Los cambios de datos o de objetivo invalidan el cálculo anterior y su procedimiento. Pulsa nuevamente Calcular Asignación Óptima.',
      ),
      ManualSection(
        'Guardar y cargar',
        'Desde Más opciones guarda el JSON con un nombre propio. Conserva nodos, posiciones, conexiones y objetivo. Cargar recupera el ejercicio; calcula de nuevo para obtener el resultado y su procedimiento. Guarda antes de limpiar o cargar otro archivo.',
      ),
    ],
  ),
  transport(
    'Esquina Noroeste',
    'Distribuye cantidades entre orígenes y destinos, respetando oferta y demanda, y consulta cómo se obtiene el costo final.',
    [
      ManualSection(
        'Dibujar la red de transporte',
        'Crea los orígenes a la izquierda y los destinos a la derecha. Conecta cada ruta permitida y escribe su costo unitario. Revisa los encabezados de Mostrar matriz: los grupos dependen de la posición horizontal de los nodos.',
      ),
      ManualSection(
        'Escribir oferta y demanda',
        'En la matriz modifica Oferta para cada origen y Dem para cada destino. Son cantidades no negativas. El número de una conexión es el costo por unidad, no la cantidad transportada. Una ruta ausente no puede utilizarse.',
      ),
      ManualSection(
        'Resolver diferencias entre totales',
        'Puedes calcular directamente aunque la oferta total y la demanda total difieran. El sistema introduce un auxiliar de costo cero. Oferta sin utilizar indica sobrante; Demanda pendiente indica una necesidad que no pudo cubrirse con oferta real.',
      ),
      ManualSection(
        'Calcular mínimo o máximo',
        'Elige Minimizar o Maximizar y pulsa el botón Calcular correspondiente. Esquina noroeste construye la distribución inicial por orden de filas y columnas, sin elegir por el precio. Después se ajusta esa solución según el objetivo. Por eso el resultado final puede diferir de la distribución noroeste inicial.',
      ),
      ManualSection(
        'Ver procedimiento matemático',
        'Después de calcular pulsa Ver procedimiento matemático. Cada paso noroeste muestra cantidad=min(oferta restante, demanda restante), los saldos y la matriz de cantidades. Después aparecen los ajustes, las verificaciones por fila y columna y la suma cantidad×costo de todas las rutas utilizadas.',
      ),
      ManualSection(
        'Ejemplo para comprobar',
        'Dos orígenes con oferta 10 cada uno y dos destinos con demanda 10 cada uno. Costos: A–X=1, A–Y=2, B–X=2, B–Y=100. La distribución noroeste cuesta 1010; la minimización final envía 10 por A–Y y 10 por B–X: 10×2+10×2=40.',
      ),
      ManualSection(
        'Corregir un problema sin solución',
        'Si las rutas no permiten enviar las cantidades, revisa las conexiones permitidas, ofertas y demandas. En computadora, usa clic derecho sobre un nodo o conexión para editarlo o eliminarlo; arrastra los nodos para acomodarlos. No sustituyas una ruta prohibida por costo cero salvo que realmente exista. Tras editar datos, mover nodos de grupo o cambiar el objetivo, vuelve a calcular.',
      ),
      ManualSection(
        'Guardar y cargar',
        'Usa Más opciones > Guardar para descargar o guardar un JSON con el dibujo, costos, ofertas y demandas. Cargar recupera los datos. Revisa las cantidades y selecciona el objetivo antes de recalcular. Guarda tu trabajo antes de Limpiar.',
      ),
    ],
  ),
  johnson(
    'Johnson · Red de actividades',
    'Este módulo trabaja con una red de actividades CPM/PERT: eventos, duraciones, tiempos y holguras.',
    [
      ManualSection(
        'Crear eventos e inicio',
        'Toca una zona vacía para crear un evento. Identifícalo con una etiqueta. El tiempo inicial siempre es cero y no se puede editar, tampoco al cargar archivos anteriores. Conserva la misma unidad de tiempo en todas las duraciones.',
      ),
      ManualSection(
        'Conectar actividades',
        'Selecciona un evento de origen y después otro de destino. Introduce la duración de esa actividad. Todas las conexiones tienen un sentido: no se permiten bucles, la conexión inversa de una pareja ya conectada ni ciclos que regresen a un evento anterior.',
      ),
      ManualSection(
        'Calcular la red',
        'Pulsa Calcular para abrir el resultado. Revisa que las dependencias reflejen el proyecto y que los eventos estén conectados como esperas. El panel muestra el inicio fijo en cero y los tiempos calculados; vuelve a calcular después de modificar la red.',
      ),
      ManualSection(
        'Interpretar tiempos y holguras',
        'El tiempo temprano representa cuándo puede alcanzarse un evento según sus predecesores. El tardío indica el margen respecto al final calculado. La holgura es la diferencia entre ambos. En Maximizar se resaltan actividades críticas sin margen: retrasarlas puede retrasar el proyecto.',
      ),
      ManualSection(
        'Entender los dos modos',
        'Maximizar utiliza la duración total y resalta la ruta crítica de la red. En Minimizar, esta implementación selecciona el evento terminal con menor tiempo temprano y reconstruye su camino de precedencias. Los tiempos tempranos se calculan respetando todas las dependencias; este modo no acorta automáticamente las duraciones ni equivale a Dijkstra.',
      ),
      ManualSection(
        'Ejemplo sencillo',
        'Construye A a B con duración 4 y B a C con duración 6, inicio en A con valor 0. En Maximizar, C se alcanza en 10 y la cadena es crítica. Añade una rama y compara sus tiempos y holguras. Mantén todas las actividades en la misma unidad.',
      ),
      ManualSection(
        'Mover y corregir',
        'Arrastra los eventos para ordenar el dibujo. Usa clic derecho, doble clic o pulsación larga para editar nombres, duraciones o eliminar elementos. Si se rechaza una conexión, comprueba su sentido y si cerraría un ciclo.',
      ),
      ManualSection(
        'Guardar y cargar',
        'En Más opciones guarda un JSON con la red y el modo; el inicio se guarda siempre en cero. Carga ese archivo para continuar y vuelve a calcular. Los archivos con conexiones incompatibles se rechazan. Guarda antes de limpiar o reemplazar el ejercicio.',
      ),
    ],
  ),
  sorting(
    'Ordenamiento',
    'Explora Selection, Insertion, Merge y Shell con tus propios números, en orden ascendente o descendente.',
    [
      ManualSection(
        'Elegir método y sentido',
        'Selecciona un método en el catálogo. Ascendente va de menor a mayor; Descendente, de mayor a menor. Cambiar el sentido recalcula desde los mismos datos originales y reinicia los pasos.',
      ),
      ManualSection(
        'Definir aleatorios a tu medida',
        'Pulsa Nuevo ordenamiento. Escribe Cantidad de números, Valor mínimo y Valor máximo. Los extremos están incluidos y pueden ser negativos o tener muchas cifras. No hay un tope fijo de cantidad ni de cifras impuesto por el módulo. El tiempo y la memoria disponibles dependen del dispositivo.',
      ),
      ManualSection(
        'Elegir si se repiten',
        'Sin repetir desactivado permite cualquier cantidad, incluso si el rango es pequeño. Activado exige que el rango contenga suficientes enteros distintos: entre 1 y 5 solo hay cinco valores diferentes. Amplía el rango o permite repetidos si necesitas más.',
      ),
      ManualSection(
        'Ingresar por teclado',
        'Escribe enteros separados por comas, por ejemplo: -2500, 0, 99999999999999999999, -2500. Se permiten repetidos. Confirma con Usar estos números o Enter. Los enteros grandes conservan todas sus cifras; no se convierten a valores redondeados.',
      ),
      ManualSection(
        'Cómo trabaja cada método',
        'Selection selecciona el menor o mayor pendiente. Insertion inserta cada elemento dentro del tramo ordenado. Merge divide en mitades y combina en orden; mantiene el orden relativo de iguales. Shell hace inserciones con saltos que se reducen a la mitad hasta llegar a uno.',
      ),
      ManualSection(
        'Controlar e interpretar los pasos',
        'Reproducir y Pausar controlan el avance. Anterior y Siguiente permiten revisar operaciones; Reiniciar vuelve a la entrada. Limpiar vacía los números y resultados y detiene la reproducción; después puedes ingresar otra lista o cargar un archivo. Los colores distinguen comparación, movimiento y posiciones ordenadas. La lista Estado del arreglo muestra los valores completos; sobre una pieza puedes consultar su valor si la etiqueta se abrevia.',
      ),
      ManualSection(
        'Consultar el resultado y Big O',
        'Ver resultado salta al final sin reproducir todos los pasos. Al terminar aparecen el arreglo ordenado, comparaciones, movimientos, tiempo de cálculo de los pasos y Big O. El tiempo de cálculo no incluye la animación. Intercambios, desplazamientos y escrituras no representan exactamente la misma operación.',
      ),
      ManualSection(
        'Guardar y cargar',
        'Desde Más opciones puedes guardar el arreglo original, método, sentido, velocidad y paso en JSON. Cargar recalcula los pasos y abre la sesión en pausa. Se admiten archivos anteriores y el formato nuevo conserva enteros grandes con todas sus cifras.',
      ),
      ManualSection(
        'Ejemplo y comprobación',
        'Con -5, 12, 0, -5, 1000, el resultado ascendente es -5, -5, 0, 12, 1000. El descendente invierte ese orden. Debe conservarse la cantidad y cada aparición de los valores repetidos.',
      ),
      ManualSection(
        'Vuelve a experimentar',
        'Prueba la misma entrada en varios métodos, una lista ordenada, otra invertida y otra con repetidos. Usa la carrera desde el dashboard para compararlos con datos comunes. Abrir el manual o un diálogo pausa la reproducción.',
      ),
    ],
  ),
  binaryTree(
    'Árboles binarios',
    'Construye un árbol de búsqueda o reconstruye un árbol binario desde dos recorridos compatibles.',
    [
      ManualSection(
        'Crear con números',
        'Escribe enteros separados por comas o espacios y confirma la creación. La primera cifra será la raíz; menores van a la izquierda y mayores a la derecha. Cada valor debe ser único. Cambiar el orden de inserción puede cambiar la forma del árbol.',
      ),
      ManualSection(
        'Generar por rango',
        'Indica mínimo, máximo y cantidad. Se incluyen ambos extremos y el rango debe contener suficientes valores diferentes. Este editor admite hasta 63 nodos y valores entre -999999999 y 999999999. Estos límites pertenecen al editor de árboles, no al ordenamiento.',
      ),
      ManualSection(
        'Leer los tres recorridos',
        'Pre-order visita raíz, izquierda, derecha. In-order visita izquierda, raíz, derecha. Post-order visita izquierda, derecha, raíz. En un árbol de búsqueda, In-order queda ordenado; en un árbol reconstruido de forma general eso no tiene por qué ocurrir.',
      ),
      ManualSection(
        'Reconstruir con dos recorridos',
        'Selecciona dos recorridos distintos: Pre/In, In/Pre, Post/In, In/Post, Pre/Post o Post/Pre. Introduce sus listas. Deben tener la misma cantidad, los mismos valores únicos y un orden compatible. Si no coinciden, aparece un error y se conserva el árbol anterior.',
      ),
      ManualSection(
        'Reconocer una reconstrucción ambigua',
        'In-order combinado con Pre-order o Post-order determina un árbol único si los datos son válidos y distintos. Pre-order y Post-order pueden admitir varios árboles cuando existe un hijo único. La app muestra una solución válida colocando ese hijo a la izquierda e informa la ambigüedad.',
      ),
      ManualSection(
        'Guardar y cargar',
        'Abre Más opciones para guardar o cargar JSON. Se conserva la forma del árbol y la posición de los nodos, también para árboles reconstruidos. Un archivo inválido conserva el árbol actual. Guarda antes de crear otro ejercicio o limpiar.',
      ),
      ManualSection(
        'Acomodar la vista',
        'Arrastra cada nodo para ubicarlo sin cambiar las relaciones ni los recorridos. Arrastra el fondo para desplazar la vista y usa zoom. Ordenar nodos automáticamente restaura su distribución; Ajustar árbol a la vista vuelve a encuadrarlo.',
      ),
      ManualSection(
        'Ejemplo para practicar',
        'Inserta 8, 3, 10. Pre-order: 8, 3, 10. In-order: 3, 8, 10. Post-order: 3, 10, 8. Reconstruye con In-order y Pre-order y comprueba la raíz 8 con hijos 3 y 10.',
      ),
    ],
  ),
  sortingRace(
    'Carrera de algoritmos',
    'Compara los cuatro métodos con la misma entrada y el mismo sentido, observando el trabajo que realiza cada uno.',
    [
      ManualSection(
        'Preparar una entrada común',
        'Escribe enteros separados por comas y pulsa Aplicar números. También puedes abrir Aleatorios y definir cantidad, mínimo, máximo y repetición. Las listas ordenada e invertida son ejemplos preparados; puedes reemplazarlos con tus propios datos.',
      ),
      ManualSection(
        'Elegir el sentido',
        'Ascendente y Descendente se aplican a los cuatro métodos. Al cambiar el sentido o los datos, se recalculan y reinician todos para mantener una comparación con la misma entrada.',
      ),
      ManualSection(
        'Recorrer la carrera',
        'Iniciar carrera reproduce pasos; Pausar carrera los detiene. Un paso avanza una vez; la línea de tiempo permite retroceder o adelantarse. Ver resultado lleva al final y Reiniciar recupera el comienzo. Limpiar vacía los datos, resultados y comparaciones y detiene la carrera. Puedes cambiar el ritmo entre 1×, 2× y 4×.',
      ),
      ManualSection(
        'Interpretar la comparación',
        'Cada turno visual muestra un paso por método. No es una medición de velocidad real del equipo. Al terminar aparecen comparaciones, movimientos y Big O. Las escrituras de Merge, los desplazamientos de Insertion/Shell y los intercambios de Selection tienen significados diferentes.',
      ),
      ManualSection(
        'Abrir detalle y guardar',
        'Pulsa Abrir detalle en el método que quieras. Allí puedes revisar sus pasos, guardar un JSON o cargar una sesión y leer el manual de ordenamiento. La carrera queda pausada al abrir el detalle o esta ayuda.',
      ),
      ManualSection(
        'Experimento sugerido',
        'Compara una entrada ya ordenada, otra invertida y otra con valores iguales. Anota comparaciones y movimientos. El método con menos comparaciones en un ejemplo no necesariamente será el mejor para todas las entradas.',
      ),
    ],
  );

  const AlgorithmManual(this.title, this.introduction, this.sections);
  final String title;
  final String introduction;
  final List<ManualSection> sections;
}
