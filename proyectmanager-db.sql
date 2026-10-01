--
-- PostgreSQL database dump
--

\restrict uuNg7fa6l1ryDywauFsubD1xPCBSFWafUerTw8PK0GA5QoQKsNklnTuAV2riljo

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

-- Started on 2026-10-01 11:39:26

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 249 (class 1255 OID 18956)
-- Name: fn_calcular_avance_proyecto(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_calcular_avance_proyecto(p_id_proyecto integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE v_total_tareas INT; v_tareas_completadas INT;
BEGIN
    SELECT COUNT(*) INTO v_total_tareas FROM TAREA WHERE id_proyecto = p_id_proyecto;
    IF v_total_tareas = 0 THEN RETURN 0.00; END IF;
    SELECT COUNT(*) INTO v_tareas_completadas FROM TAREA WHERE id_proyecto = p_id_proyecto AND estado = 'completada';
    RETURN ROUND((v_tareas_completadas::NUMERIC / v_total_tareas) * 100, 2);
END; $$;


ALTER FUNCTION public.fn_calcular_avance_proyecto(p_id_proyecto integer) OWNER TO postgres;

--
-- TOC entry 248 (class 1255 OID 18957)
-- Name: fn_log_cambio_estado_tarea(); Type: FUNCTION; Schema: public; Owner: postgres
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
END; $$;


ALTER FUNCTION public.fn_log_cambio_estado_tarea() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 220 (class 1259 OID 22805)
-- Name: cliente; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cliente (
    id_cliente integer NOT NULL,
    nombre_empresa character varying(100) NOT NULL,
    persona_contacto character varying(100),
    email_contacto character varying(100),
    telefono character varying(20)
);


ALTER TABLE public.cliente OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 22804)
-- Name: cliente_id_cliente_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cliente_id_cliente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cliente_id_cliente_seq OWNER TO postgres;

--
-- TOC entry 5100 (class 0 OID 0)
-- Dependencies: 219
-- Name: cliente_id_cliente_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cliente_id_cliente_seq OWNED BY public.cliente.id_cliente;


--
-- TOC entry 232 (class 1259 OID 22936)
-- Name: comentario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comentario (
    id_comentario integer NOT NULL,
    id_tarea integer,
    id_usuario integer,
    contenido text NOT NULL,
    fecha_hora timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.comentario OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 22935)
-- Name: comentario_id_comentario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.comentario_id_comentario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.comentario_id_comentario_seq OWNER TO postgres;

--
-- TOC entry 5101 (class 0 OID 0)
-- Dependencies: 231
-- Name: comentario_id_comentario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.comentario_id_comentario_seq OWNED BY public.comentario.id_comentario;


--
-- TOC entry 234 (class 1259 OID 22958)
-- Name: config_notificacion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.config_notificacion (
    id_config integer NOT NULL,
    id_usuario integer,
    recibir_emails boolean DEFAULT true,
    alerta_vencimiento boolean DEFAULT true
);


ALTER TABLE public.config_notificacion OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 22957)
-- Name: config_notificacion_id_config_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.config_notificacion_id_config_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.config_notificacion_id_config_seq OWNER TO postgres;

--
-- TOC entry 5102 (class 0 OID 0)
-- Dependencies: 233
-- Name: config_notificacion_id_config_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.config_notificacion_id_config_seq OWNED BY public.config_notificacion.id_config;


--
-- TOC entry 236 (class 1259 OID 22975)
-- Name: dependencia_tarea; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dependencia_tarea (
    id_dependencia integer NOT NULL,
    id_tarea_principal integer,
    id_tarea_dependiente integer,
    CONSTRAINT dependencia_tarea_check CHECK ((id_tarea_principal <> id_tarea_dependiente))
);


ALTER TABLE public.dependencia_tarea OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 22974)
-- Name: dependencia_tarea_id_dependencia_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dependencia_tarea_id_dependencia_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dependencia_tarea_id_dependencia_seq OWNER TO postgres;

--
-- TOC entry 5103 (class 0 OID 0)
-- Dependencies: 235
-- Name: dependencia_tarea_id_dependencia_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dependencia_tarea_id_dependencia_seq OWNED BY public.dependencia_tarea.id_dependencia;


--
-- TOC entry 222 (class 1259 OID 22816)
-- Name: equipo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.equipo (
    id_equipo integer NOT NULL,
    nombre_equipo character varying(50) NOT NULL,
    descripcion text
);


ALTER TABLE public.equipo OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 22815)
-- Name: equipo_id_equipo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.equipo_id_equipo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.equipo_id_equipo_seq OWNER TO postgres;

--
-- TOC entry 5104 (class 0 OID 0)
-- Dependencies: 221
-- Name: equipo_id_equipo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.equipo_id_equipo_seq OWNED BY public.equipo.id_equipo;


--
-- TOC entry 238 (class 1259 OID 22994)
-- Name: habilidad; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.habilidad (
    id_habilidad integer NOT NULL,
    nombre_habilidad character varying(50) NOT NULL
);


ALTER TABLE public.habilidad OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 22993)
-- Name: habilidad_id_habilidad_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.habilidad_id_habilidad_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.habilidad_id_habilidad_seq OWNER TO postgres;

--
-- TOC entry 5105 (class 0 OID 0)
-- Dependencies: 237
-- Name: habilidad_id_habilidad_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.habilidad_id_habilidad_seq OWNED BY public.habilidad.id_habilidad;


--
-- TOC entry 240 (class 1259 OID 23005)
-- Name: habilidad_usuario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.habilidad_usuario (
    id_habilidad_usuario integer NOT NULL,
    id_usuario integer,
    id_habilidad integer
);


ALTER TABLE public.habilidad_usuario OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 23004)
-- Name: habilidad_usuario_id_habilidad_usuario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.habilidad_usuario_id_habilidad_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.habilidad_usuario_id_habilidad_usuario_seq OWNER TO postgres;

--
-- TOC entry 5106 (class 0 OID 0)
-- Dependencies: 239
-- Name: habilidad_usuario_id_habilidad_usuario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.habilidad_usuario_id_habilidad_usuario_seq OWNED BY public.habilidad_usuario.id_habilidad_usuario;


--
-- TOC entry 242 (class 1259 OID 23025)
-- Name: historial_cambio; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.historial_cambio (
    id_historial integer NOT NULL,
    id_tarea integer,
    id_usuario integer,
    estado_anterior character varying(15),
    estado_nuevo character varying(15) NOT NULL,
    fecha_cambio timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.historial_cambio OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 23024)
-- Name: historial_cambio_id_historial_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.historial_cambio_id_historial_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.historial_cambio_id_historial_seq OWNER TO postgres;

--
-- TOC entry 5107 (class 0 OID 0)
-- Dependencies: 241
-- Name: historial_cambio_id_historial_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.historial_cambio_id_historial_seq OWNED BY public.historial_cambio.id_historial;


--
-- TOC entry 228 (class 1259 OID 22882)
-- Name: hito; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.hito (
    id_hito integer NOT NULL,
    id_proyecto integer,
    nombre_hito character varying(100) NOT NULL,
    fecha_objetivo date NOT NULL,
    alcanzado boolean DEFAULT false
);


ALTER TABLE public.hito OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 22881)
-- Name: hito_id_hito_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.hito_id_hito_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.hito_id_hito_seq OWNER TO postgres;

--
-- TOC entry 5108 (class 0 OID 0)
-- Dependencies: 227
-- Name: hito_id_hito_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.hito_id_hito_seq OWNED BY public.hito.id_hito;


--
-- TOC entry 244 (class 1259 OID 23045)
-- Name: notificacion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notificacion (
    id_notificacion integer NOT NULL,
    id_usuario integer,
    mensaje text NOT NULL,
    fecha_envio timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    leida boolean DEFAULT false
);


ALTER TABLE public.notificacion OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 23044)
-- Name: notificacion_id_notificacion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notificacion_id_notificacion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notificacion_id_notificacion_seq OWNER TO postgres;

--
-- TOC entry 5109 (class 0 OID 0)
-- Dependencies: 243
-- Name: notificacion_id_notificacion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notificacion_id_notificacion_seq OWNED BY public.notificacion.id_notificacion;


--
-- TOC entry 226 (class 1259 OID 22852)
-- Name: proyecto; Type: TABLE; Schema: public; Owner: postgres
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
    CONSTRAINT proyecto_estado_check CHECK (((estado)::text = ANY ((ARRAY['planificacion'::character varying, 'en_desarrollo'::character varying, 'pruebas'::character varying, 'finalizado'::character varying, 'cancelado'::character varying])::text[]))),
    CONSTRAINT proyecto_presupuesto_total_check CHECK ((presupuesto_total > (0)::numeric))
);


ALTER TABLE public.proyecto OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 22851)
-- Name: proyecto_id_proyecto_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.proyecto_id_proyecto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.proyecto_id_proyecto_seq OWNER TO postgres;

