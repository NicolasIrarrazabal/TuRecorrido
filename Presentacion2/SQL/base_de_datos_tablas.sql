DROP TABLE historial_mantenimiento CASCADE CONSTRAINTS;
DROP TABLE ticket_incidencia CASCADE CONSTRAINTS;
DROP TABLE telemetria_vehiculo CASCADE CONSTRAINTS;
DROP TABLE recorrido CASCADE CONSTRAINTS;
DROP TABLE tarifa CASCADE CONSTRAINTS;
DROP TABLE horario CASCADE CONSTRAINTS;
DROP TABLE ruta_parada CASCADE CONSTRAINTS;
DROP TABLE ruta CASCADE CONSTRAINTS;
DROP TABLE vehiculo_transporte CASCADE CONSTRAINTS;
DROP TABLE conductor CASCADE CONSTRAINTS;
DROP TABLE parada CASCADE CONSTRAINTS;
DROP TABLE usuario CASCADE CONSTRAINTS;
DROP TABLE tipo_pasajero CASCADE CONSTRAINTS;
DROP TABLE operador_transporte CASCADE CONSTRAINTS;

CREATE TABLE operador_transporte (
    id_operador     VARCHAR2(50)  NOT NULL,
    razon_social    VARCHAR2(150) NOT NULL,
    nombre_fantasia VARCHAR2(100) NOT NULL,
    rut             VARCHAR2(12)  NOT NULL,
    telefono        VARCHAR2(20),
    CONSTRAINT pk_operador PRIMARY KEY (id_operador),
    CONSTRAINT uk_operador_rut UNIQUE (rut)
);

CREATE TABLE tipo_pasajero (
    id_tipo_pasajero VARCHAR2(50) NOT NULL,
    categoria        VARCHAR2(30) NOT NULL,
    porcentaje_dscto NUMBER(5,2)  DEFAULT 0 NOT NULL,
    CONSTRAINT pk_tipo_pasajero PRIMARY KEY (id_tipo_pasajero),
    CONSTRAINT ck_tipo_categoria CHECK (categoria IN ('ESTUDIANTE', 'ADULTO_MAYOR', 'TARIFA_NORMAL')),
    CONSTRAINT ck_tipo_dscto CHECK (porcentaje_dscto >= 0 AND porcentaje_dscto <= 100)
);

CREATE TABLE usuario (
    id_usuario          VARCHAR2(50)  NOT NULL,
    id_tipo_pasajero    VARCHAR2(50)  NOT NULL,
    rut                 VARCHAR2(12)  NOT NULL,
    correo_electronico  VARCHAR2(150) NOT NULL,
    telefono            VARCHAR2(20),
    hash_contrasena     VARCHAR2(255) NOT NULL,
    CONSTRAINT pk_usuario PRIMARY KEY (id_usuario),
    CONSTRAINT uk_usuario_rut UNIQUE (rut),
    CONSTRAINT uk_usuario_correo UNIQUE (correo_electronico),
    CONSTRAINT fk_usuario_tipo FOREIGN KEY (id_tipo_pasajero)
        REFERENCES tipo_pasajero (id_tipo_pasajero)
);

CREATE TABLE parada (
    id_parada         VARCHAR2(50)  NOT NULL,
    codigo_parada     VARCHAR2(20)  NOT NULL,
    nombre_parada     VARCHAR2(100) NOT NULL,
    latitud           NUMBER(10,8)  NOT NULL,
    longitud          NUMBER(11,8)  NOT NULL,
    referencia_urbana VARCHAR2(150),
    CONSTRAINT pk_parada PRIMARY KEY (id_parada),
    CONSTRAINT uk_parada_codigo UNIQUE (codigo_parada),
    CONSTRAINT ck_parada_lat CHECK (latitud BETWEEN -90 AND 90),
    CONSTRAINT ck_parada_lon CHECK (longitud BETWEEN -180 AND 180)
);

