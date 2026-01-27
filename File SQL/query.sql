--Query per la creazione di un'unica tabella per tutti i voli, con i gate.
SELECT CodiceVoloN AS Volo, Compagnia, Destinazione, DataOraPartenza, G.CodiceGate, G.StatoGate
FROM VOLO_NAZIONALE VN
JOIN GATE G ON VN.ID_Gate = G.ID_Gate
UNION ALL
SELECT CodiceVoloIN, Compagnia, Destinazione, DataOraPartenza, G.CodiceGate, G.StatoGate
FROM VOLO_INTERNAZIONALE VI
JOIN GATE G ON VI.ID_Gate = G.ID_Gate
ORDER BY DataOraPartenza;

--Query per visualizzare la lista dei passeggeri per un volo.
SELECT P.PostoAssegnato, Pass.Cognome, Pass.Nome, Pass.Documento, P.StatoPrenotazione
FROM PRENOTAZIONE P
JOIN PASSEGGERO Pass ON P.ID_Passeggero = Pass.ID_Passeggero
WHERE P.CodiceVoloIN = 'AF112'
ORDER BY P.PostoAssegnato;

--Query che mostra tutti i passeggeri per voli internazionali che richiedono passaporto.
SELECT P.Nome, P.Cognome, V.Destinazione, P.Documento
FROM PASSEGGERO P
JOIN PRENOTAZIONE PR ON P.ID_Passeggero = PR.ID_Passeggero
JOIN VOLO_INTERNAZIONALE V ON PR.CodiceVoloIN = V.CodiceVoloIN
WHERE V.CodiceNazione IN ('USA', 'QAT', 'ARE');

--Query che conta il numero di passeggeri a bordo per ogni volo internazionale.
SELECT CodiceVoloIN AS Volo, COUNT(*) AS Passeggeri_A_Bordo
FROM PRENOTAZIONE
WHERE CodiceVoloIN IS NOT NULL
GROUP BY CodiceVoloIN;

--Query che mostra il numero di voli Internazionali per ogni nazione di destinazione.
SELECT CodiceNazione, COUNT(*) AS NumeroVoli
FROM VOLO_INTERNAZIONALE
GROUP BY CodiceNazione
ORDER BY NumeroVoli DESC;

