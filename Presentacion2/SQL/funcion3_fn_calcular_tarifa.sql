-- Funcion publica: delega el calculo en pkg_tarifas.
-- Requiere que package2_pkg_tarifas.sql se haya ejecutado antes.
CREATE OR REPLACE FUNCTION fn_calcular_tarifa(
    p_id_ruta    IN NUMBER,
    p_id_usuario IN NUMBER
)
RETURN NUMBER
IS
BEGIN
    RETURN pkg_tarifas.fn_calcular_tarifa(p_id_ruta, p_id_usuario);
END fn_calcular_tarifa;
/