--
-- TOC entry 5110 (class 0 OID 0)
-- Dependencies: 225
-- Name: proyecto_id_proyecto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.proyecto_id_proyecto_seq OWNED BY public.proyecto.id_proyecto;


--
-- TOC entry 230 (class 1259 OID 22898)
-- Name: tarea; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tarea (
    id_tarea integer NOT NULL,
    id_proyecto integer,
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
    CONSTRAINT tarea_estado_check CHECK (((estado)::text = ANY ((ARRAY['pendiente'::character varying, 'en_progreso'::character varying, 'completada'::character varying, 'bloqueada'::character varying])::text[]))),
    CONSTRAINT tarea_prioridad_check CHECK (((prioridad)::text = ANY ((ARRAY['baja'::character varying, 'media'::character varying, 'alta'::character varying])::text[]))),
    CONSTRAINT tarea_tiempo_estimado_horas_check CHECK ((tiempo_estimado_horas >= (0)::numeric)),
    CONSTRAINT tarea_tiempo_real_horas_check CHECK ((tiempo_real_horas >= (0)::numeric))
);


ALTER TABLE public.tarea OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 22897)
-- Name: tarea_id_tarea_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tarea_id_tarea_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tarea_id_tarea_seq OWNER TO postgres;

--
-- TOC entry 5111 (class 0 OID 0)
-- Dependencies: 229
-- Name: tarea_id_tarea_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tarea_id_tarea_seq OWNED BY public.tarea.id_tarea;


--
-- TOC entry 224 (class 1259 OID 22827)
-- Name: usuario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuario (
    id_usuario integer NOT NULL,
    id_equipo integer,
    nombre character varying(100) NOT NULL,
    email character varying(100) NOT NULL,
    rol character varying(30) NOT NULL,
    costo_hora numeric(10,2) DEFAULT 0.00 NOT NULL,
    activo boolean DEFAULT true,
    usuario character varying(50),
    contrasena character varying(255),
    CONSTRAINT usuario_costo_hora_check CHECK ((costo_hora >= (0)::numeric)),
    CONSTRAINT usuario_rol_check CHECK (((rol)::text = ANY ((ARRAY['desarrollador'::character varying, 'diseñador'::character varying, 'analista'::character varying, 'administrador'::character varying])::text[])))
);


ALTER TABLE public.usuario OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 22826)
-- Name: usuario_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.usuario_id_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.usuario_id_usuario_seq OWNER TO postgres;

--
-- TOC entry 5112 (class 0 OID 0)
-- Dependencies: 223
-- Name: usuario_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.usuario_id_usuario_seq OWNED BY public.usuario.id_usuario;


--
-- TOC entry 245 (class 1259 OID 23063)
-- Name: vw_carga_usuarios; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_carga_usuarios AS
 SELECT u.id_usuario,
    u.nombre,
    u.rol,
    eq.nombre_equipo,
    count(t.id_tarea) FILTER (WHERE ((t.estado)::text = 'en_progreso'::text)) AS tareas_en_progreso,
    count(t.id_tarea) FILTER (WHERE ((t.estado)::text = 'pendiente'::text)) AS tareas_pendientes,
    COALESCE(sum(t.tiempo_estimado_horas) FILTER (WHERE ((t.estado)::text = ANY ((ARRAY['en_progreso'::character varying, 'pendiente'::character varying])::text[]))), (0)::numeric) AS horas_estimadas_pendientes
   FROM ((public.usuario u
     LEFT JOIN public.equipo eq ON ((u.id_equipo = eq.id_equipo)))
     LEFT JOIN public.tarea t ON ((u.id_usuario = t.id_usuario_asignado)))
  GROUP BY u.id_usuario, u.nombre, u.rol, eq.nombre_equipo;


ALTER VIEW public.vw_carga_usuarios OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 23068)
-- Name: vw_presupuesto_proyecto; Type: VIEW; Schema: public; Owner: postgres
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


ALTER VIEW public.vw_presupuesto_proyecto OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 23073)
-- Name: vw_proyectos_en_riesgo; Type: VIEW; Schema: public; Owner: postgres
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


ALTER VIEW public.vw_proyectos_en_riesgo OWNER TO postgres;

--
-- TOC entry 4829 (class 2604 OID 22808)
-- Name: cliente id_cliente; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente ALTER COLUMN id_cliente SET DEFAULT nextval('public.cliente_id_cliente_seq'::regclass);


--
-- TOC entry 4843 (class 2604 OID 22939)
-- Name: comentario id_comentario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comentario ALTER COLUMN id_comentario SET DEFAULT nextval('public.comentario_id_comentario_seq'::regclass);


--
-- TOC entry 4845 (class 2604 OID 22961)
-- Name: config_notificacion id_config; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.config_notificacion ALTER COLUMN id_config SET DEFAULT nextval('public.config_notificacion_id_config_seq'::regclass);


--
-- TOC entry 4848 (class 2604 OID 22978)
-- Name: dependencia_tarea id_dependencia; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dependencia_tarea ALTER COLUMN id_dependencia SET DEFAULT nextval('public.dependencia_tarea_id_dependencia_seq'::regclass);


--
-- TOC entry 4830 (class 2604 OID 22819)
-- Name: equipo id_equipo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipo ALTER COLUMN id_equipo SET DEFAULT nextval('public.equipo_id_equipo_seq'::regclass);


--
-- TOC entry 4849 (class 2604 OID 22997)
-- Name: habilidad id_habilidad; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.habilidad ALTER COLUMN id_habilidad SET DEFAULT nextval('public.habilidad_id_habilidad_seq'::regclass);


--
-- TOC entry 4850 (class 2604 OID 23008)
-- Name: habilidad_usuario id_habilidad_usuario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.habilidad_usuario ALTER COLUMN id_habilidad_usuario SET DEFAULT nextval('public.habilidad_usuario_id_habilidad_usuario_seq'::regclass);


--
-- TOC entry 4851 (class 2604 OID 23028)
-- Name: historial_cambio id_historial; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historial_cambio ALTER COLUMN id_historial SET DEFAULT nextval('public.historial_cambio_id_historial_seq'::regclass);


--
-- TOC entry 4836 (class 2604 OID 22885)
-- Name: hito id_hito; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hito ALTER COLUMN id_hito SET DEFAULT nextval('public.hito_id_hito_seq'::regclass);


--
-- TOC entry 4853 (class 2604 OID 23048)
-- Name: notificacion id_notificacion; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notificacion ALTER COLUMN id_notificacion SET DEFAULT nextval('public.notificacion_id_notificacion_seq'::regclass);


--
-- TOC entry 4834 (class 2604 OID 22855)
-- Name: proyecto id_proyecto; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proyecto ALTER COLUMN id_proyecto SET DEFAULT nextval('public.proyecto_id_proyecto_seq'::regclass);


--
-- TOC entry 4838 (class 2604 OID 22901)
-- Name: tarea id_tarea; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tarea ALTER COLUMN id_tarea SET DEFAULT nextval('public.tarea_id_tarea_seq'::regclass);


--
-- TOC entry 4831 (class 2604 OID 22830)
-- Name: usuario id_usuario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario ALTER COLUMN id_usuario SET DEFAULT nextval('public.usuario_id_usuario_seq'::regclass);


--
-- TOC entry 5070 (class 0 OID 22805)
-- Dependencies: 220
-- Data for Name: cliente; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cliente (id_cliente, nombre_empresa, persona_contacto, email_contacto, telefono) FROM stdin;
1	TechSolutions C.A.	Carlos Mendoza	cmendoza@techsolutions.com	+584141234567
2	Banco Global	Mariana López	mlopez@bancoglobal.com	+584129876543
3	Logística Express	Roberto Gómez	rgomez@logisticaexp.com	+584165554433
4	VEO STREAM	Miguel Lopez	miguelopez79@example.com	04123658942
5	Apex Systems Latam	Diego Herrera	diego.herrera@apexsystems.com	+584141087133
6	NeuroTech Corp	Valeria Silva	valeria.silva@neurotech.latam	+584146041576
7	Fintech Innova	Fernando Castillo	fernando.castillo@fintechinnova.com	+584145889934
8	Logistica del Sur	Lucia Navarro	lucia.navarro@logsur.com	+584143062673
9	MercadoDigital C.A.	Andres Peña	andres.peña@mercadodigital.com	+584144294438
10	AgroTech Venezuela	Camila Rivas	camila.rivas@agrotech.ve	+584142810031
11	Constructora Horizonte	Javier Ortega	javier.ortega@chorizonte.com	+584149415273
12	Seguros Andinos	Mariana Vega	mariana.vega@segurosandinos.com	+584148395457
13	Retail Corp C.A.	Ricardo Castro	ricardo.castro@retailcorp.com	+584148717281
14	Consultores Empresariales	Elena Guzman	elena.guzman@ce-consultores.com	+584144559477
15	DataSys Solutions	Hector Mora	hector.mora@datasys.com	+584141916614
16	CyberShield Global	Daniela Salazar	daniela.salazar@cybershield.com	+584142789758
17	BLENKI Café	David Paz	david.paz@blenki.com	+584128543341
\.


