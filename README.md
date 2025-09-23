# FHIR Demo

Diese Ansammlung von Applikationen implementiert den Patienten als kleine Demo.

## Komponenten

Alle Komponenten koennen via `docker compose up` gestartet werden.
Die Oberflaeche ist ueber `http://127.0.0.1:3000/` standardmaessig zu erreichen.

### db

DB beinhaltet die Datenbank mit Schema und einer Erweiterung die in PLPGSQL geschrieben ist.
Die beigefuegte Dockerfile startet die Datenbank.

### cache

Eine kleine Redis DB die als Cache benutzt wird.
Fuer diese Demo wird sie nur fuer die `GET /fhir/patient/{id}` API verwendet.
Der Cache laeuft nach 5 Minuten aus.

### server

Der Server, der zwischen der GUI und der DB steht.
Implementiert in RUST.
APIs:
- `GET /fhir/patient` Liefert Zusammenfassungen (Name, Geburtstag, ID, Registrierungszeit, Geschlecht) aller Patienten zurueck.
- `GET /fhir/patient/{id}` Liefert alle Informationen zu einem Patienten zurueck.
- `GET /fhir/patient?gender=XXX&birthdateFrom=XXX&birthdateUntil=XXX&name=XXX&count=XXX&lastId=XXX&iterationKey=XXX`
  Paginated Suche nach Patienten. Um zu verhindern dass Daten auf vorherigen Seiten veraendert werden koennen, wird die Registrierungszeit der Patienten, sowie deren ID zur Sortierung und Seitenangabe benutzt.
- `PUT /fhir/patient` Upsert (insert oder update) den Patienten. Erwartet ein gueltiges Patientenobjekt. Wenn die ID im Objekt gesetzt ist, wird der Patient geupdated (falls vorhanden), andernfalls wird er immer eingefuegt.

Alle APIs sind durch ein access token geschuetzt (statisch).
Es gibt ein Lesetoken (`myread`) das nur die GET APIs aufrufen darf, und ein Schreibtoken (`mywrite`) das alle APIs aufrufen darf.

### app

Ein Vue Frontend.
Standardmaessig auf port :3000 fuer localhost verfuegbar.

