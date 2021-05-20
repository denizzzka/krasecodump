--
-- PostgreSQL database dump
--

-- Dumped from database version 11.9 (Debian 11.9-0+deb10u1)
-- Dumped by pg_dump version 11.1 (Debian 11.1-1+b2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: measurements; Type: TABLE; Schema: public; Owner: denizzz
--

CREATE TABLE public.measurements (
    measurement_id bigint NOT NULL,
    measurement_time timestamp with time zone NOT NULL,
    place_id smallint NOT NULL,
    value double precision NOT NULL,
    recorded_time timestamp with time zone NOT NULL,
    substance_id smallint NOT NULL
);


ALTER TABLE public.measurements OWNER TO denizzz;

--
-- Name: measurements_measurement_id_seq; Type: SEQUENCE; Schema: public; Owner: denizzz
--

ALTER TABLE public.measurements ALTER COLUMN measurement_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.measurements_measurement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: places; Type: TABLE; Schema: public; Owner: denizzz
--

CREATE TABLE public.places (
    place_id integer NOT NULL,
    lat double precision NOT NULL,
    lon double precision NOT NULL,
    place_name text
);


ALTER TABLE public.places OWNER TO denizzz;

--
-- Name: places_place_id_seq; Type: SEQUENCE; Schema: public; Owner: denizzz
--

ALTER TABLE public.places ALTER COLUMN place_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.places_place_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: substances; Type: TABLE; Schema: public; Owner: denizzz
--

CREATE TABLE public.substances (
    substance_id integer NOT NULL,
    substance_name text NOT NULL,
    unit text NOT NULL,
    pdk double precision NOT NULL
);


ALTER TABLE public.substances OWNER TO denizzz;

--
-- Name: substances_substance_id_seq; Type: SEQUENCE; Schema: public; Owner: denizzz
--

ALTER TABLE public.substances ALTER COLUMN substance_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.substances_substance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: measurements measurement_uniq; Type: CONSTRAINT; Schema: public; Owner: denizzz
--

ALTER TABLE ONLY public.measurements
    ADD CONSTRAINT measurement_uniq UNIQUE (place_id, measurement_time, substance_id, value);


--
-- Name: places places_pkey; Type: CONSTRAINT; Schema: public; Owner: denizzz
--

ALTER TABLE ONLY public.places
    ADD CONSTRAINT places_pkey PRIMARY KEY (place_id);


--
-- Name: places places_unique_coords; Type: CONSTRAINT; Schema: public; Owner: denizzz
--

ALTER TABLE ONLY public.places
    ADD CONSTRAINT places_unique_coords UNIQUE (lat, lon);


--
-- Name: substances substance_pkey; Type: CONSTRAINT; Schema: public; Owner: denizzz
--

ALTER TABLE ONLY public.substances
    ADD CONSTRAINT substance_pkey UNIQUE (substance_id);


--
-- Name: substances substance_unique; Type: CONSTRAINT; Schema: public; Owner: denizzz
--

ALTER TABLE ONLY public.substances
    ADD CONSTRAINT substance_unique UNIQUE (substance_name, unit, pdk);


--
-- Name: measurements places_fkey; Type: FK CONSTRAINT; Schema: public; Owner: denizzz
--

ALTER TABLE ONLY public.measurements
    ADD CONSTRAINT places_fkey FOREIGN KEY (place_id) REFERENCES public.places(place_id);


--
-- Name: measurements substance_fkey; Type: FK CONSTRAINT; Schema: public; Owner: denizzz
--

ALTER TABLE ONLY public.measurements
    ADD CONSTRAINT substance_fkey FOREIGN KEY (substance_id) REFERENCES public.substances(substance_id);


--
-- PostgreSQL database dump complete
--

