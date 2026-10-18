CREATE TABLE IF NOT EXISTS users (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'STUDENT',
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    department VARCHAR(255) NOT NULL DEFAULT 'Computer Science & Engineering',
    created_at DATETIME NOT NULL
);

CREATE TABLE IF NOT EXISTS auth_tokens (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    token VARCHAR(64) NOT NULL UNIQUE,
    created_at DATETIME NOT NULL,
    expires_at DATETIME NULL,
    INDEX idx_tokens_token (token),
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS sessions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    mentor_id INT UNSIGNED NULL,
    title VARCHAR(255) NOT NULL,
    mentor_name VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    created_at DATETIME NOT NULL,
    closed_at DATETIME NULL,
    INDEX idx_sessions_mentor (mentor_id),
    FOREIGN KEY (mentor_id) REFERENCES users (id)
);

CREATE TABLE IF NOT EXISTS doubts (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    session_id INT UNSIGNED NOT NULL,
    student_id INT UNSIGNED NULL,
    student_name VARCHAR(255) NOT NULL,
    student_email VARCHAR(255) NOT NULL,
    topic VARCHAR(255) NOT NULL,
    question TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'WAITING',
    resolution_notes TEXT NULL,
    created_at DATETIME NOT NULL,
    started_at DATETIME NULL,
    finished_at DATETIME NULL,
    INDEX idx_doubts_session_status (session_id, status),
    INDEX idx_doubts_status_topic (status, topic),
    INDEX idx_doubts_student (student_id),
    FOREIGN KEY (session_id) REFERENCES sessions (id),
    FOREIGN KEY (student_id) REFERENCES users (id)
);

