--CREATE DATABASE Aeroporto;

DROP TABLE IF EXISTS PRENOTAZIONE;
DROP TABLE IF EXISTS VOLO_INTERNAZIONALE;
DROP TABLE IF EXISTS VOLO_NAZIONALE;
DROP TABLE IF EXISTS GATE;
DROP TABLE IF EXISTS PASSEGGERO;
DROP TABLE IF EXISTS UTENTE;

CREATE TABLE Utente (
    ID_Utente SERIAL PRIMARY KEY,
    Username VARCHAR(20) UNIQUE NOT NULL,
    Password VARCHAR(255) NOT NULL,
    isAdmin BOOLEAN DEFAULT FALSE
);

CREATE TABLE Gate (
    ID_Gate SERIAL PRIMARY KEY,
    CodiceGate VARCHAR(5) UNIQUE NOT NULL,
    Terminale INTEGER NOT NULL,
    StatoGate VARCHAR(10) CHECK (StatoGate IN ('Aperto', 'Chiuso', 'Occupato'))
);

CREATE TABLE Volo_Nazionale (
    CodiceVoloN VARCHAR(5) PRIMARY KEY,
    Compagnia VARCHAR(10) NOT NULL,
    Partenza VARCHAR(20) NOT NULL,
    Destinazione VARCHAR(20) NOT NULL,
    RegioneDestinazione VARCHAR(20) NOT NULL,
    DataOraPartenza TIMESTAMP NOT NULL,
    DataOraArrivo TIMESTAMP NOT NULL,
    ID_Gate INTEGER REFERENCES GATE(ID_Gate),
    CONSTRAINT chk_date_voloN CHECK (DataOraArrivo > DataOraPartenza)
);

CREATE TABLE Volo_Internazionale (
    CodiceVoloIN VARCHAR(5) PRIMARY KEY,
    Compagnia VARCHAR(10) NOT NULL,
    Partenza VARCHAR(20) NOT NULL,
    Destinazione VARCHAR(20) NOT NULL,
    CodiceNazione VARCHAR(5) NOT NULL,
    TipoDocumento VARCHAR(20) CHECK (TipoDocumento IN ('Passaporto', 'Visto', 'Carta Identità')),
    DataOraPartenza TIMESTAMP NOT NULL,
    DataOraArrivo TIMESTAMP NOT NULL,
    ID_Gate INTEGER REFERENCES GATE(ID_Gate),
    CONSTRAINT chk_date_voloIN CHECK (DataOraArrivo > DataOraPartenza)
);

--Non si può inserire un volo ad un gate chiuso.
CREATE OR REPLACE FUNCTION check_gate_chiuso()
RETURNS TRIGGER AS $$
DECLARE
    stato_attuale VARCHAR(10);
BEGIN
    SELECT StatoGate INTO stato_attuale FROM Gate WHERE ID_Gate = NEW.ID_Gate;
    IF stato_attuale = 'Chiuso' THEN
        RAISE EXCEPTION 'Impossibile assegnare un volo al gate %, è chiuso.', NEW.ID_Gate;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--Trigger per i voli nazionali
CREATE OR REPLACE TRIGGER trg_check_gate_nazionale
BEFORE INSERT OR UPDATE ON Volo_Nazionale
FOR EACH ROW
EXECUTE FUNCTION check_gate_chiuso();

--Trigger per i voli internazionali
CREATE OR REPLACE TRIGGER trg_check_gate_internazionale
BEFORE INSERT OR UPDATE ON Volo_Internazionale
FOR EACH ROW
EXECUTE FUNCTION check_gate_chiuso();

CREATE TABLE Passeggero (
    ID_Passeggero SERIAL PRIMARY KEY,
    Nome VARCHAR(30) NOT NULL,
    Cognome VARCHAR(30) NOT NULL,
    Documento VARCHAR(50) NOT NULL,
    ID_Utente INTEGER REFERENCES Utente(ID_Utente) ON DELETE CASCADE
);

CREATE TABLE Prenotazione (
    ID_Prenotazione SERIAL PRIMARY KEY,
    CodicePrenotazione VARCHAR(20) UNIQUE NOT NULL,
    PostoAssegnato VARCHAR(10) NOT NULL,
    StatoPrenotazione VARCHAR(20) DEFAULT 'In Attesa' 
        CHECK (StatoPrenotazione IN ('Confermata', 'Cancellata', 'In Attesa')),
    ID_Passeggero INTEGER NOT NULL REFERENCES PASSEGGERO(ID_Passeggero),
    ID_Utente INTEGER NOT NULL REFERENCES UTENTE(ID_Utente),
    CodiceVoloN VARCHAR(5) REFERENCES VOLO_NAZIONALE(CodiceVoloN),
    CodiceVoloIN VARCHAR(5) REFERENCES VOLO_INTERNAZIONALE(CodiceVoloIN),
    
    -- Vincolo XOR: una prenotazione deve avere o un volo N o un volo IN, non entrambi
    CONSTRAINT chk_xor_volo CHECK (
        (CodiceVoloN IS NOT NULL AND CodiceVoloIN IS NULL) OR 
        (CodiceVoloN IS NULL AND CodiceVoloIN IS NOT NULL)
    )
);

