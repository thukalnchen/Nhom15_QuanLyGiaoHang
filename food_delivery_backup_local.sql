--
-- PostgreSQL database dump
--

\restrict 2TagBjkrCMe2Ij80p782A0sEYCkzivbGCd7fuaYF5vnmxRnqxMsDnir9Ar2ifSq

-- Dumped from database version 18.0
-- Dumped by pg_dump version 18.0

-- Started on 2025-11-11 22:23:39

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
-- TOC entry 5177 (class 1262 OID 16831)
-- Name: food_delivery_db; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE food_delivery_db WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1252';


ALTER DATABASE food_delivery_db OWNER TO postgres;

\unrestrict 2TagBjkrCMe2Ij80p782A0sEYCkzivbGCd7fuaYF5vnmxRnqxMsDnir9Ar2ifSq
\connect food_delivery_db
\restrict 2TagBjkrCMe2Ij80p782A0sEYCkzivbGCd7fuaYF5vnmxRnqxMsDnir9Ar2ifSq

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
-- TOC entry 4 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- TOC entry 5178 (class 0 OID 0)
-- Dependencies: 4
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 238 (class 1259 OID 17052)
-- Name: complaint_responses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.complaint_responses (
    id integer NOT NULL,
    complaint_id integer NOT NULL,
    user_id integer NOT NULL,
    user_role character varying(20) NOT NULL,
    message text NOT NULL,
    attachments jsonb DEFAULT '[]'::jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.complaint_responses OWNER TO postgres;

--
-- TOC entry 5179 (class 0 OID 0)
-- Dependencies: 238
-- Name: TABLE complaint_responses; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.complaint_responses IS 'Store complaint conversation history';


--
-- TOC entry 237 (class 1259 OID 17051)
-- Name: complaint_responses_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.complaint_responses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.complaint_responses_id_seq OWNER TO postgres;

--
-- TOC entry 5180 (class 0 OID 0)
-- Dependencies: 237
-- Name: complaint_responses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.complaint_responses_id_seq OWNED BY public.complaint_responses.id;


--
-- TOC entry 236 (class 1259 OID 17017)
-- Name: complaints; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.complaints (
    id integer NOT NULL,
    user_id integer NOT NULL,
    order_id integer NOT NULL,
    complaint_type character varying(50) NOT NULL,
    subject character varying(255) NOT NULL,
    description text NOT NULL,
    priority character varying(20) DEFAULT 'medium'::character varying,
    status character varying(20) DEFAULT 'open'::character varying,
    evidence_images jsonb DEFAULT '[]'::jsonb,
    resolution_note text,
    resolved_at timestamp without time zone,
    resolved_by integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_complaint_type CHECK (((complaint_type)::text = ANY ((ARRAY['product_issue'::character varying, 'delivery_issue'::character varying, 'driver_issue'::character varying, 'payment_issue'::character varying, 'service_issue'::character varying, 'other'::character varying])::text[]))),
    CONSTRAINT chk_priority CHECK (((priority)::text = ANY ((ARRAY['low'::character varying, 'medium'::character varying, 'high'::character varying, 'urgent'::character varying])::text[]))),
    CONSTRAINT chk_status CHECK (((status)::text = ANY ((ARRAY['open'::character varying, 'in_progress'::character varying, 'resolved'::character varying, 'closed'::character varying])::text[])))
);


ALTER TABLE public.complaints OWNER TO postgres;

--
-- TOC entry 5181 (class 0 OID 0)
-- Dependencies: 236
-- Name: TABLE complaints; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.complaints IS 'Store customer complaints and feedback';


--
-- TOC entry 5182 (class 0 OID 0)
-- Dependencies: 236
-- Name: COLUMN complaints.complaint_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.complaints.complaint_type IS 'Type of complaint: product_issue, delivery_issue, driver_issue, payment_issue, service_issue, other';


--
-- TOC entry 5183 (class 0 OID 0)
-- Dependencies: 236
-- Name: COLUMN complaints.priority; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.complaints.priority IS 'Priority level: low, medium, high, urgent';


--
-- TOC entry 5184 (class 0 OID 0)
-- Dependencies: 236
-- Name: COLUMN complaints.status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.complaints.status IS 'Status: open, in_progress, resolved, closed';


--
-- TOC entry 5185 (class 0 OID 0)
-- Dependencies: 236
-- Name: COLUMN complaints.evidence_images; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.complaints.evidence_images IS 'JSON array of evidence image file paths';


--
-- TOC entry 235 (class 1259 OID 17016)
-- Name: complaints_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.complaints_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.complaints_id_seq OWNER TO postgres;

--
-- TOC entry 5186 (class 0 OID 0)
-- Dependencies: 235
-- Name: complaints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.complaints_id_seq OWNED BY public.complaints.id;


--
-- TOC entry 226 (class 1259 OID 16894)
-- Name: delivery_tracking; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.delivery_tracking (
    id integer NOT NULL,
    order_id integer,
    shipper_id integer,
    latitude numeric(10,8),
    longitude numeric(11,8),
    address text,
    status character varying(50) DEFAULT 'preparing'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.delivery_tracking OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16893)
-- Name: delivery_tracking_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.delivery_tracking_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.delivery_tracking_id_seq OWNER TO postgres;

--
-- TOC entry 5187 (class 0 OID 0)
-- Dependencies: 225
-- Name: delivery_tracking_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.delivery_tracking_id_seq OWNED BY public.delivery_tracking.id;


--
-- TOC entry 230 (class 1259 OID 16938)
-- Name: menu_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.menu_items (
    id integer NOT NULL,
    restaurant_id integer,
    name character varying(255) NOT NULL,
    description text,
    price integer NOT NULL,
    category character varying(100),
    image_url text,
    is_available boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.menu_items OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16937)
-- Name: menu_items_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.menu_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.menu_items_id_seq OWNER TO postgres;

--
-- TOC entry 5188 (class 0 OID 0)
-- Dependencies: 229
-- Name: menu_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.menu_items_id_seq OWNED BY public.menu_items.id;


--
-- TOC entry 234 (class 1259 OID 16989)
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    user_id integer NOT NULL,
    title character varying(255) NOT NULL,
    body text NOT NULL,
    type character varying(50) DEFAULT 'general'::character varying,
    reference_id integer,
    data jsonb DEFAULT '{}'::jsonb,
    is_read boolean DEFAULT false,
    read_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- TOC entry 5189 (class 0 OID 0)
-- Dependencies: 234
-- Name: TABLE notifications; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.notifications IS 'Store all user notifications including push notifications';


--
-- TOC entry 5190 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN notifications.type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.notifications.type IS 'Notification type: general, order, payment, driver, system';


--
-- TOC entry 5191 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN notifications.reference_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.notifications.reference_id IS 'Reference ID to related entity (order_id, etc)';


--
-- TOC entry 5192 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN notifications.data; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.notifications.data IS 'Additional JSON data for the notification';


--
-- TOC entry 233 (class 1259 OID 16988)
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notifications_id_seq OWNER TO postgres;

--
-- TOC entry 5193 (class 0 OID 0)
-- Dependencies: 233
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- TOC entry 232 (class 1259 OID 16958)
-- Name: order_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_items (
    id integer NOT NULL,
    order_id integer,
    menu_item_id integer,
    quantity integer DEFAULT 1 NOT NULL,
    price integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.order_items OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 16957)
-- Name: order_items_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.order_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.order_items_id_seq OWNER TO postgres;

--
-- TOC entry 5194 (class 0 OID 0)
-- Dependencies: 231
-- Name: order_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.order_items_id_seq OWNED BY public.order_items.id;


--
-- TOC entry 224 (class 1259 OID 16877)
-- Name: order_status_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_status_history (
    id integer NOT NULL,
    order_id integer,
    status character varying(50) NOT NULL,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.order_status_history OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16876)
-- Name: order_status_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.order_status_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.order_status_history_id_seq OWNER TO postgres;

--
-- TOC entry 5195 (class 0 OID 0)
-- Dependencies: 223
-- Name: order_status_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.order_status_history_id_seq OWNED BY public.order_status_history.id;


--
-- TOC entry 222 (class 1259 OID 16851)
-- Name: orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orders (
    id integer NOT NULL,
    order_number character varying(50) NOT NULL,
    user_id integer,
    restaurant_name character varying(255),
    items jsonb,
    total_amount numeric(10,2) NOT NULL,
    delivery_fee numeric(10,2) DEFAULT 0,
    status character varying(50) DEFAULT 'pending'::character varying,
    delivery_address text NOT NULL,
    delivery_phone character varying(20),
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    vehicle_type character varying(50),
    pickup_address text,
    pickup_lat numeric(10,7),
    pickup_lng numeric(10,7),
    delivery_lat numeric(10,7),
    delivery_lng numeric(10,7),
    recipient_name character varying(255),
    recipient_phone character varying(20),
    distance numeric(10,2),
    duration character varying(50),
    services jsonb DEFAULT '[]'::jsonb,
    base_fare numeric(10,2),
    service_fee numeric(10,2) DEFAULT 0,
    cancellation_reason text,
    cancellation_type character varying(50),
    cancelled_at timestamp without time zone,
    cancelled_by integer,
    payment_status character varying(50) DEFAULT 'pending'::character varying,
    payment_method character varying(50),
    refund_status character varying(50),
    refund_initiated_at timestamp without time zone,
    warehouse_id character varying(50),
    warehouse_name character varying(255),
    intake_staff_id character varying(50),
    intake_staff_name character varying(255),
    received_at timestamp without time zone,
    classified_at timestamp without time zone,
    zone character varying(20),
    recommended_vehicle character varying(20),
    cod_payment_type character varying(20),
    cod_collected_at_warehouse boolean DEFAULT false,
    cod_collected_at timestamp without time zone,
    customer_estimated_size character varying(20),
    customer_requested_vehicle character varying(20),
    package_size character varying(50),
    package_type character varying(50),
    weight numeric(10,2),
    description text,
    images jsonb
);


ALTER TABLE public.orders OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16850)
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.orders_id_seq OWNER TO postgres;

