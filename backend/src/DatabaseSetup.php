<?php

declare(strict_types=1);

namespace DoubtQueue;

use PDO;

class DatabaseSetup
{
    public function __construct(private PDO $pdo)
    {
    }

    public function run(): void
    {
        $this->createTables();
        $this->migrateColumns();
        $this->seedUsers();

        if ($this->isEmpty()) {
            $this->insertSampleData();
        }
    }

    public function createTables(): void
    {
        $driver = $this->pdo->getAttribute(PDO::ATTR_DRIVER_NAME);
        $file = $driver === 'mysql' ? 'schema-mysql.sql' : 'schema-sqlite.sql';
        $sql = (string) file_get_contents(dirname(__DIR__) . '/database/' . $file);

        foreach (array_filter(array_map('trim', explode(';', $sql))) as $statement) {
            $this->pdo->exec($statement);
        }
    }

    public function migrateColumns(): void
    {
        $driver = $this->pdo->getAttribute(PDO::ATTR_DRIVER_NAME);

        if ($driver === 'sqlite') {
            $this->migrateSqliteColumns();
        } else {
            $this->migrateMysqlColumns();
        }
    }

    private function migrateSqliteColumns(): void
    {
        $sessionCols = $this->pdo->query("PRAGMA table_info(sessions)")->fetchAll(PDO::FETCH_COLUMN, 1);
        if (!in_array('mentor_id', $sessionCols, true)) {
            $this->pdo->exec('ALTER TABLE sessions ADD COLUMN mentor_id INTEGER NULL');
        }

        $doubtCols = $this->pdo->query("PRAGMA table_info(doubts)")->fetchAll(PDO::FETCH_COLUMN, 1);
        if (!in_array('student_id', $doubtCols, true)) {
            $this->pdo->exec('ALTER TABLE doubts ADD COLUMN student_id INTEGER NULL');
        }
    }

    private function migrateMysqlColumns(): void
    {
        $stmt = $this->pdo->query("SHOW COLUMNS FROM sessions LIKE 'mentor_id'");
        if ($stmt->fetch() === false) {
            $this->pdo->exec('ALTER TABLE sessions ADD COLUMN mentor_id INT UNSIGNED NULL');
        }

        $stmt = $this->pdo->query("SHOW COLUMNS FROM doubts LIKE 'student_id'");
        if ($stmt->fetch() === false) {
            $this->pdo->exec('ALTER TABLE doubts ADD COLUMN student_id INT UNSIGNED NULL');
        }
    }

    public function seedUsers(): void
    {
        $now = gmdate('Y-m-d H:i:s');
        $pwdHash = password_hash('Password123!', PASSWORD_BCRYPT);

        // Seed default mentor
        $stmt = $this->pdo->prepare('SELECT id FROM users WHERE LOWER(email) = ?');
        $stmt->execute(['mentor@doubtqueue.edu']);
        $mentor = $stmt->fetch();
        if ($mentor === false) {
            $this->pdo->prepare(
                'INSERT INTO users (name, email, password_hash, role, status, department, created_at)
                 VALUES (?, ?, ?, ?, ?, ?, ?)'
            )->execute(['Priya Sharma', 'mentor@doubtqueue.edu', $pwdHash, 'MENTOR', 'ACTIVE', 'Computer Science & Engineering', $now]);
            $mentorId = (int) $this->pdo->lastInsertId();
        } else {
            $mentorId = (int) $mentor['id'];
        }

        // Seed default student
        $stmt->execute(['student@doubtqueue.edu']);
        $student = $stmt->fetch();
        if ($student === false) {
            $this->pdo->prepare(
                'INSERT INTO users (name, email, password_hash, role, status, department, created_at)
                 VALUES (?, ?, ?, ?, ?, ?, ?)'
            )->execute(['Arjun Sharma', 'student@doubtqueue.edu', $pwdHash, 'STUDENT', 'ACTIVE', 'Computer Science & Engineering', $now]);
            $studentId = (int) $this->pdo->lastInsertId();
        } else {
            $studentId = (int) $student['id'];
        }

        // Also ensure arjun.sharma@doubtqueue.edu alias exists
        $stmt->execute(['arjun.sharma@doubtqueue.edu']);
        if ($stmt->fetch() === false) {
            $this->pdo->prepare(
                'INSERT INTO users (name, email, password_hash, role, status, department, created_at)
                 VALUES (?, ?, ?, ?, ?, ?, ?)'
            )->execute(['Arjun Sharma', 'arjun.sharma@doubtqueue.edu', $pwdHash, 'STUDENT', 'ACTIVE', 'Computer Science & Engineering', $now]);
        }

        // Link legacy sessions with null mentor_id to mentor
        $this->pdo->prepare('UPDATE sessions SET mentor_id = ? WHERE mentor_id IS NULL')
            ->execute([$mentorId]);

        // Link legacy doubts with null student_id to student
        $this->pdo->prepare('UPDATE doubts SET student_id = ? WHERE student_id IS NULL')
            ->execute([$studentId]);
    }