CREATE TABLE conductor (
    id_conductor         VARCHAR2(50)  NOT NULL,
    id_operador          VARCHAR2(50)  NOT NULL,
    rut                  VARCHAR2(12)  NOT NULL,
    nombre_completo      VARCHAR2(150) NOT NULL,
    licencia_conducir    VARCHAR2(30)  NOT NULL,
    telefono             VARCHAR2(20),
    calificacion_interna NUMBER(3,2)   DEFAULT 5.0 NOT NULL,
    CONSTRAINT pk_conductor PRIMARY KEY (id_conductor),
    CONSTRAINT uk_conductor_rut UNIQUE (rut),
    CONSTRAINT uk_conductor_lic UNIQUE (licencia_conducir),
    CONSTRAINT uk_cond_operador UNIQUE (id_operador, id_conductor),
    CONSTRAINT fk_conductor_operador FOREIGN KEY (id_operador)
        REFERENCES operador_transporte (id_operador)
);

CREATE TABLE vehiculo_transporte (
    id_vehiculo             VARCHAR2(50) NOT NULL,
    id_operador             VARCHAR2(50) NOT NULL,
    patente                 VARCHAR2(8)  NOT NULL,
    numero_maquina          VARCHAR2(10) NOT NULL,
    modelo                  VARCHAR2(80),
    anio_fabricacion        INTEGER,
    accesibilidad_universal CHAR(1)      DEFAULT 'N' NOT NULL,
    estado_operativo        VARCHAR2(30) NOT NULL,
    CONSTRAINT pk_vehiculo PRIMARY KEY (id_vehiculo),
    CONSTRAINT uk_vehiculo_patente UNIQUE (patente),
    CONSTRAINT uk_veh_operador UNIQUE (id_operador, id_vehiculo),
    CONSTRAINT ck_vehiculo_acc CHECK (accesibilidad_universal IN ('S','N')),
    CONSTRAINT ck_vehiculo_estado CHECK (estado_operativo IN ('ACTIVO', 'MANTENCION', 'FUERA_SERVICIO')),
    CONSTRAINT fk_vehiculo_operador FOREIGN KEY (id_operador)
        REFERENCES operador_transporte (id_operador)
);

CREATE TABLE ruta (
    id_ruta         VARCHAR2(50)  NOT NULL,
    id_operador     VARCHAR2(50)  NOT NULL,
    codigo_ruta     VARCHAR2(20)  NOT NULL,
    nombre_ruta     VARCHAR2(100) NOT NULL,
    origen          VARCHAR2(100) NOT NULL,
    destino         VARCHAR2(100) NOT NULL,
    CONSTRAINT pk_ruta PRIMARY KEY (id_ruta),
    CONSTRAINT uk_ruta_codigo UNIQUE (codigo_ruta),
    CONSTRAINT uk_ruta_operador UNIQUE (id_operador, id_ruta),
    CONSTRAINT fk_ruta_operador FOREIGN KEY (id_operador)
        REFERENCES operador_transporte (id_operador)
);

CREATE TABLE ruta_parada (
    id_ruta         VARCHAR2(50) NOT NULL,
    id_parada       VARCHAR2(50) NOT NULL,
    orden_secuencia NUMBER(3)    NOT NULL,
    CONSTRAINT pk_ruta_parada PRIMARY KEY (id_ruta, id_parada),
    CONSTRAINT uk_ruta_secuencia UNIQUE (id_ruta, orden_secuencia),
    CONSTRAINT ck_rp_orden CHECK (orden_secuencia > 0),
    CONSTRAINT fk_rp_ruta FOREIGN KEY (id_ruta)
        REFERENCES ruta (id_ruta),
    CONSTRAINT fk_rp_parada FOREIGN KEY (id_parada)
        REFERENCES parada (id_parada)
);

