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
    status_id INT NOT NULL FOREIGN KEY REFERENCES Status(status_id),
    total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount >= 0)
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
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    unit_cost DECIMAL(10,2) NOT NULL CHECK (unit_cost >= 0)
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


/* CDC Configuration */
USE library_transactional;
GO

EXEC sys.sp_cdc_enable_db;
GO

EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'Client', @role_name = NULL, @supports_net_changes = 1;
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'Item', @role_name = NULL, @supports_net_changes = 1;
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'Book', @role_name = NULL, @supports_net_changes = 1;
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'Publisher', @role_name = NULL, @supports_net_changes = 1;
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'Genre', @role_name = NULL, @supports_net_changes = 1;
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'Book_Genre', @role_name = NULL, @supports_net_changes = 1;
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'Service', @role_name = NULL, @supports_net_changes = 1;
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'ServiceType', @role_name = NULL, @supports_net_changes = 1;
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'CustomerOrder', @role_name = NULL, @supports_net_changes = 1;
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'Status', @role_name = NULL, @supports_net_changes = 1;
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'OrderDetail', @role_name = NULL, @supports_net_changes = 1;
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
    last_names VARCHAR(100)
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

CREATE TABLE cdc_states (
    name VARCHAR(256) NOT NULL,
    state VARCHAR(256) NOT NULL
);
GO


-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


/* Staging Tables */
USE library_data_warehouse;
GO

CREATE SCHEMA staging;
GO

CREATE TABLE staging.stg_Client (
    client_id INT,
    first_name VARCHAR(50),
    last_name1 VARCHAR(50),
    last_name2 VARCHAR(50)
);

CREATE TABLE staging.stg_Item (
    item_id INT,
    name VARCHAR(150),
    item_type VARCHAR(20),
    base_price DECIMAL(10,2)
);

CREATE TABLE staging.stg_Book (
    isbn VARCHAR(20),
    item_id INT,
    publisher_id INT
);

CREATE TABLE staging.stg_Publisher (
    publisher_id INT,
    publisher_name VARCHAR(100)
);

CREATE TABLE staging.stg_Genre (
    genre_id INT,
    genre_name VARCHAR(100)
);

CREATE TABLE staging.stg_Book_Genre (
    isbn VARCHAR(20),
    genre_id INT
);

CREATE TABLE staging.stg_Service (
    item_id INT,
    modality VARCHAR(100),
    type_id INT
);

CREATE TABLE staging.stg_ServiceType (
    type_id INT,
    type_name VARCHAR(50)
);

CREATE TABLE staging.stg_CustomerOrder (
    order_id INT,
    order_date DATE,
    client_id INT,
    status_id INT
);

CREATE TABLE staging.stg_Status (
    status_id INT,
    status_name VARCHAR(50)
);

CREATE TABLE staging.stg_OrderDetail (
    order_detail_id INT,
    order_id INT,
    item_id INT,
    quantity INT,
    unit_price DECIMAL(10,2),
    unit_cost DECIMAL(10,2)
);


-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


/* Library Insert Data */
USE library_transactional;
GO

/* Catalog Tables */
INSERT INTO Client (first_name, last_name1, last_name2, phone_number, email) VALUES
('Juan', 'Pérez', 'Rojas', '8888-1111', 'juan@email.com'),
('María', 'Gómez', 'Salas', '8888-2222', 'maria@email.com'),
('Carlos', 'López', 'Mora', '8888-3333', 'carlos@email.com'),
('Ana', 'Rodríguez', 'Castro', '8888-4444', 'ana@email.com'),
('Luis', 'Fernández', 'Vega', '8888-5555', 'luis@email.com'),
('Marta', 'Martínez', 'Soto', '8888-6666', 'marta@email.com'),
('José', 'Sánchez', 'Ruiz', '8888-7777', 'jose@email.com'),
('Elena', 'Romero', 'Díaz', '8888-8888', 'elena@email.com'),
('David', 'Suárez', 'Cruz', '8888-9999', 'david@email.com'),
('Lucía', 'Díaz', 'Arias', '8888-1010', 'lucia@email.com'),
('Jorge', 'Morales', 'Pena', '8888-1212', 'jorge@email.com'),
('Laura', 'Ortiz', 'Rios', '8888-1313', 'laura@email.com'),
('Diego', 'Gutiérrez', 'Lara', '8888-1414', 'diego@email.com'),
('Carmen', 'Navarro', 'Sola', '8888-1515', 'carmen@email.com'),
('Pedro', 'Torres', 'Moya', '8888-1616', 'pedro@email.com'),
('Sofía', 'Domínguez', 'Rayo', '8888-1717', 'sofia@email.com'),
('Andrés', 'Ramos', 'Gila', '8888-1818', 'andres@email.com'),
('Paula', 'Gil', 'Mesa', '8888-1919', 'paula@email.com'),
('Miguel', 'Blanco', 'Cobo', '8888-2020', 'miguel@email.com'),
('Rosa', 'Molina', 'Pino', '8888-2121', 'rosa@email.com');

