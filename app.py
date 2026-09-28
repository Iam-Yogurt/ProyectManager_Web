import os
from decimal import Decimal
from flask import Flask, render_template, request, redirect, url_for, flash, jsonify, session, g
from conexion import obtener_conexion
from dotenv import load_dotenv
import psycopg2.extras
from functools import wraps

load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv("SECRET_KEY", "projectflow_erp_secret_key_2026")

# ─────────────────────────────────────────────
#  HELPERS & MIDDLEWARE
# ─────────────────────────────────────────────

def _get_clientes(cur):
    cur.execute("SELECT id_cliente, nombre_empresa, persona_contacto FROM cliente ORDER BY nombre_empresa")
    return cur.fetchall()

def _get_lideres(cur):
    cur.execute("SELECT id_usuario, nombre, rol FROM usuario WHERE activo = true ORDER BY nombre")
    return cur.fetchall()

def _get_proyectos_select(cur):
    cur.execute("SELECT id_proyecto, nombre_proyecto FROM proyecto ORDER BY nombre_proyecto")
    return cur.fetchall()

def _get_usuarios_select(cur):
    cur.execute("SELECT id_usuario, nombre, rol, id_equipo FROM usuario WHERE activo = true ORDER BY nombre")
    return cur.fetchall()

def _get_hitos_select(cur, id_proyecto=None):
    if id_proyecto:
        cur.execute("SELECT id_hito, nombre_hito FROM hito WHERE id_proyecto = %s ORDER BY fecha_objetivo", (id_proyecto,))
    else:
        cur.execute("SELECT id_hito, id_proyecto, nombre_hito FROM hito ORDER BY fecha_objetivo")
    return cur.fetchall()

def _get_equipos_select(cur):
    cur.execute("SELECT id_equipo, nombre_equipo FROM equipo ORDER BY nombre_equipo")
    return cur.fetchall()

@app.before_request
def load_logged_in_user():
    user_id = session.get('user_id')
    if user_id is None:
        g.user = None
    else:
        conn = obtener_conexion()
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute("SELECT * FROM usuario WHERE id_usuario = %s", (user_id,))
        g.user = cur.fetchone()
        cur.close()
        conn.close()

    # Protect routes globally except for auth and static
    if request.endpoint and request.endpoint not in ('login', 'static') and g.user is None:
        return redirect(url_for('login'))

def login_required(view):
    @wraps(view)
    def wrapped_view(**kwargs):
        if g.user is None:
            return redirect(url_for('login'))
        return view(**kwargs)
    return wrapped_view

@app.context_processor
def inject_user():
    return dict(current_user=g.user)

# ─────────────────────────────────────────────
#  AUTENTICACIÓN
# ─────────────────────────────────────────────

@app.route('/login', methods=('GET', 'POST'))
def login():
    if request.method == 'POST':
        usuario = request.form['usuario']
        contrasena = request.form['contrasena']
        conn = obtener_conexion()
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        error = None
        
        if not usuario:
            error = 'El usuario es requerido.'
        elif not contrasena:
            error = 'La contraseña es requerida.'
        else:
            cur.execute("SELECT * FROM usuario WHERE usuario = %s", (usuario,))
            user = cur.fetchone()
            
            if user is None:
                error = 'Usuario incorrecto.'
            elif user['contrasena'] != contrasena:
                error = 'Contraseña incorrecta.'
            elif not user['activo']:
                error = 'La cuenta está desactivada.'
                
        cur.close()
        conn.close()
        
        if error is None:
            session.clear()
            session['user_id'] = user['id_usuario']
            return redirect(url_for('index'))
            
        flash(error, 'danger')
        
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

# ─────────────────────────────────────────────
#  RUTA RAÍZ
# ─────────────────────────────────────────────

@app.route('/')
def index():
    return redirect(url_for('dashboard'))


# ═══════════════════════════════════════════════
#  A. DASHBOARD PRINCIPAL (Vista General)
# ═══════════════════════════════════════════════

@app.route('/dashboard')
def dashboard():
    conn = obtener_conexion()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    # 1. KPIs de Proyectos
    cur.execute("""
        SELECT
            COUNT(*) AS total_proyectos,
            COUNT(*) FILTER (WHERE estado IN ('planificacion', 'en_desarrollo', 'pruebas')) AS activos,
            COUNT(*) FILTER (WHERE estado = 'planificacion') AS planificacion,
            COUNT(*) FILTER (WHERE estado = 'en_desarrollo') AS en_desarrollo,
            COUNT(*) FILTER (WHERE estado = 'pruebas') AS pruebas,
            COUNT(*) FILTER (WHERE estado = 'finalizado') AS finalizados,
            COALESCE(SUM(presupuesto_total), 0) AS presupuesto_total_asignado
        FROM proyecto
    """)
    kpi_proyectos = cur.fetchone()

    # 2. Finanzas globales (Presupuesto Asignado vs Consumido)
    cur.execute("""
        SELECT
            COALESCE(SUM(t.tiempo_real_horas * u.costo_hora), 0) AS costo_total_consumido
        FROM tarea t
        JOIN usuario u ON u.id_usuario = t.id_usuario_asignado
    """)
    res_finanzas = cur.fetchone()
    costo_total_consumido = res_finanzas['costo_total_consumido'] if res_finanzas else Decimal(0)
    presupuesto_total = kpi_proyectos['presupuesto_total_asignado']
    pct_presupuesto = round((float(costo_total_consumido) / float(presupuesto_total) * 100), 1) if presupuesto_total > 0 else 0

    # 3. KPIs de Tareas (Vencidas y Bloqueadas)
    cur.execute("""
        SELECT
            COUNT(*) AS total_tareas,
            COUNT(*) FILTER (WHERE estado = 'bloqueada') AS bloqueadas,
            COUNT(*) FILTER (WHERE fecha_vencimiento < CURRENT_TIMESTAMP AND estado != 'completada') AS vencidas,
            COUNT(*) FILTER (WHERE estado = 'completada') AS completadas,
            COUNT(*) FILTER (WHERE estado = 'en_progreso') AS en_progreso
        FROM tarea
    """)
    kpi_tareas = cur.fetchone()

    # 4. Proyectos en Riesgo (Presupuesto excedido O >50% tareas vencidas)
    cur.execute("""
        SELECT
            p.id_proyecto,
            p.nombre_proyecto,
            p.presupuesto_total,
            p.estado,
            c.nombre_empresa AS nombre_cliente,
            u.nombre AS nombre_lider,
            public.fn_calcular_avance_proyecto(p.id_proyecto) AS avance,
            COALESCE(SUM(t.tiempo_real_horas * ut.costo_hora), 0) AS costo_consumido,
            COUNT(t.id_tarea) AS total_tareas_proy,
            COUNT(t.id_tarea) FILTER (WHERE t.fecha_vencimiento < CURRENT_TIMESTAMP AND t.estado != 'completada') AS tareas_vencidas,
            COUNT(t.id_tarea) FILTER (WHERE t.estado = 'bloqueada') AS tareas_bloqueadas
        FROM proyecto p
        JOIN cliente c ON c.id_cliente = p.id_cliente
        JOIN usuario u ON u.id_usuario = p.id_lider
        LEFT JOIN tarea t ON t.id_proyecto = p.id_proyecto
        LEFT JOIN usuario ut ON ut.id_usuario = t.id_usuario_asignado
        WHERE p.estado NOT IN ('finalizado', 'cancelado')
        GROUP BY p.id_proyecto, p.nombre_proyecto, p.presupuesto_total, p.estado, c.nombre_empresa, u.nombre
    """)
    todos_proyectos_analisis = cur.fetchall()

    proyectos_en_riesgo = []
    for p in todos_proyectos_analisis:
        costo_excedido = p['costo_consumido'] > p['presupuesto_total']
        pct_vencidas = (p['tareas_vencidas'] / p['total_tareas_proy'] * 100) if p['total_tareas_proy'] > 0 else 0
        tiene_bloqueadas = p['tareas_bloqueadas'] > 0

        motivos_riesgo = []
        if costo_excedido:
            motivos_riesgo.append(f"Presupuesto superado (${p['costo_consumido']:.2f} / ${p['presupuesto_total']:.2f})")
        if pct_vencidas >= 50 and p['total_tareas_proy'] > 0:
            motivos_riesgo.append(f"{p['tareas_vencidas']} de {p['total_tareas_proy']} tareas vencidas ({pct_vencidas:.0f}%)")
        elif tiene_bloqueadas:
            motivos_riesgo.append(f"{p['tareas_bloqueadas']} tarea(s) bloqueada(s)")

        if motivos_riesgo:
            p['motivos_riesgo'] = motivos_riesgo
            proyectos_en_riesgo.append(p)

    # 5. Gráfico de Carga de Trabajo de Usuarios (Horas estimadas pendientes por usuario)
    cur.execute("""
        SELECT
            u.id_usuario,
            u.nombre,
            u.rol,
            eq.nombre_equipo,
            COALESCE(SUM(CASE WHEN t.estado != 'completada' THEN t.tiempo_estimado_horas ELSE 0 END), 0) AS horas_pendientes,
            COUNT(t.id_tarea) FILTER (WHERE t.estado != 'completada') AS tareas_activas
        FROM usuario u
        LEFT JOIN equipo eq ON eq.id_equipo = u.id_equipo
        LEFT JOIN tarea t ON t.id_usuario_asignado = u.id_usuario
        WHERE u.activo = true
        GROUP BY u.id_usuario, u.nombre, u.rol, eq.nombre_equipo
        ORDER BY horas_pendientes DESC, u.nombre ASC
    """)
    carga_usuarios = cur.fetchall()
    max_horas = max([float(u['horas_pendientes']) for u in carga_usuarios] + [40.0])

    cur.close()
    conn.close()

    return render_template(
        'dashboard/index.html',
        active_tab='dashboard',
        kpi_proyectos=kpi_proyectos,
        costo_total_consumido=costo_total_consumido,
        pct_presupuesto=pct_presupuesto,
        kpi_tareas=kpi_tareas,
        proyectos_en_riesgo=proyectos_en_riesgo,
        carga_usuarios=carga_usuarios,
        max_horas=max_horas
    )


