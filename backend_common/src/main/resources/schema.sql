-- Script SQL pour créer la base de données (optionnel, Spring Boot peut le faire automatiquement)
-- Ce script est fourni à titre de référence

-- Créer la base de données (à exécuter manuellement)
-- CREATE DATABASE microgrid_db;

-- Les tables seront créées automatiquement par Hibernate avec spring.jpa.hibernate.ddl-auto=update
-- Mais voici la structure pour référence:

/*
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    role VARCHAR(20) NOT NULL DEFAULT 'USER',
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE establishments (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    type VARCHAR(50) NOT NULL,
    number_of_beds INTEGER NOT NULL,
    address VARCHAR(500),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    irradiation_class VARCHAR(1),
    installable_surface_m2 DOUBLE PRECISION,
    non_critical_surface_m2 DOUBLE PRECISION,
    monthly_consumption_kwh DOUBLE PRECISION,
    existing_pv_installed BOOLEAN DEFAULT FALSE,
    existing_pv_power_kwc DOUBLE PRECISION,
    project_budget_dh DOUBLE PRECISION,
    total_available_surface_m2 DOUBLE PRECISION,
    population_served INTEGER,
    project_priority VARCHAR(50),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_establishments_user_id ON establishments(user_id);
CREATE INDEX idx_users_email ON users(email);
*/


