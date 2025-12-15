create database if not exists Salling_store;
USE Salling_store;

DROP TABLE IF EXISTS clearance_offer;
DROP TABLE IF EXISTS sg_store;
DROP TABLE IF EXISTS run;

CREATE TABLE sg_store (
  store_id CHAR(36) PRIMARY KEY,
  brand    VARCHAR(50),
  name     VARCHAR(255),
  type     VARCHAR(50),
  city     VARCHAR(100),
  country  VARCHAR(50),
  street   VARCHAR(255),
  zip      VARCHAR(10),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
             ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE clearance_offer (
  id INT AUTO_INCREMENT PRIMARY KEY,
  store_id CHAR(36),
  ean VARCHAR(20),
  currency VARCHAR(10),
  new_price DECIMAL(10,2),
  product_desc VARCHAR(200),              
  original_price DECIMAL(10,2),
  percent_discount DECIMAL(5,2),
  stock INT,
  stock_unit VARCHAR(20),
  offer_start DATETIME,
  offer_end DATETIME,
  last_update DATETIME,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_store
    FOREIGN KEY (store_id)
    REFERENCES sg_store(store_id)
);