--
-- TOC entry 5082 (class 0 OID 22936)
-- Dependencies: 232
-- Data for Name: comentario; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.comentario (id_comentario, id_tarea, id_usuario, contenido, fecha_hora) FROM stdin;
1	281	2	Por favor, realizar cuanto antes. Gracias.	2026-09-30 05:57:36.042077
\.


--
-- TOC entry 5084 (class 0 OID 22958)
-- Dependencies: 234
-- Data for Name: config_notificacion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.config_notificacion (id_config, id_usuario, recibir_emails, alerta_vencimiento) FROM stdin;
1	2	t	t
\.


--
-- TOC entry 5086 (class 0 OID 22975)
-- Dependencies: 236
-- Data for Name: dependencia_tarea; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dependencia_tarea (id_dependencia, id_tarea_principal, id_tarea_dependiente) FROM stdin;
\.


--
-- TOC entry 5072 (class 0 OID 22816)
-- Dependencies: 222
-- Data for Name: equipo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.equipo (id_equipo, nombre_equipo, descripcion) FROM stdin;
1	Frontend	Desarrollo de interfaces de usuario y experiencia cliente
2	Backend	Desarrollo de APIs, lógica de negocio y arquitectura de datos
3	QA / Pruebas	Aseguramiento de calidad, pruebas unitarias e integración
4	Diseño UX/UI	Diseño visual, maquetación y prototipado
\.


--
-- TOC entry 5088 (class 0 OID 22994)
-- Dependencies: 238
-- Data for Name: habilidad; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.habilidad (id_habilidad, nombre_habilidad) FROM stdin;
1	React
2	PostgreSQL
3	Python
4	Java
5	Figma
6	QA Automation
7	Docker
\.


--
-- TOC entry 5090 (class 0 OID 23005)
-- Dependencies: 240
-- Data for Name: habilidad_usuario; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.habilidad_usuario (id_habilidad_usuario, id_usuario, id_habilidad) FROM stdin;
1	1	2
2	1	3
4	3	5
5	4	2
6	4	4
7	5	6
8	6	2
9	6	6
10	7	1
11	7	7
12	8	2
13	8	4
14	9	2
15	9	5
16	10	2
17	10	7
18	11	3
19	11	4
20	12	3
21	12	6
22	13	1
23	13	7
24	14	3
25	14	7
26	15	2
27	15	5
28	16	3
29	16	7
30	17	3
31	17	7
32	18	1
33	18	4
34	19	3
35	19	7
36	20	3
37	20	7
38	21	2
39	21	7
40	22	1
41	22	7
42	23	2
43	23	6
44	24	2
45	24	7
46	25	3
47	25	5
48	26	4
49	26	3
51	2	5
52	2	4
53	2	2
\.


--
-- TOC entry 5092 (class 0 OID 23025)
-- Dependencies: 242
-- Data for Name: historial_cambio; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.historial_cambio (id_historial, id_tarea, id_usuario, estado_anterior, estado_nuevo, fecha_cambio) FROM stdin;
1	279	20	pendiente	completada	2026-09-30 23:38:11.365655
2	281	2	pendiente	en_progreso	2026-09-30 23:43:31.716758
\.


--
-- TOC entry 5078 (class 0 OID 22882)
-- Dependencies: 228
-- Data for Name: hito; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.hito (id_hito, id_proyecto, nombre_hito, fecha_objetivo, alcanzado) FROM stdin;
1	6	Fase 1	2026-10-30	t
2	6	Fase 2	2026-10-30	t
3	7	Fase 1	2026-10-30	t
4	7	Fase 2	2026-10-30	t
5	8	Fase 1	2026-10-30	t
6	8	Fase 2	2026-10-30	t
7	9	Fase 1	2026-10-30	t
8	9	Fase 2	2026-10-30	t
9	10	Fase 1	2026-10-30	t
10	10	Fase 2	2026-10-30	t
11	11	Fase 1	2026-10-30	t
12	11	Fase 2	2026-10-30	t
13	12	Fase 1	2026-10-30	t
14	12	Fase 2	2026-10-30	t
15	13	Fase 1	2026-10-30	t
16	13	Fase 2	2026-10-30	t
17	14	Fase 1	2026-10-30	t
18	14	Fase 2	2026-10-30	t
19	15	Fase 1	2026-10-30	t
20	15	Fase 2	2026-10-30	t
21	16	Fase 1	2026-10-30	t
22	16	Fase 2	2026-10-30	t
23	17	Fase 1	2026-10-30	t
24	17	Fase 2	2026-10-30	t
25	18	Fase 1	2026-10-30	t
26	18	Fase 2	2026-10-30	t
27	19	Fase 1	2026-10-30	t
28	19	Fase 2	2026-10-30	t
29	20	Fase 1	2026-10-30	t
30	20	Fase 2	2026-10-30	t
31	21	Fase 1	2026-10-30	t
32	21	Fase 2	2026-10-30	t
33	22	Fase 1	2026-10-30	t
34	22	Fase 2	2026-10-30	t
35	23	Fase 1	2026-10-30	t
36	23	Fase 2	2026-10-30	t
37	24	Fase 1	2026-10-30	t
38	24	Fase 2	2026-10-30	t
39	25	Fase 1	2026-10-30	t
40	25	Fase 2	2026-10-30	t
41	26	Fase 1	2026-10-30	t
42	26	Fase 2	2026-10-30	t
43	27	Fase 1	2026-10-30	t
44	27	Fase 2	2026-10-30	t
45	28	Fase 1	2026-10-30	t
46	28	Fase 2	2026-10-30	t
47	29	Fase 1	2026-10-30	t
48	29	Fase 2	2026-10-30	t
49	30	Fase 1	2026-10-30	t
50	30	Fase 2	2026-10-30	t
51	31	Fase 1	2026-10-30	t
52	31	Fase 2	2026-10-30	t
53	32	Fase 1	2026-10-30	t
54	32	Fase 2	2026-10-30	t
55	33	Fase 1	2026-10-30	t
56	33	Fase 2	2026-10-30	t
57	34	Fase 1	2026-10-30	t
58	34	Fase 2	2026-10-30	t
59	35	Fase 1	2026-10-30	t
60	35	Fase 2	2026-10-30	t
61	36	Fase 1	2026-10-30	t
62	36	Fase 2	2026-10-30	f
63	37	Fase 1	2026-10-30	t
64	37	Fase 2	2026-10-30	f
65	38	Fase 1	2026-10-30	t
66	38	Fase 2	2026-10-30	f
67	39	Fase 1	2026-10-30	t
68	39	Fase 2	2026-10-30	f
71	10	Fase 3	2026-10-30	f
72	41	Fase 1	2026-10-31	f
69	40	Fase 1	2026-10-30	t
70	40	Fase 2	2026-10-30	f
\.


--
-- TOC entry 5094 (class 0 OID 23045)
-- Dependencies: 244
-- Data for Name: notificacion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notificacion (id_notificacion, id_usuario, mensaje, fecha_envio, leida) FROM stdin;
\.


