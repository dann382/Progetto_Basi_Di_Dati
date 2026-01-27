-- Serve per garantire il reset delle chiavi primarie.
TRUNCATE UTENTE, GATE, PASSEGGERO, VOLO_NAZIONALE, VOLO_INTERNAZIONALE, PRENOTAZIONE RESTART IDENTITY CASCADE;

INSERT INTO UTENTE (Username, Password, isAdmin) VALUES 
('admin_centrale', 'admin', true),
('viaggiatore_88', 'password', false),
('globetrotter', 'flyhigh', false),
('flyer_pro', 'secure789', false),
('travel_lady', 'pass2026', false);

INSERT INTO GATE (CodiceGate, Terminale, StatoGate) VALUES 
('A01', 1, 'Aperto'),
('A02', 1, 'Occupato'),
('C10', 2, 'Chiuso');

INSERT INTO PASSEGGERO (Nome, Cognome, Documento, ID_Utente) VALUES 
('Mario', 'Rossi', 'Passaporto', 2),
('Luigi', 'Bianchi', 'Carta Identità', 2),
('Anna', 'Verdi', 'Passaporto', 3),
('Alessandro', 'Manzoni', 'Carta Identità', 4),
('Giacomo', 'Leopardi', 'Carta Identità', 4),
('Elena', 'Ferrante', 'Passaporto', 5),
('Grazia', 'Deledda', 'Carta Identità', 5),
('Italo', 'Calvino', 'Passaporto', 1), -- Admin che prenota per se stesso
('Umberto', 'Eco', 'Passaporto', 3);

INSERT INTO VOLO_NAZIONALE (CodiceVoloN, Compagnia, Partenza, Destinazione, RegioneDestinazione, DataOraPartenza, DataOraArrivo, ID_Gate) 
VALUES 
('AZ100', 'ITA', 'Roma', 'Milano', 'Lombardia', '2026-06-01 08:00:00', '2026-06-01 09:10:00', 1),
('V7550', 'Volotea', 'Napoli', 'Venezia', 'Veneto', '2026-06-02 14:00:00', '2026-06-02 15:30:00', 2),
('AZ201', 'ITA', 'Roma', 'Bari', 'Puglia', '2026-06-01 18:30:00', '2026-06-01 19:35:00', 1),
('FR456', 'Ryanair', 'Milano', 'Catania', 'Sicilia', '2026-06-02 06:15:00', '2026-06-02 08:10:00', 2),
('EZ112', 'EasyJet', 'Venezia', 'Napoli', 'Campania', '2026-06-02 11:00:00', '2026-06-02 12:20:00', 1),
('AZ333', 'ITA', 'Torino', 'Roma', 'Lazio', '2026-06-03 09:00:00', '2026-06-03 10:15:00', 2);

INSERT INTO VOLO_INTERNAZIONALE (CodiceVoloIN, Compagnia, Partenza, Destinazione, CodiceNazione, TipoDocumento, DataOraPartenza, DataOraArrivo, ID_Gate) 
VALUES 
('LH450', 'Lufthansa', 'Roma', 'Berlino', 'DEU', 'Carta Identità', '2026-06-05 10:00:00', '2026-06-05 12:15:00', 1),
('AF112', 'AirFrance', 'Milano', 'New York', 'USA', 'Passaporto', '2026-06-10 09:00:00', '2026-06-10 18:30:00', 2),
('LH123', 'Lufthansa', 'Roma', 'Francoforte', 'DEU', 'Carta Identità', '2026-06-04 07:00:00', '2026-06-04 09:15:00', 1),
('QA990', 'Qatar', 'Milano', 'Doha', 'QAT', 'Passaporto', '2026-06-05 22:30:00', '2026-06-06 06:00:00', 2),
('IB302', 'Iberia', 'Roma', 'Madrid', 'ESP', 'Carta Identità', '2026-06-06 13:00:00', '2026-06-06 15:30:00', 1),
('DL088', 'Delta', 'Roma', 'Atlanta', 'USA', 'Passaporto', '2026-06-12 11:00:00', '2026-06-12 21:45:00', 2),
('EK205', 'Emirates', 'Milano', 'Dubai', 'ARE', 'Passaporto', '2026-06-15 15:00:00', '2026-06-15 23:30:00', 1);

INSERT INTO PRENOTAZIONE (CodicePrenotazione, PostoAssegnato, ID_Passeggero, ID_Utente, CodiceVoloIN)
VALUES 
('PNR-NYC-001', '14B', 1, 2, 'AF112'),
('PNR-FRA-007', '18A', 4, 4, 'LH123'),
('PNR-DOH-008', '02K', 6, 5, 'QA990'),
('PNR-MAD-009', '11C', 7, 5, 'IB302'),
('PNR-ATL-010', '30G', 8, 1, 'DL088'),
('PNR-DXB-011', '01A', 9, 3, 'EK205');


INSERT INTO PRENOTAZIONE (CodicePrenotazione, PostoAssegnato, ID_Passeggero, ID_Utente, CodiceVoloN)
VALUES 
('PNR-MIL-002', '02A', 2, 2, 'AZ100'),
('PNR-BAR-003', '10C', 4, 4, 'AZ201'),
('PNR-CTA-004', '22F', 5, 4, 'FR456'),
('PNR-NAP-005', '01B', 6, 5, 'EZ112'),
('PNR-ROM-006', '04D', 7, 5, 'AZ333');