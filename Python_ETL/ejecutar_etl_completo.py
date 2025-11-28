import pyodbc

conn = pyodbc.connect(
    'DRIVER={ODBC Driver 17 for SQL Server};'
    r'SERVER=LAPTOP-ROGPHCC8\SQLEX2023;'   
    'DATABASE=DW_DataShop2;'               
    'Trusted_Connection=yes;'  
)

try:
    print("--- EJECUTANDO STORED PROCEDURE ---")
    cursor = conn.cursor()
    
    # Ejecutamos el procedimiento almacenado
    cursor.execute("EXEC sp_Ejecutar_ETL_Completo")
    
    conn.commit()
    print("ETL COMPLETO - DATA WAREHOUSE 100% CARGADO")

except Exception as e:
    print("ERROR AL EJECUTAR EL SP:")
    print(e)
    print("\nNOTA: Si dice que 'sp_Ejecutar_ETL_Completo' no se encuentra,")
    print("      es porque debes crear ese procedimiento en SQL Server primero.")