--
-- TOC entry 5076 (class 0 OID 22852)
-- Dependencies: 226
-- Data for Name: proyecto; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.proyecto (id_proyecto, id_cliente, id_lider, nombre_proyecto, descripcion, fecha_inicio, fecha_fin_estimada, fecha_fin_real, presupuesto_total, estado) FROM stdin;
3	3	1	Migración de Base de Datos	Migración hacia esquema optimizado PostgreSQL	2026-03-01	2026-04-15	\N	5000.00	planificacion
5	4	3	Plataforma de streaming VEO	Plataforma de streaming zona kids	2026-01-13	2026-12-03	\N	20000.00	en_desarrollo
6	8	10	API de Pagos Seguros	Proyecto escalable.	2026-04-30	2026-09-12	\N	45447.27	finalizado
33	11	14	Sistema de Facturacion	Proyecto escalable.	2026-03-04	2026-09-12	\N	22065.51	finalizado
12	13	12	Dashboard Analitico	Proyecto escalable.	2026-04-29	2026-09-12	\N	28904.04	finalizado
7	14	16	Migracion Nube AWS	Proyecto escalable.	2026-06-01	2026-09-24	2026-09-20	42600.00	finalizado
8	13	15	Motor de Recomendaciones	Proyecto escalable.	2026-06-20	2026-09-12	\N	21291.26	finalizado
9	16	21	App de Telemedicina	Proyecto escalable.	2026-07-02	2026-09-17	\N	46819.77	finalizado
35	6	10	Chatbot con IA	Proyecto escalable.	2026-04-06	2026-09-22	\N	56674.04	finalizado
40	8	17	Portal B2B	Proyecto escalable.	2026-04-30	2026-12-06	\N	42930.84	en_desarrollo
39	7	14	Plataforma E-Learning	Proyecto escalable.	2026-06-24	2026-12-04	\N	39092.53	en_desarrollo
36	12	1	Motor de Recomendaciones	Proyecto escalable.	2026-07-30	2026-12-05	\N	21893.51	en_desarrollo
38	12	8	Migracion Nube AWS	Proyecto escalable.	2026-06-12	2026-11-26	\N	24014.71	en_desarrollo
34	15	13	Portal B2B	Proyecto escalable.	2026-07-11	2026-09-11	\N	35554.31	finalizado
4	1	2	Sistema Movil	Desarrollo Nativo	2026-10-01	2026-12-31	\N	5000.00	planificacion
1	1	9	Sistema ERP Web	Desarrollo de sistema web de gestión de recursos empresariales	2026-01-15	2026-06-30	\N	15000.00	en_desarrollo
10	13	22	App de Telemedicina	Proyecto escalable.	2026-06-01	2026-09-22	\N	41265.91	finalizado
11	5	19	Integracion CRM	Proyecto escalable.	2026-03-12	2026-09-24	\N	29379.17	finalizado
28	7	23	Chatbot con IA	Proyecto escalable.	2026-03-02	2026-09-20	\N	24426.20	finalizado
14	11	5	Dashboard Analitico	Proyecto escalable.	2026-02-06	2026-09-14	\N	36210.20	finalizado
13	13	18	Portal B2B	Proyecto escalable.	2026-07-15	2026-09-13	\N	44823.14	finalizado
15	5	2	Dashboard Analitico	Proyecto escalable.	2026-05-10	2026-09-23	\N	43169.75	finalizado
16	11	17	Dashboard Analitico	Proyecto escalable.	2026-03-15	2026-09-16	\N	39801.19	finalizado
17	13	25	Dashboard Analitico	Proyecto escalable.	2026-06-15	2026-09-14	\N	31859.14	finalizado
32	14	25	Migracion Nube AWS	Proyecto escalable.	2026-04-17	2026-09-22	\N	31722.60	finalizado
29	11	16	Plataforma E-Learning	Proyecto escalable.	2026-04-15	2026-09-22	\N	22898.87	finalizado
18	11	9	Chatbot con IA	Proyecto escalable.	2026-05-14	2026-09-20	\N	59959.17	finalizado
19	11	10	App de Telemedicina	Proyecto escalable.	2026-03-09	2026-09-24	\N	53756.66	finalizado
31	14	7	Chatbot con IA	Proyecto escalable.	2026-07-17	2026-09-10	\N	44678.61	finalizado
20	11	21	Motor de Recomendaciones	Proyecto escalable.	2026-02-28	2026-09-13	\N	40078.51	finalizado
21	6	14	Integracion CRM	Proyecto escalable.	2026-04-29	2026-09-12	\N	26175.95	finalizado
22	10	13	Dashboard Analitico	Proyecto escalable.	2026-05-22	2026-09-25	\N	51922.41	finalizado
23	9	4	Integracion CRM	Proyecto escalable.	2026-07-28	2026-09-18	\N	32423.01	finalizado
24	7	10	Sistema de Facturacion	Proyecto escalable.	2026-06-08	2026-09-11	\N	34084.05	finalizado
25	9	18	Migracion Nube AWS	Proyecto escalable.	2026-07-03	2026-09-21	\N	32816.19	finalizado
26	7	8	Dashboard Analitico	Proyecto escalable.	2026-07-06	2026-09-16	\N	59428.19	finalizado
27	16	4	App de Telemedicina	Proyecto escalable.	2026-05-18	2026-09-21	\N	29167.21	finalizado
30	6	22	App de Telemedicina	Proyecto escalable.	2026-07-02	2026-09-10	\N	54814.43	finalizado
37	16	23	Portal B2B	Proyecto escalable.	2026-02-10	2026-11-04	\N	22805.57	cancelado
2	2	4	App Banca Móvil	Rediseño e integración de API para aplicación bancaria	2026-02-10	2026-05-15	\N	20000.00	en_desarrollo
41	17	2	App Automatización	Portafolio virtual de servicios y productos para la venta.	2026-10-01	2027-01-01	\N	10630.00	planificacion
\.


