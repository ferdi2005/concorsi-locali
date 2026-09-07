# Guida al Deploy su Wikimedia Toolforge

Questa guida descrive la procedura completa per effettuare il deploy dell'applicazione `concorsi-locali` su **Wikimedia Toolforge**
- [Help:Toolforge/My first Ruby on Rails tool](https://wikitech.wikimedia.org/wiki/Help:Toolforge/My_first_Ruby_on_Rails_tool)
- [Help:Toolforge/Redis](https://wikitech.wikimedia.org/wiki/Help:Toolforge/Redis)
- [Sample Ruby on Rails Buildpack App](https://gitlab.wikimedia.org/toolforge-repos/sample-ruby-rails-buildpack-app)

---

## 1. Variabile d'ambiente `TOOLFORGE`

L'applicazione integra uno switch centralizzato controllato dalla variabile d'ambiente:
```bash
TOOLFORGE=true
```

Quando `TOOLFORGE=true` è impostato:
- **Database:** Si connette automaticamente a MariaDB ToolsDB (`tools.db.svc.wikimedia.cloud`) usando l'adapter `mysql2`, credenziali `TOOL_TOOLSDB_USER` e `TOOL_TOOLSDB_PASSWORD`, e database `s<tool>__concorsi`.
- **Porta Web:** La porta predefinita di Puma diventa `8000` (standard dei webservice Kubernetes su Toolforge).
- **File statici:** `config.public_file_server.enabled = true` per servire direttamente gli asset precompilati dal container pod.
- **Log:** Emissione su `STDOUT` per consentire la visualizzazione in tempo reale tramite `toolforge webservice logs -f` e `toolforge jobs logs`.
- **SSL:** `force_ssl = true` per sfruttare la terminazione TLS dell'ingress di Toolforge.
- **ActiveStorage:** I file caricati (es. logo dei concorsi) vengono archiviati su filesystem persistente NFS in `$HOME/storage` (`/data/project/<tool>/storage`), evitando che vadano persi al riavvio dei pod.
- **Sidekiq / Redis:** Si connette al cluster Redis di Toolforge e applica automaticamente il **namespacing delle chiavi** (es. `s<tool>_sidekiq:`), isolando completamente i dati da tutti gli altri tool Wikimedia.

---

## 2. Prerequisiti su Toolforge Bastion

Accedi al bastion di Toolforge e assumi l'identità del tool account:
```bash
ssh login.toolforge.org
become <nome_tool>
```
*(Sostituisci `<nome_tool>` con il nome del tuo tool, ad esempio `statistiche-wlm`)*

---

## 3. Configurazione del Database (ToolsDB MariaDB)

Su Toolforge ogni tool ha accesso a MariaDB ToolsDB.

1. **Trova la password del database:**
   La password è memorizzata nel file `~/replica.my.cnf`:
   ```bash
   cat ~/replica.my.cnf
   ```
   Annota i valori di `user` (solitamente `s<tool>`) e `password`.

2. **Crea il database dell'applicazione:**
   Connettiti al client MySQL locale:
   ```bash
   sql local
   ```
   Nel prompt MySQL, crea il database (il nome **deve** iniziare con `<user>__`, es. `s54321__concorsi`):
   ```sql
   CREATE DATABASE s<tool>__concorsi CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```

3. **Verifica il supporto ai fusi orari (Time zone support per Groupdate):**
   La gemma `groupdate` (utilizzata per i grafici temporali delle foto e dei partecipanti) richiede che MariaDB supporti la conversione dei fusi orari con `CONVERT_TZ`.

   Sempre all'interno del client `sql local`, verifica se le tabelle dei fusi orari sono attive:
   ```sql
   SELECT CONVERT_TZ(NOW(), '+00:00', 'Europe/Rome');
   ```
   - **Se restituisce la data/ora:** il supporto fusi orari è già attivo e funzionante.
   - **Se restituisce `NULL`:** significa che le tabelle dei fusi orari non sono caricate nel server MariaDB.

   > [!NOTE]
   > Su ToolsDB `CONVERT_TZ(..., 'Europe/Rome')` restituisce `NULL` perché le tabelle dei fusi orari non sono caricate nel database di sistema e i tool account non hanno i permessi di root per caricarle.
   > L'applicazione gestisce automaticamente questo scenario: quando `TOOLFORGE=true`, converte la timezone nel rispettivo offset numerico (es. `+02:00` durante l'ora legale e `+01:00` durante l'ora solare). MariaDB supporta nativamente gli offset numerici tramite calcolo aritmetico senza richiedere alcuna tabella dei fusi orari nel database.

   Esci dal client MySQL:
   ```sql
   EXIT;
   ```

---

## 4. Configurazione di Redis

Come documentato in [Help:Toolforge/Redis](https://wikitech.wikimedia.org/wiki/Help:Toolforge/Redis), hai due opzioni:

### Opzione Consigliata: Istanza Condivisa con Namespacing (Nessun container extra da gestire)
Toolforge offre un'istanza Redis gratuita e gestita su `redis.svc.tools.eqiad1.wikimedia.cloud:6379`.
Grazie a `gem 'redis-namespace'`, l'applicazione prefissa automaticamente ogni chiave (es. `s<tool>_sidekiq:*`).

Non serve fare nulla: con `TOOLFORGE=true` l'applicazione punterà automaticamente all'istanza condivisa! Se desideri personalizzare il prefisso, puoi impostare:
```bash
toolforge envvars create REDIS_NAMESPACE "mio_tool_sidekiq"
```

### Opzione Alternativa: Container Redis Privato
Se preferisci un'istanza Redis dedicata in esecuzione nel tuo namespace:
```bash
# 1. Genera una password sicura
toolforge envvars create REDIS_PASSWORD $(openssl rand -hex 16)

# 2. Avvia il container Redis continuo
toolforge jobs run \
  --image tool-containers/redis:latest \
  --command server \
  --continuous \
  --emails none \
  --port 6379 \
  redis
```
In presenza di `REDIS_PASSWORD`, l'app si collegherà automaticamente a `redis://:<REDIS_PASSWORD>@redis:6379/0`.

---

## 5. Configurazione delle Variabili d'Ambiente (`envvars`)

Imposta le variabili d'ambiente necessarie tramite il comando `toolforge envvars`:

```bash
# Attiva lo switch univoco Toolforge
toolforge envvars create TOOLFORGE true

# Chiave segreta di Rails per la crittografia delle sessioni
toolforge envvars create SECRET_KEY_BASE $(openssl rand -hex 64)

# Password di ToolsDB (trovata al punto 3 da replica.my.cnf)
toolforge envvars create TOOL_TOOLSDB_PASSWORD "LA_TUA_PASSWORD_DA_REPLICA_MY_CNF"

# Password per l'autenticazione delle pagine amministrative
toolforge envvars create SECRET_PASSWORD "LA_TUA_SECRET_PASSWORD"

# Configurazione concorsi e date WLM (adatta alle tue esigenze)
toolforge envvars create TITLE "Wiki Loves Monuments Italia"
toolforge envvars create PERIOD_START "1 september"
toolforge envvars create PERIOD_END "30 september"
toolforge envvars create MONTH "9"
toolforge envvars create MONTHS "9-10"
toolforge envvars create CAT_PREFIX "Category:Images from Wiki Loves Monuments"
toolforge envvars create CAT_SUFFIX "in Italy"

# Opzionale: attiva la dashboard web di Sidekiq su /sidekiq
toolforge envvars create WEBSIDEKIQ TRUE
```

Puoi verificare le variabili impostate in qualsiasi momento con:
```bash
toolforge envvars list
```

---

## 6. Build dell'Applicazione con il Build Service

Esegui il build container dal repository Git pubblico (sostituisci l'URL con il tuo repository GitHub/GitLab):

```bash
toolforge build start https://github.com/ferdi2005/concorsi-locali
```

Per seguire l'avanzamento della compilazione (installazione pacchetti Node, bundle gemme e precompilazione asset):
```bash
toolforge build show
toolforge build logs
```

Attendi che lo stato del build diventi `SUCCEEDED`.

---

## 7. Esecuzione delle Migrazioni Database (`migrate`)

Una volta completato il build, esegui il job di migrazione database:

```bash
toolforge jobs run migrate-job \
  --image tool-statistiche-wlm/tool-statistiche-wlm:latest \
  --command "migrate" \
  --mount all \
  --wait
```

Verifica l'esito della migrazione:
```bash
toolforge jobs logs migrate-job
# Dopo aver verificato, puoi cancellare il job completato:
toolforge jobs delete migrate-job
```

---

## 8. Avvio del Servizio Web (Puma)

Avvia il webservice HTTP specificando `--mount all` per montare lo storage persistente NFS:

```bash
toolforge webservice buildservice start --mount all --cpu 2 --mem 2Gi
```

Verifica lo stato del webservice:
```bash
toolforge webservice status
```

L'applicazione sarà raggiungibile all'indirizzo:
`https://statistiche-wlm.toolforge.org/`

---

## 9. Avvio del Worker Sidekiq in Background

Per gestire l'aggiornamento dei dati e i cron job pianificati in `config/schedule.yml`, avvia il worker Sidekiq come **continuous job**:

```bash
toolforge jobs run worker-job \
  --image tool-statistiche-wlm/tool-statistiche-wlm:latest \
  --command "worker" \
  --continuous \
  --cpu 1 \
  --mem 1Gi \
  --emails none \
  --mount all
```

Controlla lo stato del worker:
```bash
toolforge jobs list
toolforge jobs logs -f worker-job
```

---

## 10. Manutenzione, Aggiornamenti e Log

- **Consultare i log del webservice in streaming:**
  ```bash
  toolforge webservice logs -f
  ```

- **Consultare i log del worker Sidekiq:**
  ```bash
  toolforge jobs logs -f worker-job
  ```

- **Riavviare il webservice:**
  ```bash
  toolforge webservice restart
  ```

- **Accedere alla console Rails interattiva:**
  ```bash
  toolforge webservice buildservice shell
  ```
  Una volta avviata la shell nel container pod:
  ```bash
  launcher console
  # oppure
  launcher bundle exec rails console
  ```
  Al termine digitare `exit` per uscire dalla console Rails e nuovamente `exit` per chiudere la sessione del container.

- **Riavviare il worker:**
  ```bash
  toolforge jobs restart worker-job
  ```

- **Deploy di una nuova versione (dopo un `git push`):**
  ```bash
  # 1. Ricompila l'immagine
  toolforge build start https://github.com/ferdi2005/concorsi-locali

  # 2. Esegui eventuali nuove migrazioni
  toolforge jobs run migrate-job --image tool-statistiche-wlm/tool-statistiche-wlm:latest --command "migrate" --wait
  toolforge jobs delete migrate-job

  # 3. Riavvia webservice e worker
  toolforge webservice restart
  toolforge jobs restart worker-job
  ```

---

## 11. Migrazione dei Dati dalla Vecchia Webapp (PostgreSQL -> ToolsDB MariaDB)

Poiché il vecchio database usa **PostgreSQL** e Toolforge usa **MariaDB**, un dump SQL diretto (`pg_dump`) è incompatibile per via della differente sintassi SQL (tipi booleani, offset di timestamp, escaping e foreign key).

Per risolvere questo, è stato predisposto un task agnostico Rails ad alte prestazioni (`db:export_data` e `db:import_data`) basato su JSON compresso con Gzip:

### Metodo Rapido Automatizzato:
Dal tuo computer locale, esegui lo script dedicato:
```bash
./bin/transfer_to_toolforge.sh
```
Questo script:
1. Si collega via SSH al vecchio server (`deploy@c.ferdi.cc`) ed esporta tutte le tabelle applicative e ActiveStorage in `/tmp/concorsi_data_*.json.gz`.
2. Scarica il dump compresso in locale e lo invia direttamente al bastion di Toolforge in `/data/project/statistiche-wlm/`.
3. Mostra i comandi pronti per avviare il job di importazione su Toolforge.

### Esecuzione dell'importazione su Toolforge:
Sul bastion di Toolforge (`become statistiche-wlm`):
```bash
# Esegui il job di importazione (disabilita temporaneamente i vincoli di foreign key ed esegue insert_all a blocchi)
toolforge jobs run import-data-job \
  --image tool-statistiche-wlm/tool-statistiche-wlm:latest \
  --command "bundle exec rake 'db:import_data[/data/project/statistiche-wlm/concorsi_data_NOMEFILE.json.gz]'" \
  --mount all \
  --wait

# Controlla l'esito
toolforge jobs logs import-data-job

# Cancella il job completato e il file di dump
toolforge jobs delete import-data-job
rm -f /data/project/statistiche-wlm/concorsi_data_*.json.gz
```
