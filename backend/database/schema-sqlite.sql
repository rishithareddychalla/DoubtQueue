CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'STUDENT',
    status TEXT NOT NULL DEFAULT 'ACTIVE',
    department TEXT NOT NULL DEFAULT 'Computer Science & Engineering',
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS auth_tokens (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    token TEXT NOT NULL UNIQUE,
    created_at TEXT NOT NULL,
    expires_at TEXT NULL,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    mentor_id INTEGER NULL,
    title TEXT NOT NULL,
    mentor_name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'OPEN',
    created_at TEXT NOT NULL,
    closed_at TEXT NULL,
    FOREIGN KEY (mentor_id) REFERENCES users (id)
);

CREATE TABLE IF NOT EXISTS doubts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id INTEGER NOT NULL,
    student_id INTEGER NULL,
    student_name TEXT NOT NULL,
    student_email TEXT NOT NULL,
    topic TEXT NOT NULL,
    question TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'WAITING',
    resolution_notes TEXT NULL,
    created_at TEXT NOT NULL,
    started_at TEXT NULL,
    finished_at TEXT NULL,
    FOREIGN KEY (session_id) REFERENCES sessions (id),
    FOREIGN KEY (student_id) REFERENCES users (id)
);

CREATE INDEX IF NOT EXISTS idx_tokens_token ON auth_tokens (token);
CREATE INDEX IF NOT EXISTS idx_sessions_mentor ON sessions (mentor_id);
CREATE INDEX IF NOT EXISTS idx_doubts_student ON doubts (student_id);
CREATE INDEX IF NOT EXISTS idx_doubts_session_status ON doubts (session_id, status);
CREATE INDEX IF NOT EXISTS idx_doubts_status_topic ON doubts (status, topic);