--
-- TOC entry 5080 (class 0 OID 22898)
-- Dependencies: 230
-- Data for Name: tarea; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tarea (id_tarea, id_proyecto, id_hito, id_usuario_asignado, nombre_tarea, descripcion, fecha_creacion, fecha_vencimiento, prioridad, estado, tiempo_estimado_horas, tiempo_real_horas) FROM stdin;
1	6	1	17	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-06 23:33:32.308743	alta	completada	11.48	9.76
2	6	1	11	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-21 07:56:04.044625	baja	completada	4.38	3.72
3	6	1	25	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-07 19:44:02.462353	media	completada	4.10	3.49
4	6	1	8	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-10 08:53:01.244418	alta	completada	6.31	5.36
5	6	2	11	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-23 13:17:18.808061	media	completada	4.63	3.94
6	6	2	21	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-02 07:05:50.438983	media	completada	8.49	7.22
7	6	2	22	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-26 01:19:45.153643	alta	completada	4.96	4.22
8	6	2	23	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-29 21:10:42.246843	baja	completada	9.68	8.23
9	7	3	6	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-01 03:57:55.040221	media	completada	8.34	7.09
10	7	3	20	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-01 01:55:15.853653	media	completada	4.44	3.77
11	7	3	13	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-14 07:10:56.122681	alta	completada	7.28	6.19
12	7	3	8	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-29 16:00:55.409182	alta	completada	4.16	3.54
13	7	4	14	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-26 10:44:38.373058	media	completada	7.58	6.44
14	7	4	24	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-04 05:00:26.597592	baja	completada	10.95	9.31
15	7	4	10	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-08-31 06:33:12.577208	alta	completada	9.54	8.11
16	7	4	15	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-18 01:16:39.211824	media	completada	9.62	8.18
17	8	5	13	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-01 00:12:48.880757	alta	completada	8.60	7.31
18	8	5	16	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-05 10:34:52.265148	baja	completada	4.55	3.87
19	8	5	17	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-07 02:12:51.189626	alta	completada	4.69	3.99
20	8	5	10	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-22 00:57:51.343144	baja	completada	7.69	6.54
21	8	6	12	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-08 23:51:32.51898	baja	completada	6.12	5.20
22	8	6	10	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-11 00:54:12.783309	alta	completada	9.35	7.95
23	8	6	17	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-11 19:05:11.184169	baja	completada	11.45	9.73
24	8	6	25	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-26 03:26:07.205323	baja	completada	11.08	9.42
25	9	7	14	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-04 16:27:40.723808	alta	completada	10.16	8.64
26	9	7	25	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-11 01:29:14.077127	alta	completada	4.78	4.06
27	9	7	13	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-14 09:17:34.186052	baja	completada	7.79	6.62
28	9	7	21	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-02 21:07:53.077127	alta	completada	7.64	6.49
30	9	8	17	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-21 05:27:49.960777	baja	completada	4.79	4.07
31	9	8	17	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-04 06:55:08.119595	alta	completada	5.71	4.85
32	9	8	17	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-11 12:10:49.399971	alta	completada	10.73	9.12
33	10	9	17	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-14 07:59:59.461647	baja	completada	10.57	8.98
34	10	9	17	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-28 11:38:26.780446	baja	completada	5.52	4.69
35	10	9	15	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-07 13:48:57.503431	media	completada	11.02	9.37
36	10	9	7	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-21 07:07:46.681474	alta	completada	9.20	7.82
37	10	10	6	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-17 16:56:47.918774	media	completada	4.54	3.86
38	10	10	6	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-02 02:40:36.933488	baja	completada	10.90	9.27
39	10	10	9	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-05 14:46:00.643982	media	completada	11.09	9.43
40	10	10	24	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-10 18:38:32.135663	media	completada	9.29	7.90
41	11	11	19	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-28 20:13:37.037555	media	completada	10.88	9.25
42	11	11	24	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-12 15:53:39.445277	alta	completada	9.27	7.88
43	11	11	22	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-21 20:02:47.911492	media	completada	4.45	3.78
44	11	11	20	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-01 08:04:09.221744	media	completada	6.96	5.92
45	11	12	7	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-28 13:54:47.581058	media	completada	5.43	4.62
46	11	12	18	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-03 09:38:39.572308	media	completada	9.47	8.05
47	11	12	25	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-23 21:22:47.902739	media	completada	11.92	10.13
48	11	12	25	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-14 12:21:29.077395	media	completada	10.21	8.68
49	12	13	17	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-20 05:48:16.203766	media	completada	4.93	4.19
50	12	13	20	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-09 07:01:12.610518	baja	completada	8.26	7.02
51	12	13	22	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-14 01:27:17.21097	baja	completada	11.38	9.67
52	12	13	7	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-28 15:44:24.63226	alta	completada	7.56	6.43
53	12	14	20	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-10 04:26:02.566276	media	completada	11.90	10.12
54	12	14	18	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-29 01:26:58.289959	alta	completada	6.39	5.43
55	12	14	18	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-10 22:27:51.086812	alta	completada	6.02	5.12
56	12	14	11	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-01 17:05:55.594377	media	completada	5.73	4.87
57	13	15	12	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-11 10:47:50.877298	baja	completada	5.73	4.87
58	13	15	14	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-23 18:12:44.009639	alta	completada	10.96	9.32
59	13	15	9	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-19 02:06:35.332679	baja	completada	8.74	7.43
60	13	15	11	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-01 02:44:26.808274	baja	completada	9.59	8.15
61	13	16	25	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-24 21:32:45.51095	alta	completada	7.05	5.99
62	13	16	7	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-10 09:08:18.005064	alta	completada	10.84	9.21
63	13	16	10	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-02 10:13:08.375141	media	completada	5.78	4.91
64	13	16	21	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-21 10:59:19.337061	baja	completada	4.92	4.18
65	14	17	8	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-08 18:51:04.646125	alta	completada	8.26	7.02
66	14	17	9	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-26 14:22:44.904045	media	completada	10.33	8.78
67	14	17	9	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-15 13:30:13.663346	baja	completada	5.91	5.02
68	14	17	13	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-21 17:47:12.928434	media	completada	6.66	5.66
69	14	18	15	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-16 08:22:15.816029	media	completada	4.57	3.88
70	14	18	21	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-02 02:42:04.382642	baja	completada	4.65	3.95
71	14	18	22	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-15 20:13:30.384792	baja	completada	5.66	4.81
72	14	18	11	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-28 17:21:04.036207	media	completada	7.73	6.57
73	15	19	13	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-25 14:28:46.166963	alta	completada	11.42	9.71
74	15	19	11	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-25 04:26:56.227205	baja	completada	11.94	10.15
75	15	19	17	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-20 22:31:29.795304	baja	completada	5.73	4.87
76	15	19	13	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-26 02:09:46.955138	media	completada	10.80	9.18
77	15	20	9	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-04 19:24:00.287107	alta	completada	7.48	6.36
78	15	20	21	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-20 06:15:21.361706	baja	completada	5.97	5.07
79	15	20	17	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-23 11:22:04.27077	baja	completada	4.64	3.94
80	15	20	22	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-05 15:37:15.517339	alta	completada	5.06	4.30
81	16	21	21	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-14 19:47:25.735562	media	completada	10.90	9.27
82	16	21	11	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-15 22:01:40.106851	alta	completada	7.38	6.27
83	16	21	9	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-28 17:50:15.644157	baja	completada	10.55	8.97
84	16	21	9	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-27 04:51:43.767267	media	completada	6.79	5.77
85	16	22	18	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-21 05:41:32.253926	alta	completada	4.85	4.12
86	16	22	6	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-12 13:15:12.58357	baja	completada	4.22	3.59
87	16	22	12	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-15 16:39:11.341817	alta	completada	8.90	7.57
88	16	22	16	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-06 02:41:29.999454	baja	completada	7.31	6.21
89	17	23	13	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-10 08:58:49.811054	baja	completada	5.27	4.48
90	17	23	7	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-29 05:36:10.373597	baja	completada	4.09	3.48
91	17	23	9	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-28 23:54:35.354913	alta	completada	5.10	4.34
92	17	23	19	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-21 23:24:21.833654	alta	completada	8.71	7.40
93	17	24	21	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-21 21:30:36.858319	alta	completada	7.62	6.48
94	17	24	25	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-28 04:13:01.242518	media	completada	7.07	6.01
95	17	24	19	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-04 21:12:16.449582	alta	completada	7.71	6.55
96	17	24	17	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-01 22:59:50.760761	alta	completada	6.62	5.63
97	18	25	10	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-18 18:02:13.798491	baja	completada	6.96	5.92
98	18	25	11	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-12 11:38:20.617728	alta	completada	9.40	7.99
99	18	25	25	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-27 20:30:01.831855	alta	completada	11.67	9.92
100	18	25	6	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-13 00:37:23.144448	baja	completada	8.15	6.93
101	18	26	7	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-14 03:13:03.373989	media	completada	4.24	3.60
102	18	26	25	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-18 10:33:15.769797	baja	completada	7.09	6.03
103	18	26	23	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-14 00:02:22.131969	alta	completada	4.68	3.98
104	18	26	11	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-22 05:50:42.92895	baja	completada	10.03	8.53
105	19	27	8	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-05 09:14:48.854375	media	completada	7.21	6.13
106	19	27	24	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-19 14:08:30.228333	media	completada	6.96	5.92
107	19	27	7	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-23 11:50:14.347132	baja	completada	10.80	9.18
108	19	27	19	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-15 23:11:08.356851	alta	completada	8.17	6.94
109	19	28	20	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-05 22:06:28.565555	baja	completada	7.75	6.59
110	19	28	19	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-14 19:04:34.949275	baja	completada	5.70	4.85
111	19	28	24	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-26 11:16:31.141586	baja	completada	7.99	6.79
112	19	28	24	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-21 14:44:53.503495	alta	completada	7.51	6.38
113	20	29	11	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-18 14:13:46.492002	media	completada	8.56	7.28
114	20	29	8	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-18 21:52:51.379217	baja	completada	5.18	4.40
115	20	29	17	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-28 20:04:48.187796	media	completada	4.41	3.75
116	20	29	13	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-22 17:59:28.392344	media	completada	8.66	7.36
117	20	30	25	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-26 19:16:52.64963	baja	completada	8.54	7.26
118	20	30	21	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-27 22:22:28.297579	media	completada	4.76	4.05
119	20	30	11	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-02 22:49:48.647803	baja	completada	7.65	6.50
120	20	30	15	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-17 22:32:16.165253	media	completada	8.24	7.00
121	21	31	24	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-03 12:55:09.125706	alta	completada	7.89	6.71
122	21	31	17	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-27 18:39:14.07428	baja	completada	7.05	5.99
123	21	31	22	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-28 10:26:52.188559	baja	completada	10.99	9.34
124	21	31	23	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-10 16:19:50.875362	media	completada	6.58	5.59
125	21	32	24	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-09 03:46:19.220315	media	completada	5.09	4.33
126	21	32	15	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-07 02:09:26.974122	media	completada	10.03	8.53
127	21	32	11	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-13 11:25:54.137866	baja	completada	11.15	9.48
128	21	32	22	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-14 20:51:25.839621	alta	completada	8.79	7.47
129	22	33	9	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-11 13:52:18.176482	media	completada	10.75	9.14
130	22	33	22	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-02 12:53:47.025519	baja	completada	7.30	6.21
131	22	33	15	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-17 01:07:01.879675	baja	completada	8.93	7.59
132	22	33	9	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-05 00:51:15.725615	baja	completada	10.88	9.25
133	22	34	13	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-15 17:18:54.236287	alta	completada	7.13	6.06
134	22	34	25	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-20 17:13:14.883422	media	completada	11.26	9.57
135	22	34	13	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-13 02:30:23.724916	alta	completada	6.95	5.91
136	22	34	25	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-13 02:52:14.753346	alta	completada	7.42	6.31
137	23	35	9	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-10 07:17:25.774727	alta	completada	6.63	5.64
138	23	35	18	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-22 10:19:54.739369	baja	completada	4.16	3.54
139	23	35	21	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-25 23:09:08.044542	alta	completada	5.77	4.90
140	23	35	13	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-30 00:51:03.457859	baja	completada	8.20	6.97
141	23	36	7	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-25 05:43:39.667243	baja	completada	8.97	7.62
142	23	36	6	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-22 19:18:50.533208	media	completada	7.91	6.72
143	23	36	15	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-27 16:11:31.664259	baja	completada	6.68	5.68
144	23	36	23	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-24 03:27:04.727255	baja	completada	7.71	6.55
145	24	37	24	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-13 00:03:38.267259	media	completada	10.83	9.21
146	24	37	17	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-25 18:36:17.820675	media	completada	11.49	9.77
147	24	37	7	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-08-31 17:43:37.714458	baja	completada	11.23	9.55
148	24	37	8	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-06 11:15:21.353101	alta	completada	10.97	9.32
149	24	38	19	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-08-31 03:04:54.167796	baja	completada	6.34	5.39
150	24	38	10	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-11 16:18:10.652306	baja	completada	9.34	7.94
151	24	38	12	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-19 05:31:47.886719	media	completada	7.57	6.43
152	24	38	23	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-02 10:07:52.04772	media	completada	7.32	6.22
153	25	39	14	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-24 10:47:35.712718	baja	completada	11.24	9.55
154	25	39	8	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-18 09:58:18.98517	baja	completada	9.10	7.74
155	25	39	24	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-25 17:56:19.255305	media	completada	6.96	5.92
156	25	39	22	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-23 10:09:38.758375	media	completada	7.72	6.56
157	25	40	22	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-06 10:16:50.248739	media	completada	5.32	4.52
158	25	40	7	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-20 03:06:27.697637	baja	completada	11.47	9.75
159	25	40	12	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-19 22:34:54.636207	alta	completada	6.74	5.73
160	25	40	10	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-10 01:22:20.749168	media	completada	11.76	10.00
161	26	41	19	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-02 22:03:02.841607	baja	completada	9.24	7.85
162	26	41	25	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-22 06:00:57.882609	alta	completada	9.89	8.41
163	26	41	13	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-24 01:59:39.978102	media	completada	4.45	3.78
164	26	41	22	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-05 23:17:04.602425	media	completada	7.94	6.75
165	26	42	16	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-09 09:34:36.672689	baja	completada	9.99	8.49
166	26	42	20	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-22 06:32:45.326915	baja	completada	8.82	7.50
167	26	42	18	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-27 04:24:33.587707	media	completada	4.50	3.83
168	26	42	14	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-24 13:25:36.020039	media	completada	5.18	4.40
169	27	43	25	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-12 15:13:39.836978	baja	completada	6.00	5.10
170	27	43	24	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-16 06:03:22.689037	media	completada	10.56	8.98
171	27	43	9	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-09 07:43:13.375751	alta	completada	10.89	9.26
172	27	43	13	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-23 05:42:27.783956	alta	completada	11.04	9.38
173	27	44	22	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-08-31 10:47:04.139099	media	completada	7.21	6.13
174	27	44	21	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-13 08:15:32.325428	baja	completada	7.53	6.40
175	27	44	9	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-27 23:56:19.693379	baja	completada	5.85	4.97
176	27	44	25	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-23 18:26:50.521099	media	completada	8.18	6.95
177	28	45	15	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-12 09:17:07.763099	baja	completada	10.91	9.27
178	28	45	13	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-12 19:50:11.866255	baja	completada	5.08	4.32
179	28	45	22	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-27 17:22:36.552274	media	completada	4.48	3.81
180	28	45	20	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-18 11:37:43.538216	baja	completada	8.36	7.11
181	28	46	14	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-06 06:20:54.335284	media	completada	8.76	7.45
182	28	46	18	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-29 18:29:34.165295	media	completada	6.26	5.32
183	28	46	16	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-05 06:19:55.646304	baja	completada	10.79	9.17
184	28	46	7	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-04 16:37:57.457562	media	completada	10.36	8.81
185	29	47	23	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-15 18:43:15.07847	media	completada	5.04	4.28
186	29	47	6	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-21 13:43:36.774116	baja	completada	6.18	5.25
187	29	47	9	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-28 07:32:39.971269	baja	completada	5.27	4.48
188	29	47	16	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-25 21:53:08.174612	media	completada	8.48	7.21
189	29	48	10	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-12 17:13:40.022449	media	completada	8.67	7.37
190	29	48	18	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-29 18:24:19.739481	media	completada	10.58	8.99
191	29	48	20	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-26 10:51:58.797583	alta	completada	8.71	7.40
192	29	48	25	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-11 00:47:21.579979	baja	completada	11.27	9.58
193	30	49	10	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-13 18:58:03.339858	baja	completada	4.29	3.65
194	30	49	22	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-29 02:28:44.972965	baja	completada	6.91	5.87
195	30	49	25	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-07 19:31:02.27888	media	completada	5.81	4.94
196	30	49	12	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-13 16:57:13.794468	alta	completada	5.36	4.56
197	30	50	23	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-12 16:28:50.078528	media	completada	4.88	4.15
198	30	50	14	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-04 19:11:21.149926	baja	completada	8.29	7.05
199	30	50	22	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-14 20:53:43.465919	media	completada	5.87	4.99
200	30	50	16	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-09 05:12:30.747821	baja	completada	6.23	5.30
201	31	51	22	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-19 18:39:16.885952	baja	completada	5.31	4.51
202	31	51	9	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-25 08:21:36.109144	alta	completada	10.89	9.26
203	31	51	24	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-03 14:49:42.296766	alta	completada	5.01	4.26
204	31	51	12	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-20 12:46:28.037996	media	completada	4.92	4.18
205	31	52	13	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-24 06:05:55.348137	alta	completada	6.25	5.31
206	31	52	6	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-18 07:25:32.240724	alta	completada	11.01	9.36
207	31	52	14	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-08-31 11:31:47.705674	alta	completada	6.72	5.71
208	31	52	15	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-07 23:46:50.456342	alta	completada	10.38	8.82
209	32	53	22	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-22 11:40:14.218783	alta	completada	7.34	6.24
210	32	53	12	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-25 18:45:54.26834	alta	completada	5.68	4.83
211	32	53	25	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-04 12:53:04.768058	baja	completada	4.88	4.15
212	32	53	7	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-08-31 05:15:28.272218	media	completada	5.03	4.28
213	32	54	14	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-05 20:39:11.140395	alta	completada	7.23	6.15
214	32	54	11	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-04 12:09:28.624809	alta	completada	9.03	7.68
215	32	54	12	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-12 01:06:28.281305	baja	completada	11.64	9.89
216	32	54	18	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-25 07:12:31.046444	media	completada	4.33	3.68
217	33	55	25	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-10 13:21:01.253745	media	completada	11.15	9.48
218	33	55	21	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-23 11:08:45.076664	alta	completada	7.57	6.43
219	33	55	16	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-10 02:13:14.76489	alta	completada	11.97	10.17
220	33	55	14	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-19 07:04:35.810658	baja	completada	6.22	5.29
221	33	56	23	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-09 14:11:27.802412	baja	completada	6.51	5.53
222	33	56	11	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-28 05:16:31.636078	baja	completada	7.31	6.21
223	33	56	8	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-13 05:51:33.117669	baja	completada	4.17	3.54
224	33	56	7	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-17 13:20:23.813562	alta	completada	8.91	7.57
225	34	57	12	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-30 01:10:14.500401	media	completada	5.87	4.99
226	34	57	7	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-12 05:11:08.362183	media	completada	6.40	5.44
227	34	57	25	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-05 12:51:19.458403	baja	completada	10.53	8.95
228	34	57	7	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-30 00:37:16.827846	baja	completada	10.18	8.65
229	34	58	12	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-09 20:19:39.136876	media	completada	6.06	5.15
230	34	58	7	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-26 14:16:01.910839	alta	completada	6.74	5.73
231	34	58	8	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-12 16:17:59.47929	alta	completada	7.25	6.16
232	34	58	12	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-25 05:46:17.130262	baja	completada	5.46	4.64
233	35	59	6	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-03 10:47:01.840527	baja	completada	4.57	3.88
234	35	59	17	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-24 07:38:43.773837	alta	completada	7.54	6.41
235	35	59	18	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-03 20:16:34.818462	alta	completada	9.63	8.19
236	35	59	21	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-12 14:02:44.008661	media	completada	8.18	6.95
237	35	60	14	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-27 19:44:26.39431	alta	completada	11.60	9.86
238	35	60	20	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-21 20:11:58.016363	baja	completada	5.53	4.70
239	35	60	6	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-01 21:48:01.084303	media	completada	7.93	6.74
240	35	60	7	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-13 06:43:42.572813	baja	completada	4.90	4.17
241	36	61	6	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-19 12:13:46.984498	alta	completada	9.67	8.22
242	36	61	7	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-08-31 19:39:41.725812	alta	completada	11.54	9.81
243	36	61	8	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-12 18:51:11.230872	baja	completada	4.33	3.68
244	36	61	9	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-15 15:49:49.169502	media	completada	4.72	4.01
245	36	62	6	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-10-07 03:36:21.026451	baja	en_progreso	7.84	3.14
246	36	62	7	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-30 21:00:00.55981	baja	pendiente	11.34	0.00
247	36	62	8	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-10-07 09:52:40.082515	baja	pendiente	10.08	0.00
248	36	62	9	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-10-12 16:04:50.591174	baja	pendiente	7.74	0.00
249	37	63	9	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-05 20:38:39.339323	alta	completada	7.78	6.61
250	37	63	10	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-24 20:23:54.225398	alta	completada	9.38	7.97
251	37	63	11	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-07 23:24:40.675011	media	completada	11.45	9.73
252	37	63	12	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-26 15:14:05.150469	baja	completada	8.90	7.57
253	37	64	9	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-10-08 20:41:31.873738	alta	en_progreso	9.97	3.99
254	37	64	10	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-30 17:10:51.385582	baja	pendiente	10.61	0.00
255	37	64	11	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-10-12 16:53:11.884605	baja	pendiente	9.59	0.00
256	37	64	12	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-10-10 11:04:10.431829	media	pendiente	9.15	0.00
257	38	65	12	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-09 05:01:49.810786	media	completada	5.93	5.04
258	38	65	13	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-11 04:42:30.278926	media	completada	7.65	6.50
259	38	65	14	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-02 16:32:03.197148	baja	completada	5.08	4.32
260	38	65	15	Configurar servidor CI/CD	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-11 22:05:06.17282	baja	completada	6.73	5.72
261	38	66	12	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-10-14 05:17:58.574106	media	en_progreso	5.01	2.00
262	38	66	13	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-10-09 17:16:08.609107	alta	pendiente	10.75	0.00
263	38	66	14	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-10-05 23:43:48.366946	media	pendiente	11.47	0.00
264	38	66	15	Levantamiento de requerimientos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-10-07 10:22:42.727895	baja	pendiente	6.09	0.00
265	39	67	15	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-21 06:55:52.454047	baja	completada	5.21	4.43
266	39	67	16	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-04 17:00:56.76644	baja	completada	10.88	9.25
267	39	67	17	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-15 05:54:07.546076	baja	completada	7.52	6.39
268	39	67	18	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-03 03:17:21.02007	baja	completada	11.98	10.18
269	39	68	15	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-10-04 09:27:38.34354	alta	en_progreso	6.14	2.46
270	39	68	16	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-10-08 19:37:29.977347	alta	pendiente	9.23	0.00
271	39	68	17	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-10-10 00:23:13.208222	alta	pendiente	6.07	0.00
272	39	68	18	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-10-14 08:21:02.766062	media	pendiente	6.60	0.00
273	40	69	18	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-06 15:50:46.420087	alta	completada	4.13	3.51
274	40	69	19	Crear wireframes	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-05 21:10:30.108998	alta	completada	11.17	9.49
275	40	69	20	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-12 01:53:20.784247	media	completada	4.91	4.17
276	40	69	21	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-09 13:05:54.849976	alta	completada	4.19	3.56
280	40	70	21	Crear componentes UI	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-10-10 11:35:03.015266	media	pendiente	10.70	0.00
29	9	8	16	Pruebas de integracion	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-07 17:26:00	media	completada	11.50	10.00
282	41	72	26	Realizar bosquejo inicial	\N	2026-09-30 06:00:28.948583	2026-10-16 18:00:00	media	bloqueada	4.00	0.00
277	40	70	18	Optimizacion SQL	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-30 15:00:00	baja	en_progreso	11.50	10.00
279	40	70	20	Diseño de base de datos	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-10-03 03:56:00	baja	completada	7.00	8.50
278	40	70	19	Desarrollo de API REST	Ejecución técnica según requerimientos.	2026-09-30 02:52:15.533008	2026-09-30 20:30:00	baja	pendiente	10.50	0.00
281	41	72	2	Reunión cliente requisitos	\N	2026-09-30 05:56:14.191952	2026-09-30 21:00:00	alta	en_progreso	2.00	0.00
\.


