SOMMELIER — RELEASE CANDIDATE / PACCHETTO DEFINITIVO
Cantina personale PWA per massimo 150 bottiglie.

INCLUSO
- Interfaccia responsive in italiano, installabile come web app su iPhone.
- Cantina personale, ricerca/ordinamento, scheda bottiglia, quantità e prezzi d'acquisto.
- Campi per valore di mercato con fonte/data, finestra di beva, temperatura e decantazione (da compilare con dati verificati).
- Diario degustazioni strutturato: visivo, profumi, gusto, evoluzione, abbinamento e punteggio.
- Supabase Auth, database privato con Row Level Security, sincronizzazione e foto etichette in bucket privato.
- Backup JSON ed importazione delle schede; migrazione assistita dei dati locali al primo accesso cloud.
- Funzione server opzionale per lettura AI dell'etichetta: la chiave OpenAI resta nei secrets Supabase, mai nel browser.

PRIMA DELLA PUBBLICAZIONE
1. Apri Supabase > SQL Editor e lancia tutto supabase/schema.sql.
2. Verifica Project URL e Publishable key in config.js (sono configurazione pubblica client, non password).
3. Pubblica la cartella root su GitHub Pages (Settings > Pages > Deploy from branch, branch main, /root) o su un hosting statico HTTPS.
4. Prova creazione account, conferma email, login, aggiunta/modifica/eliminazione bottiglia, foto e degustazione.
5. Esporta un backup JSON e conservalo separatamente.

RICONOSCIMENTO AI (OPZIONALE, RICHIEDE COSTI/API)
- Installa Supabase CLI e collega il progetto.
- Imposta il secret server-side: supabase secrets set OPENAI_API_KEY=... (non inserirlo in config.js).
- Deploy: supabase functions deploy recognize-label
- La funzione usa il modello gpt-4.1-mini tramite API OpenAI. Il costo dipende dall'uso e dalle tariffe vigenti.
- L'AI trascrive dati leggibili; verifica sempre produttore, annata e denominazione prima di salvare.

IMPORTANTI LIMITI ONESTI
- Prezzi di mercato e finestre di beva non sono interrogati automaticamente da un database commerciale: l'app offre campi dedicati per valore, fonte, data e finestra, da compilare/validare. Non mostra quotazioni inventate.
- Il riconoscimento AI funziona solo dopo il deploy della Edge Function e la configurazione del secret OPENAI_API_KEY.
- Il pacchetto non può verificare il tuo progetto Supabase o pubblicare il sito al posto tuo. Prima dell'uso quotidiano, esegui i test indicati.
- Non usare mai service_role key o password database nel client.
