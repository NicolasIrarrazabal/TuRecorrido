-- Especificacion: funcion accesible desde SQL y otros programas PL/SQL.
CREATE OR REPLACE PACKAGE pkg_tarifas IS
    FUNCTION fn_calcular_tarifa(
        p_id_ruta    IN VARCHAR2,
        p_id_usuario IN VARCHAR2
    ) RETURN NUMBER;
END pkg_tarifas;
/

CREATE OR REPLACE PACKAGE BODY pkg_tarifas IS
    -- Funcion privada: solo esta declarada en el body.
    FUNCTION fn_usuario_existe_privado(p_id_usuario IN VARCHAR2)
    RETURN BOOLEAN
    IS
        v_cant NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_cant
          FROM usuario
         WHERE id_usuario = p_id_usuario;

        RETURN (v_cant > 0);
    END fn_usuario_existe_privado;

    FUNCTION fn_calcular_tarifa(
        p_id_ruta    IN VARCHAR2,
        p_id_usuario IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_monto_base  tarifa.monto_base_clp%TYPE;
        v_descuento   tipo_pasajero.porcentaje_dscto%TYPE;
        v_monto_final NUMBER;

        e_usuario_no_encontrado EXCEPTION;
        e_tarifa_no_registrada  EXCEPTION;
    BEGIN
        IF NOT fn_usuario_existe_privado(p_id_usuario) THEN
            RAISE e_usuario_no_encontrado;
        END IF;

        SELECT tp.porcentaje_dscto
          INTO v_descuento
          FROM usuario u
          JOIN tipo_pasajero tp ON u.id_tipo_pasajero = tp.id_tipo_pasajero
         WHERE u.id_usuario = p_id_usuario;

        BEGIN
            SELECT monto_base_clp
              INTO v_monto_base
              FROM tarifa
             WHERE id_ruta = p_id_ruta;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE e_tarifa_no_registrada;
        END;

        v_monto_final := ROUND(v_monto_base * (1 - v_descuento / 100));
        RETURN v_monto_final;
    EXCEPTION
        WHEN e_usuario_no_encontrado THEN
            RAISE_APPLICATION_ERROR(-20004, 'Usuario no encontrado: ' || p_id_usuario);
        WHEN e_tarifa_no_registrada THEN
            RAISE_APPLICATION_ERROR(-20003, 'Ruta sin tarifa registrada: ' || p_id_ruta);
        WHEN TOO_MANY_ROWS THEN
            RAISE_APPLICATION_ERROR(-20007, 'La ruta tiene mas de una tarifa registrada');
    END fn_calcular_tarifa;
END pkg_tarifas;
/