INSERT INTO Status (status_name) VALUES
('Pendiente'), ('En Proceso'), ('Completada'), ('Cancelada'), ('Devuelta');

INSERT INTO Genre (genre_name) VALUES
('Ficción'), ('No Ficción'), ('Fantasía'), ('Ciencia Ficción'), ('Misterio'),
('Biografía'), ('Historia'), ('Poesía'), ('Autoayuda'), ('Negocios'),
('Terror'), ('Romance'), ('Aventura'), ('Ensayo'), ('Arte'),
('Cocina'), ('Viajes'), ('Religión'), ('Humor'), ('Deportes');

INSERT INTO Publisher (publisher_name) VALUES
('Penguin Random House'), ('Planeta'), ('Alfaguara'), ('Anagrama'), ('Tusquets'),
('Seix Barral'), ('Norma'), ('Santillana'), ('McGraw-Hill'), ('Pearson'),
('Oxford'), ('Cambridge'), ('SM'), ('Akal'), ('Alianza'),
('Cátedra'), ('Ariel'), ('Crítica'), ('Destino'), ('Espasa');

INSERT INTO ServiceType (type_name) VALUES
('Impresión B/N'), ('Impresión Color'), ('Fotocopia'), ('Empaste'), ('Anillado'),
('Plastificado'), ('Escaneo'), ('Diseño Gráfico'), ('Redacción'), ('Corrección'),
('Traducción'), ('Tutoría'), ('Asesoría Tesis'), ('Impresión 3D'), ('Corte Láser'),
('Encuadernación'), ('Mantenimiento PC'), ('Instalación Soft'), ('Formateo'), ('Búsqueda Web');

INSERT INTO Author (first_name, last_name1, last_name2) VALUES
('Gabriel', 'García', 'Márquez'), ('Isabel', 'Allende', 'Llona'), ('Mario', 'Vargas', 'Llosa'),
('Julio', 'Cortázar', 'Descotte'), ('Jorge', 'Borges', 'Acevedo'), ('Pablo', 'Neruda', 'Reyes'),
('Octavio', 'Paz', 'Lozano'), ('Carlos', 'Fuentes', 'Macías'), ('Laura', 'Esquivel', 'Valdés'),
('Juan', 'Rulfo', 'Pérez'), ('Miguel', 'Cervantes', 'Saavedra'), ('William', 'Shakespeare', ''),
('Joanne', 'Rowling', ''), ('Stephen', 'King', ''), ('George', 'Martin', ''),
('John', 'Tolkien', ''), ('Agatha', 'Christie', ''), ('Isaac', 'Asimov', ''),
('Arthur', 'Doyle', ''), ('Edgar', 'Poe', '');

INSERT INTO Item (name, base_price, item_type, cost) VALUES
('Cien años de soledad', 15000, 'Book', 8000), ('La casa de los espíritus', 12000, 'Book', 6000),
('La ciudad y los perros', 11000, 'Book', 5500), ('Rayuela', 14000, 'Book', 7000),
('Ficciones', 10000, 'Book', 5000), ('Veinte poemas de amor', 8000, 'Book', 4000),
('El laberinto de la soledad', 9500, 'Book', 4500), ('Aura', 8500, 'Book', 4000),
('Como agua para chocolate', 11000, 'Book', 5500), ('Pedro Páramo', 9000, 'Book', 4500),
('Don Quijote', 18000, 'Book', 9000), ('Hamlet', 7000, 'Book', 3500),
('Harry Potter 1', 16000, 'Book', 8000), ('El Resplandor', 15000, 'Book', 7500),
('Juego de Tronos', 17000, 'Book', 8500), ('El Señor de los Anillos', 20000, 'Book', 10000),
('Diez negritos', 11000, 'Book', 5500), ('Fundación', 14000, 'Book', 7000),
('Sherlock Holmes', 13000, 'Book', 6500), ('El Cuervo', 6000, 'Book', 3000);