# ═══════════════════════════════════════════════
#  B. GESTIÓN DE PROYECTOS E HITOS
# ═══════════════════════════════════════════════

@app.route('/proyectos')
def listar_proyectos():
    view_mode = request.args.get('vista', 'grid')  # 'grid' or 'list'
    conn = obtener_conexion()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    cur.execute("""
        SELECT
            p.id_proyecto,
            p.nombre_proyecto,
            p.descripcion,
            p.fecha_inicio,
            p.fecha_fin_estimada,
            p.fecha_fin_real,
            p.presupuesto_total,
            p.estado,
            c.nombre_empresa AS nombre_cliente,
            u.nombre AS nombre_lider,
            u.rol AS rol_lider,
            public.fn_calcular_avance_proyecto(p.id_proyecto) AS avance,
            COUNT(t.id_tarea) AS total_tareas,
            COUNT(t.id_tarea) FILTER (WHERE t.estado = 'completada') AS tareas_completadas,
            COUNT(t.id_tarea) FILTER (WHERE t.estado = 'bloqueada') AS tareas_bloqueadas,
            COUNT(t.id_tarea) FILTER (WHERE t.fecha_vencimiento < CURRENT_TIMESTAMP AND t.estado != 'completada') AS tareas_vencidas,
            COALESCE(SUM(t.tiempo_real_horas * ut.costo_hora), 0) AS costo_consumido
        FROM proyecto p
        JOIN cliente c ON c.id_cliente = p.id_cliente
        JOIN usuario u ON u.id_usuario = p.id_lider
        LEFT JOIN tarea t ON t.id_proyecto = p.id_proyecto
        LEFT JOIN usuario ut ON ut.id_usuario = t.id_usuario_asignado
        GROUP BY p.id_proyecto, p.nombre_proyecto, p.descripcion, p.fecha_inicio,
                 p.fecha_fin_estimada, p.fecha_fin_real, p.presupuesto_total, p.estado,
                 c.nombre_empresa, u.nombre, u.rol
        ORDER BY p.id_proyecto ASC
    """)
    proyectos = cur.fetchall()

    for p in proyectos:
        costo_excedido = p['costo_consumido'] > p['presupuesto_total']
        pct_vencidas = (p['tareas_vencidas'] / p['total_tareas'] * 100) if p['total_tareas'] > 0 else 0
        tiene_bloqueadas = p['tareas_bloqueadas'] > 0

        # Mismo criterio que el dashboard
        p['es_riesgo'] = costo_excedido or (pct_vencidas >= 50 and p['total_tareas'] > 0) or tiene_bloqueadas

        # Motivos visibles en la tarjeta
        motivos = []
        if costo_excedido:
            motivos.append(f"Presupuesto excedido (${float(p['costo_consumido']):.0f} / ${float(p['presupuesto_total']):.0f})")
        if pct_vencidas >= 50 and p['total_tareas'] > 0:
            motivos.append(f"{p['tareas_vencidas']} de {p['total_tareas']} tareas vencidas ({pct_vencidas:.0f}%)")
        if tiene_bloqueadas:
            motivos.append(f"{p['tareas_bloqueadas']} tarea(s) bloqueada(s)")
        p['motivos_riesgo'] = motivos

        p['pct_presupuesto'] = round((float(p['costo_consumido']) / float(p['presupuesto_total']) * 100), 1) if p['presupuesto_total'] > 0 else 0

    cur.close()
    conn.close()
    return render_template('proyectos/index.html', proyectos=proyectos, view_mode=view_mode, active_tab='proyectos')


@app.route('/proyectos/nuevo', methods=['GET'])
def nuevo_proyecto():
    conn = obtener_conexion()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    clientes = _get_clientes(cur)
    lideres = _get_lideres(cur)
    cur.close()
    conn.close()
    return render_template('proyectos/form.html', proyecto=None, clientes=clientes, lideres=lideres, active_tab='proyectos')


