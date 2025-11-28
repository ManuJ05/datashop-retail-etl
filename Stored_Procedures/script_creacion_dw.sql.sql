USE DW_DataShop2;
GO

/* ==========================================================================
   SECCION 1: CREACION DE ESQUEMAS Y TABLAS (ESTRUCTURA)
   ========================================================================== */

-- 1. Crear esquema 'dw' 
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dw')
BEGIN
    EXEC('CREATE SCHEMA dw')
END
GO

-- 2. Tabla Dimensión TIEMPO 
IF OBJECT_ID('dw.Dim_Tiempo', 'U') IS NULL
CREATE TABLE dw.Dim_Tiempo (
    Tiempo_Key INT PRIMARY KEY,  
    Fecha DATE,
    Anio INT,
    Mes INT,
    Mes_Nombre VARCHAR(20),
    Semestre INT,
    Trimestre INT,
    Semana_Anio INT,
    Dia INT,
    Dia_Nombre VARCHAR(20)
);

-- 3. Tabla Dimensión CLIENTE
IF OBJECT_ID('dw.Dim_Cliente', 'U') IS NULL
CREATE TABLE dw.Dim_Cliente (
    SurrogateKey_Cliente INT IDENTITY(1,1) PRIMARY KEY,
    CodCliente INT,
    RazonSocial VARCHAR(255),
    Telefono VARCHAR(50),
    Mail VARCHAR(100),
    Direccion VARCHAR(255),
    Localidad VARCHAR(100),
    Provincia VARCHAR(100),
    CP VARCHAR(20)
);

-- 4. Tabla Dimensión PRODUCTO
IF OBJECT_ID('dw.Dim_Producto', 'U') IS NULL
CREATE TABLE dw.Dim_Producto (
    SurrogateKey_Producto INT IDENTITY(1,1) PRIMARY KEY,
    CodigoProducto VARCHAR(50),
    Descripcion VARCHAR(255),
    Categoria VARCHAR(100),
    Marca VARCHAR(100),
    PrecioCosto DECIMAL(18,2),
    PrecioVentaSugerido DECIMAL(18,2)
);

-- 5. Tabla Dimensión TIENDA
IF OBJECT_ID('dw.Dim_Tienda', 'U') IS NULL
CREATE TABLE dw.Dim_Tienda (
    SurrogateKey_Tienda INT IDENTITY(1,1) PRIMARY KEY,
    CodigoTienda INT,
    Descripcion VARCHAR(255),
    Direccion VARCHAR(255),
    Localidad VARCHAR(100),
    Provincia VARCHAR(100),
    CP VARCHAR(20),
    TipoTienda VARCHAR(50)
);

-- 6. Tabla de Hechos VENTAS
IF OBJECT_ID('dw.Fact_Ventas', 'U') IS NULL
CREATE TABLE dw.Fact_Ventas (
    IdVenta INT IDENTITY(1,1) PRIMARY KEY,
    FechaClave INT,               -- Se une con Dim_Tiempo.Tiempo_Key
    SurrogateKey_Tienda INT,      -- Se une con Dim_Tienda
    SurrogateKey_Producto INT,    -- Se une con Dim_Producto
    SurrogateKey_Cliente INT,     -- Se une con Dim_Cliente
    Cantidad INT,
    PrecioVenta DECIMAL(18,2)

    ImporteTotal AS (Cantidad * PrecioVenta) PERSISTED
);
GO

/* ==========================================================================
   SECCION 2: PROCEDIMIENTOS ALMACENADOS (LOGICA ETL)
   ========================================================================== */

-- SP 1: Cargar Dimensión Tiempo (Genera el calendario automáticamente)
CREATE OR ALTER PROCEDURE sp_Cargar_Dim_Tiempo
    @anio_inicio INT,
    @anio_fin INT
AS
BEGIN
    SET NOCOUNT ON;
    -- Generamos fechas desde el 1 de enero del año inicio
    DECLARE @fecha DATE = DATEFROMPARTS(@anio_inicio, 1, 1);
    DECLARE @fecha_fin DATE = DATEFROMPARTS(@anio_fin, 12, 31);

    WHILE @fecha <= @fecha_fin
    BEGIN
        DECLARE @Tiempo_Key INT = CAST(FORMAT(@fecha, 'yyyyMMdd') AS INT);

        -- Solo insertamos si no existe ese día
        IF NOT EXISTS (SELECT 1 FROM dw.Dim_Tiempo WHERE Tiempo_Key = @Tiempo_Key)
        BEGIN
            INSERT INTO dw.Dim_Tiempo (Tiempo_Key, Fecha, Anio, Mes, Mes_Nombre, Semestre, Trimestre, Semana_Anio, Dia, Dia_Nombre)
            VALUES (
                @Tiempo_Key,
                @fecha,
                YEAR(@fecha),
                MONTH(@fecha),
                DATENAME(MONTH, @fecha),
                CASE WHEN MONTH(@fecha) <= 6 THEN 1 ELSE 2 END,
                DATEPART(QUARTER, @fecha),
                DATEPART(WEEK, @fecha),
                DAY(@fecha),
                DATENAME(WEEKDAY, @fecha)
            );
        END
        SET @fecha = DATEADD(DAY, 1, @fecha); -- Avanzar un día
    END
