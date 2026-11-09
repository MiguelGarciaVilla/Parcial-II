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
├── punto-1/
│   ├── util.exs              # Funciones auxiliares (formato de decimales)
│   ├── ciudad.exs            # Struct Ciudad + validación de cada línea
│   ├── movimiento.exs        # Struct Movimiento + validación de cada línea
│   ├── csv.exs               # Lectura de archivos y conteo de rechazados (recursivo)
│   ├── reporte.exs           # Estadísticas recursivas y formato del reporte
│   ├── coordinador.exs       # Proceso coordinador y trabajadores concurrentes
│   ├── main.exs              # Punto de entrada del punto 1
│   └── resources/
│       ├── ciudades.txt
│       ├── movimientos.txt
│       └── reporte_sismos.txt   # Se genera al ejecutar
└── punto-2/
    ├── nodo-cliente/
    │   └── nodo_cliente.exs
    └── nodo-servidor/
        ├── util.exs, ciudad.exs, movimiento.exs, csv.exs, reporte.exs, coordinador.exs
        ├── nodo_servidor.exs
        └── resources/
            ├── ciudades.txt
            └── movimientos.txt
```

---

## Formato de los archivos de entrada

Los archivos no tienen encabezado. Cada línea es un registro y los campos se separan con `@`.

| Archivo | Formato |
|---|---|
| `resources/ciudades.txt` | `idCiudad@nombre@numeroHabitantes` |
| `resources/movimientos.txt` | `código@idCiudad@horaInicio@horaFinal@magnitud@profundidad` |

**Reglas de validación**

- Las líneas vacías se ignoran.
- Se **rechaza** una línea si no tiene el número de campos esperado, si tiene un campo vacío o si contiene un dato inválido.
- `numeroHabitantes` debe ser un entero mayor que 0.
- `horaInicio` y `horaFinal` deben ser horas válidas en formato `HH:MM:SS`.
- `magnitud` debe poder convertirse en un número decimal.
- `profundidad` debe ser un decimal mayor o igual a 0.
- Se rechaza todo movimiento cuyo `idCiudad` no corresponda a una ciudad válida del catálogo.
- Cada línea rechazada se cuenta una sola vez, en el total de su archivo.

---

## Punto 1 — Reporte local

### Ejecución

Desde la carpeta **`punto-1/`**:

```bash
cd punto-1
elixir main.exs
```

### Archivos

| Tipo | Ruta (relativa a `punto-1/`) |
|---|---|
| Entrada: ciudades | `resources/ciudades.txt` |
| Entrada: movimientos | `resources/movimientos.txt` |
| Salida: reporte | `resources/reporte_sismos.txt` |

> Las rutas son relativas a la carpeta desde la que se ejecuta el comando, por eso debe ejecutarse **dentro de `punto-1/`**.

### Funcionamiento

1. El **coordinador** inicia dos procesos trabajadores con `spawn`: uno lee `ciudades.txt` y el otro `movimientos.txt`.
2. Cada trabajador envía con `send` un mensaje que identifica el archivo y su resultado (`{:ok, ...}` o `{:error, ...}`).
3. El coordinador recibe las respuestas **en cualquier orden** mediante un `receive` recursivo y solo genera el reporte cuando ambas lecturas son exitosas.
4. Para cada ciudad, una función **recursiva** recorre sus movimientos y calcula en un solo recorrido la cantidad, el movimiento de mayor magnitud y la suma de profundidades. El promedio se calcula a partir de la suma y la cantidad.
5. El reporte se muestra en consola y se guarda en `resources/reporte_sismos.txt`, reemplazando el contenido anterior.

### Manejo de errores

- Si alguno de los archivos de entrada no se puede leer, se indica cuál falló y **se conserva el reporte anterior**.
- Si falla la escritura de `reporte_sismos.txt`, el error se informa en consola.

---

## Punto 2 — Consulta entre nodos

### Nodos y cookie

| Rol | Nombre del nodo | Proceso registrado | Carpeta |
|---|---|---|---|
| Servidor | `servidor@127.0.0.1` | `:servicio_sismos` | `punto-2/nodo-servidor/` |
| Cliente | `cliente@127.0.0.1` | `:servicio_respuesta` | `punto-2/nodo-cliente/` |

Ambos nodos deben usar **la misma cookie**. En este proyecto se configura con la opción `--cookie sismos` en los dos comandos. Si las cookies no coinciden, `Node.connect/1` falla y el cliente informa el error y finaliza.

### Ejecución

Abrir **dos terminales**. Primero el servidor y después el cliente.

**Terminal 1: servidor.** Desde la carpeta **`punto-2/nodo-servidor/`**:

```bash
cd punto-2/nodo-servidor
elixir --name servidor@127.0.0.1 --cookie sismos nodo_servidor.exs
```

El servidor registra el proceso `:servicio_sismos` y queda esperando solicitudes. No cierre esta terminal.

**Terminal 2: cliente.** Desde la carpeta **`punto-2/nodo-cliente/`**:

```bash
cd punto-2/nodo-cliente
elixir --name cliente@127.0.0.1 --cookie sismos nodo_cliente.exs
```

### Solicitudes que envía el cliente

Cada mensaje tiene la forma `{destino_respuesta, solicitud}`, donde `destino_respuesta = {:servicio_respuesta, :"cliente@127.0.0.1"}`. Se envían en este orden:

| # | Solicitud | Caso que prueba |
|---|---|---|
| 1 | `{:reporte_ciudad, "C01"}` | Ciudad **con** movimientos (Armenia) |
| 2 | `{:reporte_ciudad, "C03"}` | Ciudad **sin** movimientos (Circasia) |
| 3 | `{:reporte_ciudad, "C99"}` | Ciudad **inexistente**: responde «La ciudad no está registrada» |
| 4 | `:reporte_general` | Reporte de todas las ciudades y conteo de rechazados por archivo |
| 5 | `:fin` | El servidor confirma con `:fin` después de las respuestas anteriores |

El cliente recibe y muestra las respuestas de forma **recursiva** hasta recibir `:fin`.

Por cada solicitud de reporte, el servidor lee **concurrentemente** las versiones actuales de ambos archivos y reutiliza los structs, las validaciones y los cálculos del punto 1. Si un archivo no se puede leer, responde con un mensaje que identifica el archivo y sigue atendiendo solicitudes.

---

## Verificación del punto 2

1. Iniciar el servidor en la terminal 1, como se indicó arriba.
2. Ejecutar el cliente en la terminal 2. Debe mostrar las **cuatro respuestas en orden** (C01, C03, C99, reporte general) y finalizar al recibir `:fin`.
3. **Segunda ejecución:** sin detener el servidor, ejecutar **otra vez el mismo comando** en la terminal 2:

   ```bash
   elixir --name cliente@127.0.0.1 --cookie sismos nodo_cliente.exs
   ```

   El cliente debe volver a mostrar las cuatro respuestas en el mismo orden, lo que comprueba que el servidor sigue atendiendo solicitudes después de recibir `:fin`.

> El nombre `cliente@127.0.0.1` puede reutilizarse porque el nodo de la primera ejecución ya terminó.

### Identificadores usados

| Caso | idCiudad |
|---|---|
| Ciudad con movimientos | `C01` (Armenia) |
| Ciudad sin movimientos | `C03` (Circasia) |
| Ciudad inexistente | `C99` |

---

## Datos de prueba

Los mismos archivos están en `punto-1/resources/` y en `punto-2/nodo-servidor/resources/`.

**`ciudades.txt`**

```
C01@Armenia@304314
C02@Calarcá@78684
C03@Circasia@30941
C04@Salento@0
C05@@5000
```

**`movimientos.txt`**

```
S001@C01@08:15:02@08:15:18@3.4@18.0
S002@C02@09:30:10@09:30:29@4.1@25.0
S003@C01@11:42:00@11:42:12@2.8@10.0
S004@C01@25:10:00@25:10:09@3.0@12.0
S005@C02@10:00:00@10:00:15@abc@20.0
S006@C99@12:00:00@12:00:10@2.5@8.0
S007@C04@13:00:00@13:00:05@3.1@9.0
```

### Resultado esperado

| Ciudad | Movimientos | Movimiento de mayor magnitud | Profundidad promedio |
|---|---|---|---|
| Armenia | 2 | S001 · 3.4 | 14.00 km |
| Calarcá | 1 | S002 · 4.1 | 25.00 km |
| Circasia | 0 | No aplica | No aplica |

| Archivo | Rechazados | Motivo |
|---|---|---|
| `ciudades.txt` | 2 | `C04` (habitantes = 0), `C05` (nombre vacío) |
| `movimientos.txt` | 4 | `S004` (hora inválida), `S005` (magnitud inválida), `S006` (ciudad inexistente), `S007` (ciudad rechazada del catálogo) |

---
## Reflexión sobre el uso de inteligencia artificial

## Reflexión sobre el uso de inteligencia artificial

### 1. Herramientas y agentes

Usamos **Claude** (aplicación de escritorio) como asistente de apoyo. Lo empleamos para:

- Proponer la estructura del proyecto y la responsabilidad de cada módulo (`Ciudad`, `Movimiento`, `Lector`/`Csv`, `Coordinador`, `Reporte`).
- Resolver dudas puntuales de sintaxis mientras codificábamos (pipes, capturas con `&`, `case` con guards, `with`).
- Revisar el repositorio contra el enunciado y redactar este README.
- Resolver problemas de entorno, como la autenticación de Git con GitHub (`gh auth login`).

Le pedimos expresamente que **no nos diera las soluciones completas**, sino pistas y preguntas guía, para escribir nosotros el código. Por la misma razón desactivamos las sugerencias automáticas de **GitHub Copilot** en VS Code mientras desarrollábamos.

### 2. Caso decisivo

El tema que más se nos complicó fue la comunicación entre nodos. Al pedirle a Claude que revisara nuestro repositorio contra el enunciado, nos señaló dos errores en el punto 2 que no habíamos notado:

1. El servidor leía los dos archivos uno después del otro, cuando el enunciado exige leerlos **concurrentemente**. La sugerencia fue reutilizar el coordinador del punto 1 dentro del servidor.
2. Al recibir `:fin`, el servidor respondía con un texto (`{:respuesta, "Comunicación finalizada..."}`), pero el enunciado pide confirmar con el átomo `:fin`.

También nos recomendó iniciar los nodos con `--name servidor@127.0.0.1` en lugar de `--sname`, para evitar problemas con el nombre del equipo, y usar la misma cookie con `--cookie` en ambos nodos.

No aplicamos los cambios a ciegas. Volvimos a leer las secciones 3 y 4 del punto 2 del enunciado, confirmamos que la observación era correcta y ejecutamos el cliente dos veces seguidas contra el mismo servidor para verificar que seguía atendiendo solicitudes.

### 3. Idea diferente de la clase

Trabajamos en dos ramas y llegamos a dos formas distintas de validar los registros:

- En **MiguelDev**, cada struct (`Ciudad`, `Movimiento`) valida su línea con `case` anidados y repite la separación de campos.
- En **JuanDev**, cada struct usa una cadena `with` (un paso de validación por línea) y las funciones comunes (`campos/1`, `no_vacios?/1`) se movieron a un módulo `Util` que comparten ambos structs.

La segunda forma evita código repetido, hace más fácil agregar una validación nueva y deja explícito el caso de campos vacíos, que en la primera versión no se estaba validando. La implementamos en JuanDev y aprendimos que `with` es útil cuando hay varios pasos que pueden fallar y todos deben llevar al mismo resultado de error.

### 4. Conclusiones

- **Lo que comprendemos por nuestra cuenta:** ganamos fluidez con los módulos `String` y `Enum`, con el operador pipe y con el pattern matching en `case` y `with`, y ahora podemos escribir funciones completas de validación sin ayuda.
- **Lo que todavía nos cuesta:** la comunicación entre nodos (nombres de nodo, cookies, `Node.connect/1` y el envío de mensajes a procesos registrados en otro nodo) y razonar sobre el orden en que llegan los mensajes entre procesos.
- **Lo que cambiaríamos en un siguiente proyecto:** acordar desde el inicio la estructura de módulos y una sola rama de integración, para no llegar a dos versiones distintas del mismo código, y probar cada módulo en `iex` apenas se termina, en lugar de probar todo al final.

Por ultimo,la IA nos ayudo a organizar el README en un formato mas elegante
---

## Autores

- Luis Miguel García Villanueva
- Juan David Arias Sánchez
