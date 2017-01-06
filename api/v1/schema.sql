CREATE TABLE event
(
    id INTEGER PRIMARY KEY NOT NULL,
    name VARCHAR(100)
);
CREATE TABLE note
(
    id INTEGER PRIMARY KEY NOT NULL,
    title VARCHAR(100),
    body TEXT
);
CREATE TABLE session
(
    id INTEGER PRIMARY KEY NOT NULL,
    user_id INTEGER,
    time TIMESTAMP,
    ip CIDR,
    CONSTRAINT session_user_id_fk FOREIGN KEY (user_id) REFERENCES "user" (id)
);
CREATE UNIQUE INDEX session_id_uindex ON session (id);
CREATE TABLE "user"
(
    id INTEGER PRIMARY KEY NOT NULL,
    name VARCHAR(100),
    email VARCHAR(256) NOT NULL,
    password BYTEA
);
CREATE UNIQUE INDEX user_email_uindex ON "user" (email);
CREATE TABLE user_guest_at_event
(
    guest INTEGER,
    event INTEGER,
    signed_in BOOLEAN DEFAULT false NOT NULL,
    CONSTRAINT user_guest_at_event_user_id_fk FOREIGN KEY (guest) REFERENCES "user" (id),
    CONSTRAINT user_guest_at_event_event_id_fk FOREIGN KEY (event) REFERENCES event (id)
);
CREATE TABLE user_owns_event
(
    owner INTEGER NOT NULL,
    event INTEGER NOT NULL,
    CONSTRAINT user_owns_event_owner_event_pk PRIMARY KEY (owner, event),
    CONSTRAINT user_owns_event_user_id_fk FOREIGN KEY (owner) REFERENCES "user" (id),
    CONSTRAINT user_owns_event_event_id_fk FOREIGN KEY (event) REFERENCES event (id)
);
CREATE TABLE user_receives_note
(
    recipient INTEGER,
    note INTEGER,
    CONSTRAINT user_receives_note_user_id_fk FOREIGN KEY (recipient) REFERENCES "user" (id),
    CONSTRAINT user_receives_note_note_id_fk FOREIGN KEY (note) REFERENCES note (id)
);
CREATE TABLE user_sends_note
(
    sender INTEGER,
    note INTEGER,
    CONSTRAINT user_sends_note_user_id_fk FOREIGN KEY (sender) REFERENCES "user" (id),
    CONSTRAINT user_sends_note_note_id_fk FOREIGN KEY (note) REFERENCES note (id)
);
