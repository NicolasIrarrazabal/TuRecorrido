# Taller de avances — Evaluación Parcial 2

**Proyecto:** TuRecorrido
**Integrantes:** Vicente Herrera, Nicolás Irarrázabal
**Fecha:** 30 de septiembre de 2026

---

## Paso 2: Diseño de procedimientos y funciones

Diseñamos cuatro bloques: tres funciones y un procedimiento. Tres reciben parámetros y una no.

### 1. fn_dia_semana_actual() — función sin parámetros

**Propósito:** devolver el día de la semana de hoy ('LUNES' … 'DOMINGO'). No recibe parámetros porque su resultado depende solo de la fecha del servidor.

```sql
CREATE OR REPLACE FUNCTION fn_dia_semana_actual RETURN VARCHAR2 IS
  v_indice NUMBER;
  v_dia    VARCHAR2(15);
BEGIN
  -- lunes = 1, martes = 2, ... domingo = 7
  v_indice := TRUNC(SYSDATE) - TRUNC(SYSDATE, 'IW') + 1;

  CASE v_indice
    WHEN 1 THEN v_dia := 'LUNES';
    WHEN 2 THEN v_dia := 'MARTES';
    WHEN 3 THEN v_dia := 'MIERCOLES';
    WHEN 4 THEN v_dia := 'JUEVES';
    WHEN 5 THEN v_dia := 'VIERNES';
    WHEN 6 THEN v_dia := 'SABADO';
    ELSE        v_dia := 'DOMINGO';
  END CASE;

  RETURN v_dia;
END fn_dia_semana_actual;
/
```

### 2. fn_velocidad_promedio(p_id_recorrido) — función con parámetros

**Propósito:** devolver la velocidad promedio en km/h de un recorrido. Recibe el recorrido y devuelve un número, así que se puede usar dentro de un SELECT.

**Entrada:** p_id_recorrido
**Salida:** RETURN NUMBER (km/h con 2 decimales)

```sql
CREATE OR REPLACE FUNCTION fn_velocidad_promedio(p_id_recorrido VARCHAR2)
RETURN NUMBER IS
  v_prom NUMBER;
BEGIN
  SELECT ROUND(AVG(velocidad_kmh), 2)
    INTO v_prom
    FROM telemetria_vehiculo
   WHERE id_recorrido = p_id_recorrido;

  RETURN v_prom;   -- NULL si el recorrido no tiene velocidades
END fn_velocidad_promedio;
/
```

Promedia miles de filas de telemetría en una sola consulta, que es justamente el procesamiento masivo del proyecto.

### 3. fn_calcular_tarifa(p_id_ruta, p_id_usuario) — función con parámetros

**Propósito:** devolver lo que paga finalmente un usuario en una ruta, con el descuento de su tipo de pasajero.

**Entrada:** p_id_ruta, p_id_usuario
**Salida:** RETURN NUMBER (monto en CLP)

```sql
CREATE OR REPLACE FUNCTION fn_calcular_tarifa(p_id_ruta    VARCHAR2,
                                              p_id_usuario VARCHAR2)
RETURN NUMBER IS
  v_monto NUMBER;
  v_pct   NUMBER;
BEGIN
  -- monto base de la ruta
  SELECT monto_base_clp
    INTO v_monto
    FROM tarifa
   WHERE id_ruta = p_id_ruta;

  -- descuento del tipo de pasajero del usuario
  SELECT porcentaje_dscto
    INTO v_pct
    FROM usuario u
    JOIN tipo_pasajero tp ON u.id_tipo_pasajero = tp.id_tipo_pasajero
   WHERE u.id_usuario = p_id_usuario;

  RETURN ROUND(v_monto * (1 - v_pct / 100));

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20003, 'Ruta sin tarifa o usuario no encontrado');
END fn_calcular_tarifa;
/
```

### 4. sp_evaluar_reincidencia — procedimiento con parámetros IN y OUT

