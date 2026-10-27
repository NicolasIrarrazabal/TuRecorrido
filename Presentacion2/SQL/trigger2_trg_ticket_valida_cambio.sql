-- Trigger por fila: valida las transiciones de estado de los tickets.
CREATE OR REPLACE TRIGGER trg_ticket_valida_cambio
BEFORE UPDATE OF estado_revision ON ticket_incidencia
FOR EACH ROW
BEGIN
    IF :NEW.estado_revision IS NULL THEN
        RAISE_APPLICATION_ERROR(-20009, 'El estado no puede ser nulo');
    END IF;

    IF :NEW.estado_revision = :OLD.estado_revision THEN
        RETURN;
    END IF;

    IF :OLD.estado_revision = 'PENDIENTE' THEN
        IF :NEW.estado_revision NOT IN ('EN_PROCESO', 'DESESTIMADO') THEN
            RAISE_APPLICATION_ERROR(-20010, 'Transicion no valida desde PENDIENTE');
        END IF;
    ELSIF :OLD.estado_revision = 'EN_PROCESO' THEN
        IF :NEW.estado_revision NOT IN ('RESUELTO', 'DESESTIMADO') THEN
            RAISE_APPLICATION_ERROR(-20010, 'Transicion no valida desde EN_PROCESO');
        END IF;
    ELSIF :OLD.estado_revision IN ('RESUELTO', 'DESESTIMADO') THEN
        RAISE_APPLICATION_ERROR(-20010, 'No se permite modificar un ticket finalizado');
    END IF;
END trg_ticket_valida_cambio;
/
