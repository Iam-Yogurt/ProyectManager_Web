import sys
import traceback

try:
    from conexion import obtener_conexion
    conn = obtener_conexion()
    cur = conn.cursor()
    cur.execute('SELECT version();')
    version = cur.fetchone()
    print("Conexión exitosa:", version[0])
    cur.close()
    conn.close()
except Exception as e:
    print("Error de conexión:")
    traceback.print_exc()
