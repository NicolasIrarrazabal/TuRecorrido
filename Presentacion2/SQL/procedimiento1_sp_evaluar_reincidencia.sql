-- Cuenta tickets de un conductor o vehiculo dentro de [inicio, fin).
CREATE OR REPLACE PROCEDURE sp_evaluar_reincidencia (
    p_tipo_objetivo IN VARCHAR2,
    p_id_objetivo   IN NUMBER,
    p_fecha_inicio IN TIMESTAMP,
    p_fecha_fin    IN TIMESTAMP,
    p_limite       IN NUMBER,
    p_cantidad     OUT NUMBER,
    p_supera_limite OUT VARCHAR2
)
IS
    v_existe NUMBER := 0;
BEGIN
    IF p_tipo_objetivo IS NULL
       OR p_tipo_objetivo NOT IN ('CONDUCTOR', 'VEHICULO') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Tipo de objetivo invalido');
    END IF;

    IF p_id_objetivo IS NULL THEN
        RAISE_APPLICATION_ERROR(-20002, 'Identificador de objetivo no puede ser nulo');
    END IF;

    IF p_fecha_inicio IS NULL OR p_fecha_fin IS NULL
       OR p_fecha_fin <= p_fecha_inicio THEN
        RAISE_APPLICATION_ERROR(-20003, 'Rango de fechas invalido');
    END IF;

    IF p_limite IS NULL OR p_limite < 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Limite invalido');
    END IF;

    IF p_tipo_objetivo = 'CONDUCTOR' THEN
        SELECT COUNT(*)
          INTO v_existe
          FROM conductor
         WHERE id_conductor = p_id_objetivo;

        IF v_existe = 0 THEN
            RAISE_APPLICATION_ERROR(-20005, 'Conductor inexistente');
        END IF;

        SELECT COUNT(t.id_ticket)
          INTO p_cantidad
          FROM ticket_incidencia t
          JOIN recorrido r ON t.id_recorrido = r.id_recorrido
         WHERE r.id_conductor = p_id_objetivo
           AND t.fecha_creacion >= p_fecha_inicio
           AND t.fecha_creacion < p_fecha_fin;

    ELSIF p_tipo_objetivo = 'VEHICULO' THEN
        SELECT COUNT(*)
          INTO v_existe
          FROM vehiculo_transporte
         WHERE id_vehiculo = p_id_objetivo;

        IF v_existe = 0 THEN
            RAISE_APPLICATION_ERROR(-20006, 'Vehiculo inexistente');
        END IF;

        SELECT COUNT(t.id_ticket)
          INTO p_cantidad
          FROM ticket_incidencia t
          JOIN recorrido r ON t.id_recorrido = r.id_recorrido
         WHERE r.id_vehiculo = p_id_objetivo
           AND t.fecha_creacion >= p_fecha_inicio
           AND t.fecha_creacion < p_fecha_fin;
    END IF;

    IF p_cantidad > p_limite THEN
        p_supera_limite := 'SI';
    ELSE
        p_supera_limite := 'NO';
    END IF;
END sp_evaluar_reincidencia;
/
