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
CREATE TABLE "user"
(
    id INTEGER PRIMARY KEY NOT NULL,
    name VARCHAR(100),
    email VARCHAR(256) NOT NULL
);
CREATE TABLE user_guest_at_event
(
    guest INTEGER,
    event INTEGER,
    signed_in BOOLEAN DEFAULT false NOT NULL
);
CREATE TABLE user_owns_event
(
    owner INTEGER NOT NULL,
    event INTEGER NOT NULL,
    CONSTRAINT user_owns_event_owner_event_pk PRIMARY KEY (owner, event)
);
CREATE TABLE user_receives_note
(
    recipient INTEGER,
    note INTEGER
);
CREATE TABLE user_sends_note
(
    sender INTEGER,
    note INTEGER
);
CREATE UNIQUE INDEX user_email_uindex ON "user" (email);
ALTER TABLE user_guest_at_event ADD FOREIGN KEY (guest) REFERENCES "user" (id);
ALTER TABLE user_guest_at_event ADD FOREIGN KEY (event) REFERENCES event (id);
ALTER TABLE user_owns_event ADD FOREIGN KEY (owner) REFERENCES "user" (id);
ALTER TABLE user_owns_event ADD FOREIGN KEY (event) REFERENCES event (id);
ALTER TABLE user_receives_note ADD FOREIGN KEY (recipient) REFERENCES "user" (id);
ALTER TABLE user_receives_note ADD FOREIGN KEY (note) REFERENCES note (id);
ALTER TABLE user_sends_note ADD FOREIGN KEY (sender) REFERENCES "user" (id);
ALTER TABLE user_sends_note ADD FOREIGN KEY (note) REFERENCES note (id);