--
-- TOC entry 5074 (class 0 OID 22827)
-- Dependencies: 224
-- Data for Name: usuario; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuario (id_usuario, id_equipo, nombre, email, rol, costo_hora, activo, usuario, contrasena) FROM stdin;
3	4	Genesis Sanchez	genesis@empresa.com	diseñador	20.00	t	Genesis	genesis123
5	3	Luis Blanca	luis@empresa.com	analista	16.00	t	Luis	luis123
4	2	Jose Abache	jose@empresa.com	administrador	15.00	t	Jose	jose123
1	1	Angel Aguilera	angel@empresa.com	desarrollador	25.00	t	Angel	angel123
6	4	Diego Herrera	diego.herrera@proyectmanager.com	analista	20.73	t	dherrera	pass123
7	3	Valeria Silva	valeria.silva@proyectmanager.com	desarrollador	24.12	t	vsilva	pass123
8	4	Fernando Castillo	fernando.castillo@proyectmanager.com	diseñador	25.04	t	fcastillo	pass123
9	1	Lucia Navarro	lucia.navarro@proyectmanager.com	analista	26.47	t	lnavarro	pass123
11	4	Camila Rivas	camila.rivas@proyectmanager.com	analista	17.06	t	crivas	pass123
12	2	Javier Ortega	javier.ortega@proyectmanager.com	diseñador	26.82	t	jortega	pass123
14	3	Ricardo Castro	ricardo.castro@proyectmanager.com	diseñador	26.04	t	rcastro	pass123
15	2	Elena Guzman	elena.guzman@proyectmanager.com	diseñador	18.50	t	eguzman	pass123
16	3	Hector Mora	hector.mora@proyectmanager.com	diseñador	24.59	t	hmora	pass123
17	1	Daniela Salazar	daniela.salazar@proyectmanager.com	diseñador	16.63	t	dsalazar	pass123
18	1	Alejandro Cruz	alejandro.cruz@proyectmanager.com	diseñador	25.70	t	acruz	pass123
22	1	Carlos Pinto	carlos.pinto@proyectmanager.com	analista	18.90	t	cpinto	pass123
23	1	Ana Rios	ana.rios@proyectmanager.com	analista	23.72	t	arios	pass123
24	3	Miguel Cardenas	miguel.cardenas@proyectmanager.com	diseñador	16.03	t	mcardenas	pass123
25	2	Laura Gil	laura.gil@proyectmanager.com	diseñador	25.19	t	lgil	pass123
26	2	Alejandro Sanchez	alejosz@proyectmanager.com	desarrollador	26.00	t	asanchez	alejandro123
2	\N	Kendra Cabello	kendra@empresa.com	administrador	30.00	t	Kendra	kendra123
10	2	Andres Peña	andres.peña@proyectmanager.com	analista	20.82	t	apeña	pass123
13	2	Mariana Vega	mariana.vega@proyectmanager.com	analista	25.62	t	mvega	pass123
19	2	Paula Mendez	paula.mendez@proyectmanager.com	analista	25.47	t	pmendez	pass123
20	2	Roberto Medina	roberto.medina@proyectmanager.com	desarrollador	16.68	t	rmedina	pass123
21	2	Sofia Vargas	sofia.vargas@proyectmanager.com	analista	18.93	t	svargas	pass123
\.


