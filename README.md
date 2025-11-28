# DataShop Retail Data Warehouse & ETL Pipeline

## 🎯 Objetivo del Proyecto
Este proyecto académico implementa una **solución integral de Business Intelligence (BI)** para la empresa ficticia DataShop (venta de electrodomésticos). El objetivo principal es modelar, transformar y almacenar datos de ventas para análisis avanzados en Power BI.

## 🏗️ Arquitectura y Modelado (Esquema Estrella)

La solución utiliza una arquitectura de Data Warehouse (DW) con un **Esquema Estrella** implementado en SQL Server.

### Flujo ETL
El proceso de carga de datos sigue un flujo orquestado por Python:
1.  **Extracción/Carga (EL):** Scripts de Python (`pandas`) leen archivos `.csv` de origen y cargan los datos en tablas de **Staging** (`stg`).
2.  **Transformación y Carga (T/L):** Un script de orquestación en Python llama al Stored Procedure principal, que aplica la lógica de negocio (`MERGE`, generación de claves sustitutas) y mueve los datos a las tablas finales del DW (`dw`).

### Modelo de Datos (DW Final)
| Tipo | Tabla | Clave Natural (Ejemplo) | Clave Sustituta (PK) |
| :--- | :--- | :--- | :--- |
| **Hechos** | `Fact_Ventas` | FechaClave, CodCliente... | PK compuesta |
| **Dimensión** | `Dim_Cliente` | CodCliente | SurrogateKey_Cliente |
| **Dimensión** | `Dim_Producto` | CodigoProducto | SurrogateKey_Producto |
| **Dimensión** | `Dim_Tienda` | CodigoTienda | SurrogateKey_Tienda |
| **Dimensión** | `Dim_Tiempo` | Fecha | Tiempo_Key |

## 🛠️ Tecnologías
* **Base de Datos:** SQL Server (Gestión de DW, Tablas, Stored Procedures).
* **Lenguaje:** Python 3.x
* **Librerías Python:** `pandas`, `sqlalchemy`, `pyodbc`.
* **Visualización:** Power BI (Tablero Analítico con DAX y Formato Condicional).

## 🚀 Cómo Ejecutar el Proyecto (Instrucciones de Setup)

### 1. Configuración de SQL Server
1.  Asegúrese de tener el servidor activo (ej: `.\SQLEXPRESS`).
2.  Ejecute el script **`script_creacion_dw.sql`** en SSMS. Este script crea la base de datos (DW), las tablas Stage y DW, la lógica de `Dim_Tiempo`, y todos los Stored Procedures.

### 2. Ejecución del ETL (Python)
Abra la terminal en la carpeta que contiene los scripts y archivos `.csv` de origen.

1.  **Instalar dependencias:** `pip install pandas sqlalchemy pyodbc`
2.  **Carga a Staging:** Ejecute el script que carga los CSVs a SQL Stage.
    ```bash
    python cargar_csv_a_stage.py
    ```
3.  **Transformar y Cargar (Final):** Ejecute el script orquestador para llenar las Dimensiones y la Tabla de Hechos.
    ```bash
    python ejecutar_etl_completo.py
    ```

## 📊 Resultado Final: Dashboard Power BI
El tablero generado incluye 4 páginas de análisis para la toma de decisiones, destacando:
* **Análisis Comparativo Avanzado:** Matriz con cálculo de `% de Variación sobre el mes anterior` y formato condicional (semáforo).
* **Cumplimiento:** Todas las métricas y visualizaciones requeridas en el temario (KPIs, Gráficos de Tiempo, Top Clientes).
