# Parcial II — Programación III (Elixir)

**Universidad del Quindío** · Programa de Ingeniería de Sistemas y Computación

Aplicación en Elixir para el Observatorio Sismológico de la Universidad del Quindío. Genera un reporte de los movimientos sísmicos por ciudad a partir de dos archivos locales, usando **recursividad**, **concurrencia** (`spawn`, `send`, `receive`) y **comunicación entre nodos**.

- **Punto 1:** reporte local con lectura concurrente de los archivos.
- **Punto 2:** consulta de reportes desde un nodo cliente a un nodo servidor.

---

## Requisitos

- Elixir 1.14 o superior (verificar con `elixir --version`).
- Dos terminales para el punto 2.

---

## Estructura del repositorio

```
Parcial-II/
├── README.md
├── main.exs                      # Funciones de arranque: Main.probar_punto1/0,
│                                 # Main.arrancar_servidor/0, Main.arrancar_cliente/1
├── punto-1/
│   ├── cuidad.ex                 # Struct Ciudad + parse/1
│   ├── movimiento.ex             # Struct Movimiento + parse/1
│   ├── csv.exs                   # Lectura de archivos y conteo de rechazados (recursivo)
│   ├── coordinador.exs           # Proceso coordinador y trabajadores concurrentes
│   ├── reporte.exs               # Estadísticas recursivas y formato del reporte
│   ├── util.ex                   # Utilidades (formato a dos decimales, entrada/salida)
│   └── resources/
│       ├── ciudades.txt
│       ├── movimientos.txt
│       └── reporte_sismos.txt    # Se genera al ejecutar el punto 1
└── punto-2/
    ├── nodo-cliente/
    │   └── nodo_cliente.exs      # Módulo Cliente
    └── nodo-servidor/
        ├── nodo_servidor.exs     # Módulo Servidor
        └── resources/
            ├── ciudades.txt
            └── movimientos.txt
```

### Responsabilidad de cada módulo

| Módulo | Archivo | Responsabilidad |
|---|---|---|
| `Ciudad` | `punto-1/cuidad.ex` | Struct `[:id, :nombre, :habitantes]`. `parse/1` valida una línea y devuelve `{:ok, %Ciudad{}}` o `:error`. |
| `Movimiento` | `punto-1/movimiento.ex` | Struct `[:codigo, :id_ciudad, :hora_inicio, :hora_fin, :magnitud, :profundidad]`. `parse/1` valida una línea y devuelve `{:ok, %Movimiento{}}` o `:error`. |
| `Csv` | `punto-1/csv.exs` | `leer_con_rechazos/2` lee el archivo y recorre las líneas **recursivamente** con `procesar_lineas/4`, separando registros válidos y contando rechazados. |
| `Coordinador` | `punto-1/coordinador.exs` | `reporte_local/0` lanza los dos trabajadores con `spawn`, recibe sus resultados con `receive` y genera y guarda el reporte. |
| `Reporte` | `punto-1/reporte.exs` | `generar/4` arma el texto del reporte. `calcular_stats/4` recorre **recursivamente** los movimientos de cada ciudad. |
| `Util` | `punto-1/util.ex` | `formater/1` da formato a dos decimales. |
| `Servidor` | `punto-2/nodo-servidor/nodo_servidor.exs` | Registra `:servicio_sismos` y atiende solicitudes con `ciclo_espera/0` recursivo. |
| `Cliente` | `punto-2/nodo-cliente/nodo_cliente.exs` | Registra `:servicio_respuesta`, se conecta al servidor, envía las solicitudes y recibe las respuestas de forma recursiva. |
| `Main` | `main.exs` | Funciones de arranque para probar cada punto. |

---

## Formato de los archivos de entrada

Los archivos no tienen encabezado. Cada línea es un registro y los campos se separan con `@`.

| Archivo | Formato |
|---|---|
| `ciudades.txt` | `idCiudad@nombre@numeroHabitantes` |
| `movimientos.txt` | `código@idCiudad@horaInicio@horaFinal@magnitud@profundidad` |

**Validaciones**