INSERT INTO Item (name, base_price, item_type, cost) VALUES
('Cuaderno 100 hojas', 1500, 'Supply', 800), ('Lapicero Azul', 300, 'Supply', 100),
('Lápiz HB', 200, 'Supply', 80), ('Borrador', 250, 'Supply', 100),
('Goma en barra', 600, 'Supply', 300), ('Regla 30cm', 400, 'Supply', 150),
('Tijeras', 1200, 'Supply', 600), ('Grapadora', 3500, 'Supply', 1800),
('Grapas (Caja)', 800, 'Supply', 400), ('Calculadora', 8500, 'Supply', 4000),
('Marcador Pizarra', 800, 'Supply', 350), ('Cartulina', 200, 'Supply', 100),
('Resma de Papel Carta', 4500, 'Supply', 2500), ('Sobres Manila', 100, 'Supply', 40),
('Tinta Impresora Negra', 12000, 'Supply', 8000), ('USB 32GB', 5000, 'Supply', 2500),
('Corrector Líquido', 900, 'Supply', 450), ('Post-it', 1100, 'Supply', 500),
('Clips (Caja)', 500, 'Supply', 200), ('Carpeta Plástica', 800, 'Supply', 400);

INSERT INTO Item (name, base_price, item_type, cost) VALUES
('Impresión B/N Carta', 25, 'Service', 5), ('Impresión Color Carta', 150, 'Service', 50),
('Fotocopia', 20, 'Service', 4), ('Empaste Espiral', 1500, 'Service', 500),
('Anillado Metálico', 2000, 'Service', 800), ('Plastificado Gafete', 500, 'Service', 150),
('Escaneo Documento', 100, 'Service', 10), ('Diseño Tarjeta', 5000, 'Service', 1000),
('Redacción Carta', 3000, 'Service', 500), ('Revisión APA', 8000, 'Service', 2000),
('Traducción Inglés', 5000, 'Service', 1500), ('Tutoría Mate (1h)', 10000, 'Service', 3000),
('Asesoría General', 15000, 'Service', 4000), ('Impresión 3D (x gramo)', 100, 'Service', 30),
('Corte Láser MDF', 3000, 'Service', 1000), ('Encuadernación Cuero', 12000, 'Service', 5000),
('Limpieza Virus PC', 15000, 'Service', 2000), ('Instalar Office', 10000, 'Service', 1500),
('Formateo Completo', 25000, 'Service', 5000), ('Búsqueda Certificaciones', 2000, 'Service', 200);

INSERT INTO Book (isbn, item_id, publisher_id) VALUES
('978-001', 1, 1), ('978-002', 2, 2), ('978-003', 3, 3), ('978-004', 4, 4), ('978-005', 5, 5),
('978-006', 6, 6), ('978-007', 7, 7), ('978-008', 8, 8), ('978-009', 9, 9), ('978-010', 10, 10),
('978-011', 11, 11), ('978-012', 12, 12), ('978-013', 13, 13), ('978-014', 14, 14), ('978-015', 15, 15),
('978-016', 16, 16), ('978-017', 17, 17), ('978-018', 18, 18), ('978-019', 19, 19), ('978-020', 20, 20);

INSERT INTO Supply (item_id, stock) VALUES
(21, 100), (22, 500), (23, 200), (24, 150), (25, 80), (26, 60), (27, 40), (28, 15), (29, 30), (30, 20),
(31, 100), (32, 300), (33, 50), (34, 1000), (35, 10), (36, 25), (37, 50), (38, 120), (39, 40), (40, 200);

