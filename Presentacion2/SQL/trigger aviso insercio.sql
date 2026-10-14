CREATE OR REPLACE TRIGGER trg_ticket_aviso_insercion
AFTER INSERT ON ticket_incidencia
BEGIN
    DBMS_OUTPUT.PUT_LINE('Se ejecuto una sentencia INSERT sobre tickets.');
END trg_ticket_aviso_insercion;
/