--
-- TOC entry 5196 (class 0 OID 0)
-- Dependencies: 221
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.orders_id_seq OWNED BY public.orders.id;


--
-- TOC entry 228 (class 1259 OID 16922)
-- Name: restaurants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.restaurants (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    address text NOT NULL,
    phone character varying(20),
    image_url text,
    rating numeric(2,1) DEFAULT 0,
    cuisine_type character varying(100),
    delivery_time character varying(50),
    delivery_fee integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.restaurants OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16921)
-- Name: restaurants_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.restaurants_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.restaurants_id_seq OWNER TO postgres;

--
-- TOC entry 5197 (class 0 OID 0)
-- Dependencies: 227
-- Name: restaurants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.restaurants_id_seq OWNED BY public.restaurants.id;


--
-- TOC entry 220 (class 1259 OID 16833)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    email character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    full_name character varying(255) NOT NULL,
    phone character varying(20),
    address text,
    role character varying(20) DEFAULT 'customer'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fcm_token text
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16832)
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- TOC entry 5198 (class 0 OID 0)
-- Dependencies: 219
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- TOC entry 4944 (class 2604 OID 17055)
-- Name: complaint_responses id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.complaint_responses ALTER COLUMN id SET DEFAULT nextval('public.complaint_responses_id_seq'::regclass);


--
-- TOC entry 4938 (class 2604 OID 17020)
-- Name: complaints id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.complaints ALTER COLUMN id SET DEFAULT nextval('public.complaints_id_seq'::regclass);


--
-- TOC entry 4916 (class 2604 OID 16897)
-- Name: delivery_tracking id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_tracking ALTER COLUMN id SET DEFAULT nextval('public.delivery_tracking_id_seq'::regclass);


--
-- TOC entry 4925 (class 2604 OID 16941)
-- Name: menu_items id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items ALTER COLUMN id SET DEFAULT nextval('public.menu_items_id_seq'::regclass);


--
-- TOC entry 4932 (class 2604 OID 16992)
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- TOC entry 4929 (class 2604 OID 16961)
-- Name: order_items id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items ALTER COLUMN id SET DEFAULT nextval('public.order_items_id_seq'::regclass);


--
-- TOC entry 4914 (class 2604 OID 16880)
-- Name: order_status_history id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_status_history ALTER COLUMN id SET DEFAULT nextval('public.order_status_history_id_seq'::regclass);


--
-- TOC entry 4905 (class 2604 OID 16854)
-- Name: orders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);


--
-- TOC entry 4920 (class 2604 OID 16925)
-- Name: restaurants id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.restaurants ALTER COLUMN id SET DEFAULT nextval('public.restaurants_id_seq'::regclass);


