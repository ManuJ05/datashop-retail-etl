import pandas as pd
import sqlalchemy
import urllib
import os

# --- RUTAS ---
# Ruta de tu carpeta de datos
RUTA_CSVS = r"C:\DataShop_Entrega_Final_Jesús Manuel sack\Datos_Origen"

# --- CONFIGURACIÓN SQL ---
NOMBRE_DB = 'DW_DataShop2'
SERVIDOR  = 'LAPTOP-ROGPHCC8\SQLEX2023'  
print(f"--- CONECTANDO A: {SERVIDOR} ---")

# Configuración de conexión
params = urllib.parse.quote_plus(
    'DRIVER={ODBC Driver 17 for SQL Server};'
    f'SERVER={SERVIDOR};'       
    f'DATABASE={NOMBRE_DB};'
    'Trusted_Connection=yes;'   
)
engine = sqlalchemy.create_engine(f"mssql+pyodbc:///?odbc_connect={params}")

print("--- INICIANDO CARGA ---")

archivos = [
    ('clientes.csv', 'Clientes'),
    ('productos.csv', 'Productos'),
    ('tiendas.csv', 'Tiendas'),
    ('ventas_total.csv', 'Ventas')
]

for nombre_csv, tabla_sql in archivos:
    ruta_completa = os.path.join(RUTA_CSVS, nombre_csv)
    try:
        if not os.path.exists(ruta_completa):
            print(f"[X] NO ENCONTRADO: {ruta_completa}")
            continue

        print(f"Cargando {nombre_csv}...", end=" ")
        df = pd.read_csv(ruta_completa)
        
        # Insertar en SQL (Esquema 'stg')
        df.to_sql(tabla_sql, engine, schema='stg', if_exists='replace', index=False)
        print("OK - ¡Cargado!")
        
    except Exception as e:
        print(f"\n[X] ERROR EN {nombre_csv}:")
        print(e)

print("--- PROCESO TERMINADO ---")