INSERT INTO Service (item_id, modality, type_id) VALUES
(41, 'Local', 1), (42, 'Local', 2), (43, 'Local', 3), (44, 'Encargo', 4), (45, 'Local', 5),
(46, 'Local', 6), (47, 'Local', 7), (48, 'Encargo', 8), (49, 'Encargo', 9), (50, 'Encargo', 10),
(51, 'Encargo', 11), (52, 'Local', 12), (53, 'Encargo', 13), (54, 'Encargo', 14), (55, 'Encargo', 15),
(56, 'Encargo', 16), (57, 'Local', 17), (58, 'Local', 18), (59, 'Local', 19), (60, 'Local', 20);

INSERT INTO Book_Genre (isbn, genre_id) VALUES
('978-001', 1), ('978-002', 1), ('978-003', 1), ('978-004', 1), ('978-005', 1), ('978-006', 8),
('978-007', 14), ('978-008', 3), ('978-009', 12), ('978-010', 1), ('978-011', 1), ('978-012', 1),
('978-013', 3), ('978-014', 11), ('978-015', 3), ('978-016', 3), ('978-017', 5), ('978-018', 4),
('978-019', 5), ('978-020', 8);

INSERT INTO Book_Author (isbn, author_id, contribution_degree) VALUES
('978-001', 1, 'Principal'), ('978-002', 2, 'Principal'), ('978-003', 3, 'Principal'),
('978-004', 4, 'Principal'), ('978-005', 5, 'Principal'), ('978-006', 6, 'Principal'),
('978-007', 7, 'Principal'), ('978-008', 8, 'Principal'), ('978-009', 9, 'Principal'),
('978-010', 10, 'Principal'), ('978-011', 11, 'Principal'), ('978-012', 12, 'Principal'),
('978-013', 13, 'Principal'), ('978-014', 14, 'Principal'), ('978-015', 15, 'Principal'),
('978-016', 16, 'Principal'), ('978-017', 17, 'Principal'), ('978-018', 18, 'Principal'),
('978-019', 19, 'Principal'), ('978-020', 20, 'Principal');
GO

/* Transaction Tables */
CREATE PROCEDURE sp_InsertCustomerOrders
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @i INT = 1;
    DECLARE @count_client INT;
    DECLARE @count_status INT;

    SELECT @count_client = COUNT(*) FROM Client;
    SELECT @count_status = COUNT(*) FROM Status;

    WHILE @i <= 500
    BEGIN
        INSERT INTO CustomerOrder (order_date, client_id, status_id, total_amount)
        VALUES (
            DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 1570, '2022-01-01'),
            (ABS(CHECKSUM(NEWID())) % @count_client)+1,
            (ABS(CHECKSUM(NEWID())) % @count_status)+1,
            0
        );
        SET @i = @i+1;
    END
END;
GO

CREATE PROCEDURE sp_InsertOrderDetails
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @count_item INT;
    DECLARE @min_order INT;
    DECLARE @max_order INT;
    DECLARE @order_range INT;
    DECLARE @item_id INT;
    DECLARE @quantity INT;
    DECLARE @unit_price DECIMAL(10,2);
    DECLARE @unit_cost DECIMAL(10,2);
    DECLARE @NumLines INT;
    DECLARE @i INT;
    
    SELECT @min_order = MIN(order_id), @max_order = MAX(order_id) FROM CustomerOrder;
    SELECT @count_item = COUNT(*) FROM Item;
    
    WHILE @min_order <= @max_order
    BEGIN
        SET @NumLines = (ABS(CHECKSUM(NEWID())) % 2)+1;
        SET @i = 1;

        WHILE @i <= @NumLines
        BEGIN
            SET @item_id = (ABS(CHECKSUM(NEWID())) % @count_item)+1;
            SET @quantity = (ABS(CHECKSUM(NEWID())) % 10)+1;
            SELECT @unit_price = base_price, @unit_cost = cost
            FROM Item WHERE item_id = @item_id;
            INSERT INTO OrderDetail (order_id, item_id, quantity, unit_price, unit_cost)
            VALUES (@min_order, @item_id, @quantity, @unit_price, @unit_cost);
            SET @i = @i+1;
        END
        
        UPDATE CustomerOrder
        SET total_amount = (
            SELECT SUM(quantity * unit_price) FROM OrderDetail
            WHERE order_id = @min_order
        )
        WHERE order_id = @min_order;

        SET @min_order = @min_order+1;
    END
END;
GO

/* Execute Procedures */
EXEC sp_InsertCustomerOrders;
GO
EXEC sp_InsertOrderDetails;
GO