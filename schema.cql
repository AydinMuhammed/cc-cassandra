-- Schéma du POC : messagerie par salon de discussion

-- Un keyspace par application. NetworkTopologyStrategy est la stratégie
-- recommandée en production ; le nom 'dc1' doit correspondre à CASSANDRA_DC.
CREATE KEYSPACE IF NOT EXISTS chat
WITH replication = {'class': 'NetworkTopologyStrategy', 'dc1': 2};

USE chat;

-- Table 1 : messages d'un salon (requête : "les derniers messages du salon")
-- - partition key : channel_id  -> tous les messages d'un salon sont ensemble
-- - clustering    : message_id DESC -> tri natif, du plus récent au plus ancien
-- - TTL par défaut : 30 jours (2 592 000 secondes)
CREATE TABLE IF NOT EXISTS messages_by_channel (
    channel_id uuid,
    message_id timeuuid,
    author_id  uuid,
    content    text,
    PRIMARY KEY ((channel_id), message_id)
) WITH CLUSTERING ORDER BY (message_id DESC)
  AND default_time_to_live = 2592000;

-- Table 2 : salons d'un utilisateur (requête : "mes salons")
-- Le nom du salon est dupliqué ici pour éviter toute jointure.
CREATE TABLE IF NOT EXISTS channels_by_user (
    user_id      uuid,
    channel_id   uuid,
    channel_name text,
    PRIMARY KEY ((user_id), channel_id)
);