**Propósito:** contar cuántos tickets acumuló un conductor en un período y avisar si se pasa del límite. Es procedimiento porque devuelve dos resultados (cantidad y si pasa el límite), no uno solo, y eso se hace con parámetros OUT.

**Entrada:** p_id_conductor (IN), p_desde (IN), p_hasta (IN)
**Salida:** p_cantidad (OUT), p_supera (OUT)

```sql
CREATE OR REPLACE PROCEDURE sp_evaluar_reincidencia(
  p_id_conductor IN  VARCHAR2,
  p_desde        IN  DATE,
  p_hasta        IN  DATE,
  p_cantidad     OUT NUMBER,
  p_supera       OUT VARCHAR2)
IS
  v_total NUMBER;
BEGIN
  IF p_hasta < p_desde THEN
    RAISE_APPLICATION_ERROR(-20001, 'Fecha final no puede ser menor a la inicial');
  END IF;

  SELECT COUNT(*)
    INTO v_total
    FROM ticket_incidencia t
    JOIN recorrido r ON t.id_recorrido = r.id_recorrido
   WHERE r.id_conductor = p_id_conductor
     AND t.fecha_creacion BETWEEN p_desde AND p_hasta;

  p_cantidad := v_total;

  IF v_total > 10 THEN
    p_supera := 'SI';
  ELSE
    p_supera := 'NO';
  END IF;
END sp_evaluar_reincidencia;
/
```

Las funciones quedan guardadas en los packages del proyecto (`pkg_telemetria` y `pkg_tarifas`) para tenerlas agrupadas por tema.

---

## Paso 3: Diseño de triggers

Definimos tres triggers: dos a nivel de fila y uno a nivel de sentencia. Todos sobre `ticket_incidencia`, que es la tabla donde entra información masiva.

### 1. trg_ticket_estado_inicial — nivel de fila

- **Tabla:** ticket_incidencia
- **Evento/timing:** BEFORE INSERT, fila (FOR EACH ROW)
- **Qué hace:** le pone `PENDIENTE` al estado y la fecha de creación con SYSTIMESTAMP, para que ningún ticket entre "en blanco".
- **Por qué BEFORE:** hay que modificar los datos antes de que se guarden. **Por qué fila:** cada ticket lleva su propia fecha. En un INSERT no existe `:OLD`.

```sql
CREATE OR REPLACE TRIGGER trg_ticket_estado_inicial
BEFORE INSERT ON ticket_incidencia
FOR EACH ROW
BEGIN
  :NEW.estado_revision := 'PENDIENTE';
  :NEW.fecha_creacion  := SYSTIMESTAMP;
END trg_ticket_estado_inicial;
/
```

### 2. trg_ticket_valida_cambio — nivel de fila

- **Tabla:** ticket_incidencia
- **Evento/timing:** BEFORE UPDATE, fila (FOR EACH ROW)
- **Qué hace:** compara el estado anterior con el nuevo y solo deja pasar este flujo:
  - PENDIENTE → EN_PROCESO o DESESTIMADO
  - EN_PROCESO → RESUELTO o DESESTIMADO
  - cualquier otro salto → error
- **Por qué BEFORE y fila:** necesita `:OLD` y `:NEW`, que solo existen en FOR EACH ROW, y hay que bloquear el cambio antes de que se aplique.

```sql
CREATE OR REPLACE TRIGGER trg_ticket_valida_cambio
BEFORE UPDATE ON ticket_incidencia
FOR EACH ROW
BEGIN
  IF NOT ( (:OLD.estado_revision = 'PENDIENTE'
            AND :NEW.estado_revision IN ('EN_PROCESO', 'DESESTIMADO'))
        OR (:OLD.estado_revision = 'EN_PROCESO'
            AND :NEW.estado_revision IN ('RESUELTO', 'DESESTIMADO')) ) THEN
    RAISE_APPLICATION_ERROR(-20010, 'Transicion de estado no valida');
  END IF;
END trg_ticket_valida_cambio;
/
```

