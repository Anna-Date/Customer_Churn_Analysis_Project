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
