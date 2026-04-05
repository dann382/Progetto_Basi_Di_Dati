CREATE TABLE gate (
	codicegate varchar(5) NOT NULL,
	terminale integer NOT NULL,
	statogate varchar(10),
	CONSTRAINT gate_pkey PRIMARY KEY (codicegate),
	CONSTRAINT chk_stato_gate CHECK (StatoGate IN ('Aperto', 'Chiuso', 'Occupato'))
);

CREATE TABLE passeggero (
	id_passeggero serial,
	nome varchar(30) NOT NULL,
	cognome varchar(30) NOT NULL,
	documento varchar(50) NOT NULL,
	id_utente integer,
	CONSTRAINT passeggero_pkey PRIMARY KEY (id_passeggero),
	CONSTRAINT passeggero_id_utente_fkey FOREIGN KEY (id_utente) REFERENCES utente(id_utente) ON DELETE CASCADE
);

CREATE TABLE utente (
	id_utente serial,
	username varchar(20) NOT NULL,
	password varchar(255) NOT NULL,
	isadmin bool NOT NULL,
	CONSTRAINT utente_pkey PRIMARY KEY (id_utente),
	CONSTRAINT utente_username_key UNIQUE (username)
);

CREATE TABLE prenotazione (
	codiceprenotazione varchar(20) NOT NULL,
	postoassegnato varchar(5) NOT NULL,
	statoprenotazione varchar(20) DEFAULT 'inAttesa',
	id_passeggero integer NOT NULL,
	id_utente integer NOT NULL,
	codicevolon varchar(5),
	codicevoloin varchar(5),
	CONSTRAINT prenotazione_pkey PRIMARY KEY (codiceprenotazione),
	CONSTRAINT chk_stato_prenotazione CHECK (StatoPrenotazione IN ('Confermata', 'Cancellata', 'inAttesa')),
    CONSTRAINT prenotazione_codicevoloin_fkey FOREIGN KEY (codicevoloin) REFERENCES volo_internazionale(codicevoloin),
	CONSTRAINT prenotazione_codicevolon_fkey FOREIGN KEY (codicevolon) REFERENCES volo_nazionale(codicevolon),
	CONSTRAINT prenotazione_id_passeggero_fkey FOREIGN KEY (id_passeggero) REFERENCES passeggero(id_passeggero),
	CONSTRAINT prenotazione_id_utente_fkey FOREIGN KEY (id_utente) REFERENCES utente(id_utente)
);


CREATE TABLE volo_nazionale (
	codicevolon varchar(5) NOT NULL,
	compagnia varchar(10) NOT NULL,
	partenza varchar(20) NOT NULL,
	destinazione varchar(20) NOT NULL,
	regionedestinazione varchar(20) NOT NULL,
	dataorapartenza timestamp NOT NULL,
	dataoraarrivo timestamp NOT NULL,
	statovolo varchar(20),
	codicegate varchar(5),
	numpostidisponibili integer,
	CONSTRAINT chk_scalo_napoli CHECK (Partenza = 'Napoli' OR Destinazione = 'Napoli'),
	CONSTRAINT volo_nazionale_check1 CHECK ((dataoraarrivo > dataorapartenza)),
	CONSTRAINT volo_nazionale_numpostidisponibili_check CHECK ((numpostidisponibili <= 150)),
	CONSTRAINT volo_nazionale_pkey PRIMARY KEY (codicevolon),
	CONSTRAINT chk_stato_volo CHECK (StatoVolo IN ('Programmato', 'in Attesa', 'Decollato', 'Cancellato', 'in Arrivo', 'in Ritardo'))
    CONSTRAINT volo_nazionale_codicegate_fkey FOREIGN KEY (codicegate) REFERENCES gate(codicegate) ON DELETE CASCADE
);

CREATE TABLE volo_internazionale (
	codicevoloin varchar(5) NOT NULL,
	compagnia varchar(10) NOT NULL,
	partenza varchar(20) NOT NULL,
	destinazione varchar(20) NOT NULL,
	codicenazione varchar(5) NOT NULL,
	tipodocumento varchar(20) NULL,
	dataorapartenza timestamp NOT NULL,
	dataoraarrivo timestamp NOT NULL,
	statovolo varchar(20),
	codicegate varchar(5),
	numpostidisponibili integer,
	CONSTRAINT chk_scalo_napoli_int CHECK (Partenza = 'Napoli' OR Destinazione = 'Napoli'),
	CONSTRAINT volo_internazionale_check1 CHECK ((dataoraarrivo > dataorapartenza)),
	CONSTRAINT volo_internazionale_pkey PRIMARY KEY (codicevoloin),
	CONSTRAINT chk_stato_volo CHECK (StatoVolo IN ('Programmato', 'in Attesa', 'Decollato', 'Cancellato', 'in Arrivo', 'in Ritardo'))
    CONSTRAINT chk_documento_richiesto CHECK (TipoDocumento IN ('Passaporto', 'Carta Identità'))
    CONSTRAINT volo_internazionale_codicegate_fkey FOREIGN KEY (codicegate) REFERENCES gate(codicegate)
);