@app.route('/proyectos/crear', methods=['POST'])
def crear_proyecto():
    nombre = request.form.get('nombre_proyecto', '').strip()
    id_cliente = request.form.get('id_cliente')
    id_lider = request.form.get('id_lider')
    fecha_inicio = request.form.get('fecha_inicio')
    fecha_fin_est = request.form.get('fecha_fin_estimada')
    presupuesto = request.form.get('presupuesto_total')
    estado = request.form.get('estado', 'planificacion')
    descripcion = request.form.get('descripcion', '').strip()

    if not all([nombre, id_cliente, id_lider, fecha_inicio, fecha_fin_est, presupuesto]):
        flash('Por favor complete todos los campos requeridos (*).', 'danger')
        return redirect(url_for('nuevo_proyecto'))

    try:
        conn = obtener_conexion()
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO proyecto
                (nombre_proyecto, id_cliente, id_lider, fecha_inicio, fecha_fin_estimada, presupuesto_total, estado, descripcion)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id_proyecto
        """, (nombre, id_cliente, id_lider, fecha_inicio, fecha_fin_est, presupuesto, estado, descripcion or None))
        new_id = cur.fetchone()[0]
        conn.commit()
        cur.close()
        conn.close()
        flash(f'Proyecto "{nombre}" creado exitosamente.', 'success')
        return redirect(url_for('detalle_proyecto', id_proyecto=new_id))
    except Exception as e:
        flash(f'Error al crear el proyecto: {e}', 'danger')
        return redirect(url_for('nuevo_proyecto'))


@app.route('/proyectos/<int:id_proyecto>')
def detalle_proyecto(id_proyecto):
    conn = obtener_conexion()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    # Proyecto info
    cur.execute("""
        SELECT
            p.*,
            c.nombre_empresa AS nombre_cliente,
            c.persona_contacto, c.email_contacto, c.telefono,
            u.nombre AS nombre_lider, u.rol AS rol_lider, u.email AS email_lider,
            public.fn_calcular_avance_proyecto(p.id_proyecto) AS avance
        FROM proyecto p
        JOIN cliente c ON c.id_cliente = p.id_cliente
        JOIN usuario u ON u.id_usuario = p.id_lider
        WHERE p.id_proyecto = %s
    """, (id_proyecto,))
    proyecto = cur.fetchone()

    if not proyecto:
        flash('Proyecto no encontrado.', 'warning')
        cur.close()
        conn.close()
        return redirect(url_for('listar_proyectos'))

    # Resumen Financiero
    cur.execute("""
        SELECT
            COALESCE(SUM(t.tiempo_real_horas), 0) AS total_horas_reales,
            COALESCE(SUM(t.tiempo_estimado_horas), 0) AS total_horas_estimadas,
            COALESCE(SUM(t.tiempo_real_horas * u.costo_hora), 0) AS costo_consumido
        FROM tarea t
        LEFT JOIN usuario u ON u.id_usuario = t.id_usuario_asignado
        WHERE t.id_proyecto = %s
    """, (id_proyecto,))
    finanzas = cur.fetchone()
    costo_consumido = finanzas['costo_consumido'] if finanzas else Decimal(0)
    presupuesto = proyecto['presupuesto_total']
    pct_consumo = round((float(costo_consumido) / float(presupuesto) * 100), 1) if presupuesto > 0 else 0
    margen_restante = presupuesto - costo_consumido

    # Timeline de Hitos
    cur.execute("""
        SELECT *
        FROM hito
        WHERE id_proyecto = %s
        ORDER BY fecha_objetivo ASC
    """, (id_proyecto,))
    hitos = cur.fetchall()

    # Tareas asociadas
    cur.execute("""
        SELECT
            t.*,
            u.nombre AS nombre_asignado,
            u.rol AS rol_asignado,
            h.nombre_hito,
            (SELECT COUNT(*) FROM dependencia_tarea WHERE id_tarea_dependiente = t.id_tarea) AS num_dependencias,
            (t.fecha_vencimiento < CURRENT_TIMESTAMP AND t.estado != 'completada') AS es_vencida
        FROM tarea t
        LEFT JOIN usuario u ON u.id_usuario = t.id_usuario_asignado
        LEFT JOIN hito h ON h.id_hito = t.id_hito
        WHERE t.id_proyecto = %s
        ORDER BY t.prioridad DESC, t.fecha_vencimiento ASC
    """, (id_proyecto,))
    tareas = cur.fetchall()

    total_tareas = len(tareas)
    tareas_vencidas = sum(1 for t in tareas if t['es_vencida'])
    tareas_bloqueadas = sum(1 for t in tareas if t['estado'] == 'bloqueada')

    costo_excedido = costo_consumido > presupuesto
    pct_vencidas = (tareas_vencidas / total_tareas * 100) if total_tareas > 0 else 0
    tiene_bloqueadas = tareas_bloqueadas > 0

    proyecto['es_riesgo'] = costo_excedido or (pct_vencidas >= 50 and total_tareas > 0) or tiene_bloqueadas

    motivos = []
    if costo_excedido:
        motivos.append(f"Presupuesto excedido (${float(costo_consumido):.0f} / ${float(presupuesto):.0f})")
    if pct_vencidas >= 50 and total_tareas > 0:
        motivos.append(f"{tareas_vencidas} de {total_tareas} tareas vencidas ({pct_vencidas:.0f}%)")
    if tiene_bloqueadas:
        motivos.append(f"{tareas_bloqueadas} tarea(s) bloqueada(s)")
    proyecto['motivos_riesgo'] = motivos

    cur.close()
    conn.close()

    return render_template(
        'proyectos/detalle.html',
        proyecto=proyecto,
        finanzas=finanzas,
        costo_consumido=costo_consumido,
        pct_consumo=pct_consumo,
        margen_restante=margen_restante,
        hitos=hitos,
        tareas=tareas,
        active_tab='proyectos'
    )


@app.route('/proyectos/<int:id_proyecto>/editar', methods=['GET'])
def editar_proyecto(id_proyecto):
    conn = obtener_conexion()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("SELECT * FROM proyecto WHERE id_proyecto = %s", (id_proyecto,))
    proyecto = cur.fetchone()
    if not proyecto:
        flash('Proyecto no encontrado.', 'warning')
        cur.close()
        conn.close()
        return redirect(url_for('listar_proyectos'))
    clientes = _get_clientes(cur)
    lideres = _get_lideres(cur)
    cur.close()
    conn.close()
    return render_template('proyectos/form.html', proyecto=proyecto, clientes=clientes, lideres=lideres, active_tab='proyectos')


@app.route('/proyectos/<int:id_proyecto>/editar', methods=['POST'])
def actualizar_proyecto(id_proyecto):
    nombre = request.form.get('nombre_proyecto', '').strip()
    id_cliente = request.form.get('id_cliente')
    id_lider = request.form.get('id_lider')
    fecha_inicio = request.form.get('fecha_inicio')
    fecha_fin_est = request.form.get('fecha_fin_estimada')
    fecha_fin_real = request.form.get('fecha_fin_real') or None
    presupuesto = request.form.get('presupuesto_total')
    estado = request.form.get('estado', 'planificacion')
    descripcion = request.form.get('descripcion', '').strip()

    if not all([nombre, id_cliente, id_lider, fecha_inicio, fecha_fin_est, presupuesto]):
        flash('Por favor complete todos los campos obligatorios (*).', 'danger')
        return redirect(url_for('editar_proyecto', id_proyecto=id_proyecto))

    try:
        conn = obtener_conexion()
        cur = conn.cursor()
        cur.execute("""
            UPDATE proyecto SET
                nombre_proyecto = %s, id_cliente = %s, id_lider = %s,
                fecha_inicio = %s, fecha_fin_estimada = %s, fecha_fin_real = %s,
                presupuesto_total = %s, estado = %s, descripcion = %s
            WHERE id_proyecto = %s
        """, (nombre, id_cliente, id_lider, fecha_inicio, fecha_fin_est, fecha_fin_real, presupuesto, estado, descripcion or None, id_proyecto))
        conn.commit()
        cur.close()
        conn.close()
        flash(f'Proyecto "{nombre}" actualizado correctamente.', 'success')
        return redirect(url_for('detalle_proyecto', id_proyecto=id_proyecto))
    except Exception as e:
        flash(f'Error al actualizar el proyecto: {e}', 'danger')
        return redirect(url_for('editar_proyecto', id_proyecto=id_proyecto))


@app.route('/proyectos/<int:id_proyecto>/eliminar', methods=['POST'])
def eliminar_proyecto(id_proyecto):
    try:
        conn = obtener_conexion()
        cur = conn.cursor()
        cur.execute("SELECT nombre_proyecto FROM proyecto WHERE id_proyecto = %s", (id_proyecto,))
        row = cur.fetchone()
        if not row:
            flash('Proyecto no encontrado.', 'warning')
            cur.close()
            conn.close()
            return redirect(url_for('listar_proyectos'))
        cur.execute("DELETE FROM proyecto WHERE id_proyecto = %s", (id_proyecto,))
        conn.commit()
        cur.close()
        conn.close()
        flash(f'Proyecto "{row[0]}" y sus dependencias eliminados correctamente.', 'success')
    except Exception as e:
        flash(f'Error al eliminar el proyecto: {e}', 'danger')
    return redirect(url_for('listar_proyectos'))


# Hitos (Milestones) actions
@app.route('/proyectos/<int:id_proyecto>/hitos/crear', methods=['POST'])
def crear_hito(id_proyecto):
    nombre_hito = request.form.get('nombre_hito', '').strip()
    fecha_objetivo = request.form.get('fecha_objetivo')
    if not nombre_hito or not fecha_objetivo:
        flash('Nombre y fecha del hito son obligatorios.', 'danger')
        return redirect(url_for('detalle_proyecto', id_proyecto=id_proyecto))
    try:
        conn = obtener_conexion()
        cur = conn.cursor()
        cur.execute("INSERT INTO hito (id_proyecto, nombre_hito, fecha_objetivo, alcanzado) VALUES (%s, %s, %s, false)",
                    (id_proyecto, nombre_hito, fecha_objetivo))
        conn.commit()
        cur.close()
        conn.close()
        flash(f'Hito "{nombre_hito}" añadido exitosamente.', 'success')
    except Exception as e:
        flash(f'Error al crear hito: {e}', 'danger')
    return redirect(url_for('detalle_proyecto', id_proyecto=id_proyecto))


@app.route('/hitos/<int:id_hito>/toggle', methods=['POST'])
def toggle_hito(id_hito):
    id_proyecto = request.form.get('id_proyecto')
    try:
        conn = obtener_conexion()
        cur = conn.cursor()
        cur.execute("UPDATE hito SET alcanzado = NOT alcanzado WHERE id_hito = %s", (id_hito,))
        conn.commit()
        cur.close()
        conn.close()
        flash('Estado del hito actualizado.', 'success')
    except Exception as e:
        flash(f'Error: {e}', 'danger')
    return redirect(url_for('detalle_proyecto', id_proyecto=id_proyecto) if id_proyecto else url_for('listar_proyectos'))


# ═══════════════════════════════════════════════
#  C. TABLERO DE TAREAS (Kanban & List View)
# ═══════════════════════════════════════════════

@app.route('/tareas')
def listar_tareas():
    vista = request.args.get('vista', 'kanban')  # 'kanban' or 'lista'
    filtro_proyecto = request.args.get('proyecto', '')
    filtro_usuario = request.args.get('usuario', '')

    conn = obtener_conexion()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    query = """
        SELECT
            t.*,
            p.nombre_proyecto,
            u.nombre AS nombre_asignado,
            u.rol AS rol_asignado,
            h.nombre_hito,
            (SELECT COUNT(*) FROM dependencia_tarea WHERE id_tarea_dependiente = t.id_tarea) AS num_dependencias,
            (t.fecha_vencimiento < CURRENT_TIMESTAMP AND t.estado != 'completada') AS es_vencida
        FROM tarea t
        JOIN proyecto p ON p.id_proyecto = t.id_proyecto
        LEFT JOIN usuario u ON u.id_usuario = t.id_usuario_asignado
        LEFT JOIN hito h ON h.id_hito = t.id_hito
        WHERE 1=1
    """
    params = []
    if filtro_proyecto:
        query += " AND t.id_proyecto = %s"
        params.append(filtro_proyecto)
    if filtro_usuario:
        query += " AND t.id_usuario_asignado = %s"
        params.append(filtro_usuario)

    query += " ORDER BY t.prioridad DESC, t.fecha_vencimiento ASC"

    cur.execute(query, params)
    todas_tareas = cur.fetchall()

    # Organizar para Kanban
    kanban = {
        'pendiente': [],
        'en_progreso': [],
        'bloqueada': [],
        'completada': []
    }
    for t in todas_tareas:
        st = t['estado']
        if st in kanban:
            kanban[st].append(t)
        else:
            kanban['pendiente'].append(t)

    proyectos = _get_proyectos_select(cur)
    usuarios = _get_usuarios_select(cur)

    cur.close()
    conn.close()

    return render_template(
        'tareas/index.html',
        vista=vista,
        todas_tareas=todas_tareas,
        kanban=kanban,
        proyectos=proyectos,
        usuarios=usuarios,
        filtro_proyecto=filtro_proyecto,
        filtro_usuario=filtro_usuario,
        active_tab='tareas'
    )


@app.route('/tareas/nueva', methods=['GET'])
def nueva_tarea():
    id_proyecto_default = request.args.get('proyecto', '')
    conn = obtener_conexion()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    proyectos = _get_proyectos_select(cur)
    usuarios = _get_usuarios_select(cur)
    hitos = _get_hitos_select(cur, id_proyecto_default if id_proyecto_default else None)
    cur.close()
    conn.close()
    return render_template(
        'tareas/form.html',
        tarea=None,
        proyectos=proyectos,
        usuarios=usuarios,
        hitos=hitos,
        id_proyecto_default=id_proyecto_default,
        active_tab='tareas'
    )


@app.route('/tareas/crear', methods=['POST'])
def crear_tarea():
    nombre = request.form.get('nombre_tarea', '').strip()
    id_proyecto = request.form.get('id_proyecto')
    id_hito = request.form.get('id_hito') or None
    id_usuario = request.form.get('id_usuario_asignado') or None
    descripcion = request.form.get('descripcion', '').strip()
    fecha_venc = request.form.get('fecha_vencimiento')
    prioridad = request.form.get('prioridad', 'media')
    estado = request.form.get('estado', 'pendiente')
    tiempo_est = request.form.get('tiempo_estimado_horas')

    if not all([nombre, id_proyecto, fecha_venc, tiempo_est]):
        flash('Por favor complete todos los campos obligatorios (*).', 'danger')
        return redirect(url_for('nueva_tarea'))

    try:
        conn = obtener_conexion()
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO tarea
                (nombre_tarea, id_proyecto, id_hito, id_usuario_asignado, descripcion,
                 fecha_vencimiento, prioridad, estado, tiempo_estimado_horas)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id_tarea
        """, (nombre, id_proyecto, id_hito, id_usuario, descripcion or None, fecha_venc, prioridad, estado, tiempo_est))
        new_id = cur.fetchone()[0]
        conn.commit()
        cur.close()
        conn.close()
        flash(f'Tarea "{nombre}" creada con éxito.', 'success')
        return redirect(url_for('detalle_tarea', id_tarea=new_id))
    except Exception as e:
        flash(f'Error al crear tarea: {e}', 'danger')
        return redirect(url_for('nueva_tarea'))


