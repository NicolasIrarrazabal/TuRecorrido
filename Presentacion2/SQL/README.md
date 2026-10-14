# Objetos PL/SQL

## Packages

**`pkg_tarifas`** — Su función `fn_calcular_tarifa(id_ruta, id_usuario)` devuelve lo que paga un usuario por una ruta. Para calcularlo aplica al monto base el descuento que corresponde a su tipo de pasajero. Si el usuario no existe lanza el error -20004, y si la ruta no tiene tarifa lanza el -20003.

**`pkg_telemetria`** — Su función `fn_velocidad_promedio(id_recorrido)` devuelve la velocidad promedio de un recorrido en km/h, redondeada a 2 decimales.

## Triggers (tabla `ticket_incidencia`)

**`trg_ticket_estado_inicial`** — Al insertar un ticket, le asigna el estado `PENDIENTE` y la fecha actual.

**`trg_ticket_valida_cambio`** — Al cambiar el estado de un ticket, solo permite pasar de `PENDIENTE` a `EN_PROCESO`, de `EN_PROCESO` a `RESUELTO`, o desde cualquiera de esos dos a `DESESTIMADO`. Un ticket finalizado no se puede modificar. Si el cambio no está permitido, lanza el error -20010.

**`trg_ticket_aviso_insercion`** — Después de cada INSERT en la tabla, muestra un mensaje de aviso por `DBMS_OUTPUT`.
