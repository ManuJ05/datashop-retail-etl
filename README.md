# DataShop Retail Data Warehouse & ETL Pipeline

![Data Warehouse Star Schema Diagram]

## 🎯 Objetivo del Proyecto
[cite_start]Este proyecto desarrolla una **solución integral de Business Intelligence (BI)** para la empresa ficticia DataShop[cite: 13]. [cite_start]El objetivo principal es modelar, transformar y almacenar datos de ventas para permitir análisis informados y la toma de decisiones[cite: 7].

---

## 🏗️ Arquitectura y Modelado (Esquema Estrella)

La solución implementa una arquitectura de Data Warehouse (DW) con un **Esquema Estrella** en SQL Server.

### Componentes Clave
| Tipo | Tabla | Claves Únicas | Atributos Clave |
| :--- | :--- | :--- | :--- |
| **Hechos** | `dw.Fact_Ventas` | FechaClave, SurrogateKeys | Cantidad, PrecioVenta, **ImporteTotal (Calculado)** |
| **Dimensión** | `dw.Dim_Cliente` | SurrogateKey_Cliente, CodCliente | RazonSocial, Mail, Dirección |
| **Dimensión** | `dw.Dim_Producto` | SurrogateKey_Producto, CodigoProducto | Descripción, Categoría, Marca |
| **Dimensión** | `dw.Dim_Tienda` | SurrogateKey_Tienda, CodigoTienda | Localidad, Provincia, TipoTienda |
| **Dimensión** | `dw.Dim_Tiempo` | Tiempo_Key (YYYYMMDD) | Año, Mes, Trimestre |

### Flujo ETL
El proceso de carga se divide en dos fases orquestadas por Python:

1.  **Extracción/Carga (EL):** Scripts de Python leen archivos `.csv` (origen) y cargan los datos crudos en tablas de **Staging** (`stg`).
2.  **Transformación y Carga Final (T/L):** Un procedimiento almacenado de SQL aplica la lógica de negocio (`MERGE`), genera las claves subrogadas (`Surrogate Keys`), y mueve los datos limpios a las tablas finales del DW (`dw`).

## 🛠️ Tecnologías
* **Base de Datos:** SQL Server (Gestión de DW y Stored Procedures).
* **Lenguaje:** Python 3.x
* **Librerías Python:** `pandas` (Extracción de CSVs), `sqlalchemy` y `pyodbc` (Conexión a SQL).
* **Visualización:** Power BI (Reportes analíticos avanzados).

---

## 🚀 Cómo Ejecutar el Proyecto (Configuración)

### Requisitos
1.  Instancia de SQL Server (ej: `.\SQLEXPRESS`).
2.  Driver ODBC 17 for SQL Server instalado.
3.  Python y dependencias (`pip install pandas sqlalchemy pyodbc`).

### Pasos de Ejecución
1.  **Configurar la Base de Datos:** Ejecute el script **`script_creacion_dw.sql`** en SQL Server Management Studio (SSMS). Este script crea las tablas, los esquemas y los procedimientos almacenados (incluyendo la lógica de `Dim_Tiempo`).
2.  **Carga de Datos Inicial (Stage):** Ejecute el script de extracción.
    ```bash
    python cargar_csv_a_stage.py
    ```
3.  **Ejecución del ETL Completo (T/L):** Ejecute el script orquestador para llenar las Dimensiones y Hechos, y ejecutar las transformaciones.
    ```bash
    python ejecutar_etl_completo.py
    ```

## 📊 Resultado Final: Dashboard Power BI

[cite_start]El tablero final contiene un análisis completo de las ventas, cumpliendo con los siguientes requisitos[cite: 91, 92, 94]:

* [cite_start]**KPIs:** Importe Total de Ventas [cite: 93][cite_start], Cantidad de Ventas realizadas[cite: 94], Precio Promedio.
* [cite_start]**Análisis Temporal:** Gráfico de Barras que muestra las Ventas por Año y por Mes[cite: 96, 97].
* [cite_start]**Análisis Comparativo (Avanzado):** Matriz que utiliza medidas DAX y formato condicional (semáforo) para mostrar el % de Variación de Ventas mes a mes[cite: 137, 140].