@app.route('/tareas/<int:id_tarea>')
def detalle_tarea(id_tarea):
    conn = obtener_conexion()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    cur.execute("""
        SELECT
            t.*,
            p.nombre_proyecto,
            u.nombre AS nombre_asignado,
            u.rol AS rol_asignado,
            u.email AS email_asignado,
            h.nombre_hito,
            (SELECT COUNT(*) FROM dependencia_tarea WHERE id_tarea_dependiente = t.id_tarea) AS num_dependencias
        FROM tarea t
        JOIN proyecto p ON p.id_proyecto = t.id_proyecto
        LEFT JOIN usuario u ON u.id_usuario = t.id_usuario_asignado
        LEFT JOIN hito h ON h.id_hito = t.id_hito
        WHERE t.id_tarea = %s
    """, (id_tarea,))
    tarea = cur.fetchone()

    if not tarea:
        flash('Tarea no encontrada.', 'warning')
        cur.close()
        conn.close()
        return redirect(url_for('listar_tareas'))

    # Comentarios
    cur.execute("""
        SELECT c.*, u.nombre AS nombre_usuario, u.rol AS rol_usuario
        FROM comentario c
        JOIN usuario u ON u.id_usuario = c.id_usuario
        WHERE c.id_tarea = %s
        ORDER BY c.fecha_hora ASC
    """, (id_tarea,))
    comentarios = cur.fetchall()

    # Historial de Cambios (Audit Log)
    cur.execute("""
        SELECT hc.*, u.nombre AS nombre_usuario
        FROM historial_cambio hc
        LEFT JOIN usuario u ON u.id_usuario = hc.id_usuario
        WHERE hc.id_tarea = %s
        ORDER BY hc.fecha_cambio DESC
    """, (id_tarea,))
    historial = cur.fetchall()

    usuarios = _get_usuarios_select(cur)

    cur.close()
    conn.close()

    return render_template(
        'tareas/detalle.html',
        tarea=tarea,
        comentarios=comentarios,
        historial=historial,
        usuarios=usuarios,
        active_tab='tareas'
    )


