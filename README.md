# FHIR Demo

Diese Ansammlung von Applikationen implementiert den Patienten als kleine Demo.

## Komponenten

Alle Komponenten koennen via `docker compose up` gestartet werden.
Die Oberflaeche ist ueber `http://127.0.0.1:3000/` standardmaessig zu erreichen.

### postgres

postgres beinhaltet die Datenbank mit Schema und einer Erweiterung die in PLPGSQL geschrieben ist.
Die beigefuegte Dockerfile startet die Datenbank.

#### Implementierung

Die Datenbank besteht aus 3 Tabellen: `patient`, `patient_name` und `id_list`.

`patient` beinhaltet alle Daten die dem Patienten gehoeren. 
Die Daten werden als JSONB-Objekt gehalten.
Zudem werden das Geburtsdatum und das Geschlecht als Suchmerkmale separat als Spalte gespeichert.

`patient_name` assoziiert Patienten mit Namen.
Da der FHIR Standard mehrere Namen pro Patienten unterstuezt, muessen diese Daten in einer 
1:n Relation festgehalten werden.
Da `text` als de-facto volle Repraesentation des Namen gehandhabt wird, muessen wir nur den `text`, sowie die
Zeit in der der Name gueltig ist/war festhalten.
Wenn wir nach Namen suchen, koennen wir die Gueltigkeit der Namen mit beruecksichtigen.

`id_list` kann verwendet werden, um IDs einzigartig zu halten.
FHIR verwendet IDs gerne zur Referenzierung zwischen Objekten, beispielsweise im Reference-Typ.
Somit teilen sich separate Objekttypen (bspw Resourcen und Elemente) den gleichen ID space aber
der ist so gross, dass das keine Probleme verursachen sollte.

Interaktionen mit der DB werden durch eine Erweiterung gesteuert.
Diese Erweiterung stellt folgende Funktionen zur Verfuegung:

- `fhir.get_patient` liefert einen Patienten vollstaendig zurueck
- `fhir.search_patients` erlaubt das Suchen nach Patienten anhand von Namen, Geburtsdatum und Geschlecht.
  Das Ergebnis nutzt Pagination.
- `fhir.upsert_patient` erstellt oder ueberschreibt einen Patienten. Die Funktion stellt nur sicher, dass
  der Patient an sich eine ID hat, untergeordnete Objekte werden so wie sie sind gespeichert.
- `fhir.get_uuid` erstellt eine neue UUID und stellt sie dem Aufrufer zur Verfuegung.

**Wahrscheinlichkeit fuer Duplikate in der ID**

Das ist das gleiche Problem wie das Geburtstagsparadox.
Das heisst wir koennen die Wahrscheinlichkeit fuer ein Duplikat fuer n Eintraege durch die Formel

1-exp(-n(n-1)/(2*2^128))

ausdruecken. Das bedeutet, dass wir mit ungefaehr 26 Billionen IDs, eine Chance von ungefaehr 
1:1.000.000.000.000 (1 Billiarde) haben werden.

Wenn wir annehmen, dass wir 1000 IDs pro Sekunde, 24h am Tag erstellen, brauchen wir "lediglich"
824 Jahre um 26 Billionen IDs zu erstellen.

### cache

Eine kleine Redis DB die als Cache benutzt wird.
Fuer diese Demo wird sie nur fuer die `GET /fhir/patient/{id}` API verwendet.
Der Cache laeuft nach 45 Sekunden aus.

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

Die Tests koennen mit `cd server && cargo test` ausgefuehrt werden.

#### Implementierung

Der Server basiert komplett auf Threadpools, um einen hohen Durchsatz an Anfragen zu genuegen.
Der Server validiert die eingehenden Objekte und stellt sicher, dass sie dem FHIR Standard entsprechen.
Der Server vergibt IDs an alle Objekte, die noch keine ID haben.

### app

Ein Vue Frontend.
Standardmaessig auf port :3000 fuer localhost verfuegbar.
Das Frontend beinhaltet nicht den kompletten Patienten, da dies nur eine Demo ist und der 
restliche Patient aehnlich funktionieren wuerde.
Lediglich die Attribute die zum Suchen verwendet werden koennen sind implementiert.

