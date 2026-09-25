from flask import Flask, render_template, request, redirect, url_for
from conexion import obtener_conexion

app = Flask(__name__)

@app.route('/')
def index():
    conn = obtener_conexion()
    cursor = conn.cursor()
    
    # Traemos todos los registros de la tabla 'proyecto' de tu base de datos
    cursor.execute("SELECT * FROM proyecto;")
    proyectos = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('index.html', proyectos=proyectos)

if __name__ == '__main__':
    app.run(debug=True, port=5000)