    private function isEmpty(): bool
    {
        return (int) $this->pdo->query('SELECT COUNT(*) FROM sessions')->fetchColumn() === 0;
    }


    private function insertSampleData(): void
    {
        $now = time();
        $openId = $this->insertSession('PHP Basics Doubt Session', 'Priya', 'OPEN', $now - 3600);
        $closedId = $this->insertSession('Flutter Doubt Session', 'Arjun', 'CLOSED', $now - 86400);

        $waiting = [
            ['Asha Rao', 'asha@example.com', 'Arrays', 'How do I loop over an associative array?'],
            ['Ben Thomas', 'ben@example.com', 'Functions', 'What is the difference between return and echo?'],
            ['Chitra Nair', 'chitra@example.com', 'PDO', 'Why should I use prepared statements?'],
            ['Dev Patel', 'dev@example.com', 'Sessions', 'How do I keep a user logged in?'],
            ['Esha Iyer', 'esha@example.com', 'Composer', 'What does the autoload section do?'],
        ];

        foreach ($waiting as $i => [$name, $email, $topic, $question]) {
            $this->insertDoubt($openId, $name, $email, $topic, $question, 'WAITING', $now - 1800 + $i * 60);
        }

        $finished = [
            ['Farah Khan', 'farah@example.com', 'Widgets', 'When do I use StatefulWidget?', 'SOLVED', 'Use StatefulWidget when the UI needs to update dynamically based on user interaction or state changes (e.g. counters, forms).'],
            ['Gita Menon', 'gita@example.com', 'Layouts', 'How does Expanded work in a Row?', 'SOLVED', 'Expanded forces a child of a Row, Column, or Flex to fill available space along the main axis.'],
            ['Hari Om', 'hari@example.com', 'Async', 'What does await do?', 'SOLVED', 'await pauses execution until the Future completes and unwraps the result value.'],
            ['Isha Roy', 'isha@example.com', 'Packages', 'How do I add a package?', 'SKIPPED', null],
        ];

        foreach ($finished as $i => [$name, $email, $topic, $question, $status, $notes]) {
            $created = $now - 86400 + $i * 300;
            $this->insertDoubt(
                $closedId,
                $name,
                $email,
                $topic,
                $question,
                $status,
                $created,
                $created + 60,
                $created + 240,
                $notes
            );
        }

        $this->pdo->prepare('UPDATE sessions SET closed_at = ? WHERE id = ?')
            ->execute([gmdate('Y-m-d H:i:s', $now - 82800), $closedId]);
    }

    private function insertSession(string $title, string $mentor, string $status, int $createdAt): int
    {
        $this->pdo->prepare(
            'INSERT INTO sessions (title, mentor_name, status, created_at) VALUES (?, ?, ?, ?)'
        )->execute([$title, $mentor, $status, gmdate('Y-m-d H:i:s', $createdAt)]);

        return (int) $this->pdo->lastInsertId();
    }

    private function insertDoubt(
        int $sessionId,
        string $name,
        string $email,
        string $topic,
        string $question,
        string $status,
        int $createdAt,
        ?int $startedAt = null,
        ?int $finishedAt = null,
        ?string $resolutionNotes = null
    ): void {
        $this->pdo->prepare(
            'INSERT INTO doubts
                (session_id, student_name, student_email, topic, question, status, resolution_notes, created_at, started_at, finished_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        )->execute([
            $sessionId,
            $name,
            $email,
            $topic,
            $question,
            $status,
            $resolutionNotes,
            gmdate('Y-m-d H:i:s', $createdAt),
            $startedAt === null ? null : gmdate('Y-m-d H:i:s', $startedAt),
            $finishedAt === null ? null : gmdate('Y-m-d H:i:s', $finishedAt),
        ]);
    }
}