- Las líneas vacías se ignoran.
- Se rechaza una línea si no tiene el número de campos esperado o si contiene un dato inválido.
- `numeroHabitantes` debe ser un entero mayor que 0.
- `horaInicio` y `horaFinal` deben ser horas válidas en formato `HH:MM:SS`.
- `magnitud` debe poder convertirse en un número decimal.
- `profundidad` debe ser un decimal mayor o igual a 0.

---

## Compilación (paso previo a ambos puntos)

**Todos los comandos se ejecutan desde la raíz del repositorio (`Parcial-II/`)**, porque las rutas de los archivos de entrada son relativas a esa carpeta (por ejemplo, `punto-1/resources/ciudades.txt`).

```bash
cd Parcial-II
elixirc punto-1/coordinador.exs punto-1/cuidad.ex punto-1/reporte.exs punto-1/movimiento.ex punto-1/util.ex punto-1/csv.exs punto-2/nodo-servidor/nodo_servidor.exs punto-2/nodo-cliente/nodo_cliente.exs
```

Esto genera los archivos `Elixir.*.beam` en la raíz. Los comandos siguientes los cargan automáticamente porque se ejecutan desde la misma carpeta.

---

## Punto 1 — Reporte local

### Ejecución

Desde la raíz del repositorio (`Parcial-II/`), después de compilar:

```bash
elixir -r main.exs -e "Main.probar_punto1()"
```

### Archivos

| Tipo | Ruta (relativa a la raíz) |
|---|---|
| Entrada: ciudades | `punto-1/resources/ciudades.txt` |
| Entrada: movimientos | `punto-1/resources/movimientos.txt` |
| Salida: reporte | `punto-1/resources/reporte_sismos.txt` |

### Funcionamiento

1. `Coordinador.reporte_local/0` guarda su PID con `self()` y lanza dos procesos trabajadores con `spawn`: uno lee `ciudades.txt` y el otro `movimientos.txt`. Los dos se inician **antes** de esperar respuestas.
2. Cada trabajador envía con `send` un mensaje que identifica el archivo procesado (`:resultado_ciudades` o `:resultado_movs`) junto con el resultado de la lectura: `{:ok, registros, rechazados}` o `{:error, ruta}`.
3. El coordinador recibe las respuestas **en cualquier orden** con `esperar_y_guardar/2`, una función recursiva que vuelve a llamar a `receive` hasta tener los dos resultados.
4. Para cada ciudad, `Reporte.calcular_stats/4` recorre **recursivamente** sus movimientos y calcula en un solo recorrido la cantidad, el movimiento de mayor magnitud y la suma de profundidades. El promedio se obtiene de la suma y la cantidad. En caso de empate en la magnitud máxima se conserva el primero del archivo, porque solo se reemplaza el máximo cuando la magnitud es estrictamente mayor.
5. El reporte se muestra en consola y se guarda en `punto-1/resources/reporte_sismos.txt`, reemplazando el contenido anterior.

### Manejo de errores

Si alguno de los archivos de entrada no se puede leer, se muestra `Error leyendo archivo: <ruta>. Se conserva el reporte anterior.` y no se modifica `reporte_sismos.txt`.

---

## Punto 2 — Consulta entre nodos

### Nodos y cookie

| Rol | Nombre del nodo | Proceso registrado |
|---|---|---|
| Servidor | `servidor@127.0.0.1` | `:servicio_sismos` |
| Cliente | `cliente@127.0.0.1` | `:servicio_respuesta` |

Ambos nodos deben usar **la misma cookie**. En este proyecto se configura con la opción `--cookie sismos` en los dos comandos. Si las cookies no coinciden, `Node.connect/1` falla y el cliente muestra `No se pudo conectar al servidor` y finaliza.

### Ejecución

