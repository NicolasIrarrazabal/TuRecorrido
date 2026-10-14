# Objetos PL/SQL — Tickets, tarifas y telemetría

Este repositorio contiene dos packages y tres triggers en Oracle PL/SQL. Los packages calculan tarifas y velocidades promedio, y los triggers controlan el ciclo de vida de los tickets de incidencia.

## Packages

### `pkg_tarifas`

Su función pública es `fn_calcular_tarifa(p_id_ruta, p_id_usuario) RETURN NUMBER`.

Calcula cuánto paga un usuario por una ruta. Primero verifica que el usuario exista, usando la función privada `fn_usuario_existe_privado`, que no se puede llamar desde fuera del package. Después obtiene el porcentaje de descuento según el tipo de pasajero del usuario y el monto base de la ruta desde `tarifa`. Con eso devuelve `ROUND(monto_base * (1 - descuento / 100))`.

| Código | Caso |
|---|---|
| -20004 | El usuario no existe |
| -20003 | La ruta no tiene tarifa registrada |
| -20007 | La ruta tiene más de una tarifa registrada |

```sql
SELECT pkg_tarifas.fn_calcular_tarifa('R001', 'U001') FROM dual;
```

### `pkg_telemetria`

Su función pública es `fn_velocidad_promedio(p_id_recorrido) RETURN NUMBER`.

Devuelve la velocidad promedio en km/h de un recorrido, calculada a partir de `telemetria_vehiculo` y redondeada a 2 decimales. Si el recorrido no tiene registros, devuelve `NULL` y no lanza error.

```sql
SELECT pkg_telemetria.fn_velocidad_promedio('REC001') FROM dual;
```

## Triggers sobre `ticket_incidencia`

### `trg_ticket_estado_inicial`

Se ejecuta antes de cada INSERT, una vez por fila. Fuerza `estado_revision = 'PENDIENTE'` y `fecha_creacion = SYSTIMESTAMP`, sin importar los valores que venían en el INSERT. Así todo ticket nuevo parte en el mismo estado y con la fecha real de creación.

### `trg_ticket_valida_cambio`

Se ejecuta antes de cada UPDATE de `estado_revision`, una vez por fila. Valida que el cambio de estado siga este flujo:

```
PENDIENTE  ──► EN_PROCESO ──► RESUELTO
    │              │
    └──────────────┴──► DESESTIMADO
```

| Estado actual | Puede pasar a |
|---|---|
| `PENDIENTE` | `EN_PROCESO`, `DESESTIMADO` |
| `EN_PROCESO` | `RESUELTO`, `DESESTIMADO` |
| `RESUELTO` / `DESESTIMADO` | Ninguno (ticket finalizado) |

Primero rechaza un estado nulo. Si el estado nuevo es igual al actual, sale sin validar nada (`RETURN`). En cualquier otro caso revisa el estado anterior (`:OLD`) y comprueba que el nuevo (`:NEW`) esté entre los permitidos.

| Código | Caso |
|---|---|
| -20009 | Se intenta poner el estado en nulo |
| -20010 | La transición no es válida o el ticket ya está finalizado |

### `trg_ticket_aviso_insercion`

Se ejecuta después de cada INSERT, a nivel de sentencia, así que corre una sola vez por INSERT aunque se inserten varias filas. Imprime un aviso con `DBMS_OUTPUT`. Para verlo hay que activar `SET SERVEROUTPUT ON`.

## Instalación

Compila los scripts en este orden: los packages primero (`package tarifas.sql`, `package telemetria.sql`) y luego los triggers. Para comprobar que todo quedó válido:

```sql
SELECT object_name, status FROM user_objects
 WHERE object_name LIKE 'PKG_T%' OR object_name LIKE 'TRG_TICKET%';
```