--
-- TOC entry 4901 (class 2604 OID 16836)
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- TOC entry 5171 (class 0 OID 17052)
-- Dependencies: 238
-- Data for Name: complaint_responses; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5169 (class 0 OID 17017)
-- Dependencies: 236
-- Data for Name: complaints; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5159 (class 0 OID 16894)
-- Dependencies: 226
-- Data for Name: delivery_tracking; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.delivery_tracking (id, order_id, shipper_id, latitude, longitude, address, status, created_at, updated_at) VALUES (1, 1, NULL, NULL, NULL, NULL, 'preparing', '2025-10-15 09:36:09.334991', '2025-10-15 09:36:09.334991');
INSERT INTO public.delivery_tracking (id, order_id, shipper_id, latitude, longitude, address, status, created_at, updated_at) VALUES (2, 2, NULL, NULL, NULL, NULL, 'preparing', '2025-10-15 09:36:12.019498', '2025-10-15 09:36:12.019498');
INSERT INTO public.delivery_tracking (id, order_id, shipper_id, latitude, longitude, address, status, created_at, updated_at) VALUES (3, 3, NULL, NULL, NULL, NULL, 'preparing', '2025-10-15 09:39:58.984285', '2025-10-15 09:39:58.984285');
INSERT INTO public.delivery_tracking (id, order_id, shipper_id, latitude, longitude, address, status, created_at, updated_at) VALUES (4, 4, NULL, NULL, NULL, NULL, 'preparing', '2025-10-15 09:40:02.666991', '2025-10-15 09:40:02.666991');
INSERT INTO public.delivery_tracking (id, order_id, shipper_id, latitude, longitude, address, status, created_at, updated_at) VALUES (5, 5, NULL, NULL, NULL, NULL, 'preparing', '2025-10-15 09:40:03.449784', '2025-10-15 09:40:03.449784');
INSERT INTO public.delivery_tracking (id, order_id, shipper_id, latitude, longitude, address, status, created_at, updated_at) VALUES (6, 6, NULL, NULL, NULL, NULL, 'preparing', '2025-10-15 09:40:04.485553', '2025-10-15 09:40:04.485553');
INSERT INTO public.delivery_tracking (id, order_id, shipper_id, latitude, longitude, address, status, created_at, updated_at) VALUES (7, 7, NULL, NULL, NULL, NULL, 'preparing', '2025-10-15 09:40:05.749575', '2025-10-15 09:40:05.749575');
INSERT INTO public.delivery_tracking (id, order_id, shipper_id, latitude, longitude, address, status, created_at, updated_at) VALUES (8, 8, NULL, NULL, NULL, NULL, 'preparing', '2025-10-15 09:40:09.279539', '2025-10-15 09:40:09.279539');
INSERT INTO public.delivery_tracking (id, order_id, shipper_id, latitude, longitude, address, status, created_at, updated_at) VALUES (9, 9, NULL, NULL, NULL, NULL, 'preparing', '2025-10-15 09:40:10.451352', '2025-10-15 09:40:10.451352');
INSERT INTO public.delivery_tracking (id, order_id, shipper_id, latitude, longitude, address, status, created_at, updated_at) VALUES (10, 10, NULL, NULL, NULL, NULL, 'preparing', '2025-10-15 09:42:19.437312', '2025-10-15 09:42:19.437312');
INSERT INTO public.delivery_tracking (id, order_id, shipper_id, latitude, longitude, address, status, created_at, updated_at) VALUES (11, 16, NULL, NULL, NULL, NULL, 'preparing', '2025-10-28 22:04:24.522722', '2025-10-28 22:04:24.522722');
INSERT INTO public.delivery_tracking (id, order_id, shipper_id, latitude, longitude, address, status, created_at, updated_at) VALUES (12, 17, NULL, NULL, NULL, NULL, 'preparing', '2025-10-28 22:04:42.360283', '2025-10-28 22:04:42.360283');
INSERT INTO public.delivery_tracking (id, order_id, shipper_id, latitude, longitude, address, status, created_at, updated_at) VALUES (13, 18, NULL, NULL, NULL, NULL, 'preparing', '2025-10-28 22:04:42.501055', '2025-10-28 22:04:42.501055');
INSERT INTO public.delivery_tracking (id, order_id, shipper_id, latitude, longitude, address, status, created_at, updated_at) VALUES (14, 19, NULL, NULL, NULL, NULL, 'preparing', '2025-10-28 22:04:42.642056', '2025-10-28 22:04:42.642056');
INSERT INTO public.delivery_tracking (id, order_id, shipper_id, latitude, longitude, address, status, created_at, updated_at) VALUES (15, 24, NULL, NULL, NULL, NULL, 'preparing', '2025-11-08 12:54:33.794136', '2025-11-08 12:54:33.794136');
INSERT INTO public.delivery_tracking (id, order_id, shipper_id, latitude, longitude, address, status, created_at, updated_at) VALUES (16, 25, NULL, NULL, NULL, NULL, 'preparing', '2025-11-08 14:05:29.69643', '2025-11-08 14:05:29.69643');
INSERT INTO public.delivery_tracking (id, order_id, shipper_id, latitude, longitude, address, status, created_at, updated_at) VALUES (17, 26, NULL, NULL, NULL, NULL, 'preparing', '2025-11-08 14:06:01.24016', '2025-11-08 14:06:01.24016');
INSERT INTO public.delivery_tracking (id, order_id, shipper_id, latitude, longitude, address, status, created_at, updated_at) VALUES (18, 27, NULL, NULL, NULL, NULL, 'preparing', '2025-11-08 19:58:19.214606', '2025-11-08 19:58:19.214606');
INSERT INTO public.delivery_tracking (id, order_id, shipper_id, latitude, longitude, address, status, created_at, updated_at) VALUES (19, 28, NULL, NULL, NULL, NULL, 'preparing', '2025-11-08 20:02:09.047188', '2025-11-08 20:02:09.047188');
INSERT INTO public.delivery_tracking (id, order_id, shipper_id, latitude, longitude, address, status, created_at, updated_at) VALUES (20, 29, NULL, NULL, NULL, NULL, 'preparing', '2025-11-08 20:02:44.390439', '2025-11-08 20:02:44.390439');
INSERT INTO public.delivery_tracking (id, order_id, shipper_id, latitude, longitude, address, status, created_at, updated_at) VALUES (21, 30, NULL, NULL, NULL, NULL, 'preparing', '2025-11-09 21:57:11.066623', '2025-11-09 21:57:11.066623');
INSERT INTO public.delivery_tracking (id, order_id, shipper_id, latitude, longitude, address, status, created_at, updated_at) VALUES (22, 31, NULL, NULL, NULL, NULL, 'preparing', '2025-11-09 21:57:43.863843', '2025-11-09 21:57:43.863843');
INSERT INTO public.delivery_tracking (id, order_id, shipper_id, latitude, longitude, address, status, created_at, updated_at) VALUES (23, 32, NULL, NULL, NULL, NULL, 'preparing', '2025-11-09 22:54:24.007135', '2025-11-09 22:54:24.007135');