--
-- TOC entry 5113 (class 0 OID 0)
-- Dependencies: 219
-- Name: cliente_id_cliente_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cliente_id_cliente_seq', 17, true);


--
-- TOC entry 5114 (class 0 OID 0)
-- Dependencies: 231
-- Name: comentario_id_comentario_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.comentario_id_comentario_seq', 1, true);


--
-- TOC entry 5115 (class 0 OID 0)
-- Dependencies: 233
-- Name: config_notificacion_id_config_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.config_notificacion_id_config_seq', 2, true);


--
-- TOC entry 5116 (class 0 OID 0)
-- Dependencies: 235
-- Name: dependencia_tarea_id_dependencia_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dependencia_tarea_id_dependencia_seq', 1, false);


--
-- TOC entry 5117 (class 0 OID 0)
-- Dependencies: 221
-- Name: equipo_id_equipo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.equipo_id_equipo_seq', 4, true);


--
-- TOC entry 5118 (class 0 OID 0)
-- Dependencies: 237
-- Name: habilidad_id_habilidad_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.habilidad_id_habilidad_seq', 7, true);


--
-- TOC entry 5119 (class 0 OID 0)
-- Dependencies: 239
-- Name: habilidad_usuario_id_habilidad_usuario_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.habilidad_usuario_id_habilidad_usuario_seq', 53, true);


--
-- TOC entry 5120 (class 0 OID 0)
-- Dependencies: 241
-- Name: historial_cambio_id_historial_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.historial_cambio_id_historial_seq', 2, true);


--
-- TOC entry 5121 (class 0 OID 0)
-- Dependencies: 227
-- Name: hito_id_hito_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.hito_id_hito_seq', 72, true);


--
-- TOC entry 5122 (class 0 OID 0)
-- Dependencies: 243
-- Name: notificacion_id_notificacion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notificacion_id_notificacion_seq', 1, false);


--
-- TOC entry 5123 (class 0 OID 0)
-- Dependencies: 225
-- Name: proyecto_id_proyecto_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.proyecto_id_proyecto_seq', 41, true);


--
-- TOC entry 5124 (class 0 OID 0)
-- Dependencies: 229
-- Name: tarea_id_tarea_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tarea_id_tarea_seq', 282, true);


--
-- TOC entry 5125 (class 0 OID 0)
-- Dependencies: 223
-- Name: usuario_id_usuario_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.usuario_id_usuario_seq', 26, true);


