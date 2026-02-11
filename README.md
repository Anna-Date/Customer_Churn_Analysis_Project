# Customer_Churn_Analysis_Project
Vollständiges Customer Churn Analyse-Projekt für ein kanadisches Telekommunikationsunternehmen
---
## Projekt-Übersicht
Vollständiges Customer Churn Analytics Projekt für ein fiktives kanadisches Telekommunikationsunternehmen.

> Das Projekt bildet ein realistisches, relationales Unternehmensdatenmodell ab und kombiniert Kunden-, Vertrags-, Transaktions-, Zahlungs-, Nutzungs- und Churn-Daten zur Durchführung zeitbasierter Analysen und Business-Insights.
**Projektumfang:**
* Zeitraum: Januar - Dezember 2024 (12 Monate)
* Regionen: Ontario, Quebec, British Columbia, Alberta, Manitoba, Saskatchewan, Nova Scotia
---
## Daten 
> Als Ausgangspunkt wurde das öffentlich verfügbare Customer Churn Dataset von Kaggle verwendet.
Dieses Dataset wurde strukturell erweitert und durch **synthetisch generierte Zeit- und Verhaltensdaten** ergänzt, um ein realistisches, mehrtabelliges Analytics-Szenario abzubilden und komplexe Fragestellungen im Bereich Customer Lifecycle und Churn-Analyse zu ermöglichen.

Die synthetische Datengenerierung orientiert sich an realistischen Geschäftsannahmen (z. B. abnehmende Nutzung vor Churn, Zahlungsprobleme, Vertragslaufzeiten).

### Generierte Dateien
> Daten (CSV)
* **customers.csv** - Kundenstammdaten 
  - customer_id, signup_date, region, gender, age
* **contract.csv** - Vertragsdetails 
  - contract_id, customer_id, subscription_type, contract_length, start_date, end_date
* **transactions.csv** - Transaktionshistorie 
  - transaction_id, customer_id, transaction_date, product_id, revenue
* **payments.csv** - Zahlungsdaten 
  - payment_id, transaction_id, payment_delay_days, payment_status
* **customer_activity.csv** - Monatliche Aktivität
  - activity_id, customer_id, activity_month, logins, support_calls
* **churn_events.csv** - Abwanderungsereignisse 
  - customer_id, churn_date, churn_reason
  ---
  ## Unternehmensdatenmodell
  <img width="600" height="600" alt="Screenshot 2026-02-01 162406" src="https://github.com/user-attachments/assets/1f29c8de-9672-4cb3-b101-edd012e27646" />
---
Um aussagekräftige Analysen durchführen zu können, wandeln wir unser **OLTP-Datenmodell** in ein **OLAP**-Datenmodell um. Wir nutzen dafür ein **Galaxy Schema**, das Analysen über mehrere Dimensionen und verschiedene Geschäftsprozesse hinweg erlaubt.

## Galaxy Schema
             dim_customer
             /     |      \
    fact_transaction  fact_customer_activity  fact_churn
          |                  |
     dim_product           dim_date
          |
     dim_contract
          |
     fact_payment
          |
     dim_payment_status

<img width="600" height="600" alt="Image 2  Feb  2026, 19_46_00" src="https://github.com/user-attachments/assets/dcc5947d-13b8-452d-b17f-a50f2df40c32" />

## Tools: 
* Superbase
* DBeaver
* SQL
* Python
* Power BI
---
## Bemerkung zur SQL Script - Churn-Risiko-Analyse

In diesem Projekt wird das Kündigungsrisiko (Churn) von Kunden regelbasiert mit SQL analysiert.
Ziel ist es, Kunden zu identifizieren, die mit hoher Wahrscheinlichkeit bald kündigen, basierend auf ihrem Verhalten und ihren Vertrags- und Zahlungsdaten.

### Verwendete Churn-Indikatoren

Die Analyse berücksichtigt folgende Dimensionen:

* **Nutzungsaktivität**
  - Durchschnittliche Anzahl von Logins (avg_logins)
  - Niedrige Nutzung deutet auf sinkendes Interesse am Produkt hin
* **Support-Interaktionen**
  - Durchschnittliche Anzahl von Support-Anrufen (avg_support_calls)
  - Viele Support-Anfragen können auf Frustration oder Probleme hinweisen

* **Zahlungsverhalten**
  - Durchschnittliche Zahlungsverspätung (avg_payment_delay_days)
  - Wiederholte Verzögerungen gelten als Frühwarnsignal für Abwanderung

* **Vertragstyp**
  - Kurzfristige oder monatliche Verträge sind leichter kündbar als langfristige Verträge

## Churn-Risiko-Score

Für jeden Kunden wird ein **Score** berechnet:

* Jedes erfüllte **Risikokriterium ergibt einen Punkt**
* Der Gesamt-Score liegt zwischen **0 (kein Risiko)** und **4 (sehr hohes Risiko)**
---
## SQL
1. Gesamtumsatz nach Jahr & Monat
2. Umsatz nach Region 
3. Umsatz nach Subscription-Typ
4. Durchschnittlicher Umsatz pro Kunde
5. Churn-Rate pro Monat
6. Top Churn-Gründe
7. Avg Support Calls vs. Churn
8. Durchschnittliche Logins pro Monat
9. Anteil verspäteter Zahlungen (länger als 7 Tagen)
10. Churn-Risiko Score
---
## Python Analyse
1. Customer Segmentation
2. Cohort Analysis
   > Cohort - ist Gruppe von Kunden, die zur gleichen Zeit z. B. im gleichen Monat oder Jahr einen Vertrag abgeschlossen haben (Signup oder Contract Start).
   >Cohort-Metriken messen, wie sich diese Gruppe über die Zeit verhält.
3. Was passiert mit Revenue, wenn wir Churn um 1 % senken?
4. Churn Prediction