--
-- TOC entry 5163 (class 0 OID 16938)
-- Dependencies: 230
-- Data for Name: menu_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (27, 6, 'Margherita Pizza', 'Classic tomato sauce, mozzarella, fresh basil', 89000, 'Pizza', 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (28, 6, 'Pepperoni Pizza', 'Tomato sauce, mozzarella, pepperoni', 109000, 'Pizza', 'https://images.unsplash.com/photo-1628840042765-356cda07504e', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (29, 6, 'Hawaiian Pizza', 'Ham, pineapple, mozzarella', 99000, 'Pizza', 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (30, 6, 'Garlic Bread', 'Toasted bread with garlic butter', 35000, 'Appetizer', 'https://images.unsplash.com/photo-1612682270351-0892c7b9e67e', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (31, 6, 'Caesar Salad', 'Romaine lettuce, parmesan, croutons', 45000, 'Salad', 'https://images.unsplash.com/photo-1546793665-c74683f339c1', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (32, 7, 'Classic Burger', 'Beef patty, lettuce, tomato, cheese', 79000, 'Burger', 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (33, 7, 'Cheese Burger', 'Double beef patty, double cheese', 99000, 'Burger', 'https://images.unsplash.com/photo-1586190848861-99aa4a171e90', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (34, 7, 'Chicken Burger', 'Crispy chicken, special sauce', 75000, 'Burger', 'https://images.unsplash.com/photo-1606755962773-d324e0a13086', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (35, 7, 'French Fries', 'Crispy golden fries', 30000, 'Side', 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (36, 7, 'Onion Rings', 'Crispy battered onion rings', 35000, 'Side', 'https://images.unsplash.com/photo-1639024471283-03518883512d', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (37, 7, 'Milkshake', 'Chocolate, Vanilla, or Strawberry', 45000, 'Drink', 'https://images.unsplash.com/photo-1572490122747-3968b75cc699', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (38, 8, 'Salmon Sushi Set', '8 pieces fresh salmon sushi', 159000, 'Sushi', 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (39, 8, 'California Roll', '8 pieces california roll', 129000, 'Roll', 'https://images.unsplash.com/photo-1617196034796-73dfa7b1fd56', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (40, 8, 'Dragon Roll', '8 pieces dragon roll', 149000, 'Roll', 'https://images.unsplash.com/photo-1611143669185-af224c5e3252', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (41, 8, 'Miso Soup', 'Traditional Japanese soup', 25000, 'Soup', 'https://images.unsplash.com/photo-1606491956689-2ea866880c84', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (42, 8, 'Edamame', 'Steamed soybeans with salt', 30000, 'Appetizer', 'https://images.unsplash.com/photo-1583573607873-4edb1b6e6fdd', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (43, 9, 'Pho Bo', 'Beef noodle soup', 55000, 'Noodles', 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (44, 9, 'Pho Ga', 'Chicken noodle soup', 50000, 'Noodles', 'https://images.unsplash.com/photo-1591814468924-caf88d1232e1', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (45, 9, 'Bun Cha', 'Grilled pork with rice noodles', 60000, 'Noodles', 'https://images.unsplash.com/photo-1608039829572-78524f79c4c7', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (46, 9, 'Banh Mi', 'Vietnamese baguette sandwich', 35000, 'Sandwich', 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (47, 9, 'Iced Coffee', 'Vietnamese iced coffee', 25000, 'Drink', 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (48, 10, 'Chocolate Cake', 'Rich chocolate layer cake', 45000, 'Cake', 'https://images.unsplash.com/photo-1578985545062-69928b1d9587', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (49, 10, 'Tiramisu', 'Italian coffee-flavored dessert', 55000, 'Cake', 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (50, 10, 'Croissant', 'Buttery flaky pastry', 25000, 'Pastry', 'https://images.unsplash.com/photo-1555507036-ab1f4038808a', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (51, 10, 'Macaron Box', 'Assorted macarons (6 pieces)', 65000, 'Dessert', 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.menu_items (id, restaurant_id, name, description, price, category, image_url, is_available, created_at, updated_at) VALUES (52, 10, 'Cappuccino', 'Espresso with steamed milk', 35000, 'Drink', 'https://images.unsplash.com/photo-1572442388796-11668a67e53d', true, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');


--
-- TOC entry 5167 (class 0 OID 16989)
-- Dependencies: 234
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5165 (class 0 OID 16958)
-- Dependencies: 232
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5157 (class 0 OID 16877)
-- Dependencies: 224
-- Data for Name: order_status_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.order_status_history (id, order_id, status, notes, created_at) VALUES (1, 1, 'pending', 'Order created', '2025-10-15 09:36:09.330989');
INSERT INTO public.order_status_history (id, order_id, status, notes, created_at) VALUES (2, 2, 'pending', 'Order created', '2025-10-15 09:36:12.018776');
INSERT INTO public.order_status_history (id, order_id, status, notes, created_at) VALUES (3, 3, 'pending', 'Order created', '2025-10-15 09:39:58.980983');
INSERT INTO public.order_status_history (id, order_id, status, notes, created_at) VALUES (4, 4, 'pending', 'Order created', '2025-10-15 09:40:02.665877');
INSERT INTO public.order_status_history (id, order_id, status, notes, created_at) VALUES (5, 5, 'pending', 'Order created', '2025-10-15 09:40:03.449184');
INSERT INTO public.order_status_history (id, order_id, status, notes, created_at) VALUES (6, 6, 'pending', 'Order created', '2025-10-15 09:40:04.484788');
INSERT INTO public.order_status_history (id, order_id, status, notes, created_at) VALUES (7, 7, 'pending', 'Order created', '2025-10-15 09:40:05.748938');
INSERT INTO public.order_status_history (id, order_id, status, notes, created_at) VALUES (8, 8, 'pending', 'Order created', '2025-10-15 09:40:09.278995');
INSERT INTO public.order_status_history (id, order_id, status, notes, created_at) VALUES (9, 9, 'pending', 'Order created', '2025-10-15 09:40:10.45076');
INSERT INTO public.order_status_history (id, order_id, status, notes, created_at) VALUES (10, 10, 'pending', 'Order created', '2025-10-15 09:42:19.434747');
INSERT INTO public.order_status_history (id, order_id, status, notes, created_at) VALUES (11, 16, 'pending', 'Đơn hàng đã được tạo', '2025-10-28 22:04:24.515722');
INSERT INTO public.order_status_history (id, order_id, status, notes, created_at) VALUES (12, 17, 'pending', 'Đơn hàng đã được tạo', '2025-10-28 22:04:42.357335');
INSERT INTO public.order_status_history (id, order_id, status, notes, created_at) VALUES (13, 18, 'pending', 'Đơn hàng đã được tạo', '2025-10-28 22:04:42.497277');
INSERT INTO public.order_status_history (id, order_id, status, notes, created_at) VALUES (14, 19, 'pending', 'Đơn hàng đã được tạo', '2025-10-28 22:04:42.639731');
INSERT INTO public.order_status_history (id, order_id, status, notes, created_at) VALUES (15, 19, 'cancelled', 'Test cancellation', '2025-10-28 22:37:25.686818');
INSERT INTO public.order_status_history (id, order_id, status, notes, created_at) VALUES (16, 24, 'pending', 'Order created', '2025-11-08 12:54:33.788172');
INSERT INTO public.order_status_history (id, order_id, status, notes, created_at) VALUES (17, 25, 'pending', 'Order created', '2025-11-08 14:05:29.693902');
INSERT INTO public.order_status_history (id, order_id, status, notes, created_at) VALUES (18, 26, 'pending', 'Order created', '2025-11-08 14:06:01.239078');
INSERT INTO public.order_status_history (id, order_id, status, notes, created_at) VALUES (19, 27, 'pending', 'Đơn hàng đã được tạo', '2025-11-08 19:58:19.21025');
INSERT INTO public.order_status_history (id, order_id, status, notes, created_at) VALUES (20, 28, 'pending', 'Order created', '2025-11-08 20:02:09.044791');
INSERT INTO public.order_status_history (id, order_id, status, notes, created_at) VALUES (21, 29, 'pending', 'Order created', '2025-11-08 20:02:44.389114');
INSERT INTO public.order_status_history (id, order_id, status, notes, created_at) VALUES (22, 30, 'pending', 'Order created', '2025-11-09 21:57:11.06042');
INSERT INTO public.order_status_history (id, order_id, status, notes, created_at) VALUES (23, 31, 'pending', 'Order created', '2025-11-09 21:57:43.857441');
INSERT INTO public.order_status_history (id, order_id, status, notes, created_at) VALUES (24, 32, 'pending', 'Order created', '2025-11-09 22:54:24.001466');


--
-- TOC entry 5155 (class 0 OID 16851)
-- Dependencies: 222
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (1, 'ORD-1760495769253-89567E30', 1, 'Lau', '[{"name": "Lau bo", "price": 700000, "quantity": 1}]', 715000.00, 15000.00, 'pending', '33 Hoang Ngan, HaNoi', '0812938948', 'fdfdf', '2025-10-15 09:36:09.290827', '2025-10-15 09:36:09.290827', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (2, 'ORD-1760495772016-BE52E64A', 1, 'Lau', '[{"name": "Lau bo", "price": 700000, "quantity": 1}]', 715000.00, 15000.00, 'pending', '33 Hoang Ngan, HaNoi', '0812938948', 'fdfdf', '2025-10-15 09:36:12.017743', '2025-10-15 09:36:12.017743', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (3, 'ORD-1760495998917-52C3F5B6', 1, 'Hoang Ngan', '[{"name": "Lau bo", "price": 700000, "quantity": 1}]', 715000.00, 15000.00, 'pending', '33 Hoang ngan', '0812938948', 'g', '2025-10-15 09:39:58.959131', '2025-10-15 09:39:58.959131', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (4, 'ORD-1760496002663-D4355538', 1, 'Hoang Ngan', '[{"name": "Lau bo", "price": 700000, "quantity": 1}]', 715000.00, 15000.00, 'pending', '33 Hoang ngan', '0812938948', 'g', '2025-10-15 09:40:02.664812', '2025-10-15 09:40:02.664812', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (5, 'ORD-1760496003447-FB08D862', 1, 'Hoang Ngan', '[{"name": "Lau bo", "price": 700000, "quantity": 1}]', 715000.00, 15000.00, 'pending', '33 Hoang ngan', '0812938948', 'g', '2025-10-15 09:40:03.448182', '2025-10-15 09:40:03.448182', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (6, 'ORD-1760496004482-33B80C16', 1, 'Hoang Ngan', '[{"name": "Lau bo", "price": 700000, "quantity": 1}]', 715000.00, 15000.00, 'pending', '33 Hoang ngan', '0812938948', 'g', '2025-10-15 09:40:04.48374', '2025-10-15 09:40:04.48374', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (7, 'ORD-1760496005746-89520A52', 1, 'Hoang Ngan', '[{"name": "Lau bo", "price": 700000, "quantity": 1}]', 715000.00, 15000.00, 'pending', '33 Hoang ngan', '0812938948', 'g', '2025-10-15 09:40:05.747865', '2025-10-15 09:40:05.747865', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (8, 'ORD-1760496009276-52A32DD7', 1, 'Hoang Ngan', '[{"name": "Lau bo", "price": 700000, "quantity": 1}]', 715000.00, 15000.00, 'pending', '33 Hoang ngan', '0812938948', 'g', '2025-10-15 09:40:09.2778', '2025-10-15 09:40:09.2778', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (9, 'ORD-1760496010448-A99E1C25', 1, 'Hoang Ngan', '[{"name": "Lau bo", "price": 700000, "quantity": 1}]', 715000.00, 15000.00, 'pending', '33 Hoang ngan', '0812938948', 'g', '2025-10-15 09:40:10.449829', '2025-10-15 09:40:10.449829', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (10, 'ORD-1760496139428-713EB70F', 1, 'Hoang Ngan', '[{"name": "Lau bo", "price": 700000, "quantity": 1}]', 715000.00, 15000.00, 'pending', '33 Hoang ngan', '0812938948', 'g', '2025-10-15 09:42:19.42949', '2025-10-15 09:42:19.42949', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (11, 'ORD1761640623292001', 1, 'Pizza Paradise', '[{"id": 1, "name": "Phở Bò Tái", "price": 65000, "quantity": 2}, {"id": 2, "name": "Gỏi Cuốn", "price": 35000, "quantity": 1}]', 165000.00, 15000.00, 'delivered', '123 Test Street, District 1, HCMC', '0909123456', 'Please ring doorbell', '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (12, 'ORD1761640623307002', 1, 'Burger House', '[{"id": 3, "name": "Bún Chả Hà Nội", "price": 55000, "quantity": 1}]', 70000.00, 15000.00, 'in_transit', '123 Test Street, District 1, HCMC', '0909123456', NULL, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (13, 'ORD1761640623307003', 1, 'Sushi Station', '[{"id": 5, "name": "Cơm Tấm Sườn Bì", "price": 50000, "quantity": 1}, {"id": 6, "name": "Trà Đá", "price": 5000, "quantity": 2}]', 60000.00, 10000.00, 'processing', '123 Test Street, District 1, HCMC', '0909123456', NULL, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (14, 'ORD1761640623308004', 1, 'Pho Vietnam', '[{"id": 7, "name": "Bánh Mì Thịt", "price": 25000, "quantity": 3}]', 75000.00, 10000.00, 'pending', '123 Test Street, District 1, HCMC', '0909123456', NULL, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (15, 'ORD1761640623308005', 1, 'Sweet Dreams Bakery', '[{"id": 9, "name": "Hủ Tiếu Nam Vang", "price": 60000, "quantity": 2}]', 135000.00, 15000.00, 'confirmed', '123 Test Street, District 1, HCMC', '0909123456', NULL, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (16, 'DLV-1761663864495-22D5DB59', 1, NULL, NULL, 23904.00, 0.00, 'pending', 'Landmark 81, 720A Đ. Điện Biên Phủ, Vinhomes Tân Cảng, Bình Thạnh, TP.HCM', NULL, 'Giao hàng giờ hành chính. Gọi trước 5 phút.', '2025-10-28 22:04:24.497276', '2025-10-28 22:04:24.497276', 'motorcycle', 'Đại học Huflit, 140 Lý Thường Kiệt, Phường 7, Quận 10, TP.HCM', 10.7829000, 106.6893000, 10.7946000, 106.7218000, 'Nguyễn Văn A', '0901234567', 3.78, '8 phút', '["Giao hàng nhanh", "Gọi trước khi đến"]', 18904.00, 5000.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (17, 'DLV-1761663882350-A4371F82', 1, NULL, NULL, 23904.00, 0.00, 'pending', 'Landmark 81, 720A Đ. Điện Biên Phủ, Vinhomes Tân Cảng, Bình Thạnh, TP.HCM', NULL, 'Giao hàng giờ hành chính. Gọi trước 5 phút.', '2025-10-28 22:04:42.351578', '2025-10-28 22:04:42.351578', 'motorcycle', 'Đại học Huflit, 140 Lý Thường Kiệt, Phường 7, Quận 10, TP.HCM', 10.7829000, 106.6893000, 10.7946000, 106.7218000, 'Nguyễn Văn A', '0901234567', 3.78, '8 phút', '["Giao hàng nhanh", "Gọi trước khi đến"]', 18904.00, 5000.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (18, 'DLV-1761663882490-C855BAE4', 1, NULL, NULL, 23904.00, 0.00, 'pending', 'Landmark 81, 720A Đ. Điện Biên Phủ, Vinhomes Tân Cảng, Bình Thạnh, TP.HCM', NULL, 'Giao hàng giờ hành chính. Gọi trước 5 phút.', '2025-10-28 22:04:42.491622', '2025-10-28 22:04:42.491622', 'motorcycle', 'Đại học Huflit, 140 Lý Thường Kiệt, Phường 7, Quận 10, TP.HCM', 10.7829000, 106.6893000, 10.7946000, 106.7218000, 'Nguyễn Văn A', '0901234567', 3.78, '8 phút', '["Giao hàng nhanh", "Gọi trước khi đến"]', 18904.00, 5000.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (20, 'TEST-1762441668142', 1, NULL, NULL, 100000.00, 50000.00, 'classified', '456 Trần Văn B, Quận 3, TP.HCM', NULL, NULL, '2025-11-06 22:07:48.226007', '2025-11-06 22:07:48.226007', NULL, '123 Nguyễn Văn A, Quận 1, TP.HCM', 10.7626220, 106.6601720, 10.7864000, 106.6952000, 'Trần Thị Nhận', '0912345678', NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, 'WH-001', 'Kho Trung Tâm Q1', 'intake-staff-456', 'Nguyễn Staff Test', '2025-11-06 22:07:48.294622', '2025-11-06 22:07:48.313727', 'zone_3', 'car', NULL, false, NULL, 'medium', 'car', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (21, 'TEST-1762441720908', 1, NULL, NULL, 100000.00, 50000.00, 'classified', '456 Trần Văn B, Quận 3, TP.HCM', NULL, NULL, '2025-11-06 22:08:40.958599', '2025-11-06 22:08:40.958599', NULL, '123 Nguyễn Văn A, Quận 1, TP.HCM', 10.7626220, 106.6601720, 10.7864000, 106.6952000, 'Trần Thị Nhận', '0912345678', NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, 'WH-001', 'Kho Trung Tâm Q1', 'intake-staff-456', 'Nguyễn Staff Test', '2025-11-06 22:08:40.970099', '2025-11-06 22:08:40.975285', 'zone_3', 'car', NULL, false, NULL, 'medium', 'car', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (22, 'TEST-1762443450465', 3, NULL, NULL, 100000.00, 50000.00, 'assigned_to_driver', '456 Trần Văn B, Quận 3, TP.HCM', NULL, NULL, '2025-11-06 22:37:30.52668', '2025-11-06 22:37:30.52668', 'bike', '123 Nguyễn Văn A, Quận 1, TP.HCM', 10.7626220, 106.6601720, 10.7864000, 106.6952000, 'Trần Thị Nhận', '0912345678', NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, 'WH-001', 'Kho Trung Tâm Q1', 'intake-staff-456', 'Nguyễn Staff Test', '2025-11-06 22:37:30.535368', '2025-11-06 22:37:30.539376', 'zone_3', 'car', NULL, false, NULL, 'medium', 'car', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (23, 'TEST-1762444256020', 3, NULL, NULL, 100000.00, 50000.00, 'assigned_to_driver', '456 Trần Văn B, Quận 3, TP.HCM', NULL, NULL, '2025-11-06 22:50:56.072357', '2025-11-06 22:50:56.072357', 'bike', '123 Nguyễn Văn A, Quận 1, TP.HCM', 10.7626220, 106.6601720, 10.7864000, 106.6952000, 'Trần Thị Nhận', '0912345678', NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, 'WH-001', 'Kho Trung Tâm Q1', 'intake-staff-456', 'Nguyễn Staff Test', '2025-11-06 22:50:56.082591', '2025-11-06 22:50:56.086909', 'zone_3', 'car', NULL, false, NULL, 'medium', 'car', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (24, 'ORD-1762581273764-AEBD9EBC', 6, 'Test Restaurant', '[{"name": "Test Item 1", "price": 50000, "quantity": 2}, {"name": "Test Item 2", "price": 30000, "quantity": 1}]', 130000.00, 20000.00, 'pending', '123 Test Street, Ho Chi Minh City', '0909123456', 'Test order from script', '2025-11-08 12:54:33.76827', '2025-11-08 12:54:33.76827', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (25, 'ORD-1762585529666-A8BB93F8', 1, 'Khu công nghiệp Tân Tạo, Hóc Môn, Hồ Chí Minh', '[{"name": "Delivery Service - Van 500 kg", "price": 76128, "quantity": 1}]', 76128.00, 76128.00, 'pending', '373/155 Lý Thường Kiệt, Phường 9, Tân Bình, Hồ Chí Minh 700000, Vietnam', '0812938948', 'Distance: 9.5 km, Duration: 19 phút', '2025-11-08 14:05:29.669737', '2025-11-08 14:05:29.669737', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (26, 'ORD-1762585561232-CECB9EA4', 5, 'Khu công nghiệp Tân Tạo, Hóc Môn, Hồ Chí Minh', '[{"name": "Delivery Service - Van 750 kg", "price": 136260, "quantity": 1}]', 136260.00, 136260.00, 'pending', '190-192 Lý Chính Thắng, Phường Võ Thị Sáu, Quận 3, TP.HCM', '0812938948', 'Distance: 13.6 km, Duration: 27 phút', '2025-11-08 14:06:01.232497', '2025-11-08 14:06:01.232497', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (27, 'DLV-1762606699166-0358B050', 1, NULL, NULL, 23904.00, 0.00, 'pending', 'Landmark 81, 720A Đ. Điện Biên Phủ, Vinhomes Tân Cảng, Bình Thạnh, TP.HCM', NULL, 'Giao hàng giờ hành chính. Gọi trước 5 phút.', '2025-11-08 19:58:19.169735', '2025-11-08 19:58:19.169735', 'motorcycle', 'Đại học Huflit, 140 Lý Thường Kiệt, Phường 7, Quận 10, TP.HCM', 10.7829000, 106.6893000, 10.7946000, 106.7218000, 'Nguyễn Văn A', '0901234567', 3.78, '8 phút', '["Giao hàng nhanh", "Gọi trước khi đến"]', 18904.00, 5000.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (28, 'ORD-1762606929018-D1443064', 5, 'Khu công nghiệp Tân Tạo, Hóc Môn, Hồ Chí Minh', '[{"name": "Delivery Service - Van 750 kg", "price": 95160, "quantity": 1}]', 95160.00, 95160.00, 'pending', '373/155 Lý Thường Kiệt, Phường 9, Tân Bình, Hồ Chí Minh 700000, Vietnam', '0123578787', 'Distance: 9.5 km, Duration: 19 phút', '2025-11-08 20:02:09.022276', '2025-11-08 20:02:09.022276', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (29, 'ORD-1762606964383-29BCD6F3', 5, '720A Đ. Điện Biên Phủ, Vinhomes Tân Cảng, Bình Thạnh, TP.HCM', '[{"name": "Delivery Service - Motorcycle", "price": 37955, "quantity": 1}]', 37955.00, 37955.00, 'pending', '373/155 Lý Thường Kiệt, Phường 9, Tân Bình, Hồ Chí Minh 700000, Vietnam', '0123456789', 'Distance: 7.6 km, Duration: 15 phút', '2025-11-08 20:02:44.384531', '2025-11-08 20:02:44.384531', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (19, 'DLV-1761663882632-2A998AE0', 1, NULL, NULL, 23904.00, 0.00, 'classified', 'Landmark 81, 720A Đ. Điện Biên Phủ, Vinhomes Tân Cảng, Bình Thạnh, TP.HCM', NULL, 'Giao hàng giờ hành chính. Gọi trước 5 phút.', '2025-10-28 22:04:42.634159', '2025-11-08 20:32:04.331397', 'motorcycle', 'Đại học Huflit, 140 Lý Thường Kiệt, Phường 7, Quận 10, TP.HCM', 10.7829000, 106.6893000, 10.7946000, 106.7218000, 'Nguyễn Văn A', '0901234567', 3.78, '8 phút', '["Giao hàng nhanh", "Gọi trước khi đến"]', 18904.00, 5000.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, '4', 'Nhân Viên Kho', '2025-11-08 20:31:21.142323', '2025-11-08 20:32:04.331397', 'zone_2', 'car', NULL, false, NULL, NULL, NULL, 'medium', 'fragile', 10.00, 'vf', '[]');
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (30, 'ORD-1762700231024-808A70E8', 5, '720A Đ. Điện Biên Phủ, Vinhomes Tân Cảng, Bình Thạnh, TP.HCM', '[{"name": "Delivery Service - Van 750 kg", "price": 75910, "quantity": 1}]', 75910.00, 75910.00, 'pending', '373/155 Lý Thường Kiệt, Phường 9, Tân Bình, Hồ Chí Minh 700000, Vietnam', '0812938948', 'Distance: 7.6 km, Duration: 15 phút', '2025-11-09 21:57:11.026698', '2025-11-09 21:57:11.026698', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (31, 'ORD-1762700263807-51235575', 5, '190-192 Lý Chính Thắng, Phường Võ Thị Sáu, Quận 3, TP.HCM', '[{"name": "Delivery Service - Motorcycle", "price": 68130, "quantity": 1}]', 68130.00, 68130.00, 'pending', 'Khu công nghiệp Tân Tạo, Hóc Môn, Hồ Chí Minh', '08129383948', 'Distance: 13.6 km, Duration: 27 phút', '2025-11-09 21:57:43.848405', '2025-11-09 21:57:43.848405', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.orders (id, order_number, user_id, restaurant_name, items, total_amount, delivery_fee, status, delivery_address, delivery_phone, notes, created_at, updated_at, vehicle_type, pickup_address, pickup_lat, pickup_lng, delivery_lat, delivery_lng, recipient_name, recipient_phone, distance, duration, services, base_fare, service_fee, cancellation_reason, cancellation_type, cancelled_at, cancelled_by, payment_status, payment_method, refund_status, refund_initiated_at, warehouse_id, warehouse_name, intake_staff_id, intake_staff_name, received_at, classified_at, zone, recommended_vehicle, cod_payment_type, cod_collected_at_warehouse, cod_collected_at, customer_estimated_size, customer_requested_vehicle, package_size, package_type, weight, description, images) VALUES (32, 'ORD-1762703663912-3409B6A8', 5, '190-192 Lý Chính Thắng, Phường Võ Thị Sáu, Quận 3, TP.HCM', '[{"name": "Delivery Service - Motorcycle", "price": 68130, "quantity": 1}]', 68130.00, 68130.00, 'pending', 'Khu công nghiệp Tân Tạo, Hóc Môn, Hồ Chí Minh', '0812938498', 'Distance: 13.6 km, Duration: 27 phút', '2025-11-09 22:54:23.969293', '2025-11-09 22:54:23.969293', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', NULL, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);


--
-- TOC entry 5161 (class 0 OID 16922)
-- Dependencies: 228
-- Data for Name: restaurants; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.restaurants (id, name, address, phone, image_url, rating, cuisine_type, delivery_time, delivery_fee, created_at, updated_at) VALUES (6, 'Pizza Paradise', '123 Nguyen Hue, District 1, HCMC', '0901234567', 'https://images.unsplash.com/photo-1513104890138-7c749659a591', 4.8, 'Italian', '30-40 min', 15000, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.restaurants (id, name, address, phone, image_url, rating, cuisine_type, delivery_time, delivery_fee, created_at, updated_at) VALUES (7, 'Burger House', '456 Le Loi, District 1, HCMC', '0901234568', 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd', 4.6, 'American', '20-30 min', 10000, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.restaurants (id, name, address, phone, image_url, rating, cuisine_type, delivery_time, delivery_fee, created_at, updated_at) VALUES (8, 'Sushi Station', '789 Tran Hung Dao, District 5, HCMC', '0901234569', 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351', 4.9, 'Japanese', '40-50 min', 20000, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.restaurants (id, name, address, phone, image_url, rating, cuisine_type, delivery_time, delivery_fee, created_at, updated_at) VALUES (9, 'Pho Vietnam', '321 Hai Ba Trung, District 3, HCMC', '0901234570', 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43', 4.7, 'Vietnamese', '25-35 min', 8000, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');
INSERT INTO public.restaurants (id, name, address, phone, image_url, rating, cuisine_type, delivery_time, delivery_fee, created_at, updated_at) VALUES (10, 'Sweet Dreams Bakery', '654 Pasteur, District 1, HCMC', '0901234571', 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35', 4.5, 'Dessert', '15-25 min', 12000, '2025-10-28 15:37:03.280917', '2025-10-28 15:37:03.280917');


--
-- TOC entry 5153 (class 0 OID 16833)
-- Dependencies: 220
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.users (id, email, password, full_name, phone, address, role, created_at, updated_at, fcm_token) VALUES (1, 'khanggialata@gmail.com', '$2a$12$6flN21ek4cerCYwcCSeVbe4E.wHCHhw21ZPtPg01jZ1UShQA839Zi', 'TrongKahgn', '0812938948', 'HaNoi', 'customer', '2025-10-15 09:26:16.048493', '2025-10-15 09:26:16.048493', NULL);
INSERT INTO public.users (id, email, password, full_name, phone, address, role, created_at, updated_at, fcm_token) VALUES (2, 'test@gmail.com', '$2a$12$LMnRx.Zh226jMBxK7iGkj.iGZ69z6WfL9yBEgtVEXSZQBeNQkSwga', 'trongkhang', '0812938948', 'ThaiBinh', 'customer', '2025-10-28 01:30:04.218308', '2025-10-28 01:30:04.218308', NULL);
INSERT INTO public.users (id, email, password, full_name, phone, address, role, created_at, updated_at, fcm_token) VALUES (3, 'driver.test@lalamove.com', 'hashed_password_123', 'Nguyễn Tài Xế Test', '0923456789', NULL, 'driver', '2025-11-06 22:37:30.54449', '2025-11-06 22:37:30.54449', NULL);
INSERT INTO public.users (id, email, password, full_name, phone, address, role, created_at, updated_at, fcm_token) VALUES (4, 'staff@intake.com', '$2a$10$Q1iMJDbzOv6zZv0d9cP70uOH8rGEUftD0OSyCUNA1amDDLIlxY4ru', 'Nhân Viên Kho', '0909123456', NULL, 'intake_staff', '2025-11-08 12:19:05.088297', '2025-11-08 12:19:05.088297', NULL);
INSERT INTO public.users (id, email, password, full_name, phone, address, role, created_at, updated_at, fcm_token) VALUES (5, 'test123@gmail.com', '$2a$12$/aFW3AdRQUv/8hBJiHEpH.u8JJGsZZiGuYThxd.kdEs0bbgIViDza', 'Test customer intake', '0812938948', 'HQC', 'customer', '2025-11-08 12:47:41.260894', '2025-11-08 12:47:41.260894', NULL);
INSERT INTO public.users (id, email, password, full_name, phone, address, role, created_at, updated_at, fcm_token) VALUES (6, 'customer@test.com', '$2a$12$FXPOsoYqKpyOOHrCdgqRt./iot5WCyU9ZsrVZBEZNfULHYNbvBgfC', 'Test Customer', '0909123456', NULL, 'customer', '2025-11-08 12:54:28.0004', '2025-11-08 12:54:28.0004', NULL);
INSERT INTO public.users (id, email, password, full_name, phone, address, role, created_at, updated_at, fcm_token) VALUES (7, 'khanggialata123@gmail.com', '$2a$12$QtQ9EWZN3JI1LpSxepxqae5L5Vgd65sHQodNGDhcdaFB7Hncp9d8i', 'Tran Trong Khang', '0812938948', 'Trongkahgn', 'customer', '2025-11-11 22:08:54.825927', '2025-11-11 22:08:54.825927', NULL);


--
-- TOC entry 5199 (class 0 OID 0)
-- Dependencies: 237
-- Name: complaint_responses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.complaint_responses_id_seq', 1, false);


--
-- TOC entry 5200 (class 0 OID 0)
-- Dependencies: 235
-- Name: complaints_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.complaints_id_seq', 1, false);


--
-- TOC entry 5201 (class 0 OID 0)
-- Dependencies: 225
-- Name: delivery_tracking_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.delivery_tracking_id_seq', 23, true);


--
-- TOC entry 5202 (class 0 OID 0)
-- Dependencies: 229
-- Name: menu_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.menu_items_id_seq', 52, true);


--
-- TOC entry 5203 (class 0 OID 0)
-- Dependencies: 233
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notifications_id_seq', 1, false);


--
-- TOC entry 5204 (class 0 OID 0)
-- Dependencies: 231
-- Name: order_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.order_items_id_seq', 1, false);


--
-- TOC entry 5205 (class 0 OID 0)
-- Dependencies: 223
-- Name: order_status_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.order_status_history_id_seq', 24, true);


--
-- TOC entry 5206 (class 0 OID 0)
-- Dependencies: 221
-- Name: orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.orders_id_seq', 32, true);


--
-- TOC entry 5207 (class 0 OID 0)
-- Dependencies: 227
-- Name: restaurants_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.restaurants_id_seq', 10, true);


--
-- TOC entry 5208 (class 0 OID 0)
-- Dependencies: 219
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 7, true);


--
-- TOC entry 4988 (class 2606 OID 17066)
-- Name: complaint_responses complaint_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.complaint_responses
    ADD CONSTRAINT complaint_responses_pkey PRIMARY KEY (id);


--
-- TOC entry 4981 (class 2606 OID 17035)
-- Name: complaints complaints_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.complaints
    ADD CONSTRAINT complaints_pkey PRIMARY KEY (id);


--
-- TOC entry 4965 (class 2606 OID 16905)
-- Name: delivery_tracking delivery_tracking_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_tracking
    ADD CONSTRAINT delivery_tracking_pkey PRIMARY KEY (id);


--
-- TOC entry 4970 (class 2606 OID 16951)
-- Name: menu_items menu_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items
    ADD CONSTRAINT menu_items_pkey PRIMARY KEY (id);


--
-- TOC entry 4979 (class 2606 OID 17005)
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- TOC entry 4972 (class 2606 OID 16968)
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (id);


--
-- TOC entry 4963 (class 2606 OID 16887)
-- Name: order_status_history order_status_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_status_history
    ADD CONSTRAINT order_status_history_pkey PRIMARY KEY (id);


--
-- TOC entry 4959 (class 2606 OID 16870)
-- Name: orders orders_order_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_order_number_key UNIQUE (order_number);


--
-- TOC entry 4961 (class 2606 OID 16868)
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- TOC entry 4968 (class 2606 OID 16936)
-- Name: restaurants restaurants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.restaurants
    ADD CONSTRAINT restaurants_pkey PRIMARY KEY (id);


--
-- TOC entry 4952 (class 2606 OID 16849)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 4954 (class 2606 OID 16847)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 4989 (class 1259 OID 17082)
-- Name: idx_complaint_responses_complaint_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_complaint_responses_complaint_id ON public.complaint_responses USING btree (complaint_id);


--
-- TOC entry 4990 (class 1259 OID 17083)
-- Name: idx_complaint_responses_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_complaint_responses_created_at ON public.complaint_responses USING btree (created_at);


--
-- TOC entry 4982 (class 1259 OID 17081)
-- Name: idx_complaints_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_complaints_created_at ON public.complaints USING btree (created_at DESC);


--
-- TOC entry 4983 (class 1259 OID 17078)
-- Name: idx_complaints_order_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_complaints_order_id ON public.complaints USING btree (order_id);


--
-- TOC entry 4984 (class 1259 OID 17080)
-- Name: idx_complaints_priority; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_complaints_priority ON public.complaints USING btree (priority);


--
-- TOC entry 4985 (class 1259 OID 17079)
-- Name: idx_complaints_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_complaints_status ON public.complaints USING btree (status);


--
-- TOC entry 4986 (class 1259 OID 17077)
-- Name: idx_complaints_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_complaints_user_id ON public.complaints USING btree (user_id);


--
-- TOC entry 4966 (class 1259 OID 16919)
-- Name: idx_delivery_tracking_order_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_delivery_tracking_order_id ON public.delivery_tracking USING btree (order_id);


--
-- TOC entry 4973 (class 1259 OID 17014)
-- Name: idx_notifications_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_created_at ON public.notifications USING btree (created_at DESC);


--
-- TOC entry 4974 (class 1259 OID 17012)
-- Name: idx_notifications_is_read; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_is_read ON public.notifications USING btree (is_read);


--
-- TOC entry 4975 (class 1259 OID 17013)
-- Name: idx_notifications_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_type ON public.notifications USING btree (type);


--
-- TOC entry 4976 (class 1259 OID 17011)
-- Name: idx_notifications_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_user_id ON public.notifications USING btree (user_id);


--
-- TOC entry 4977 (class 1259 OID 17015)
-- Name: idx_notifications_user_is_read; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_user_is_read ON public.notifications USING btree (user_id, is_read);


--
-- TOC entry 4955 (class 1259 OID 16918)
-- Name: idx_orders_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_orders_created_at ON public.orders USING btree (created_at);


--
-- TOC entry 4956 (class 1259 OID 16917)
-- Name: idx_orders_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_orders_status ON public.orders USING btree (status);


--
-- TOC entry 4957 (class 1259 OID 16916)
-- Name: idx_orders_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_orders_user_id ON public.orders USING btree (user_id);


--
-- TOC entry 4950 (class 1259 OID 16920)
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- TOC entry 5003 (class 2606 OID 17067)
-- Name: complaint_responses complaint_responses_complaint_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.complaint_responses
    ADD CONSTRAINT complaint_responses_complaint_id_fkey FOREIGN KEY (complaint_id) REFERENCES public.complaints(id) ON DELETE CASCADE;


--
-- TOC entry 5004 (class 2606 OID 17072)
-- Name: complaint_responses complaint_responses_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.complaint_responses
    ADD CONSTRAINT complaint_responses_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5000 (class 2606 OID 17041)
-- Name: complaints complaints_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.complaints
    ADD CONSTRAINT complaints_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- TOC entry 5001 (class 2606 OID 17046)
-- Name: complaints complaints_resolved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.complaints
    ADD CONSTRAINT complaints_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.users(id);


--
-- TOC entry 5002 (class 2606 OID 17036)
-- Name: complaints complaints_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.complaints
    ADD CONSTRAINT complaints_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4994 (class 2606 OID 16906)
-- Name: delivery_tracking delivery_tracking_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_tracking
    ADD CONSTRAINT delivery_tracking_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- TOC entry 4995 (class 2606 OID 16911)
-- Name: delivery_tracking delivery_tracking_shipper_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_tracking
    ADD CONSTRAINT delivery_tracking_shipper_id_fkey FOREIGN KEY (shipper_id) REFERENCES public.users(id);


--
-- TOC entry 4996 (class 2606 OID 16952)
-- Name: menu_items menu_items_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menu_items
    ADD CONSTRAINT menu_items_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id) ON DELETE CASCADE;


--
-- TOC entry 4999 (class 2606 OID 17006)
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4997 (class 2606 OID 16974)
-- Name: order_items order_items_menu_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_menu_item_id_fkey FOREIGN KEY (menu_item_id) REFERENCES public.menu_items(id);


--
-- TOC entry 4998 (class 2606 OID 16969)
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- TOC entry 4993 (class 2606 OID 16888)
-- Name: order_status_history order_status_history_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_status_history
    ADD CONSTRAINT order_status_history_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- TOC entry 4991 (class 2606 OID 16981)
-- Name: orders orders_cancelled_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_cancelled_by_fkey FOREIGN KEY (cancelled_by) REFERENCES public.users(id);


--
-- TOC entry 4992 (class 2606 OID 16871)
-- Name: orders orders_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


-- Completed on 2025-11-11 22:23:39

--
-- PostgreSQL database dump complete
--

\unrestrict 2TagBjkrCMe2Ij80p782A0sEYCkzivbGCd7fuaYF5vnmxRnqxMsDnir9Ar2ifSq