@app.route('/tareas/<int:id_tarea>/editar', methods=['GET'])
def editar_tarea(id_tarea):
    conn = obtener_conexion()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("SELECT * FROM tarea WHERE id_tarea = %s", (id_tarea,))
    tarea = cur.fetchone()
    if not tarea:
        flash('Tarea no encontrada.', 'warning')
        cur.close()
        conn.close()
        return redirect(url_for('listar_tareas'))
    proyectos = _get_proyectos_select(cur)
    usuarios = _get_usuarios_select(cur)
    hitos = _get_hitos_select(cur, tarea['id_proyecto'])
    cur.close()
    conn.close()
    return render_template('tareas/form.html', tarea=tarea, proyectos=proyectos, usuarios=usuarios, hitos=hitos, active_tab='tareas')


@app.route('/tareas/<int:id_tarea>/editar', methods=['POST'])
def actualizar_tarea(id_tarea):
    nombre = request.form.get('nombre_tarea', '').strip()
    id_proyecto = request.form.get('id_proyecto')
    id_hito = request.form.get('id_hito') or None
    id_usuario = request.form.get('id_usuario_asignado') or None
    descripcion = request.form.get('descripcion', '').strip()
    fecha_venc = request.form.get('fecha_vencimiento')
    prioridad = request.form.get('prioridad', 'media')
    estado = request.form.get('estado', 'pendiente')
    tiempo_est = request.form.get('tiempo_estimado_horas')
    tiempo_real = request.form.get('tiempo_real_horas') or 0

    if not all([nombre, id_proyecto, fecha_venc, tiempo_est]):
        flash('Por favor complete todos los campos obligatorios (*).', 'danger')
        return redirect(url_for('editar_tarea', id_tarea=id_tarea))

    try:
        conn = obtener_conexion()
        cur = conn.cursor()
        cur.execute("""
            UPDATE tarea SET
                nombre_tarea = %s, id_proyecto = %s, id_hito = %s, id_usuario_asignado = %s,
                descripcion = %s, fecha_vencimiento = %s, prioridad = %s, estado = %s,
                tiempo_estimado_horas = %s, tiempo_real_horas = %s
            WHERE id_tarea = %s
        """, (nombre, id_proyecto, id_hito, id_usuario, descripcion or None, fecha_venc, prioridad, estado, tiempo_est, tiempo_real, id_tarea))
        conn.commit()
        cur.close()
        conn.close()
        flash(f'Tarea "{nombre}" actualizada correctamente.', 'success')
        return redirect(url_for('detalle_tarea', id_tarea=id_tarea))
    except Exception as e:
        flash(f'Error al actualizar tarea: {e}', 'danger')
        return redirect(url_for('editar_tarea', id_tarea=id_tarea))


@app.route('/tareas/<int:id_tarea>/comentar', methods=['POST'])
def agregar_comentario(id_tarea):
    id_usuario = g.user['id_usuario']
    contenido = request.form.get('contenido', '').strip()
    if not contenido:
        flash('El comentario no puede estar vacío.', 'warning')
        return redirect(url_for('detalle_tarea', id_tarea=id_tarea))
    try:
        conn = obtener_conexion()
        cur = conn.cursor()
        cur.execute("INSERT INTO comentario (id_tarea, id_usuario, contenido) VALUES (%s, %s, %s)",
                    (id_tarea, id_usuario, contenido))
        conn.commit()
        cur.close()
        conn.close()
        flash('Comentario publicado.', 'success')
    except Exception as e:
        flash(f'Error al publicar comentario: {e}', 'danger')
    return redirect(url_for('detalle_tarea', id_tarea=id_tarea))


@app.route('/tareas/<int:id_tarea>/eliminar', methods=['POST'])
def eliminar_tarea(id_tarea):
    try:
        conn = obtener_conexion()
        cur = conn.cursor()
        cur.execute("SELECT nombre_tarea FROM tarea WHERE id_tarea = %s", (id_tarea,))
        row = cur.fetchone()
        if not row:
            flash('Tarea no encontrada.', 'warning')
            cur.close()
            conn.close()
            return redirect(url_for('listar_tareas'))
        cur.execute("DELETE FROM tarea WHERE id_tarea = %s", (id_tarea,))
        conn.commit()
        cur.close()
        conn.close()
        flash(f'Tarea "{row[0]}" eliminada correctamente.', 'success')
    except Exception as e:
        flash(f'Error al eliminar tarea: {e}', 'danger')
    return redirect(url_for('listar_tareas'))


# ═══════════════════════════════════════════════
#  D. EQUIPOS, USUARIOS Y HABILIDADES
# ═══════════════════════════════════════════════

