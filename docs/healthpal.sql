-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.appointments (
  appointment_id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  doctor_id uuid,
  clinic_id uuid,
  appointment_date timestamp with time zone NOT NULL,
  status text DEFAULT 'pending'::text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT appointments_pkey PRIMARY KEY (appointment_id),
  CONSTRAINT appointments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT appointments_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(doctor_id),
  CONSTRAINT appointments_clinic_id_fkey FOREIGN KEY (clinic_id) REFERENCES public.clinics(clinic_id)
);
CREATE TABLE public.clinics (
  clinic_id uuid NOT NULL DEFAULT gen_random_uuid(),
  clinic_name text NOT NULL,
  address text,
  phone_number character varying,
  city text,
  country text,
  latitude double precision,
  longitude double precision,
  CONSTRAINT clinics_pkey PRIMARY KEY (clinic_id)
);
CREATE TABLE public.doctors (
  doctor_id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  specialization text,
  education text,
  experience text,
  contact_info text,
  profile_picture text,
  clinic_id uuid,
  rating numeric DEFAULT 0,
  CONSTRAINT doctors_pkey PRIMARY KEY (doctor_id),
  CONSTRAINT doctors_clinic_id_fkey FOREIGN KEY (clinic_id) REFERENCES public.clinics(clinic_id)
);
CREATE TABLE public.notifications (
  notification_id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  message text NOT NULL,
  notif_type text,
  status text DEFAULT 'unread'::text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (notification_id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.palnews (
  news_id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  content text,
  source text,
  published_at timestamp with time zone DEFAULT now(),
  category text,
  image_url text,
  CONSTRAINT palnews_pkey PRIMARY KEY (news_id)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  full_name text,
  created_at timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text),
  nickname text,
  email text,
  date_of_birth date,
  gender text,
  profile_photo_url text,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.ratings_reviews (
  review_id uuid NOT NULL DEFAULT gen_random_uuid(),
  appointment_id uuid,
  doctor_id uuid,
  user_id uuid,
  rating integer CHECK (rating >= 1 AND rating <= 5),
  review text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT ratings_reviews_pkey PRIMARY KEY (review_id),
  CONSTRAINT ratings_reviews_appointment_id_fkey FOREIGN KEY (appointment_id) REFERENCES public.appointments(appointment_id),
  CONSTRAINT ratings_reviews_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(doctor_id),
  CONSTRAINT ratings_reviews_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
