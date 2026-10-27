-- Devuelve el dia actual sin depender del idioma de la sesion.
CREATE OR REPLACE FUNCTION fn_dia_semana_actual
RETURN VARCHAR2
IS
    v_indice     NUMBER;
    v_nombre_dia VARCHAR2(15);
BEGIN
    v_indice := TRUNC(SYSDATE) - TRUNC(SYSDATE, 'IW') + 1;

    CASE v_indice
        WHEN 1 THEN v_nombre_dia := 'LUNES';
        WHEN 2 THEN v_nombre_dia := 'MARTES';
        WHEN 3 THEN v_nombre_dia := 'MIERCOLES';
        WHEN 4 THEN v_nombre_dia := 'JUEVES';
        WHEN 5 THEN v_nombre_dia := 'VIERNES';
        WHEN 6 THEN v_nombre_dia := 'SABADO';
        WHEN 7 THEN v_nombre_dia := 'DOMINGO';
    END CASE;

    RETURN v_nombre_dia;
END fn_dia_semana_actual;
/
