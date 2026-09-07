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
toolforge webservice buildservice start --mount all --cpu 1 --mem 1Gi
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
