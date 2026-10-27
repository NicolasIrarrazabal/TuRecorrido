-- Especificacion publica.
CREATE OR REPLACE PACKAGE pkg_telemetria IS
    FUNCTION fn_velocidad_promedio(p_id_recorrido IN NUMBER)
    RETURN NUMBER;
END pkg_telemetria;
/

-- Implementacion de la funcion del package.
CREATE OR REPLACE PACKAGE BODY pkg_telemetria IS
    FUNCTION fn_velocidad_promedio(p_id_recorrido IN NUMBER)
    RETURN NUMBER
    IS
        v_promedio NUMBER;
    BEGIN
        SELECT ROUND(AVG(velocidad_kmh), 2)
          INTO v_promedio
          FROM telemetria_vehiculo
         WHERE id_recorrido = p_id_recorrido;

        RETURN v_promedio;
    END fn_velocidad_promedio;
END pkg_telemetria;
/
