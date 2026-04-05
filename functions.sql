CREATE OR REPLACE FUNCTION gestione_ripristino_posti_unificata()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        IF (OLD.StatoPrenotazione = 'Confermata' AND NEW.StatoPrenotazione = 'Cancellata') THEN
            IF NEW.CodiceVoloN IS NOT NULL THEN
                UPDATE Volo_Nazionale 
                SET NumPostiDisponibili = NumPostiDisponibili + 1 
                WHERE CodiceVoloN = NEW.CodiceVoloN AND NumPostiDisponibili < 150;
            ELSE
                UPDATE Volo_Internazionale 
                SET NumPostiDisponibili = NumPostiDisponibili + 1 
                WHERE CodiceVoloIN = NEW.CodiceVoloIN AND NumPostiDisponibili < 150;
            END IF;
        END IF;
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        IF (OLD.StatoPrenotazione = 'Confermata') THEN
            IF OLD.CodiceVoloN IS NOT NULL THEN
                UPDATE Volo_Nazionale 
                SET NumPostiDisponibili = NumPostiDisponibili + 1 
                WHERE CodiceVoloN = OLD.CodiceVoloN AND NumPostiDisponibili < 150;
            ELSE
                UPDATE Volo_Internazionale 
                SET NumPostiDisponibili = NumPostiDisponibili + 1 
                WHERE CodiceVoloIN = OLD.CodiceVoloIN AND NumPostiDisponibili < 150;
            END IF;
        END IF;
        RETURN OLD;
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION controllo_documenti_internazionali()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    v_doc_richiesto VARCHAR(20);
    v_doc_passeggero VARCHAR(20);
BEGIN
    -- Scatta solo se è un volo internazionale
    IF NEW.CodiceVoloIN IS NOT NULL THEN
        
        -- 1. Recupero il documento richiesto dal volo
        SELECT TipoDocumento INTO v_doc_richiesto
        FROM Volo_Internazionale 
        WHERE CodiceVoloIN = NEW.CodiceVoloIN;

        -- 2. Recupero il documento in possesso del passeggero
        SELECT Documento INTO v_doc_passeggero 
        FROM PASSEGGERO 
        WHERE ID_Passeggero = NEW.ID_Passeggero;

        -- Se il volo richiede Passaporto ma il passeggero ha Carta Identità -> ERRORE
        IF v_doc_richiesto = 'Passaporto' AND v_doc_passeggero = 'Carta Identità' THEN
            RAISE EXCEPTION 'Documento non idoneo: il volo % richiede il Passaporto.', NEW.CodiceVoloIN;
        END IF;
    END IF;

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION gestione_prenotazione_completa()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    v_posti_disp INTEGER;
    v_partenza VARCHAR(20);
    v_stato VARCHAR(20);
BEGIN
    -- RECUPERO DATI DEL VOLO (Nazionale o Internazionale)
    IF NEW.CodiceVoloN IS NOT NULL THEN
        SELECT NumPostiDisponibili, Partenza, StatoVolo 
        INTO v_posti_disp, v_partenza, v_stato
        FROM Volo_Nazionale WHERE CodiceVoloN = NEW.CodiceVoloN;
    ELSE
        SELECT NumPostiDisponibili, Partenza, StatoVolo 
        INTO v_posti_disp, v_partenza, v_stato
        FROM Volo_Internazionale WHERE CodiceVoloIN = NEW.CodiceVoloIN;
    END IF;
    
    -- Controllo Aeroporto
    IF v_partenza != 'Napoli' THEN
        RAISE EXCEPTION 'Errore: Volo non valido. L''aeroporto gestito è solo Napoli.';
    END IF;

    -- Controllo Stato Volo
    IF v_stato IN ('Decollato', 'Cancellato') THEN
        RAISE EXCEPTION 'Errore: Impossibile prenotare un volo in stato %.', v_stato;
    END IF;

    -- Controllo Capienza
    IF v_posti_disp <= 0 THEN
        RAISE EXCEPTION 'Errore: Volo al completo.';
    END IF;

    NEW.StatoPrenotazione := 'Confermata';

    -- Scala il posto dal volo corrispondente
    IF NEW.CodiceVoloN IS NOT NULL THEN
        UPDATE Volo_Nazionale 
        SET NumPostiDisponibili = NumPostiDisponibili - 1 
        WHERE CodiceVoloN = NEW.CodiceVoloN;
    ELSE
        UPDATE Volo_Internazionale 
        SET NumPostiDisponibili = NumPostiDisponibili - 1 
        WHERE CodiceVoloIN = NEW.CodiceVoloIN;
    END IF;

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION assegna_gate_automatico()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_id_gate_libero varchar;
BEGIN
    
    IF NEW.StatoVolo = 'in Attesa' AND NEW.CodiceGate IS NULL THEN
        
        SELECT CodiceGate INTO v_id_gate_libero 
        FROM GATE 
        WHERE StatoGate = 'Aperto' 
        ORDER BY CodiceGate ASC 
        LIMIT 1;

        IF v_id_gate_libero IS NOT NULL THEN
            NEW.CodiceGate := v_id_gate_libero;
            
            UPDATE GATE 
            SET StatoGate = 'Occupato' 
            WHERE CodiceGate = v_id_gate_libero;
        ELSE
            
            RAISE NOTICE 'Attenzione: Nessun Gate disponibile per il volo %', COALESCE(NEW.CodiceVoloN, NEW.CodiceVoloIN);
        END IF;
    END IF;

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION libera_gate_automatico()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
    -- CASO 1: DELETE (Il volo viene rimosso fisicamente)
    IF (TG_OP = 'DELETE') THEN
        IF OLD.CodiceGate IS NOT NULL THEN
            UPDATE GATE SET StatoGate = 'Aperto' WHERE CodiceGate = OLD.CodiceGate;
        END IF;
        RETURN OLD;

    -- CASO 2: UPDATE (Il volo cambia stato in Decollato o Cancellato)
    ELSIF (TG_OP = 'UPDATE') THEN
        IF NEW.StatoVolo IN ('Decollato', 'Cancellato') AND OLD.CodiceGate IS NOT NULL THEN
            UPDATE GATE SET StatoGate = 'Aperto' WHERE CodiceGate = OLD.CodiceGate;
        END IF;
        RETURN NEW;
    END IF;

    RETURN NULL;
END;
$function$;