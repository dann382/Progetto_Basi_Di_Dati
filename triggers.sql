CREATE TRIGGER trg_controllo_documenti
BEFORE INSERT OR UPDATE ON prenotazione
FOR EACH ROW
EXECUTE FUNCTION controllo_documenti_internazionali();

CREATE TRIGGER trg_prenotazione_insert
BEFORE INSERT ON prenotazione
FOR EACH ROW
EXECUTE FUNCTION gestione_prenotazione_completa();

CREATE TRIGGER trg_ripristino_posti
AFTER DELETE OR UPDATE ON prenotazione
FOR EACH ROW
EXECUTE FUNCTION gestione_ripristino_posti_unificata();

CREATE TRIGGER trg_assegna_gate_n
BEFORE UPDATE OF StatoVolo ON volo_nazionale
FOR EACH ROW
EXECUTE FUNCTION assegna_gate_automatico();

CREATE TRIGGER trg_libera_gate_n
AFTER UPDATE OF StatoVolo OR DELETE ON volo_nazionale
FOR EACH ROW
EXECUTE FUNCTION libera_gate_automatico();

CREATE TRIGGER trg_assegna_gate_n
BEFORE UPDATE OF StatoVolo ON volo_internazionale
FOR EACH ROW
EXECUTE FUNCTION assegna_gate_automatico();

CREATE TRIGGER trg_libera_gate_n
AFTER UPDATE OF StatoVolo OR DELETE ON volo_internazionale
FOR EACH ROW
EXECUTE FUNCTION libera_gate_automatico();