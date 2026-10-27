-- Requiere sp_evaluar_reincidencia compilado previamente.
CREATE OR REPLACE PROCEDURE sp_revisar_reincidencia_diaria
IS
    v_inicio TIMESTAMP := TRUNC(SYSDATE);
    v_fin    TIMESTAMP := TRUNC(SYSDATE) + 1;
    v_cant   NUMBER;
    v_supera VARCHAR2(2);

    CURSOR c_conductores IS
        SELECT id_conductor, nombre_completo
          FROM conductor;
BEGIN
    FOR r_cond IN c_conductores LOOP
        sp_evaluar_reincidencia(
            'CONDUCTOR', r_cond.id_conductor, v_inicio, v_fin, 10,
            v_cant, v_supera
        );

        DBMS_OUTPUT.PUT_LINE(
            'Conductor: ' || r_cond.nombre_completo ||
            ' | Tickets: ' || v_cant ||
            ' | Supera limite: ' || v_supera
        );
    END LOOP;
END sp_revisar_reincidencia_diaria;
/