@app.route('/equipos')
def listar_equipos():
    conn = obtener_conexion()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    cur.execute("""
        SELECT
            e.*,
            COUNT(u.id_usuario) AS total_miembros
        FROM equipo e
        LEFT JOIN usuario u ON u.id_equipo = e.id_equipo
        GROUP BY e.id_equipo
        ORDER BY e.nombre_equipo
    """)
    equipos = cur.fetchall()

    # Directorio de todos los usuarios con sus habilidades y carga de trabajo
    cur.execute("""
        SELECT
            u.*,
            eq.nombre_equipo,
            COALESCE(array_agg(h.nombre_habilidad) FILTER (WHERE h.nombre_habilidad IS NOT NULL), '{}') AS habilidades,
            COUNT(t.id_tarea) FILTER (WHERE t.estado != 'completada') AS tareas_activas,
            COALESCE(SUM(CASE WHEN t.estado != 'completada' THEN t.tiempo_estimado_horas ELSE 0 END), 0) AS horas_pendientes
        FROM usuario u
        LEFT JOIN equipo eq ON eq.id_equipo = u.id_equipo
        LEFT JOIN habilidad_usuario hu ON hu.id_usuario = u.id_usuario
        LEFT JOIN habilidad h ON h.id_habilidad = hu.id_habilidad
        LEFT JOIN tarea t ON t.id_usuario_asignado = u.id_usuario
        GROUP BY u.id_usuario, eq.nombre_equipo
        ORDER BY u.nombre ASC
    """)
    usuarios = cur.fetchall()

    cur.close()
    conn.close()
    return render_template('equipos/index.html', equipos=equipos, usuarios=usuarios, active_tab='equipos')


@app.route('/equipos/nuevo', methods=['GET'])
def nuevo_equipo():
    return render_template('equipos/form.html', equipo=None, active_tab='equipos')


@app.route('/equipos/crear', methods=['POST'])
def crear_equipo():
    nombre = request.form.get('nombre_equipo', '').strip()
    descripcion = request.form.get('descripcion', '').strip()
    if not nombre:
        flash('El nombre del equipo es obligatorio.', 'danger')
        return redirect(url_for('nuevo_equipo'))
    try:
        conn = obtener_conexion()
        cur = conn.cursor()
        cur.execute("INSERT INTO equipo (nombre_equipo, descripcion) VALUES (%s, %s)", (nombre, descripcion or None))
        conn.commit()
        cur.close()
        conn.close()
        flash(f'Equipo "{nombre}" creado exitosamente.', 'success')
        return redirect(url_for('listar_equipos'))
    except Exception as e:
        flash(f'Error al crear el equipo: {e}', 'danger')
        return redirect(url_for('nuevo_equipo'))


@app.route('/equipos/<int:id_equipo>')
def detalle_equipo(id_equipo):
    conn = obtener_conexion()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("SELECT * FROM equipo WHERE id_equipo = %s", (id_equipo,))
    equipo = cur.fetchone()
    if not equipo:
        flash('Equipo no encontrado.', 'warning')
        cur.close()
        conn.close()
        return redirect(url_for('listar_equipos'))

    cur.execute("""
        SELECT
            u.*,
            COALESCE(array_agg(h.nombre_habilidad) FILTER (WHERE h.nombre_habilidad IS NOT NULL), '{}') AS habilidades,
            COUNT(t.id_tarea) FILTER (WHERE t.estado != 'completada') AS tareas_activas,
            COALESCE(SUM(CASE WHEN t.estado != 'completada' THEN t.tiempo_estimado_horas ELSE 0 END), 0) AS horas_pendientes
        FROM usuario u
        LEFT JOIN habilidad_usuario hu ON hu.id_usuario = u.id_usuario
        LEFT JOIN habilidad h ON h.id_habilidad = hu.id_habilidad
        LEFT JOIN tarea t ON t.id_usuario_asignado = u.id_usuario
        WHERE u.id_equipo = %s
        GROUP BY u.id_usuario
        ORDER BY u.nombre
    """, (id_equipo,))
    miembros = cur.fetchall()

    cur.close()
    conn.close()
    return render_template('equipos/detalle.html', equipo=equipo, miembros=miembros, active_tab='equipos')


@app.route('/equipos/<int:id_equipo>/editar', methods=['GET'])
def editar_equipo(id_equipo):
    conn = obtener_conexion()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("SELECT * FROM equipo WHERE id_equipo = %s", (id_equipo,))
    equipo = cur.fetchone()
    cur.close()
    conn.close()
    if not equipo:
        flash('Equipo no encontrado.', 'warning')
        return redirect(url_for('listar_equipos'))
    return render_template('equipos/form.html', equipo=equipo, active_tab='equipos')


@app.route('/equipos/<int:id_equipo>/editar', methods=['POST'])
def actualizar_equipo(id_equipo):
    nombre = request.form.get('nombre_equipo', '').strip()
    descripcion = request.form.get('descripcion', '').strip()
    if not nombre:
        flash('El nombre del equipo es obligatorio.', 'danger')
        return redirect(url_for('editar_equipo', id_equipo=id_equipo))
    try:
        conn = obtener_conexion()
        cur = conn.cursor()
        cur.execute("UPDATE equipo SET nombre_equipo=%s, descripcion=%s WHERE id_equipo=%s", (nombre, descripcion or None, id_equipo))
        conn.commit()
        cur.close()
        conn.close()
        flash(f'Equipo "{nombre}" actualizado.', 'success')
        return redirect(url_for('detalle_equipo', id_equipo=id_equipo))
    except Exception as e:
        flash(f'Error al actualizar: {e}', 'danger')
        return redirect(url_for('editar_equipo', id_equipo=id_equipo))


@app.route('/equipos/<int:id_equipo>/eliminar', methods=['POST'])
def eliminar_equipo(id_equipo):
    try:
        conn = obtener_conexion()
        cur = conn.cursor()
        cur.execute("SELECT nombre_equipo FROM equipo WHERE id_equipo = %s", (id_equipo,))
        row = cur.fetchone()
        if not row:
            flash('Equipo no encontrado.', 'warning')
            cur.close()
            conn.close()
            return redirect(url_for('listar_equipos'))
        cur.execute("DELETE FROM equipo WHERE id_equipo = %s", (id_equipo,))
        conn.commit()
        cur.close()
        conn.close()
        flash(f'Equipo "{row[0]}" eliminado.', 'success')
    except Exception as e:
        flash(f'Error al eliminar el equipo: {e}', 'danger')
    return redirect(url_for('listar_equipos'))


@app.route('/usuarios')
def listar_usuarios():
    conn = obtener_conexion()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("""
        SELECT
            u.*,
            eq.nombre_equipo,
            COALESCE(array_agg(h.nombre_habilidad) FILTER (WHERE h.nombre_habilidad IS NOT NULL), '{}') AS habilidades,
            COUNT(t.id_tarea) FILTER (WHERE t.estado != 'completada') AS tareas_activas,
            COALESCE(SUM(CASE WHEN t.estado != 'completada' THEN t.tiempo_estimado_horas ELSE 0 END), 0) AS horas_pendientes
        FROM usuario u
        LEFT JOIN equipo eq ON eq.id_equipo = u.id_equipo
        LEFT JOIN habilidad_usuario hu ON hu.id_usuario = u.id_usuario
        LEFT JOIN habilidad h ON h.id_habilidad = hu.id_habilidad
        LEFT JOIN tarea t ON t.id_usuario_asignado = u.id_usuario
        GROUP BY u.id_usuario, eq.nombre_equipo
        ORDER BY u.nombre
    """)
    usuarios = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('usuarios/index.html', usuarios=usuarios, active_tab='usuarios')


@app.route('/usuarios/nuevo', methods=['GET'])
def nuevo_usuario():
    conn = obtener_conexion()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    equipos = _get_equipos_select(cur)
    cur.close()
    conn.close()
    return render_template('usuarios/form.html', usuario=None, equipos=equipos, active_tab='usuarios')


