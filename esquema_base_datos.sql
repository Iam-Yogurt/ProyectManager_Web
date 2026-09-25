--
-- PostgreSQL database dump
--


-- Dumped from database version 18.6 (6569466)
-- Dumped by pg_dump version 18.6 (Ubuntu 18.6-0ubuntu0.26.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: fn_calcular_avance_proyecto(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_calcular_avance_proyecto(p_id_proyecto integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total_tareas INT;
    v_tareas_completadas INT;
BEGIN
    SELECT COUNT(*) INTO v_total_tareas 
    FROM TAREA 
    WHERE id_proyecto = p_id_proyecto;

    IF v_total_tareas = 0 THEN
        RETURN 0.00;
    END IF;

    SELECT COUNT(*) INTO v_tareas_completadas 
    FROM TAREA 
    WHERE id_proyecto = p_id_proyecto AND estado = 'completada';

    RETURN ROUND((v_tareas_completadas::NUMERIC / v_total_tareas) * 100, 2);
END;
$$;


--
-- Name: fn_log_cambio_estado_tarea(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_log_cambio_estado_tarea() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF OLD.estado IS DISTINCT FROM NEW.estado THEN
        INSERT INTO HISTORIAL_CAMBIO (id_tarea, id_usuario, estado_anterior, estado_nuevo)
        VALUES (NEW.id_tarea, NEW.id_usuario_asignado, OLD.estado, NEW.estado);
    END IF;
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: cliente; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cliente (
    id_cliente integer NOT NULL,
    nombre_empresa character varying(100) NOT NULL,
    persona_contacto character varying(100),
    email_contacto character varying(100),
    telefono character varying(20)
);


--
-- Name: cliente_id_cliente_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cliente_id_cliente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cliente_id_cliente_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cliente_id_cliente_seq OWNED BY public.cliente.id_cliente;


--
-- Name: comentario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comentario (
    id_comentario integer NOT NULL,
    id_tarea integer NOT NULL,
    id_usuario integer NOT NULL,
    contenido text NOT NULL,
    fecha_hora timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: comentario_id_comentario_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comentario_id_comentario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comentario_id_comentario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comentario_id_comentario_seq OWNED BY public.comentario.id_comentario;


--
-- Name: config_notificacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.config_notificacion (
    id_config integer NOT NULL,
    id_usuario integer NOT NULL,
    recibir_emails boolean DEFAULT true,
    alerta_vencimiento boolean DEFAULT true
);


--
-- Name: config_notificacion_id_config_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.config_notificacion_id_config_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: config_notificacion_id_config_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.config_notificacion_id_config_seq OWNED BY public.config_notificacion.id_config;


--
-- Name: dependencia_tarea; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dependencia_tarea (
    id_dependencia integer NOT NULL,
    id_tarea_principal integer NOT NULL,
    id_tarea_dependiente integer NOT NULL,
    CONSTRAINT dependencia_tarea_check CHECK ((id_tarea_principal <> id_tarea_dependiente))
);


--
-- Name: dependencia_tarea_id_dependencia_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dependencia_tarea_id_dependencia_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dependencia_tarea_id_dependencia_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dependencia_tarea_id_dependencia_seq OWNED BY public.dependencia_tarea.id_dependencia;


--
-- Name: equipo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.equipo (
    id_equipo integer NOT NULL,
    nombre_equipo character varying(50) NOT NULL,
    descripcion text
);


--
-- Name: equipo_id_equipo_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.equipo_id_equipo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: equipo_id_equipo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.equipo_id_equipo_seq OWNED BY public.equipo.id_equipo;


--
-- Name: habilidad; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.habilidad (
    id_habilidad integer NOT NULL,
    nombre_habilidad character varying(50) NOT NULL
);


--
-- Name: habilidad_id_habilidad_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.habilidad_id_habilidad_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: habilidad_id_habilidad_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.habilidad_id_habilidad_seq OWNED BY public.habilidad.id_habilidad;


--
-- Name: habilidad_usuario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.habilidad_usuario (
    id_habilidad_usuario integer NOT NULL,
    id_usuario integer,
    id_habilidad integer
);


--
-- Name: habilidad_usuario_id_habilidad_usuario_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.habilidad_usuario_id_habilidad_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: habilidad_usuario_id_habilidad_usuario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.habilidad_usuario_id_habilidad_usuario_seq OWNED BY public.habilidad_usuario.id_habilidad_usuario;


--
-- Name: historial_cambio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.historial_cambio (
    id_historial integer NOT NULL,
    id_tarea integer NOT NULL,
    id_usuario integer,
    estado_anterior character varying(15),
    estado_nuevo character varying(15) NOT NULL,
    fecha_cambio timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: historial_cambio_id_historial_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.historial_cambio_id_historial_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: historial_cambio_id_historial_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.historial_cambio_id_historial_seq OWNED BY public.historial_cambio.id_historial;


--
-- Name: hito; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hito (
    id_hito integer NOT NULL,
    id_proyecto integer NOT NULL,
    nombre_hito character varying(100) NOT NULL,
    fecha_objetivo date NOT NULL,
    alcanzado boolean DEFAULT false
);


--
-- Name: hito_id_hito_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hito_id_hito_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hito_id_hito_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hito_id_hito_seq OWNED BY public.hito.id_hito;


--
-- Name: notificacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notificacion (
    id_notificacion integer NOT NULL,
    id_usuario integer NOT NULL,
    mensaje text NOT NULL,
    fecha_envio timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    leida boolean DEFAULT false
);


--
-- Name: notificacion_id_notificacion_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notificacion_id_notificacion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notificacion_id_notificacion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notificacion_id_notificacion_seq OWNED BY public.notificacion.id_notificacion;


--
-- Name: proyecto; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.proyecto (
    id_proyecto integer NOT NULL,
    id_cliente integer NOT NULL,
    id_lider integer NOT NULL,
    nombre_proyecto character varying(100) NOT NULL,
    descripcion text,
    fecha_inicio date NOT NULL,
    fecha_fin_estimada date NOT NULL,
    fecha_fin_real date,
    presupuesto_total numeric(12,2) NOT NULL,
    estado character varying(20) DEFAULT 'planificacion'::character varying NOT NULL,
    CONSTRAINT proyecto_estado_check CHECK (((estado)::text = ANY (ARRAY[('planificacion'::character varying)::text, ('en_desarrollo'::character varying)::text, ('pruebas'::character varying)::text, ('finalizado'::character varying)::text, ('cancelado'::character varying)::text]))),
    CONSTRAINT proyecto_presupuesto_total_check CHECK ((presupuesto_total > (0)::numeric))
);


--
-- Name: proyecto_id_proyecto_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.proyecto_id_proyecto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: proyecto_id_proyecto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.proyecto_id_proyecto_seq OWNED BY public.proyecto.id_proyecto;


--
-- Name: tarea; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tarea (
    id_tarea integer NOT NULL,
    id_proyecto integer NOT NULL,
    id_hito integer,
    id_usuario_asignado integer,
    nombre_tarea character varying(150) NOT NULL,
    descripcion text,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_vencimiento timestamp without time zone NOT NULL,
    prioridad character varying(10) DEFAULT 'media'::character varying NOT NULL,
    estado character varying(15) DEFAULT 'pendiente'::character varying NOT NULL,
    tiempo_estimado_horas numeric(6,2) NOT NULL,
    tiempo_real_horas numeric(6,2) DEFAULT 0.00,
    CONSTRAINT tarea_estado_check CHECK (((estado)::text = ANY (ARRAY[('pendiente'::character varying)::text, ('en_progreso'::character varying)::text, ('completada'::character varying)::text, ('bloqueada'::character varying)::text]))),
    CONSTRAINT tarea_prioridad_check CHECK (((prioridad)::text = ANY (ARRAY[('baja'::character varying)::text, ('media'::character varying)::text, ('alta'::character varying)::text]))),
    CONSTRAINT tarea_tiempo_estimado_horas_check CHECK ((tiempo_estimado_horas >= (0)::numeric)),
    CONSTRAINT tarea_tiempo_real_horas_check CHECK ((tiempo_real_horas >= (0)::numeric))
);


--
-- Name: tarea_id_tarea_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tarea_id_tarea_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tarea_id_tarea_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tarea_id_tarea_seq OWNED BY public.tarea.id_tarea;


--
-- Name: usuario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuario (
    id_usuario integer NOT NULL,
    id_equipo integer,
    nombre character varying(100) NOT NULL,
    email character varying(100) NOT NULL,
    rol character varying(30) NOT NULL,
    costo_hora numeric(10,2) DEFAULT 0.00 NOT NULL,
    activo boolean DEFAULT true,
    CONSTRAINT usuario_costo_hora_check CHECK ((costo_hora >= (0)::numeric)),
    CONSTRAINT usuario_rol_check CHECK (((rol)::text = ANY (ARRAY[('desarrollador'::character varying)::text, ('diseñador'::character varying)::text, ('analista'::character varying)::text, ('líder_proyecto'::character varying)::text, ('administrador'::character varying)::text])))
);


--
-- Name: usuario_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usuario_id_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usuario_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usuario_id_usuario_seq OWNED BY public.usuario.id_usuario;


--
-- Name: vw_carga_usuarios; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_carga_usuarios AS
 SELECT u.id_usuario,
    u.nombre,
    u.rol,
    eq.nombre_equipo,
    count(t.id_tarea) FILTER (WHERE ((t.estado)::text = 'en_progreso'::text)) AS tareas_en_progreso,
    count(t.id_tarea) FILTER (WHERE ((t.estado)::text = 'pendiente'::text)) AS tareas_pendientes,
    COALESCE(sum(t.tiempo_estimado_horas) FILTER (WHERE ((t.estado)::text = ANY (ARRAY[('en_progreso'::character varying)::text, ('pendiente'::character varying)::text]))), (0)::numeric) AS horas_estimadas_pendientes
   FROM ((public.usuario u
     LEFT JOIN public.equipo eq ON ((u.id_equipo = eq.id_equipo)))
     LEFT JOIN public.tarea t ON ((u.id_usuario = t.id_usuario_asignado)))
  GROUP BY u.id_usuario, u.nombre, u.rol, eq.nombre_equipo;


--
-- Name: vw_presupuesto_proyecto; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_presupuesto_proyecto AS
 SELECT p.id_proyecto,
    p.nombre_proyecto,
    p.presupuesto_total,
    COALESCE(sum((t.tiempo_real_horas * u.costo_hora)), (0)::numeric) AS presupuesto_consumido,
    round(((COALESCE(sum((t.tiempo_real_horas * u.costo_hora)), (0)::numeric) / p.presupuesto_total) * (100)::numeric), 2) AS porcentaje_consumido
   FROM ((public.proyecto p
     LEFT JOIN public.tarea t ON ((p.id_proyecto = t.id_proyecto)))
     LEFT JOIN public.usuario u ON ((t.id_usuario_asignado = u.id_usuario)))
  GROUP BY p.id_proyecto, p.nombre_proyecto, p.presupuesto_total;


--
-- Name: vw_proyectos_en_riesgo; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_proyectos_en_riesgo AS
 WITH estadisticas_tareas AS (
         SELECT tarea.id_proyecto,
            count(*) AS total_tareas,
            count(*) FILTER (WHERE ((tarea.fecha_vencimiento < CURRENT_TIMESTAMP) AND ((tarea.estado)::text <> 'completada'::text))) AS tareas_vencidas
           FROM public.tarea
          GROUP BY tarea.id_proyecto
        )
 SELECT p.id_proyecto,
    p.nombre_proyecto,
    p.estado AS estado_proyecto,
    vp.presupuesto_total,
    vp.presupuesto_consumido,
    COALESCE(et.total_tareas, (0)::bigint) AS total_tareas,
    COALESCE(et.tareas_vencidas, (0)::bigint) AS tareas_vencidas,
        CASE
            WHEN (et.total_tareas > 0) THEN round((((et.tareas_vencidas)::numeric / (et.total_tareas)::numeric) * (100)::numeric), 2)
            ELSE (0)::numeric
        END AS porcentaje_tareas_vencidas,
        CASE
            WHEN (((et.total_tareas > 0) AND (((et.tareas_vencidas)::numeric / (et.total_tareas)::numeric) >= 0.50)) OR (vp.presupuesto_consumido > vp.presupuesto_total)) THEN true
            ELSE false
        END AS en_riesgo
   FROM ((public.proyecto p
     LEFT JOIN public.vw_presupuesto_proyecto vp ON ((p.id_proyecto = vp.id_proyecto)))
     LEFT JOIN estadisticas_tareas et ON ((p.id_proyecto = et.id_proyecto)));


--
-- Name: cliente id_cliente; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente ALTER COLUMN id_cliente SET DEFAULT nextval('public.cliente_id_cliente_seq'::regclass);


--
-- Name: comentario id_comentario; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comentario ALTER COLUMN id_comentario SET DEFAULT nextval('public.comentario_id_comentario_seq'::regclass);


--
-- Name: config_notificacion id_config; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.config_notificacion ALTER COLUMN id_config SET DEFAULT nextval('public.config_notificacion_id_config_seq'::regclass);


--
-- Name: dependencia_tarea id_dependencia; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dependencia_tarea ALTER COLUMN id_dependencia SET DEFAULT nextval('public.dependencia_tarea_id_dependencia_seq'::regclass);


--
-- Name: equipo id_equipo; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipo ALTER COLUMN id_equipo SET DEFAULT nextval('public.equipo_id_equipo_seq'::regclass);


--
-- Name: habilidad id_habilidad; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.habilidad ALTER COLUMN id_habilidad SET DEFAULT nextval('public.habilidad_id_habilidad_seq'::regclass);


--
-- Name: habilidad_usuario id_habilidad_usuario; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.habilidad_usuario ALTER COLUMN id_habilidad_usuario SET DEFAULT nextval('public.habilidad_usuario_id_habilidad_usuario_seq'::regclass);


--
-- Name: historial_cambio id_historial; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historial_cambio ALTER COLUMN id_historial SET DEFAULT nextval('public.historial_cambio_id_historial_seq'::regclass);


--
-- Name: hito id_hito; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hito ALTER COLUMN id_hito SET DEFAULT nextval('public.hito_id_hito_seq'::regclass);


--
-- Name: notificacion id_notificacion; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notificacion ALTER COLUMN id_notificacion SET DEFAULT nextval('public.notificacion_id_notificacion_seq'::regclass);


--
-- Name: proyecto id_proyecto; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proyecto ALTER COLUMN id_proyecto SET DEFAULT nextval('public.proyecto_id_proyecto_seq'::regclass);


--
-- Name: tarea id_tarea; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tarea ALTER COLUMN id_tarea SET DEFAULT nextval('public.tarea_id_tarea_seq'::regclass);


--
-- Name: usuario id_usuario; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario ALTER COLUMN id_usuario SET DEFAULT nextval('public.usuario_id_usuario_seq'::regclass);


--
-- Data for Name: cliente; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.cliente VALUES (1, 'TechSolutions C.A.', 'Carlos Mendoza', 'cmendoza@techsolutions.com', '+584141234567');
INSERT INTO public.cliente VALUES (2, 'Banco Global', 'Mariana López', 'mlopez@bancoglobal.com', '+584129876543');
INSERT INTO public.cliente VALUES (3, 'Logística Express', 'Roberto Gómez', 'rgomez@logisticaexp.com', '+584165554433');


--
-- Data for Name: comentario; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.comentario VALUES (1, 1, 4, 'Maquetas completadas y aprobadas por el cliente.', '2026-09-23 09:57:06.558408');
INSERT INTO public.comentario VALUES (2, 2, 3, 'Estructura de tablas DDL ejecutada con éxito en el servidor de pruebas.', '2026-09-23 09:57:06.558408');
INSERT INTO public.comentario VALUES (3, 5, 5, 'Esperando credenciales de acceso para entorno de pruebas.', '2026-09-23 09:57:06.558408');


--
-- Data for Name: config_notificacion; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.config_notificacion VALUES (1, 1, true, true);
INSERT INTO public.config_notificacion VALUES (2, 2, true, true);
INSERT INTO public.config_notificacion VALUES (3, 3, true, true);
INSERT INTO public.config_notificacion VALUES (4, 4, false, true);
INSERT INTO public.config_notificacion VALUES (5, 5, true, false);
INSERT INTO public.config_notificacion VALUES (6, 6, true, true);


--
-- Data for Name: dependencia_tarea; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.dependencia_tarea VALUES (1, 2, 3);
INSERT INTO public.dependencia_tarea VALUES (2, 2, 4);


--
-- Data for Name: equipo; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.equipo VALUES (1, 'Frontend', 'Desarrollo de interfaces de usuario y experiencia cliente');
INSERT INTO public.equipo VALUES (2, 'Backend', 'Desarrollo de APIs, lógica de negocio y arquitectura de datos');
INSERT INTO public.equipo VALUES (3, 'QA / Pruebas', 'Aseguramiento de calidad, pruebas unitarias e integración');
INSERT INTO public.equipo VALUES (4, 'Diseño UX/UI', 'Diseño visual, maquetación y prototipado');


--
-- Data for Name: habilidad; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.habilidad VALUES (1, 'React');
INSERT INTO public.habilidad VALUES (2, 'PostgreSQL');
INSERT INTO public.habilidad VALUES (3, 'Python');
INSERT INTO public.habilidad VALUES (4, 'Java');
INSERT INTO public.habilidad VALUES (5, 'Figma');
INSERT INTO public.habilidad VALUES (6, 'QA Automation');
INSERT INTO public.habilidad VALUES (7, 'Docker');


--
-- Data for Name: habilidad_usuario; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.habilidad_usuario VALUES (1, 1, 2);
INSERT INTO public.habilidad_usuario VALUES (2, 1, 3);
INSERT INTO public.habilidad_usuario VALUES (3, 2, 1);
INSERT INTO public.habilidad_usuario VALUES (4, 3, 2);
INSERT INTO public.habilidad_usuario VALUES (5, 3, 4);
INSERT INTO public.habilidad_usuario VALUES (6, 4, 5);
INSERT INTO public.habilidad_usuario VALUES (7, 5, 6);


--
-- Data for Name: historial_cambio; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.historial_cambio VALUES (1, 1, 4, 'en_progreso', 'completada', '2026-09-23 09:57:06.561214');
INSERT INTO public.historial_cambio VALUES (2, 2, 3, 'en_progreso', 'completada', '2026-09-23 09:57:06.561214');
INSERT INTO public.historial_cambio VALUES (3, 5, 5, 'pendiente', 'bloqueada', '2026-09-23 09:57:06.561214');
INSERT INTO public.historial_cambio VALUES (4, 3, 2, 'en_progreso', 'completada', '2026-09-23 10:06:05.170675');
INSERT INTO public.historial_cambio VALUES (5, 1, 4, 'completada', 'en_progreso', '2026-09-23 11:33:34.439739');


--
-- Data for Name: hito; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.hito VALUES (1, 1, 'Aprobación de Prototipos UX', '2026-02-15', true);
INSERT INTO public.hito VALUES (2, 1, 'Lanzamiento Alfa / Backend listo', '2026-04-30', false);
INSERT INTO public.hito VALUES (3, 2, 'Integración de API de Pagos', '2026-03-31', false);


--
-- Data for Name: notificacion; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.notificacion VALUES (1, 1, 'El proyecto Sistema ERP Web ha completado el Hito 1.', '2026-09-23 09:57:06.56362', true);
INSERT INTO public.notificacion VALUES (2, 5, 'La tarea Pruebas de Seguridad API se encuentra bloqueada.', '2026-09-23 09:57:06.56362', false);


--
-- Data for Name: proyecto; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.proyecto VALUES (1, 1, 1, 'Sistema ERP Web', 'Desarrollo de sistema web de gestión de recursos empresariales', '2026-01-15', '2026-06-30', NULL, 15000.00, 'en_desarrollo');
INSERT INTO public.proyecto VALUES (2, 2, 1, 'App Banca Móvil', 'Rediseño e integración de API para aplicación bancaria', '2026-02-01', '2026-05-15', NULL, 20000.00, 'en_desarrollo');
INSERT INTO public.proyecto VALUES (3, 3, 1, 'Migración de Base de Datos', 'Migración de datos antiguos hacia esquema optimizado PostgreSQL', '2026-03-01', '2026-04-15', NULL, 5000.00, 'planificacion');
INSERT INTO public.proyecto VALUES (4, 1, 1, 'Sistema Movil', NULL, '2026-10-01', '2026-12-31', NULL, 5000.00, 'planificacion');


--
-- Data for Name: tarea; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tarea VALUES (2, 1, 2, 3, 'Crear Tablas PostgreSQL', 'Implementación de scripts DDL y triggers base', '2026-09-23 09:56:43.920483', '2026-03-05 18:00:00', 'alta', 'completada', 15.00, 14.00);
INSERT INTO public.tarea VALUES (4, 1, 2, 3, 'API Endpoint Usuarios', 'Endpoints REST para CRUD de usuarios', '2026-09-23 09:56:43.920483', '2026-03-12 18:00:00', 'alta', 'en_progreso', 12.00, 8.00);
INSERT INTO public.tarea VALUES (5, 2, 3, 5, 'Pruebas de Seguridad API', 'Pruebas de penetración y rendimiento', '2026-09-23 09:56:43.920483', '2026-03-01 18:00:00', 'alta', 'bloqueada', 25.00, 5.00);
INSERT INTO public.tarea VALUES (1, 1, 1, 4, 'Diseñar Maquetas UI', 'Diseño de pantallas principales en Figma', '2026-09-23 09:56:43.920483', '2026-02-10 18:00:00', 'alta', 'en_progreso', 20.00, 10.00);
INSERT INTO public.tarea VALUES (3, 1, 2, 2, 'Desarrollar Login Frontend', 'Pantalla de autenticación y consumo de JWT', '2026-09-23 09:56:43.920483', '2026-03-10 18:00:00', 'media', 'completada', 10.00, 15.00);


--
-- Data for Name: usuario; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.usuario VALUES (1, 1, 'Angel Aguilera', 'angel@empresa.com', 'líder_proyecto', 25.00, true);
INSERT INTO public.usuario VALUES (2, 1, 'María Pérez', 'maria@empresa.com', 'desarrollador', 18.00, true);
INSERT INTO public.usuario VALUES (3, 2, 'José Rodríguez', 'jose@empresa.com', 'desarrollador', 20.00, true);
INSERT INTO public.usuario VALUES (4, 4, 'Sofia Gómez', 'sofia@empresa.com', 'diseñador', 15.00, true);
INSERT INTO public.usuario VALUES (5, 3, 'Luis Fernández', 'luis@empresa.com', 'analista', 16.00, true);
INSERT INTO public.usuario VALUES (6, 3, 'Elena Torres', 'elena@empresa.com', 'administrador', 30.00, true);


--
-- Name: cliente_id_cliente_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.cliente_id_cliente_seq', 3, true);


--
-- Name: comentario_id_comentario_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.comentario_id_comentario_seq', 3, true);


--
-- Name: config_notificacion_id_config_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.config_notificacion_id_config_seq', 6, true);


--
-- Name: dependencia_tarea_id_dependencia_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.dependencia_tarea_id_dependencia_seq', 2, true);


--
-- Name: equipo_id_equipo_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.equipo_id_equipo_seq', 4, true);


--
-- Name: habilidad_id_habilidad_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.habilidad_id_habilidad_seq', 7, true);


--
-- Name: habilidad_usuario_id_habilidad_usuario_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.habilidad_usuario_id_habilidad_usuario_seq', 7, true);


--
-- Name: historial_cambio_id_historial_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.historial_cambio_id_historial_seq', 5, true);


--
-- Name: hito_id_hito_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.hito_id_hito_seq', 3, true);


--
-- Name: notificacion_id_notificacion_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.notificacion_id_notificacion_seq', 2, true);


--
-- Name: proyecto_id_proyecto_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.proyecto_id_proyecto_seq', 4, true);


--
-- Name: tarea_id_tarea_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tarea_id_tarea_seq', 5, true);


--
-- Name: usuario_id_usuario_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.usuario_id_usuario_seq', 6, true);


--
-- Name: cliente cliente_email_contacto_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_email_contacto_key UNIQUE (email_contacto);


--
-- Name: cliente cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_pkey PRIMARY KEY (id_cliente);


--
-- Name: comentario comentario_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comentario
    ADD CONSTRAINT comentario_pkey PRIMARY KEY (id_comentario);


--
-- Name: config_notificacion config_notificacion_id_usuario_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.config_notificacion
    ADD CONSTRAINT config_notificacion_id_usuario_key UNIQUE (id_usuario);


--
-- Name: config_notificacion config_notificacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.config_notificacion
    ADD CONSTRAINT config_notificacion_pkey PRIMARY KEY (id_config);


--
-- Name: dependencia_tarea dependencia_tarea_id_tarea_principal_id_tarea_dependiente_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dependencia_tarea
    ADD CONSTRAINT dependencia_tarea_id_tarea_principal_id_tarea_dependiente_key UNIQUE (id_tarea_principal, id_tarea_dependiente);


--
-- Name: dependencia_tarea dependencia_tarea_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dependencia_tarea
    ADD CONSTRAINT dependencia_tarea_pkey PRIMARY KEY (id_dependencia);


--
-- Name: equipo equipo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipo
    ADD CONSTRAINT equipo_pkey PRIMARY KEY (id_equipo);


--
-- Name: habilidad habilidad_nombre_habilidad_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.habilidad
    ADD CONSTRAINT habilidad_nombre_habilidad_key UNIQUE (nombre_habilidad);


--
-- Name: habilidad habilidad_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.habilidad
    ADD CONSTRAINT habilidad_pkey PRIMARY KEY (id_habilidad);


--
-- Name: habilidad_usuario habilidad_usuario_id_usuario_id_habilidad_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.habilidad_usuario
    ADD CONSTRAINT habilidad_usuario_id_usuario_id_habilidad_key UNIQUE (id_usuario, id_habilidad);


--
-- Name: habilidad_usuario habilidad_usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.habilidad_usuario
    ADD CONSTRAINT habilidad_usuario_pkey PRIMARY KEY (id_habilidad_usuario);


--
-- Name: historial_cambio historial_cambio_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historial_cambio
    ADD CONSTRAINT historial_cambio_pkey PRIMARY KEY (id_historial);


--
-- Name: hito hito_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hito
    ADD CONSTRAINT hito_pkey PRIMARY KEY (id_hito);


--
-- Name: notificacion notificacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notificacion
    ADD CONSTRAINT notificacion_pkey PRIMARY KEY (id_notificacion);


--
-- Name: proyecto proyecto_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proyecto
    ADD CONSTRAINT proyecto_pkey PRIMARY KEY (id_proyecto);


--
-- Name: tarea tarea_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tarea
    ADD CONSTRAINT tarea_pkey PRIMARY KEY (id_tarea);


--
-- Name: usuario usuario_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_email_key UNIQUE (email);


--
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id_usuario);


--
-- Name: tarea trg_bitacora_tarea; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_bitacora_tarea AFTER UPDATE ON public.tarea FOR EACH ROW EXECUTE FUNCTION public.fn_log_cambio_estado_tarea();


--
-- Name: comentario comentario_id_tarea_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comentario
    ADD CONSTRAINT comentario_id_tarea_fkey FOREIGN KEY (id_tarea) REFERENCES public.tarea(id_tarea) ON DELETE CASCADE;


--
-- Name: comentario comentario_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comentario
    ADD CONSTRAINT comentario_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario) ON DELETE CASCADE;


--
-- Name: config_notificacion config_notificacion_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.config_notificacion
    ADD CONSTRAINT config_notificacion_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario) ON DELETE CASCADE;


--
-- Name: dependencia_tarea dependencia_tarea_id_tarea_dependiente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dependencia_tarea
    ADD CONSTRAINT dependencia_tarea_id_tarea_dependiente_fkey FOREIGN KEY (id_tarea_dependiente) REFERENCES public.tarea(id_tarea) ON DELETE CASCADE;


--
-- Name: dependencia_tarea dependencia_tarea_id_tarea_principal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dependencia_tarea
    ADD CONSTRAINT dependencia_tarea_id_tarea_principal_fkey FOREIGN KEY (id_tarea_principal) REFERENCES public.tarea(id_tarea) ON DELETE CASCADE;


--
-- Name: habilidad_usuario habilidad_usuario_id_habilidad_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.habilidad_usuario
    ADD CONSTRAINT habilidad_usuario_id_habilidad_fkey FOREIGN KEY (id_habilidad) REFERENCES public.habilidad(id_habilidad) ON DELETE CASCADE;


--
-- Name: habilidad_usuario habilidad_usuario_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.habilidad_usuario
    ADD CONSTRAINT habilidad_usuario_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario) ON DELETE CASCADE;


--
-- Name: historial_cambio historial_cambio_id_tarea_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historial_cambio
    ADD CONSTRAINT historial_cambio_id_tarea_fkey FOREIGN KEY (id_tarea) REFERENCES public.tarea(id_tarea) ON DELETE CASCADE;


--
-- Name: historial_cambio historial_cambio_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historial_cambio
    ADD CONSTRAINT historial_cambio_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- Name: hito hito_id_proyecto_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hito
    ADD CONSTRAINT hito_id_proyecto_fkey FOREIGN KEY (id_proyecto) REFERENCES public.proyecto(id_proyecto) ON DELETE CASCADE;


--
-- Name: notificacion notificacion_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notificacion
    ADD CONSTRAINT notificacion_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario) ON DELETE CASCADE;


--
-- Name: proyecto proyecto_id_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proyecto
    ADD CONSTRAINT proyecto_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.cliente(id_cliente) ON DELETE RESTRICT;


--
-- Name: proyecto proyecto_id_lider_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proyecto
    ADD CONSTRAINT proyecto_id_lider_fkey FOREIGN KEY (id_lider) REFERENCES public.usuario(id_usuario) ON DELETE RESTRICT;


--
-- Name: tarea tarea_id_hito_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tarea
    ADD CONSTRAINT tarea_id_hito_fkey FOREIGN KEY (id_hito) REFERENCES public.hito(id_hito) ON DELETE SET NULL;


--
-- Name: tarea tarea_id_proyecto_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tarea
    ADD CONSTRAINT tarea_id_proyecto_fkey FOREIGN KEY (id_proyecto) REFERENCES public.proyecto(id_proyecto) ON DELETE CASCADE;


--
-- Name: tarea tarea_id_usuario_asignado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tarea
    ADD CONSTRAINT tarea_id_usuario_asignado_fkey FOREIGN KEY (id_usuario_asignado) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- Name: usuario usuario_id_equipo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_id_equipo_fkey FOREIGN KEY (id_equipo) REFERENCES public.equipo(id_equipo) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--