--
-- TOC entry 4866 (class 2606 OID 22814)
-- Name: cliente cliente_email_contacto_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_email_contacto_key UNIQUE (email_contacto);


--
-- TOC entry 4868 (class 2606 OID 22812)
-- Name: cliente cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_pkey PRIMARY KEY (id_cliente);


--
-- TOC entry 4882 (class 2606 OID 22946)
-- Name: comentario comentario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comentario
    ADD CONSTRAINT comentario_pkey PRIMARY KEY (id_comentario);


--
-- TOC entry 4884 (class 2606 OID 22968)
-- Name: config_notificacion config_notificacion_id_usuario_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.config_notificacion
    ADD CONSTRAINT config_notificacion_id_usuario_key UNIQUE (id_usuario);


--
-- TOC entry 4886 (class 2606 OID 22966)
-- Name: config_notificacion config_notificacion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.config_notificacion
    ADD CONSTRAINT config_notificacion_pkey PRIMARY KEY (id_config);


--
-- TOC entry 4888 (class 2606 OID 22982)
-- Name: dependencia_tarea dependencia_tarea_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dependencia_tarea
    ADD CONSTRAINT dependencia_tarea_pkey PRIMARY KEY (id_dependencia);


--
-- TOC entry 4870 (class 2606 OID 22825)
-- Name: equipo equipo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipo
    ADD CONSTRAINT equipo_pkey PRIMARY KEY (id_equipo);


--
-- TOC entry 4890 (class 2606 OID 23003)
-- Name: habilidad habilidad_nombre_habilidad_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.habilidad
    ADD CONSTRAINT habilidad_nombre_habilidad_key UNIQUE (nombre_habilidad);


--
-- TOC entry 4892 (class 2606 OID 23001)
-- Name: habilidad habilidad_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.habilidad
    ADD CONSTRAINT habilidad_pkey PRIMARY KEY (id_habilidad);


--
-- TOC entry 4894 (class 2606 OID 23011)
-- Name: habilidad_usuario habilidad_usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.habilidad_usuario
    ADD CONSTRAINT habilidad_usuario_pkey PRIMARY KEY (id_habilidad_usuario);


--
-- TOC entry 4898 (class 2606 OID 23033)
-- Name: historial_cambio historial_cambio_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historial_cambio
    ADD CONSTRAINT historial_cambio_pkey PRIMARY KEY (id_historial);


--
-- TOC entry 4878 (class 2606 OID 22891)
-- Name: hito hito_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hito
    ADD CONSTRAINT hito_pkey PRIMARY KEY (id_hito);


--
-- TOC entry 4900 (class 2606 OID 23056)
-- Name: notificacion notificacion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notificacion
    ADD CONSTRAINT notificacion_pkey PRIMARY KEY (id_notificacion);


--
-- TOC entry 4876 (class 2606 OID 22870)
-- Name: proyecto proyecto_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proyecto
    ADD CONSTRAINT proyecto_pkey PRIMARY KEY (id_proyecto);


--
-- TOC entry 4880 (class 2606 OID 22919)
-- Name: tarea tarea_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tarea
    ADD CONSTRAINT tarea_pkey PRIMARY KEY (id_tarea);


--
-- TOC entry 4896 (class 2606 OID 23013)
-- Name: habilidad_usuario uk_habilidad_usuario; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.habilidad_usuario
    ADD CONSTRAINT uk_habilidad_usuario UNIQUE (id_usuario, id_habilidad);


--
-- TOC entry 4872 (class 2606 OID 22845)
-- Name: usuario usuario_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_email_key UNIQUE (email);


--
-- TOC entry 4874 (class 2606 OID 22843)
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id_usuario);


--
-- TOC entry 4918 (class 2620 OID 23062)
-- Name: tarea trg_bitacora_tarea; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_bitacora_tarea AFTER UPDATE ON public.tarea FOR EACH ROW EXECUTE FUNCTION public.fn_log_cambio_estado_tarea();


--
-- TOC entry 4908 (class 2606 OID 22947)
-- Name: comentario comentario_id_tarea_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comentario
    ADD CONSTRAINT comentario_id_tarea_fkey FOREIGN KEY (id_tarea) REFERENCES public.tarea(id_tarea) ON DELETE CASCADE;


--
-- TOC entry 4909 (class 2606 OID 22952)
-- Name: comentario comentario_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comentario
    ADD CONSTRAINT comentario_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario) ON DELETE CASCADE;


--
-- TOC entry 4910 (class 2606 OID 22969)
-- Name: config_notificacion config_notificacion_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.config_notificacion
    ADD CONSTRAINT config_notificacion_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario) ON DELETE CASCADE;


--
-- TOC entry 4911 (class 2606 OID 22988)
-- Name: dependencia_tarea dependencia_tarea_id_tarea_dependiente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dependencia_tarea
    ADD CONSTRAINT dependencia_tarea_id_tarea_dependiente_fkey FOREIGN KEY (id_tarea_dependiente) REFERENCES public.tarea(id_tarea) ON DELETE CASCADE;


--
-- TOC entry 4912 (class 2606 OID 22983)
-- Name: dependencia_tarea dependencia_tarea_id_tarea_principal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dependencia_tarea
    ADD CONSTRAINT dependencia_tarea_id_tarea_principal_fkey FOREIGN KEY (id_tarea_principal) REFERENCES public.tarea(id_tarea) ON DELETE CASCADE;


--
-- TOC entry 4913 (class 2606 OID 23019)
-- Name: habilidad_usuario habilidad_usuario_id_habilidad_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.habilidad_usuario
    ADD CONSTRAINT habilidad_usuario_id_habilidad_fkey FOREIGN KEY (id_habilidad) REFERENCES public.habilidad(id_habilidad) ON DELETE CASCADE;


--
-- TOC entry 4914 (class 2606 OID 23014)
-- Name: habilidad_usuario habilidad_usuario_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.habilidad_usuario
    ADD CONSTRAINT habilidad_usuario_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario) ON DELETE CASCADE;


--
-- TOC entry 4915 (class 2606 OID 23034)
-- Name: historial_cambio historial_cambio_id_tarea_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historial_cambio
    ADD CONSTRAINT historial_cambio_id_tarea_fkey FOREIGN KEY (id_tarea) REFERENCES public.tarea(id_tarea) ON DELETE CASCADE;


--
-- TOC entry 4916 (class 2606 OID 23039)
-- Name: historial_cambio historial_cambio_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historial_cambio
    ADD CONSTRAINT historial_cambio_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 4904 (class 2606 OID 22892)
-- Name: hito hito_id_proyecto_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hito
    ADD CONSTRAINT hito_id_proyecto_fkey FOREIGN KEY (id_proyecto) REFERENCES public.proyecto(id_proyecto) ON DELETE CASCADE;


--
-- TOC entry 4917 (class 2606 OID 23057)
-- Name: notificacion notificacion_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notificacion
    ADD CONSTRAINT notificacion_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario) ON DELETE CASCADE;


--
-- TOC entry 4902 (class 2606 OID 22871)
-- Name: proyecto proyecto_id_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proyecto
    ADD CONSTRAINT proyecto_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.cliente(id_cliente);


--
-- TOC entry 4903 (class 2606 OID 22876)
-- Name: proyecto proyecto_id_lider_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proyecto
    ADD CONSTRAINT proyecto_id_lider_fkey FOREIGN KEY (id_lider) REFERENCES public.usuario(id_usuario);


--
-- TOC entry 4905 (class 2606 OID 22925)
-- Name: tarea tarea_id_hito_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tarea
    ADD CONSTRAINT tarea_id_hito_fkey FOREIGN KEY (id_hito) REFERENCES public.hito(id_hito) ON DELETE SET NULL;


--
-- TOC entry 4906 (class 2606 OID 22920)
-- Name: tarea tarea_id_proyecto_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tarea
    ADD CONSTRAINT tarea_id_proyecto_fkey FOREIGN KEY (id_proyecto) REFERENCES public.proyecto(id_proyecto) ON DELETE CASCADE;


--
-- TOC entry 4907 (class 2606 OID 22930)
-- Name: tarea tarea_id_usuario_asignado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tarea
    ADD CONSTRAINT tarea_id_usuario_asignado_fkey FOREIGN KEY (id_usuario_asignado) REFERENCES public.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 4901 (class 2606 OID 22846)
-- Name: usuario usuario_id_equipo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_id_equipo_fkey FOREIGN KEY (id_equipo) REFERENCES public.equipo(id_equipo) ON DELETE SET NULL;


-- Completed on 2026-10-01 11:39:26

--
-- PostgreSQL database dump complete
--

\unrestrict uuNg7fa6l1ryDywauFsubD1xPCBSFWafUerTw8PK0GA5QoQKsNklnTuAV2riljo

