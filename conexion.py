import psycopg2

def obtener_conexion():
    return psycopg2.connect(
        host="localhost",
        database="proyectmanager-db",
        user="postgres",
        password="angel",  # La clave de tu usuario postgres en pgAdmin
        port="5432"
    )