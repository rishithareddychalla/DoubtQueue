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