--Funzione per controllare la disponibilità del posto
CREATE OR REPLACE FUNCTION check_posto_disponibile()
RETURNS TRIGGER AS $$
BEGIN
    -- Controlla se esiste già una prenotazione confermata per lo stesso volo e stesso posto
    IF EXISTS (
        SELECT 1 FROM PRENOTAZIONE 
        WHERE PostoAssegnato = NEW.PostoAssegnato 
        AND (CodiceVoloN = NEW.CodiceVoloN OR CodiceVoloIN = NEW.CodiceVoloIN)
        AND StatoPrenotazione = 'Confermata'
        AND ID_Prenotazione != NEW.ID_Prenotazione
    ) THEN
        RAISE EXCEPTION 'Errore: Il posto % è già stato occupato per questo volo.', NEW.PostoAssegnato;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_check_posto
BEFORE INSERT OR UPDATE ON PRENOTAZIONE
FOR EACH ROW EXECUTE FUNCTION check_posto_disponibile();

CREATE OR REPLACE FUNCTION check_coerenza_documenti()
RETURNS TRIGGER AS $$
DECLARE
    tipo_richiesto_dal_volo VARCHAR;
    tipo_posseduto_dal_passeggero VARCHAR;
BEGIN
    -- Se il volo non è internazionale, non c'è bisogno di fare nulla
    IF NEW.CodiceVoloIN IS NULL THEN
        RETURN NEW;
    END IF;

    -- Ottenimento del tipo di documento richiesto.
    SELECT TipoDocumento INTO tipo_richiesto_dal_volo 
    FROM VOLO_INTERNAZIONALE 
    WHERE CodiceVoloIN = NEW.CodiceVoloIN;

    -- Ottenimento del tipo di documento del passeggero.
    SELECT Documento INTO tipo_posseduto_dal_passeggero 
    FROM PASSEGGERO 
    WHERE ID_Passeggero = NEW.ID_Passeggero;

    -- Confronto tra i due dati, per verificare se il passeggero è idoneo.
    IF tipo_richiesto_dal_volo != tipo_posseduto_dal_passeggero THEN
        RAISE EXCEPTION 'Impossibile prenotare: il volo richiede %, ma il passeggero ha %.', 
        tipo_richiesto_dal_volo, tipo_posseduto_dal_passeggero;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_coerenza_documenti
BEFORE INSERT OR UPDATE ON PRENOTAZIONE
FOR EACH ROW EXECUTE FUNCTION check_coerenza_documenti();

CREATE OR REPLACE FUNCTION gestione_cancellazione_volo()
RETURNS TRIGGER AS $$
BEGIN
    -- Annulla tutte le prenotazioni collegate al volo cancellato
    -- Operiamo sui record cancellati usando OLD
    UPDATE PRENOTAZIONE 
    SET StatoPrenotazione = 'Cancellata'
    WHERE CodiceVoloN = OLD.CodiceVoloN OR CodiceVoloIN = OLD.CodiceVoloIN;

    -- Se il volo aveva un Gate assegnato, riportiamo il Gate a "Aperto"
    IF OLD.ID_Gate IS NOT NULL THEN
        UPDATE GATE 
        SET StatoGate = 'Aperto'
        WHERE ID_Gate = OLD.ID_Gate;
        
        RAISE NOTICE 'Gate % riaperto a seguito della cancellazione del volo.', OLD.ID_Gate;
    END IF;

    RAISE NOTICE 'Tutte le prenotazioni per il volo % sono state annullate.', 
                 COALESCE(OLD.CodiceVoloN, OLD.CodiceVoloIN);

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Applichiamo il trigger a entrambe le tabelle voli
CREATE TRIGGER trg_cancella_volo_naz
AFTER DELETE ON VOLO_NAZIONALE
FOR EACH ROW EXECUTE FUNCTION gestione_cancellazione_volo();

CREATE TRIGGER trg_cancella_volo_int
AFTER DELETE ON VOLO_INTERNAZIONALE
FOR EACH ROW EXECUTE FUNCTION gestione_cancellazione_volo();