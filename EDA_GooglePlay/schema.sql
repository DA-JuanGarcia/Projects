-- schema.sql
CREATE SCHEMA IF NOT EXISTS googleplay;
SET search_path TO googleplay;

DROP TABLE IF EXISTS apps_raw;
CREATE TABLE apps_raw (
  app TEXT,
  category TEXT,
  rating TEXT,
  reviews TEXT,
  size TEXT,
  installs TEXT,
  type TEXT,
  price TEXT,
  content_rating TEXT,
  genres TEXT,
  last_updated TEXT,
  current_ver TEXT,
  android_ver TEXT
);