Compilar primero (ver [Compilación](#compilación-paso-previo-a-ambos-puntos)). Luego abrir **dos terminales**, ambas en la raíz del repositorio (`Parcial-II/`). Iniciar primero el servidor y después el cliente.

**Terminal 1: servidor**

```bash
elixir --name servidor@127.0.0.1 --cookie sismos -r main.exs -e "Main.arrancar_servidor()"
```

Debe mostrar `Servidor iniciado. Esperando consultas`. No cierre esta terminal.

**Terminal 2: cliente**

```bash
elixir --name cliente@127.0.0.1 --cookie sismos -r main.exs -e 'Main.arrancar_cliente(:"servidor@127.0.0.1")'
```

> **Alternativa con `iex`** (útil en Windows, donde las comillas del comando anterior pueden dar problemas). En PowerShell se escribe `iex.bat` en lugar de `iex`.
>
> ```bash
> # Terminal 1
> iex --name servidor@127.0.0.1 --cookie sismos main.exs
> iex> Main.arrancar_servidor()
>
> # Terminal 2
> iex --name cliente@127.0.0.1 --cookie sismos main.exs
> iex> Main.arrancar_cliente(:"servidor@127.0.0.1")
> ```

### Solicitudes que envía el cliente

Cada mensaje tiene la forma `{destino_respuesta, solicitud}`, donde `destino_respuesta = {:servicio_respuesta, Node.self()}` identifica el proceso registrado y el nodo cliente. Se envían en este orden:

| # | Solicitud | Caso que prueba |
|---|---|---|
| 1 | `{:reporte_ciudad, "C01"}` | Ciudad **con** movimientos (Armenia) |
| 2 | `{:reporte_ciudad, "C03"}` | Ciudad **sin** movimientos (Circasia) |
| 3 | `{:reporte_ciudad, "C99"}` | Ciudad **inexistente**: responde «La ciudad no está registrada» |
| 4 | `:reporte_general` | Reporte de todas las ciudades y conteo de rechazados por archivo |
| 5 | `:fin` | El servidor confirma el fin de las respuestas |

El cliente muestra cada respuesta y continúa recibiendo de forma **recursiva** (`recibir_respuestas/0`) hasta recibir la confirmación de fin.

El servidor atiende las solicitudes en un solo proceso, una por una, así que responde en el mismo orden en que las recibe. Para cada consulta lee las versiones actuales de los archivos de `punto-2/nodo-servidor/resources/` y reutiliza los structs, las validaciones y los cálculos del punto 1. Si un archivo no se puede leer, responde `Error del servidor: No se pudo leer <ruta>` y sigue atendiendo solicitudes. Después de responder a `:fin`, vuelve a esperar solicitudes con una llamada recursiva a `ciclo_espera/0`.

---

## Verificación del punto 2

1. Iniciar el servidor en la terminal 1.
2. Ejecutar el cliente en la terminal 2. Debe mostrar las **cuatro respuestas en orden** (C01, C03, C99, reporte general) y terminar con:
   ```
   FIN
   Comunicación finalizada por el servidor.
   ```
3. **Segunda ejecución:** sin detener el servidor, ejecutar **otra vez el mismo comando** del cliente en la terminal 2:
   ```bash
   elixir --name cliente@127.0.0.1 --cookie sismos -r main.exs -e 'Main.arrancar_cliente(:"servidor@127.0.0.1")'
   ```
   El cliente debe volver a mostrar las cuatro respuestas en el mismo orden, lo que comprueba que el servidor sigue atendiendo solicitudes.

> Si se usa la alternativa con `iex`, para la segunda ejecución hay que **cerrar la sesión del cliente** (`Ctrl+C` dos veces) y abrirla de nuevo, porque el nombre `:servicio_respuesta` queda registrado mientras la sesión siga abierta.

### Identificadores usados

| Caso | idCiudad |
|---|---|
| Ciudad con movimientos | `C01` (Armenia) |
| Ciudad sin movimientos | `C03` (Circasia) |
| Ciudad inexistente | `C99` |

---

## Datos de prueba

**`ciudades.txt`**

```
C01@Armenia@304314
C02@Calarcá@78684
C03@Circasia@30941
C04@CiudadMala@-50
```

**`movimientos.txt`**

```
S001@C01@08:15:02@08:15:18@3.4@18.0
S002@C02@09:30:10@09:30:29@4.1@25.0
S003@C01@11:42:00@11:42:12@2.8@10.0
S004@C01@12:00:00@12:00:10@hola@10.0
```

### Resultado esperado

| Ciudad | Movimientos | Movimiento de mayor magnitud | Profundidad promedio |
|---|---|---|---|
| Armenia | 2 | S001 · 3.4 | 14.00 km |
| Calarcá | 1 | S002 · 4.1 | 25.00 km |
| Circasia | 0 | No aplica | No aplica |

| Archivo | Rechazados | Motivo |
|---|---|---|
| `ciudades.txt` | 1 | `C04`: número de habitantes negativo |
| `movimientos.txt` | 1 | `S004`: magnitud no numérica |

---

## Reflexión sobre el uso de inteligencia artificial

### 1. Herramientas y agentes

Usamos **Claude** (aplicación de escritorio) como asistente de apoyo. Lo empleamos para:

- Proponer la estructura del proyecto y la responsabilidad de cada módulo (`Ciudad`, `Movimiento`, `Csv`, `Coordinador`, `Reporte`).
- Resolver dudas puntuales de sintaxis mientras codificábamos (pipes, capturas con `&`, `case` con guards, `with`).
- Revisar el repositorio contra el enunciado y redactar este README.
- Resolver problemas de entorno, como la autenticación de Git con GitHub (`gh auth login`).

Además, el archivo `main.exs` de pruebas se generó con ayuda de IA (commit «Creacion de main de prueba generado por IA») y lo revisamos antes de usarlo.

Le pedimos expresamente que **no nos diera las soluciones completas**, sino pistas y preguntas guía, para escribir nosotros el código. Por la misma razón desactivamos las sugerencias automáticas de **GitHub Copilot** en VS Code mientras desarrollábamos.

### 2. Caso decisivo

El tema que más se nos complicó fue la comunicación entre nodos. Al pedirle a Claude que revisara la primera versión del punto 2 contra el enunciado, nos señaló dos puntos que no habíamos notado:

1. El servidor leía los dos archivos uno después del otro, cuando el enunciado exige leerlos **concurrentemente**. La sugerencia fue reutilizar el coordinador del punto 1 dentro del servidor.
2. Al recibir `:fin`, el servidor respondía con un texto (`{:respuesta, "Comunicación finalizada..."}`), pero el enunciado pide confirmar con el átomo `:fin`.

También nos recomendó iniciar los nodos con `--name servidor@127.0.0.1` en lugar de `--sname`, para evitar problemas con el nombre del equipo, y usar la misma cookie con `--cookie` en ambos nodos.

No aplicamos los cambios a ciegas. Volvimos a leer las secciones 3 y 4 del punto 2 del enunciado para contrastar cada observación y ejecutamos el cliente dos veces seguidas contra el mismo servidor para verificar que seguía atendiendo solicitudes.

### 3. Idea diferente de la clase

Trabajamos en dos ramas y llegamos a dos formas distintas de organizar y validar los registros:

- En **`MiguelDev`**, `Ciudad` y `Movimiento` se escribieron como archivos `.ex`, y cada uno valida su línea con `case` anidados, repitiendo la separación de campos.
- En **`JuanDev`**, todos los módulos son `.exs`, como pide el enunciado. Cada struct valida con una cadena `with` (un paso de validación por línea), y las funciones comunes (`campos/1`, `no_vacios?/1`) se movieron a un módulo `Util` que comparten ambos structs.

La segunda forma evita código repetido, hace más fácil agregar una validación nueva y deja explícito el caso de campos vacíos, que en la primera versión no se estaba validando. La implementamos en la rama `JuanDev` y aprendimos que `with` es útil cuando hay varios pasos que pueden fallar y todos deben llevar al mismo resultado de error.

### 4. Conclusiones

- **Lo que comprendemos por nuestra cuenta:** ganamos fluidez con los módulos `String` y `Enum`, con el operador pipe y con el pattern matching en `case` y `with`, y ahora podemos escribir funciones completas de validación sin ayuda.
- **Lo que todavía nos cuesta:** la comunicación entre nodos (nombres de nodo, cookies, `Node.connect/1` y el envío de mensajes a procesos registrados en otro nodo) y razonar sobre el orden en que llegan los mensajes entre procesos.
- **Lo que cambiaríamos en un siguiente proyecto:** acordar desde el inicio la estructura de módulos y una sola rama de integración, para no llegar a dos versiones distintas del mismo código, y probar cada módulo en `iex` apenas se termina, en lugar de probar todo al final.

La IA nos ayudo a que el README tuviera un formato mas sofisticado

---

## Autores

- Luis Miguel García Villanueva
- Juan David Arias Sánchez
