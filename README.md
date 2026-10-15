# POC Cassandra : messagerie par salon

Démonstration d'une messagerie de type chat sur un cluster Apache Cassandra à deux nœuds.
Le but est de montrer le partitionnement, la réplication, la tolérance aux pannes, le clustering order et le TTL.

## Prérequis

- Docker Desktop (au moins 3 Go de RAM alloués)
- Un terminal (PowerShell, bash ou zsh)

## Lancer le cluster

```bash
docker compose up -d
docker compose logs -f init
```

Attendez le message `Schema et donnees charges`. Le premier démarrage prend 1 à 2 minutes.

Vérifier que les deux nœuds sont up :

```bash
docker exec cassandra1 nodetool status
```

Deux lignes doivent commencer par `UN` (Up, Normal).

## Structure du projet

```
.
├── docker-compose.yml   # deux nœuds Cassandra + un service d'initialisation
├── schema.cql           # keyspace et tables
├── seed.cql             # utilisateurs, salons et messages de démonstration
└── README.md
```

## Démonstration

Ouvrez un shell CQL sur le nœud 1 :

```bash
docker exec -it cassandra1 cqlsh
```

Les commandes CQL ci-dessous se tapent dans ce shell.

### 1. Partitionnement et réplication

```bash
docker exec cassandra1 nodetool status chat
```

Avec `chat` en paramètre, la colonne *Owns (effective)* vaut 100 % pour chaque nœud. Avec un RF de 2 sur 2 nœuds, chaque nœud porte une copie de toutes les partitions.

### 2. Écriture sur un nœud, lecture sur l'autre

Dans le shell du nœud 1 :

```sql
USE chat;
INSERT INTO messages_by_channel (channel_id, message_id, author_id, content)
VALUES (c0000000-0000-0000-0000-000000000001, now(),
        a0000000-0000-0000-0000-000000000001, 'Ecrit sur le noeud 1');
```

Puis, sur le nœud 2 (dans un autre terminal) :

```bash
docker exec -it cassandra2 cqlsh
```

```sql
USE chat;
SELECT content FROM messages_by_channel
WHERE channel_id = c0000000-0000-0000-0000-000000000001 LIMIT 3;
```

Le message écrit sur le nœud 1 apparaît sur le nœud 2.

### 3. Tolérance aux pannes (QUORUM contre ONE)

Arrêtez le nœud 2 :

```bash
docker stop cassandra2
```

Attendez une trentaine de secondes, puis dans le shell du nœud 1 :

```sql
USE chat;
CONSISTENCY QUORUM;
SELECT content FROM messages_by_channel
WHERE channel_id = c0000000-0000-0000-0000-000000000001;
```

La requête échoue avec une erreur du type `Cannot achieve consistency level QUORUM`. Avec RF = 2, QUORUM demande 2 réponses et il n'y en a qu'une.

```sql
CONSISTENCY ONE;
SELECT content FROM messages_by_channel
WHERE channel_id = c0000000-0000-0000-0000-000000000001;
```

Avec `ONE`, la requête réussit. Relancez le nœud :

```bash
docker start cassandra2
```

### 4. Clustering order (tri sans ORDER BY)

```sql
SELECT message_id, content FROM messages_by_channel
WHERE channel_id = c0000000-0000-0000-0000-000000000001 LIMIT 5;
```

Les messages sortent du plus récent au plus ancien, sans `ORDER BY`. Le tri est défini par `CLUSTERING ORDER BY (message_id DESC)` dans `schema.cql`.

### 5. TTL (expiration automatique)

```sql
INSERT INTO messages_by_channel (channel_id, message_id, author_id, content)
VALUES (c0000000-0000-0000-0000-000000000001, now(),
        a0000000-0000-0000-0000-000000000001, 'Message ephemere')
USING TTL 60;

SELECT content, TTL(content) FROM messages_by_channel
WHERE channel_id = c0000000-0000-0000-0000-000000000001 LIMIT 1;
```

`TTL(content)` affiche le nombre de secondes restantes. Après 60 secondes, le message disparaît de la requête.

### 6. Dénormalisation (optionnel)

```sql
SELECT channel_name FROM channels_by_user
WHERE user_id = a0000000-0000-0000-0000-000000000001;
```

La liste des salons d'Alice se lit dans une seule partition, sans jointure. Pour comparer les coûts, activez `TRACING ON;` avant la requête.

## Réinitialiser

```bash
docker compose down -v
```

L'option `-v` supprime aussi les volumes de données. Relancez ensuite `docker compose up -d`.

## Dépannage

- **`init` échoue avec une erreur de connexion** : les nœuds ne sont pas encore prêts. Vérifiez `docker compose ps` puis relancez `docker compose up init`.
- **Mémoire insuffisante** : augmentez la RAM allouée à Docker Desktop, ou réduisez `MAX_HEAP_SIZE` dans `docker-compose.yml`.
- **Erreurs de schéma pendant le chargement** : `schema.cql` utilise `IF NOT EXISTS`, vous pouvez donc le rejouer sans risque.