CREATE TABLE horario (
    id_horario  VARCHAR2(50) NOT NULL,
    id_ruta     VARCHAR2(50) NOT NULL,
    dia_semana  VARCHAR2(15) NOT NULL,
    hora_salida VARCHAR2(5)  NOT NULL,
    CONSTRAINT pk_horario PRIMARY KEY (id_horario),
    CONSTRAINT uk_horario UNIQUE (id_ruta, dia_semana, hora_salida),
    CONSTRAINT ck_horario_dia CHECK (
        dia_semana IN ('LUNES','MARTES','MIERCOLES','JUEVES','VIERNES','SABADO','DOMINGO')
    ),
    CONSTRAINT ck_horario_formato CHECK (REGEXP_LIKE(hora_salida, '^([01][0-9]|2[0-3]):[0-5][0-9]$')),
    CONSTRAINT fk_horario_ruta FOREIGN KEY (id_ruta)
        REFERENCES ruta (id_ruta)
);

CREATE TABLE tarifa (
    id_tarifa      VARCHAR2(50) NOT NULL,
    id_ruta        VARCHAR2(50) NOT NULL,
    monto_base_clp NUMBER(6)    NOT NULL,
    CONSTRAINT pk_tarifa PRIMARY KEY (id_tarifa),
    CONSTRAINT uk_tarifa_ruta UNIQUE (id_ruta),
    CONSTRAINT ck_tarifa_monto CHECK (monto_base_clp > 0),
    CONSTRAINT fk_tarifa_ruta FOREIGN KEY (id_ruta)
        REFERENCES ruta (id_ruta)
);

CREATE TABLE recorrido (
    id_recorrido      VARCHAR2(50) NOT NULL,
    id_operador       VARCHAR2(50) NOT NULL,
    id_ruta           VARCHAR2(50) NOT NULL,
    id_vehiculo       VARCHAR2(50) NOT NULL,
    id_conductor      VARCHAR2(50) NOT NULL,
    fecha_hora_inicio TIMESTAMP    NOT NULL,
    fecha_hora_fin    TIMESTAMP,
    estado_recorrido  VARCHAR2(30) NOT NULL,
    CONSTRAINT pk_recorrido PRIMARY KEY (id_recorrido),
    CONSTRAINT ck_recorrido_estado CHECK (estado_recorrido IN ('PROGRAMADO', 'EN_TRANSITO', 'FINALIZADO', 'CANCELADO')),
    CONSTRAINT fk_rec_ruta FOREIGN KEY (id_operador, id_ruta) 
        REFERENCES ruta (id_operador, id_ruta),
    CONSTRAINT fk_rec_vehiculo FOREIGN KEY (id_operador, id_vehiculo) 
        REFERENCES vehiculo_transporte (id_operador, id_vehiculo),
    CONSTRAINT fk_rec_conductor FOREIGN KEY (id_operador, id_conductor) 
        REFERENCES conductor (id_operador, id_conductor)
);

CREATE TABLE telemetria_vehiculo (
    id_registro   VARCHAR2(50) NOT NULL,
    id_recorrido  VARCHAR2(50) NOT NULL,
    latitud       NUMBER(10,8) NOT NULL,
    longitud      NUMBER(11,8) NOT NULL,
    velocidad_kmh NUMBER(5,2),
    fecha_hora    TIMESTAMP    NOT NULL,
    CONSTRAINT pk_telemetria PRIMARY KEY (id_registro),
    CONSTRAINT ck_telem_vel CHECK (velocidad_kmh IS NULL OR velocidad_kmh >= 0),
    CONSTRAINT ck_telem_lat CHECK (latitud BETWEEN -90 AND 90),
    CONSTRAINT ck_telem_lon CHECK (longitud BETWEEN -180 AND 180),
    CONSTRAINT fk_telem_recorrido FOREIGN KEY (id_recorrido)
        REFERENCES recorrido (id_recorrido)
);

