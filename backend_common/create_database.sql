-- Script pour créer la base de données PostgreSQL
-- Exécutez ce script avec psql ou pgAdmin

-- Créer la base de données si elle n'existe pas
SELECT 'CREATE DATABASE microgrid_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'microgrid_db')\gexec

-- Se connecter à la base de données
\c microgrid_db

-- Les tables seront créées automatiquement par Hibernate avec spring.jpa.hibernate.ddl-auto=update