@app.route('/usuarios/crear', methods=['POST'])
def crear_usuario():
    nombre = request.form.get('nombre', '').strip()
    email = request.form.get('email', '').strip()
    usuario_val = request.form.get('usuario', '').strip() or None
    contrasena_val = request.form.get('contrasena', '').strip() or None
    rol = request.form.get('rol', '').strip()
    id_equipo = request.form.get('id_equipo') or None
    costo_hora = request.form.get('costo_hora', 0)
    activo = request.form.get('activo') == 'on'

    if not all([nombre, email, rol]):
        flash('Nombre, email y rol son obligatorios.', 'danger')
        return redirect(url_for('nuevo_usuario'))
    try:
        conn = obtener_conexion()
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO usuario (nombre, email, usuario, contrasena, rol, id_equipo, costo_hora, activo)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (nombre, email, usuario_val, contrasena_val, rol, id_equipo, costo_hora, activo))
        conn.commit()
        cur.close()
        conn.close()
        flash(f'Usuario "{nombre}" creado con éxito.', 'success')
        return redirect(url_for('listar_usuarios'))
    except Exception as e:
        flash(f'Error al crear usuario: {e}', 'danger')
        return redirect(url_for('nuevo_usuario'))


@app.route('/usuarios/<int:id_usuario>/editar', methods=['GET'])
def editar_usuario(id_usuario):
    conn = obtener_conexion()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("SELECT * FROM usuario WHERE id_usuario = %s", (id_usuario,))
    usuario = cur.fetchone()
    if not usuario:
        flash('Usuario no encontrado.', 'warning')
        cur.close()
        conn.close()
        return redirect(url_for('listar_usuarios'))
    equipos = _get_equipos_select(cur)
    cur.close()
    conn.close()
    return render_template('usuarios/form.html', usuario=usuario, equipos=equipos, active_tab='usuarios')


@app.route('/usuarios/<int:id_usuario>/editar', methods=['POST'])
def actualizar_usuario(id_usuario):
    nombre = request.form.get('nombre', '').strip()
    email = request.form.get('email', '').strip()
    usuario_val = request.form.get('usuario', '').strip() or None
    contrasena_val = request.form.get('contrasena', '').strip() or None
    rol = request.form.get('rol', '').strip()
    id_equipo = request.form.get('id_equipo') or None
    costo_hora = request.form.get('costo_hora', 0)
    activo = request.form.get('activo') == 'on'

    if not all([nombre, email, rol]):
        flash('Nombre, email y rol son obligatorios.', 'danger')
        return redirect(url_for('editar_usuario', id_usuario=id_usuario))
    try:
        conn = obtener_conexion()
        cur = conn.cursor()
        cur.execute("""
            UPDATE usuario SET nombre=%s, email=%s, usuario=%s, contrasena=%s, rol=%s, id_equipo=%s, costo_hora=%s, activo=%s
            WHERE id_usuario=%s
        """, (nombre, email, usuario_val, contrasena_val, rol, id_equipo, costo_hora, activo, id_usuario))
        conn.commit()
        cur.close()
        conn.close()
        flash(f'Usuario "{nombre}" actualizado.', 'success')
        return redirect(url_for('listar_usuarios'))
    except Exception as e:
        flash(f'Error al actualizar usuario: {e}', 'danger')
        return redirect(url_for('editar_usuario', id_usuario=id_usuario))


@app.route('/usuarios/<int:id_usuario>/eliminar', methods=['POST'])
def eliminar_usuario(id_usuario):
    try:
        conn = obtener_conexion()
        cur = conn.cursor()
        cur.execute("DELETE FROM usuario WHERE id_usuario = %s", (id_usuario,))
        conn.commit()
        cur.close()
        conn.close()
        flash('Usuario eliminado.', 'success')
    except Exception as e:
        flash(f'Error al eliminar: {e}', 'danger')
    return redirect(url_for('listar_usuarios'))


# ═══════════════════════════════════════════════
#  E. CLIENTES
# ═══════════════════════════════════════════════

@app.route('/clientes')
def listar_clientes():
    conn = obtener_conexion()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("""
        SELECT
            c.*,
            COUNT(p.id_proyecto) AS total_proyectos
        FROM cliente c
        LEFT JOIN proyecto p ON p.id_cliente = c.id_cliente
        GROUP BY c.id_cliente
        ORDER BY c.nombre_empresa ASC
    """)
    clientes = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('clientes/index.html', clientes=clientes, active_tab='clientes')


@app.route('/clientes/nuevo', methods=['GET'])
def nuevo_cliente():
    return render_template('clientes/form.html', cliente=None, active_tab='clientes')


@app.route('/clientes/crear', methods=['POST'])
def crear_cliente():
    nombre = request.form.get('nombre_empresa', '').strip()
    contacto = request.form.get('persona_contacto', '').strip()
    email = request.form.get('email_contacto', '').strip()
    telefono = request.form.get('telefono', '').strip()

    if not nombre:
        flash('El nombre de la empresa es obligatorio.', 'danger')
        return redirect(url_for('nuevo_cliente'))
    try:
        conn = obtener_conexion()
        cur = conn.cursor()
        cur.execute("INSERT INTO cliente (nombre_empresa, persona_contacto, email_contacto, telefono) VALUES (%s, %s, %s, %s)",
                    (nombre, contacto or None, email or None, telefono or None))
        conn.commit()
        cur.close()
        conn.close()
        flash(f'Cliente "{nombre}" creado con éxito.', 'success')
        return redirect(url_for('listar_clientes'))
    except Exception as e:
        flash(f'Error al crear el cliente: {e}', 'danger')
        return redirect(url_for('nuevo_cliente'))


@app.route('/clientes/<int:id_cliente>')
def detalle_cliente(id_cliente):
    conn = obtener_conexion()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("SELECT * FROM cliente WHERE id_cliente = %s", (id_cliente,))
    cliente = cur.fetchone()
    if not cliente:
        flash('Cliente no encontrado.', 'warning')
        cur.close()
        conn.close()
        return redirect(url_for('listar_clientes'))

    cur.execute("""
        SELECT p.*, u.nombre AS nombre_lider,
               public.fn_calcular_avance_proyecto(p.id_proyecto) AS avance
        FROM proyecto p
        JOIN usuario u ON u.id_usuario = p.id_lider
        WHERE p.id_cliente = %s
        ORDER BY p.fecha_inicio DESC
    """, (id_cliente,))
    proyectos = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('clientes/detalle.html', cliente=cliente, proyectos=proyectos, active_tab='clientes')


@app.route('/clientes/<int:id_cliente>/editar', methods=['GET'])
def editar_cliente(id_cliente):
    conn = obtener_conexion()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("SELECT * FROM cliente WHERE id_cliente = %s", (id_cliente,))
    cliente = cur.fetchone()
    cur.close()
    conn.close()
    if not cliente:
        flash('Cliente no encontrado.', 'warning')
        return redirect(url_for('listar_clientes'))
    return render_template('clientes/form.html', cliente=cliente, active_tab='clientes')


@app.route('/clientes/<int:id_cliente>/editar', methods=['POST'])
def actualizar_cliente(id_cliente):
    nombre = request.form.get('nombre_empresa', '').strip()
    contacto = request.form.get('persona_contacto', '').strip()
    email = request.form.get('email_contacto', '').strip()
    telefono = request.form.get('telefono', '').strip()

    if not nombre:
        flash('El nombre de la empresa es obligatorio.', 'danger')
        return redirect(url_for('editar_cliente', id_cliente=id_cliente))
    try:
        conn = obtener_conexion()
        cur = conn.cursor()
        cur.execute("UPDATE cliente SET nombre_empresa=%s, persona_contacto=%s, email_contacto=%s, telefono=%s WHERE id_cliente=%s",
                    (nombre, contacto or None, email or None, telefono or None, id_cliente))
        conn.commit()
        cur.close()
        conn.close()
        flash(f'Cliente "{nombre}" actualizado.', 'success')
        return redirect(url_for('detalle_cliente', id_cliente=id_cliente))
    except Exception as e:
        flash(f'Error al actualizar: {e}', 'danger')
        return redirect(url_for('editar_cliente', id_cliente=id_cliente))