CREATE TABLE ticket_incidencia (
    id_ticket            VARCHAR2(50)   NOT NULL,
    id_usuario           VARCHAR2(50)   NOT NULL,
    id_recorrido         VARCHAR2(50)   NOT NULL,
    categoria_incidencia VARCHAR2(50)   NOT NULL,
    detalle_incidente    VARCHAR2(1000) NOT NULL,
    estado_revision      VARCHAR2(30)   NOT NULL,
    respuesta_operador   VARCHAR2(1000),
    fecha_creacion       TIMESTAMP      NOT NULL,
    CONSTRAINT pk_ticket PRIMARY KEY (id_ticket),
    CONSTRAINT ck_ticket_cat CHECK (categoria_incidencia IN ('FALLA_MECANICA', 'CONDUCTA_CHOFER', 'RETRASO', 'LIMPIEZA', 'OTRO')),
    CONSTRAINT ck_ticket_estado CHECK (estado_revision IN ('PENDIENTE', 'EN_PROCESO', 'RESUELTO', 'DESESTIMADO')),
    CONSTRAINT fk_ticket_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario),
    CONSTRAINT fk_ticket_recorrido FOREIGN KEY (id_recorrido)
        REFERENCES recorrido (id_recorrido)
);

CREATE TABLE historial_mantenimiento (
    id_mantenimiento    VARCHAR2(50)   NOT NULL,
    id_vehiculo         VARCHAR2(50)   NOT NULL,
    id_ticket_origen    VARCHAR2(50),
    fecha_ingreso       TIMESTAMP      NOT NULL,
    fecha_salida        TIMESTAMP,
    descripcion_falla   VARCHAR2(500)  NOT NULL,
    acciones_realizadas VARCHAR2(1000),
    estado_reparacion   VARCHAR2(30)   NOT NULL,
    CONSTRAINT pk_mantenimiento PRIMARY KEY (id_mantenimiento),
    CONSTRAINT ck_mant_estado CHECK (estado_reparacion IN ('EN_EVALUACION', 'REPARANDO', 'FINALIZADO')),
    CONSTRAINT fk_mant_vehiculo FOREIGN KEY (id_vehiculo)
        REFERENCES vehiculo_transporte (id_vehiculo),
    CONSTRAINT fk_mant_ticket FOREIGN KEY (id_ticket_origen)
        REFERENCES ticket_incidencia (id_ticket)
);

CREATE INDEX ix_usuario_tipo ON usuario (id_tipo_pasajero);
CREATE INDEX ix_conductor_operador ON conductor (id_operador);
CREATE INDEX ix_vehiculo_operador ON vehiculo_transporte (id_operador);
CREATE INDEX ix_ruta_operador ON ruta (id_operador);
CREATE INDEX ix_rp_parada ON ruta_parada (id_parada);
CREATE INDEX ix_rec_operador ON recorrido (id_operador);
CREATE INDEX ix_recorrido_ruta ON recorrido (id_ruta);
CREATE INDEX ix_recorrido_vehiculo ON recorrido (id_vehiculo);
CREATE INDEX ix_recorrido_conductor ON recorrido (id_conductor);
CREATE INDEX ix_horario_ruta ON horario (id_ruta);
CREATE INDEX ix_telem_recorrido ON telemetria_vehiculo (id_recorrido);
CREATE INDEX ix_telem_fecha ON telemetria_vehiculo (fecha_hora);
CREATE INDEX ix_ticket_usuario ON ticket_incidencia (id_usuario);
CREATE INDEX ix_ticket_recorrido ON ticket_incidencia (id_recorrido);
CREATE INDEX ix_ticket_estado ON ticket_incidencia (estado_revision);
CREATE INDEX ix_mant_vehiculo ON historial_mantenimiento (id_vehiculo);
CREATE INDEX ix_mant_ticket ON historial_mantenimiento (id_ticket_origen);