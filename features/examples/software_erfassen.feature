# language: de

Funktionalität: Software erfassen

  Grundlage:
    Angenommen Personas existieren
    Und ich bin "Mike"

  @javascript
  Szenario: Software-Produkt erfassen
    Wenn ich eine neue Software hinzufüge
    Und ich erfasse die folgenden Details
      | Feld                               | Wert                       |
      | Produkt                            | Test Software              |
      | Version                            | Test Version               |
      | Hersteller                         | Test Hersteller            |
      | Technische Details                 | Installationslink beachten: http://wwww.dokuwiki.ch    |
    Wenn ich speichere
    Dann ist die neue Software erstellt und unter Software auffindbar

  @javascript
  Szenario: Mögliche Werte in Software-Produkt erfassen
    Angenommen ich befinde mich auf der Software-Erstellungsseite
    Dann kann ich auf mehreren Zeilen Hinweise und Links anfügen

  @javascript
  Szenario: Mögliche Werte in Software-Lizenz erfassen
    Angenommen ich befinde mich auf der Lizenz-Erstellungsseite
    Dann die mögliche Werte für Aktivierungstyp sind in der folgenden Reihenfolge:
      | Aktivierungstyp |
      | Dongle |
      | Seriennummer |
      | Lizenzserver |
      | Challenge Response/System ID |
      | Keine/r |
    Dann die mögliche Werte für Lizenztyp sind in der folgenden Reihenfolge:
      | Lizenztyp |
      | Frei |
      | Einzelplatz |
      | Mehrplatz |
      | Site-Lizenz |
      | Konkurrent |
    Dann die mögliche Werte für Ausleihbar sind in der folgenden Reihenfolge:
      | Ausleihbar |
      | OK |
      | Nicht ausleihbar |
    Dann kann man als "Betriebssystem" keine, eine oder mehrere der folgenden Möglichkeiten in Form einer Checkbox auswählen:
      | Betriebssystem |
      | Windows |
      | Mac OS |
      | Mac OS X |
      | Linux |
    Dann kann man als "Installation" keine, eine oder mehrere der folgenden Möglichkeiten in Form einer Checkbox auswählen:
      | Citrix |
      | Lokal |
      | Web |
    Und die Option "Ausleihbar" ist standardmässig auf "Nicht ausleihbar" gesetzt

  @javascript
  Szenario: Software-Lizenz erfassen
    Angenommen es existiert ein Software-Produkt
    Wenn ich eine neue Software-Lizenz hinzufüge
    Und ich die Software setze
    Und eine Inventarnummer vergeben wird
    Und ich eine Seriennummer eingebe
    Und ich eine Aktivierungsart eingebe
    Und ich eine Lizenzart eingebe
    Und ich als Betriebssystem keine, eine oder mehrere der vorhandenen Möglichkeiten auswähle
    Und ich als Installation keine, eine oder mehrere der vorhandenen Möglichkeiten auswähle
    Und ich die den Wert "ausleihbar" setze
    Und ich speichere
    Dann sind die Informationen dieser Software-Lizenz gespeichert