### 3. trg_ticket_carga_masiva — nivel de sentencia

- **Tabla:** ticket_incidencia
- **Evento/timing:** AFTER INSERT, sentencia (sin FOR EACH ROW)
- **Qué hace:** se ejecuta una sola vez por sentencia, aunque la sentencia inserte muchas filas. Revisa `SQL%ROWCOUNT` y, si una sola carga creó más de 100 tickets, corta la operación con un error (puede ser un error de integración o un intento de saturar el sistema).
- **Por qué sentencia:** acá no importa fila por fila, sino el total de la operación, y así no se repite N veces en una carga masiva.

```sql
CREATE OR REPLACE TRIGGER trg_ticket_carga_masiva
AFTER INSERT ON ticket_incidencia
BEGIN
  IF SQL%ROWCOUNT > 100 THEN
    RAISE_APPLICATION_ERROR(-20011,
      'Carga masiva de tickets: ' || SQL%ROWCOUNT || ' filas en una sola sentencia');
  END IF;
END trg_ticket_carga_masiva;
/
```

---

## Paso 4: Justificación técnica (borrador de la presentación)

**Diapositiva 1 — El problema**

- Poca información de horarios y rutas en Puerto Montt y Puerto Varas
- Los reclamos no tienen canal formal ni seguimiento
- La telemetría GPS llega cada pocos segundos y nadie la analiza
- Hoy todo es manual, lento y se presta a errores

**Diapositiva 2 — Qué hacemos**

- Base Oracle con 14 tablas y objetos PL/SQL encima
- Automatizamos incidencias, telemetría, tarifas y validaciones
- 3 funciones, 1 procedimiento y 3 triggers

**Diapositiva 3 — Estructuras que ya usamos (evaluación anterior)**

- RECORD `v_resumen`: junta recorrido, ruta, conductor, velocidad e incidencias en una variable → código ordenado, pero la estructura es fija
- VARRAY `v_dia`: guarda los 7 días de la semana → acceso directo por índice, pero el tamaño no cambia
- Cursor con ciclos anidados: recorre conductores y sus recorridos → procesa gran volumen, pero es más verboso

**Diapositiva 4 — Funciones**

- `fn_dia_semana_actual` no tiene parámetros: depende de la fecha del servidor
- `fn_velocidad_promedio` y `fn_calcular_tarifa` sí reciben parámetros y devuelven un valor con RETURN
- Ventaja: se usan dentro de un SELECT, como cualquier columna
- Desventaja: solo devuelven un resultado, si necesitáramos dos habría que hacer un procedimiento

**Diapositiva 5 — Procedimiento**

- `sp_evaluar_reincidencia` recibe un conductor y un período, y devuelve dos cosas: la cantidad de tickets y si pasa del límite
- Por eso es procedimiento y no función: dos salidas (OUT), no una
- Ventaja: perfecto para procesar y devolver resultados de un proceso completo
- Desventaja: no se puede usar dentro de un SELECT

**Diapositiva 6 — Triggers**

- Dos BEFORE de fila: ponen los datos iniciales del ticket y validan el cambio de estado
- Uno AFTER de sentencia: vigila las cargas masivas con SQL%ROWCOUNT
- :OLD y :NEW solo existen en FOR EACH ROW
- Ventaja: las reglas se cumplen siempre, aunque alguien escriba directo en la tabla
- Desventaja: son difíciles de ver cuando hay un error, porque se ejecutan solos
- Se dejaron solo tres, que es lo mínimo para controlar el ciclo de vida del ticket

**Diapositiva 7 — Excepciones**

- Capturamos NO_DATA_FOUND y OTHERS (este último muestra SQLCODE/SQLERRM)
- En las funciones usamos RAISE_APPLICATION_ERROR para avisar errores de negocio con mensaje claro
- Se justifica porque así el error dice qué pasó, en vez de un error genérico de Oracle
