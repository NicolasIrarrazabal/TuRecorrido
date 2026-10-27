-- Trigger por fila: asigna estado y fecha a cada ticket insertado.
CREATE OR REPLACE TRIGGER trg_ticket_estado_inicial
BEFORE INSERT ON ticket_incidencia
FOR EACH ROW
BEGIN
    :NEW.estado_revision := 'PENDIENTE';
    :NEW.fecha_creacion  := SYSTIMESTAMP;
END trg_ticket_estado_inicial;
/
