-- Funcion publica: delega el calculo en pkg_telemetria.
-- Requiere que package1_pkg_telemetria.sql se haya ejecutado antes.
CREATE OR REPLACE FUNCTION fn_velocidad_promedio(
    p_id_recorrido IN NUMBER
)
RETURN NUMBER
IS
BEGIN
    RETURN pkg_telemetria.fn_velocidad_promedio(p_id_recorrido);
END fn_velocidad_promedio;
/
