--
-- PostgreSQL database dump
--

-- Dumped from database version 13.2
-- Dumped by pg_dump version 13.2

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
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track execution statistics of all SQL statements executed';


--
-- Name: contract_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.contract_role AS ENUM (
    'admin',
    'teacher',
    'student'
);


--
-- Name: dom_username; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.dom_username AS text;


--
-- Name: snap_user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.snap_user_role AS ENUM (
    'standard',
    'reviewer',
    'moderator',
    'admin',
    'banned'
);


--
-- Name: expire_token(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.expire_token() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  DELETE FROM tokens WHERE created < NOW() - INTERVAL '3 days';
RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects (
    id integer NOT NULL,
    projectname text NOT NULL,
    ispublic boolean,
    ispublished boolean,
    notes text,
    created timestamp with time zone,
    lastupdated timestamp with time zone,
    lastshared timestamp with time zone,
    username public.dom_username NOT NULL,
    firstpublished timestamp with time zone,
    deleted timestamp with time zone
);


--
-- Name: active_projects; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.active_projects AS
 SELECT projects.id,
    projects.projectname,
    projects.ispublic,
    projects.ispublished,
    projects.notes,
    projects.created,
    projects.lastupdated,
    projects.lastshared,
    projects.username,
    projects.firstpublished,
    projects.deleted
   FROM public.projects
  WHERE (projects.deleted IS NULL);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    created timestamp with time zone,
    username public.dom_username NOT NULL,
    email text,
    salt text,
    password text,
    about text,
    location text,
    verified boolean,
    role public.snap_user_role DEFAULT 'standard'::public.snap_user_role,
    deleted timestamp with time zone,
    unique_email text,
    last_session_at timestamp with time zone,
    last_login_at timestamp with time zone
);


--
-- Name: active_users; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.active_users AS
 SELECT users.id,
    users.created,
    users.username,
    users.email,
    users.salt,
    users.password,
    users.about,
    users.location,
    users.verified,
    users.role,
    users.deleted,
    users.unique_email,
    users.last_session_at,
    users.last_login_at
   FROM public.users
  WHERE (users.deleted IS NULL);


--
-- Name: banned_ips; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.banned_ips (
    ip text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    offense_count integer DEFAULT 0 NOT NULL
);


