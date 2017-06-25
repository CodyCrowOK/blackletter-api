CREATE TABLE events
(
    id SERIAL PRIMARY KEY NOT NULL,
    name VARCHAR(100)
);
CREATE TABLE notes
(
    id SERIAL PRIMARY KEY NOT NULL,
    title VARCHAR(100),
    body TEXT
);
CREATE TABLE users
(
    id SERIAL PRIMARY KEY NOT NULL,
    name VARCHAR(100),
    email VARCHAR(256) NOT NULL,
    password BYTEA
);
CREATE TABLE sessions
(
    user_id INTEGER,
    time TIMESTAMP,
    ip CIDR,
    id BYTEA PRIMARY KEY NOT NULL,
    CONSTRAINT session_user_id_fk FOREIGN KEY (user_id) REFERENCES users (id)
);
CREATE TABLE user_guest_at_event
(
    guest INTEGER,
    event INTEGER,
    signed_in BOOLEAN DEFAULT false NOT NULL,
    CONSTRAINT user_guest_at_event_user_id_fk FOREIGN KEY (guest) REFERENCES users (id),
    CONSTRAINT user_guest_at_event_event_id_fk FOREIGN KEY (event) REFERENCES events (id)
);
CREATE TABLE user_owns_event
(
    owner INTEGER NOT NULL,
    event INTEGER NOT NULL,
    CONSTRAINT user_owns_event_owner_event_pk PRIMARY KEY (owner, event),
    CONSTRAINT user_owns_event_user_id_fk FOREIGN KEY (owner) REFERENCES users (id),
    CONSTRAINT user_owns_event_event_id_fk FOREIGN KEY (event) REFERENCES events (id)
);
CREATE TABLE user_receives_note
(
    recipient INTEGER,
    note INTEGER,
    CONSTRAINT user_receives_note_user_id_fk FOREIGN KEY (recipient) REFERENCES users (id),
    CONSTRAINT user_receives_note_note_id_fk FOREIGN KEY (note) REFERENCES notes (id)
);
CREATE TABLE user_sends_note
(
    sender INTEGER,
    note INTEGER,
    CONSTRAINT user_sends_note_user_id_fk FOREIGN KEY (sender) REFERENCES users (id),
    CONSTRAINT events_sends_note_note_id_fk FOREIGN KEY (note) REFERENCES notes (id)
);
CREATE UNIQUE INDEX user_email_uindex ON users (email);
CREATE UNIQUE INDEX sessions_id_uindex ON sessions (id);