END
GO

-- SP 2: Cargar Dimensiones (Cliente, Producto, Tienda) desde Stage
CREATE OR ALTER PROCEDURE sp_Cargar_Dimensiones AS
BEGIN
    SET NOCOUNT ON;
    
    -- Carga Clientes (Upsert: Actualiza si existe, Inserta si es nuevo)
    MERGE dw.Dim_Cliente AS t
    USING stg.Clientes AS s ON t.CodCliente = s.CodCliente
    WHEN NOT MATCHED THEN INSERT (CodCliente,RazonSocial,Telefono,Mail,Direccion,Localidad,Provincia,CP)
                          VALUES (s.CodCliente,s.RazonSocial,s.Telefono,s.Mail,s.Direccion,s.Localidad,s.Provincia,s.CP);

    -- Carga Productos
    MERGE dw.Dim_Producto AS t
    USING stg.Productos AS s ON t.CodigoProducto = s.CodigoProducto
    WHEN NOT MATCHED THEN INSERT (CodigoProducto,Descripcion,Categoria,Marca,PrecioCosto,PrecioVentaSugerido)
                          VALUES (s.CodigoProducto,s.Descripcion,s.Categoria,s.Marca,s.PrecioCosto,s.PrecioVentaSugerido);

    -- Carga Tiendas
    MERGE dw.Dim_Tienda AS t
    USING stg.Tiendas AS s ON t.CodigoTienda = s.CodigoTienda
    WHEN NOT MATCHED THEN INSERT (CodigoTienda,Descripcion,Direccion,Localidad,Provincia,CP,TipoTienda)
                          VALUES (s.CodigoTienda,s.Descripcion,s.Direccion,s.Localidad,s.Provincia,s.CP,s.TipoTienda);
END
GO

-- SP 3: Cargar Fact Ventas (Cruza las IDs con las dimensiones)
CREATE OR ALTER PROCEDURE sp_Cargar_Fact_Ventas AS
BEGIN
    SET NOCOUNT ON;
    
    -- Limpieza total de la tabla de hechos antes de recargar (Carga Full)
    TRUNCATE TABLE dw.Fact_Ventas;

    INSERT INTO dw.Fact_Ventas (FechaClave, SurrogateKey_Tienda, SurrogateKey_Producto, SurrogateKey_Cliente, Cantidad, PrecioVenta)
    SELECT 
        -- Convertimos la fecha de venta al formato YYYYMMDD para unir con Dim_Tiempo
        CONVERT(INT, FORMAT(TRY_CAST(v.FechaVenta AS DATE), 'yyyyMMdd')),
        
        -- Obtenemos las claves foráneas (Surrogate Keys) de las dimensiones ya cargadas
        t.SurrogateKey_Tienda,
        p.SurrogateKey_Producto,
        c.SurrogateKey_Cliente,
        
        v.Cantidad,
        v.PrecioVenta
    FROM stg.Ventas v
    JOIN dw.Dim_Tienda   t ON t.CodigoTienda   = v.CodigoTienda
    JOIN dw.Dim_Producto p ON p.CodigoProducto = v.CodigoProducto
    JOIN dw.Dim_Cliente  c ON c.CodCliente     = v.CodigoCliente;
END
GO

 
CREATE OR ALTER PROCEDURE sp_Ejecutar_ETL_Completo AS
BEGIN
    PRINT '--- INICIO DEL PROCESO ETL ---';
    
    -- 1. Cargar Dimensión Tiempo (Años 2023 a 2025 para cubrir historia y futuro cercano)
    PRINT '> Generando Dim_Tiempo...';
    EXEC sp_Cargar_Dim_Tiempo 2023, 2025;

    -- 2. Cargar Dimensiones de Negocio
    PRINT '> Cargando Clientes, Productos y Tiendas...';
    EXEC sp_Cargar_Dimensiones;
    
    -- 3. Cargar Hechos (Ventas)
    PRINT '> Cargando Tabla de Hechos Ventas...';
    EXEC sp_Cargar_Fact_Ventas;
    
    PRINT '--- FIN DEL PROCESO ETL EXITOSO ---';
END
GO