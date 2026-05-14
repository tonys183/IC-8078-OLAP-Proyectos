/* Library Transactional Database */
CREATE DATABASE library_transactional;
GO

USE library_transactional;
GO

CREATE TABLE Client (
    client_id INT IDENTITY(1,1) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name1 VARCHAR(50) NOT NULL,
    last_name2 VARCHAR(50),
    phone_number VARCHAR(20),
    email VARCHAR(100)
);

CREATE TABLE Status (
    status_id INT IDENTITY(1,1) PRIMARY KEY,
    status_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Genre (
    genre_id INT IDENTITY(1,1) PRIMARY KEY,
    genre_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Publisher (
    publisher_id INT IDENTITY(1,1) PRIMARY KEY,
    publisher_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE ServiceType (
    type_id INT IDENTITY(1,1) PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Author (
    author_id INT IDENTITY(1,1) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name1 VARCHAR(50) NOT NULL,
    last_name2 VARCHAR(50)
);

CREATE TABLE Item (
    item_id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    base_price DECIMAL(10,2) NOT NULL,
    item_type VARCHAR(20) NOT NULL CHECK (item_type IN ('Book', 'Supply', 'Service')),
    cost DECIMAL(10,2) NOT NULL
);

CREATE TABLE CustomerOrder (
    order_id INT IDENTITY(1,1) PRIMARY KEY,
    order_date DATE NOT NULL,
    client_id INT NOT NULL FOREIGN KEY REFERENCES Client(client_id),
    status_id INT NOT NULL FOREIGN KEY REFERENCES Status(status_id)
);

CREATE TABLE Book (
    isbn VARCHAR(20) PRIMARY KEY,
    item_id INT NOT NULL UNIQUE FOREIGN KEY REFERENCES Item(item_id),
    publisher_id INT FOREIGN KEY REFERENCES Publisher(publisher_id)
);

CREATE TABLE Supply (
    item_id INT PRIMARY KEY FOREIGN KEY REFERENCES Item(item_id),
    stock INT NOT NULL
);

CREATE TABLE Service (
    item_id INT PRIMARY KEY FOREIGN KEY REFERENCES Item(item_id),
    modality VARCHAR(100),
    type_id INT NOT NULL FOREIGN KEY REFERENCES ServiceType(type_id)
);

CREATE TABLE OrderDetail (
    order_detail_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT NOT NULL FOREIGN KEY REFERENCES CustomerOrder(order_id),
    item_id INT NOT NULL FOREIGN KEY REFERENCES Item(item_id),
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0)
);

CREATE TABLE Book_Genre (
    isbn VARCHAR(20) NOT NULL FOREIGN KEY REFERENCES Book(isbn),
    genre_id INT NOT NULL FOREIGN KEY REFERENCES Genre(genre_id),
    PRIMARY KEY (isbn, genre_id)
);

CREATE TABLE Book_Author (
    isbn VARCHAR(20) NOT NULL FOREIGN KEY REFERENCES Book(isbn),
    author_id INT NOT NULL FOREIGN KEY REFERENCES Author(author_id),
    contribution_degree VARCHAR(50),
    PRIMARY KEY (isbn, author_id)
);
GO

-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

/* Library Data Warehouse */
CREATE DATABASE library_data_warehouse;
GO

USE library_data_warehouse;
GO

CREATE SCHEMA datamart;
GO

CREATE TABLE datamart.dim_client (
    client_sk INT IDENTITY(1,1) PRIMARY KEY,
    client_id INT NOT NULL,
    first_name VARCHAR(50),
    last_names VARCHAR(100),
    email VARCHAR(100)
);

CREATE TABLE datamart.dim_item (
    item_sk INT IDENTITY(1,1) PRIMARY KEY,
    item_id INT NOT NULL,
    name VARCHAR(150),
    item_type VARCHAR(20),
    category VARCHAR(100),
    modality VARCHAR(20),
    isbn VARCHAR(20),
    publisher VARCHAR(100),
    base_price DECIMAL(10,2)
);

CREATE TABLE datamart.dim_time (
    time_sk INT PRIMARY KEY,
    full_date DATE NOT NULL,
    day INT NOT NULL,
    month INT NOT NULL,
    year INT NOT NULL
);

CREATE TABLE datamart.fact_sales (
    sales_id INT IDENTITY(1,1) PRIMARY KEY,
    client_sk INT NOT NULL REFERENCES datamart.dim_client(client_sk),
    item_sk INT NOT NULL REFERENCES datamart.dim_item(item_sk),
    time_sk INT NOT NULL REFERENCES datamart.dim_time(time_sk),
    order_id INT NOT NULL,
    quantity INT NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    total_cost DECIMAL(10,2) NOT NULL,
    profit AS (total_amount - total_cost)
);