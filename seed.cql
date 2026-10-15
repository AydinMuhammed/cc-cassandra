-- Données de démonstration

USE chat;

-- Utilisateurs
--   alice : a0000000-0000-0000-0000-000000000001
--   bob   : b0000000-0000-0000-0000-000000000002
-- Salons
--   general          : c0000000-0000-0000-0000-000000000001
--   projet-cassandra : c0000000-0000-0000-0000-000000000002

-- Appartenance aux salons (les deux lignes sont dans la même partition :
-- le BATCH est donc atomique et isolé)
BEGIN BATCH
  INSERT INTO channels_by_user (user_id, channel_id, channel_name)
  VALUES (a0000000-0000-0000-0000-000000000001, c0000000-0000-0000-0000-000000000001, 'general');
  INSERT INTO channels_by_user (user_id, channel_id, channel_name)
  VALUES (a0000000-0000-0000-0000-000000000001, c0000000-0000-0000-0000-000000000002, 'projet-cassandra');
APPLY BATCH;

BEGIN BATCH
  INSERT INTO channels_by_user (user_id, channel_id, channel_name)
  VALUES (b0000000-0000-0000-0000-000000000002, c0000000-0000-0000-0000-000000000001, 'general');
APPLY BATCH;

-- Messages du salon "general"
INSERT INTO messages_by_channel (channel_id, message_id, author_id, content)
VALUES (c0000000-0000-0000-0000-000000000001, now(), a0000000-0000-0000-0000-000000000001, 'Bonjour a tous !');
INSERT INTO messages_by_channel (channel_id, message_id, author_id, content)
VALUES (c0000000-0000-0000-0000-000000000001, now(), b0000000-0000-0000-0000-000000000002, 'Salut Alice, ca va ?');
INSERT INTO messages_by_channel (channel_id, message_id, author_id, content)
VALUES (c0000000-0000-0000-0000-000000000001, now(), a0000000-0000-0000-0000-000000000001, 'Tres bien, on prepare le POC Cassandra.');

-- Messages du salon "projet-cassandra"
INSERT INTO messages_by_channel (channel_id, message_id, author_id, content)
VALUES (c0000000-0000-0000-0000-000000000002, now(), b0000000-0000-0000-0000-000000000002, 'Qui fait la partie CQL ?');
INSERT INTO messages_by_channel (channel_id, message_id, author_id, content)
VALUES (c0000000-0000-0000-0000-000000000002, now(), a0000000-0000-0000-0000-000000000001, 'Moi, je m en occupe.');