@app.route('/clientes/<int:id_cliente>/eliminar', methods=['POST'])
def eliminar_cliente(id_cliente):
    try:
        conn = obtener_conexion()
        cur = conn.cursor()
        cur.execute("DELETE FROM cliente WHERE id_cliente = %s", (id_cliente,))
        conn.commit()
        cur.close()
        conn.close()
        flash('Cliente eliminado.', 'success')
    except Exception as e:
        flash(f'No se puede eliminar: tiene proyectos asociados. ({e})', 'danger')
    return redirect(url_for('listar_clientes'))


# ═══════════════════════════════════════════════
#  F. PERFIL DE USUARIO
# ═══════════════════════════════════════════════

@app.route('/perfil', methods=['GET', 'POST'])
def perfil():
    user_id = g.user['id_usuario']
    conn = obtener_conexion()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    if request.method == 'POST':
        recibir_emails = request.form.get('recibir_emails') == 'on'
        alerta_vencimiento = request.form.get('alerta_vencimiento') == 'on'
        try:
            cur.execute("""
                INSERT INTO config_notificacion (id_usuario, recibir_emails, alerta_vencimiento)
                VALUES (%s, %s, %s)
                ON CONFLICT (id_config) DO UPDATE
                SET recibir_emails = EXCLUDED.recibir_emails, alerta_vencimiento = EXCLUDED.alerta_vencimiento
            """, (user_id, recibir_emails, alerta_vencimiento))
            # Fallback simple update if no conflict trigger
            cur.execute("""
                UPDATE config_notificacion
                SET recibir_emails = %s, alerta_vencimiento = %s
                WHERE id_usuario = %s
            """, (recibir_emails, alerta_vencimiento, user_id))
            conn.commit()
            flash('Preferencias de notificación guardadas correctamente.', 'success')
        except Exception as e:
            flash(f'Error al guardar preferencias: {e}', 'danger')

    cur.execute("SELECT * FROM config_notificacion WHERE id_usuario = %s", (user_id,))
    config = cur.fetchone()
    if not config:
        config = {'recibir_emails': True, 'alerta_vencimiento': True}

    cur.execute("SELECT * FROM usuario WHERE id_usuario = %s", (user_id,))
    usuario_actual = cur.fetchone()

    # Get user tasks
    cur.execute("""
        SELECT t.*, p.nombre_proyecto, h.nombre_hito
        FROM tarea t
        JOIN proyecto p ON t.id_proyecto = p.id_proyecto
        LEFT JOIN hito h ON t.id_hito = h.id_hito
        WHERE t.id_usuario_asignado = %s
        ORDER BY t.prioridad DESC, t.fecha_vencimiento ASC
    """, (user_id,))
    tareas_usuario = cur.fetchall()

    cur.close()
    conn.close()
    return render_template('perfil/index.html', config=config, usuario=usuario_actual, tareas=tareas_usuario, active_tab='perfil')



# ═══════════════════════════════════════════════
#  G. API REST (Consumida por el Frontend)
# ═══════════════════════════════════════════════

def _serialize_dict(d):
    res = {}
    for k, v in d.items():
        if isinstance(v, Decimal):
            res[k] = float(v)
        elif hasattr(v, 'isoformat'):
            res[k] = v.isoformat()
        else:
            res[k] = v
    return res

@app.route('/api/proyectos_en_riesgo', methods=['GET'])
def api_proyectos_en_riesgo():
    conn = obtener_conexion()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    try:
        cur.execute("SELECT * FROM vw_proyectos_en_riesgo")
        data = cur.fetchall()
        return jsonify([_serialize_dict(row) for row in data])
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        cur.close()
        conn.close()

@app.route('/api/carga_usuarios', methods=['GET'])
def api_carga_usuarios():
    conn = obtener_conexion()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    try:
        cur.execute("SELECT * FROM vw_carga_usuarios")
        data = cur.fetchall()
        return jsonify([_serialize_dict(row) for row in data])
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        cur.close()
        conn.close()

@app.route('/api/tareas/<int:id_tarea>/estado', methods=['POST'])
def api_actualizar_estado_tarea(id_tarea):
    data = request.get_json()
    if not data or 'estado' not in data:
        return jsonify({"error": "Falta el campo estado"}), 400
        
    nuevo_estado = data.get('estado')
    conn = obtener_conexion()
    cur = conn.cursor()
    try:
        cur.execute("UPDATE tarea SET estado = %s WHERE id_tarea = %s RETURNING id_proyecto", (nuevo_estado, id_tarea))
        row = cur.fetchone()
        if not row:
            return jsonify({"error": "Tarea no encontrada"}), 404
            
        id_proyecto = row[0]
        cur.execute("SELECT public.fn_calcular_avance_proyecto(%s)", (id_proyecto,))
        nuevo_avance = cur.fetchone()[0]
        conn.commit()
        
        return jsonify({
            "success": True, 
            "mensaje": "Estado actualizado exitosamente", 
            "nuevo_avance_proyecto": float(nuevo_avance) if nuevo_avance else 0.0
        })
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        cur.close()
        conn.close()


# ═══════════════════════════════════════════════
#  BÚSQUEDA GLOBAL
# ═══════════════════════════════════════════════

@app.route('/buscar')
def buscar():
    q = request.args.get('q', '').strip()
    proyectos = []
    tareas = []
    usuarios = []

    if q:
        conn = obtener_conexion()
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        term = f'%{q}%'

        cur.execute("""
            SELECT p.id_proyecto, p.nombre_proyecto, p.estado, p.descripcion,
                   c.nombre_empresa AS nombre_cliente
            FROM proyecto p
            JOIN cliente c ON c.id_cliente = p.id_cliente
            WHERE p.nombre_proyecto ILIKE %s OR p.descripcion ILIKE %s OR c.nombre_empresa ILIKE %s
            ORDER BY p.nombre_proyecto
            LIMIT 20
        """, (term, term, term))
        proyectos = cur.fetchall()

        cur.execute("""
            SELECT t.id_tarea, t.nombre_tarea, t.estado, t.prioridad,
                   p.nombre_proyecto
            FROM tarea t
            JOIN proyecto p ON p.id_proyecto = t.id_proyecto
            WHERE t.nombre_tarea ILIKE %s OR t.descripcion ILIKE %s
            ORDER BY t.nombre_tarea
            LIMIT 20
        """, (term, term))
        tareas = cur.fetchall()

        cur.execute("""
            SELECT id_usuario, nombre, email, rol
            FROM usuario
            WHERE nombre ILIKE %s OR email ILIKE %s OR rol ILIKE %s
            ORDER BY nombre
            LIMIT 20
        """, (term, term, term))
        usuarios = cur.fetchall()

        cur.close()
        conn.close()

    total = len(proyectos) + len(tareas) + len(usuarios)
    return render_template('buscar.html', q=q, proyectos=proyectos,
                           tareas=tareas, usuarios=usuarios, total=total)


if __name__ == '__main__':
    app.run(debug=True, port=5000)