--
-- Name: collection_memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collection_memberships (
    id integer NOT NULL,
    collection_id integer NOT NULL,
    project_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: collection_memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.collection_memberships_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: collection_memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.collection_memberships_id_seq OWNED BY public.collection_memberships.id;


--
-- Name: collections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collections (
    id integer NOT NULL,
    name text NOT NULL,
    creator_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    description text,
    published boolean DEFAULT false NOT NULL,
    published_at timestamp with time zone,
    shared boolean DEFAULT false NOT NULL,
    shared_at timestamp with time zone,
    thumbnail_id integer,
    editor_ids integer[],
    free_for_all boolean DEFAULT false NOT NULL
);


--
-- Name: collections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.collections_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: collections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.collections_id_seq OWNED BY public.collections.id;


--
-- Name: contract_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contract_users (
    id integer NOT NULL,
    user_id integer NOT NULL,
    contract_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    role public.contract_role DEFAULT 'student'::public.contract_role NOT NULL
);


--
-- Name: contract_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contract_users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contract_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contract_users_id_seq OWNED BY public.contract_users.id;


--
-- Name: contracts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contracts (
    id integer NOT NULL,
    name text NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    email_domains text[] NOT NULL,
    contact_info text,
    contact_email text NOT NULL,
    notes text,
    location text,
    timezone text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: contracts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contracts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contracts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contracts_id_seq OWNED BY public.contracts.id;


--
-- Name: count_recent_projects; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.count_recent_projects AS
 SELECT count(*) AS count
   FROM public.projects
  WHERE (projects.lastupdated > (('now'::text)::date - '1 day'::interval));


--
-- Name: deleted_projects; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.deleted_projects AS
 SELECT projects.id,
    projects.projectname,
    projects.ispublic,
    projects.ispublished,
    projects.notes,
    projects.created,
    projects.lastupdated,
    projects.lastshared,
    projects.username,
    projects.firstpublished,
    projects.deleted
   FROM public.projects
  WHERE (projects.deleted IS NOT NULL);


--
-- Name: deleted_users; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.deleted_users AS
 SELECT users.id,
    users.created,
    users.username,
    users.email,
    users.salt,
    users.password,
    users.about,
    users.location,
    users.verified,
    users.role,
    users.deleted,
    users.unique_email,
    users.last_session_at,
    users.last_login_at
   FROM public.users
  WHERE (users.deleted IS NOT NULL);


--
-- Name: flagged_projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flagged_projects (
    id integer NOT NULL,
    flagger_id integer NOT NULL,
    project_id integer NOT NULL,
    reason text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    notes text
);


--
-- Name: flagged_projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flagged_projects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flagged_projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flagged_projects_id_seq OWNED BY public.flagged_projects.id;


--
-- Name: identities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.identities (
    id integer NOT NULL,
    user_id integer NOT NULL,
    provider_id integer NOT NULL,
    uid text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb
);


--
-- Name: identities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.identities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: identities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.identities_id_seq OWNED BY public.identities.id;


--
-- Name: lapis_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lapis_migrations (
    name character varying(255) NOT NULL
);


--
-- Name: oauth_providers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_providers (
    id integer NOT NULL,
    name text NOT NULL,
    short_name text NOT NULL,
    logo_path text NOT NULL,
    client_id text NOT NULL,
    client_secret text NOT NULL,
    authorization_url text NOT NULL,
    scopes text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    config jsonb DEFAULT '{}'::jsonb
);


--
-- Name: oauth_providers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_providers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_providers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_providers_id_seq OWNED BY public.oauth_providers.id;


--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.projects_id_seq OWNED BY public.projects.id;


--
-- Name: recent_projects_2_days; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.recent_projects_2_days AS
 SELECT count(*) AS count
   FROM public.projects
  WHERE (projects.lastupdated > (('now'::text)::date - '2 days'::interval));


--
-- Name: remixes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.remixes (
    original_project_id integer,
    remixed_project_id integer NOT NULL,
    created timestamp with time zone
);


--
-- Name: tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tokens (
    created timestamp without time zone DEFAULT now() NOT NULL,
    username public.dom_username NOT NULL,
    purpose text,
    value text NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: collection_memberships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_memberships ALTER COLUMN id SET DEFAULT nextval('public.collection_memberships_id_seq'::regclass);


--
-- Name: collections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections ALTER COLUMN id SET DEFAULT nextval('public.collections_id_seq'::regclass);


--
-- Name: contract_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contract_users ALTER COLUMN id SET DEFAULT nextval('public.contract_users_id_seq'::regclass);


--
-- Name: contracts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contracts ALTER COLUMN id SET DEFAULT nextval('public.contracts_id_seq'::regclass);


--
-- Name: flagged_projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flagged_projects ALTER COLUMN id SET DEFAULT nextval('public.flagged_projects_id_seq'::regclass);


--
-- Name: identities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.identities ALTER COLUMN id SET DEFAULT nextval('public.identities_id_seq'::regclass);


--
-- Name: oauth_providers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_providers ALTER COLUMN id SET DEFAULT nextval('public.oauth_providers_id_seq'::regclass);


--
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.projects_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: banned_ips banned_ips_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.banned_ips
    ADD CONSTRAINT banned_ips_pkey PRIMARY KEY (ip);


--
-- Name: collection_memberships collection_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_memberships
    ADD CONSTRAINT collection_memberships_pkey PRIMARY KEY (id);


--
-- Name: collections collections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_pkey PRIMARY KEY (id);


--
-- Name: contract_users contract_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contract_users
    ADD CONSTRAINT contract_users_pkey PRIMARY KEY (id);


--
-- Name: contracts contracts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contracts
    ADD CONSTRAINT contracts_pkey PRIMARY KEY (id);


--
-- Name: flagged_projects flagged_projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flagged_projects
    ADD CONSTRAINT flagged_projects_pkey PRIMARY KEY (id);


--
-- Name: identities identities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (id);


--
-- Name: lapis_migrations lapis_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lapis_migrations
    ADD CONSTRAINT lapis_migrations_pkey PRIMARY KEY (name);


--
-- Name: oauth_providers oauth_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_providers
    ADD CONSTRAINT oauth_providers_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (username, projectname);


--
-- Name: projects unique_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT unique_id UNIQUE (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (username);


--
-- Name: tokens value_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT value_pkey PRIMARY KEY (value);


--
-- Name: collection_memberships_collection_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX collection_memberships_collection_id_idx ON public.collection_memberships USING btree (collection_id);


--
-- Name: collection_memberships_collection_id_project_id_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX collection_memberships_collection_id_project_id_user_id_idx ON public.collection_memberships USING btree (collection_id, project_id, user_id);


--
-- Name: collection_memberships_project_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX collection_memberships_project_id_idx ON public.collection_memberships USING btree (project_id);


--
-- Name: collections_creator_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX collections_creator_id_idx ON public.collections USING btree (creator_id);


--
-- Name: contract_users_user_id_contract_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX contract_users_user_id_contract_id_idx ON public.contract_users USING btree (user_id, contract_id);


--
-- Name: flagged_projects_flagger_id_project_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX flagged_projects_flagger_id_project_id_idx ON public.flagged_projects USING btree (flagger_id, project_id);


--
-- Name: identities_user_id_provider_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX identities_user_id_provider_id_idx ON public.identities USING btree (user_id, provider_id);


--
-- Name: original_project_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX original_project_id_index ON public.remixes USING btree (original_project_id);


--
-- Name: remixed_project_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX remixed_project_id_index ON public.remixes USING btree (remixed_project_id);


--
-- Name: users_email_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_email_idx ON public.users USING btree (email);


--
-- Name: users_last_session_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_last_session_at_idx ON public.users USING btree (last_session_at);


--
-- Name: tokens expire_token_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER expire_token_trigger AFTER INSERT ON public.tokens FOR EACH STATEMENT EXECUTE FUNCTION public.expire_token();


--
-- Name: projects projects_username_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_username_fkey FOREIGN KEY (username) REFERENCES public.users(username);


--
-- Name: remixes remixes_original_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.remixes
    ADD CONSTRAINT remixes_original_project_id_fkey FOREIGN KEY (original_project_id) REFERENCES public.projects(id);


--
-- Name: remixes remixes_remixed_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.remixes
    ADD CONSTRAINT remixes_remixed_project_id_fkey FOREIGN KEY (remixed_project_id) REFERENCES public.projects(id);


--
-- Name: tokens users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT users_fkey FOREIGN KEY (username) REFERENCES public.users(username);


--
-- PostgreSQL database dump complete
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 13.2
-- Dumped by pg_dump version 13.2

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
-- Data for Name: lapis_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.lapis_migrations (name) FROM stdin;
20190140
201901291
20190141
2019-01-04:0
2019-01-29:0
2019-02-01:0
2019-02-05:0
2019-02-04:0
2020-10-22:0
2020-11-03:0
2020-11-09:0
2020-11-10:0
2021-08-11:0
2021-08-12:0
2021-08-12:1
2021-09-20:1
\.


--
-- PostgreSQL database dump complete
--

