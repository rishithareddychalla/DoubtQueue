<?php

declare(strict_types=1);

namespace DoubtQueue\Repository;

use PDO;

class DoubtRepository
{
    public function __construct(private PDO $pdo)
    {
    }

    public function save(
        int $sessionId,
        string $studentName,
        string $studentEmail,
        string $topic,
        string $question,
        string $createdAt,
        ?int $studentId = null
    ): array {
        $this->pdo->prepare(
            'INSERT INTO doubts (session_id, student_id, student_name, student_email, topic, question, status, created_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
        )->execute([$sessionId, $studentId, $studentName, $studentEmail, $topic, $question, 'WAITING', $createdAt]);

        return $this->find((int) $this->pdo->lastInsertId());
    }


    public function find(int $id): ?array
    {
        $stmt = $this->pdo->prepare(
            'SELECT d.*, s.status AS session_status
             FROM doubts d
             JOIN sessions s ON s.id = d.session_id
             WHERE d.id = ?'
        );
        $stmt->execute([$id]);
        $row = $stmt->fetch();

        return $row === false ? null : $this->format($row);
    }

    public function findCurrentInProgress(int $sessionId): ?array
    {
        $stmt = $this->pdo->prepare(
            "SELECT d.*, s.status AS session_status
             FROM doubts d
             JOIN sessions s ON s.id = d.session_id
             WHERE d.session_id = ? AND d.status = 'IN_PROGRESS'
             ORDER BY d.started_at DESC, d.id DESC LIMIT 1"
        );
        $stmt->execute([$sessionId]);
        $row = $stmt->fetch();

        return $row === false ? null : $this->format($row);
    }

    public function searchSolved(string $query, ?int $sessionId = null): array
    {
        $like = '%' . $query . '%';
        if ($sessionId !== null) {
            $stmt = $this->pdo->prepare(
                "SELECT d.*, s.status AS session_status
                 FROM doubts d
                 JOIN sessions s ON s.id = d.session_id
                 WHERE d.status = 'SOLVED'
                   AND d.session_id = ?
                   AND (d.topic LIKE ? OR d.question LIKE ? OR (d.resolution_notes IS NOT NULL AND d.resolution_notes LIKE ?))
                 ORDER BY d.finished_at DESC, d.id DESC LIMIT 10"
            );
            $stmt->execute([$sessionId, $like, $like, $like]);
        } else {
            $stmt = $this->pdo->prepare(
                "SELECT d.*, s.status AS session_status
                 FROM doubts d
                 JOIN sessions s ON s.id = d.session_id
                 WHERE d.status = 'SOLVED'
                   AND (d.topic LIKE ? OR d.question LIKE ? OR (d.resolution_notes IS NOT NULL AND d.resolution_notes LIKE ?))
                 ORDER BY d.finished_at DESC, d.id DESC LIMIT 10"
            );
            $stmt->execute([$like, $like, $like]);
        }

        return array_map([$this, 'format'], $stmt->fetchAll());
    }

    public function findWaiting(int $sessionId): array
    {
        $stmt = $this->pdo->prepare(
            "SELECT * FROM doubts WHERE session_id = ? AND status = 'WAITING' ORDER BY created_at ASC, id ASC"
        );
        $stmt->execute([$sessionId]);

        return array_map([$this, 'format'], $stmt->fetchAll());
    }

    public function findOldestWaiting(int $sessionId): ?array
    {
        $stmt = $this->pdo->prepare(
            "SELECT * FROM doubts WHERE session_id = ? AND status = 'WAITING'
             ORDER BY created_at ASC, id ASC LIMIT 1"
        );
        $stmt->execute([$sessionId]);
        $row = $stmt->fetch();

        return $row === false ? null : $this->format($row);
    }

    public function position(array $doubt): int
    {
        $stmt = $this->pdo->prepare(
            "SELECT COUNT(*) FROM doubts
             WHERE session_id = ? AND status = 'WAITING'
               AND (created_at < ? OR (created_at = ? AND id < ?))"
        );
        $stmt->execute([$doubt['session_id'], $doubt['created_at'], $doubt['created_at'], $doubt['id']]);

        return (int) $stmt->fetchColumn() + 1;
    }

    public function markStarted(int $id, string $startedAt): void
    {
        $this->pdo->prepare('UPDATE doubts SET status = ?, started_at = ? WHERE id = ?')
            ->execute(['IN_PROGRESS', $startedAt, $id]);
    }

    public function markFinished(int $id, string $status, string $finishedAt, ?string $resolutionNotes = null): void
    {
        $this->pdo->prepare('UPDATE doubts SET status = ?, finished_at = ?, resolution_notes = ? WHERE id = ?')
            ->execute([$status, $finishedAt, $resolutionNotes, $id]);
    }

    public function countByStatus(int $sessionId): array
    {
        $stmt = $this->pdo->prepare('SELECT status, COUNT(*) AS total FROM doubts WHERE session_id = ? GROUP BY status');
        $stmt->execute([$sessionId]);

        return array_map('intval', array_column($stmt->fetchAll(), 'total', 'status'));
    }

    public function findSolvedCandidates(array $tokens, ?int $sessionId = null, int $limit = 60): array
    {
        if (empty($tokens)) {
            return $this->findRecentSolved($sessionId, $limit);
        }

        $sql = "SELECT d.*, s.status AS session_status
                FROM doubts d
                JOIN sessions s ON s.id = d.session_id
                WHERE d.status = 'SOLVED'";

        $params = [];
        if ($sessionId !== null) {
            $sql .= " AND d.session_id = ?";
            $params[] = $sessionId;
        }

        $clauses = [];
        foreach (array_slice($tokens, 0, 8) as $token) {
            $clauses[] = "(d.topic LIKE ? OR d.question LIKE ? OR (d.resolution_notes IS NOT NULL AND d.resolution_notes LIKE ?))";
            $like = '%' . $token . '%';
            $params[] = $like;
            $params[] = $like;
            $params[] = $like;
        }

        $sql .= " AND (" . implode(' OR ', $clauses) . ")";
        $sql .= " ORDER BY d.finished_at DESC, d.id DESC LIMIT " . (int) $limit;

        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);

        return array_map([$this, 'format'], $stmt->fetchAll());
    }

    public function findRecentSolved(?int $sessionId = null, int $limit = 20): array
    {
        $sql = "SELECT d.*, s.status AS session_status
                FROM doubts d
                JOIN sessions s ON s.id = d.session_id
                WHERE d.status = 'SOLVED'";

        $params = [];
        if ($sessionId !== null) {
            $sql .= " AND d.session_id = ?";
            $params[] = $sessionId;
        }

        $sql .= " ORDER BY d.finished_at DESC, d.id DESC LIMIT " . (int) $limit;

        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);

        return array_map([$this, 'format'], $stmt->fetchAll());
    }

    public function getTopicIntelligence(?int $sessionId = null): array
    {
        $sql = "SELECT LOWER(TRIM(d.topic)) AS normalized_topic,
                       MIN(d.topic) AS topic,
                       COUNT(*) AS total_doubts,
                       SUM(CASE WHEN d.status = 'SOLVED' THEN 1 ELSE 0 END) AS solved_count,
                       SUM(CASE WHEN d.status = 'SKIPPED' THEN 1 ELSE 0 END) AS skipped_count,
                       SUM(CASE WHEN d.status = 'WAITING' THEN 1 ELSE 0 END) AS waiting_count,
                       SUM(CASE WHEN d.status = 'IN_PROGRESS' THEN 1 ELSE 0 END) AS in_progress_count
                FROM doubts d";

        $params = [];
        if ($sessionId !== null) {
            $sql .= " WHERE d.session_id = ?";
            $params[] = $sessionId;
        }

        $sql .= " GROUP BY LOWER(TRIM(d.topic)) ORDER BY total_doubts DESC, skipped_count DESC";

        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);

        return array_map(function (array $row): array {
            return [
                'normalized_topic' => (string) $row['normalized_topic'],
                'topic' => (string) $row['topic'],
                'total_doubts' => (int) $row['total_doubts'],
                'solved_count' => (int) $row['solved_count'],
                'skipped_count' => (int) $row['skipped_count'],
                'waiting_count' => (int) $row['waiting_count'],
                'in_progress_count' => (int) $row['in_progress_count'],
            ];
        }, $stmt->fetchAll());
    }

    public function findSolvedWithNotes(?int $sessionId = null, int $limit = 50): array
    {
        $sql = "SELECT d.*, s.status AS session_status
                FROM doubts d
                JOIN sessions s ON s.id = d.session_id
                WHERE d.status = 'SOLVED' AND d.resolution_notes IS NOT NULL AND TRIM(d.resolution_notes) != ''";

        $params = [];
        if ($sessionId !== null) {
            $sql .= " AND d.session_id = ?";
            $params[] = $sessionId;
        }

        $sql .= " ORDER BY d.finished_at DESC, d.id DESC LIMIT " . (int) $limit;

        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);

        return array_map([$this, 'format'], $stmt->fetchAll());
    }


    public function findByStudent(int $studentId, ?string $email = null): array
    {
        $sql = 'SELECT d.*, s.status AS session_status, s.title AS session_title, s.mentor_name
                FROM doubts d
                JOIN sessions s ON s.id = d.session_id';
        $params = [];

        if ($email !== null && trim($email) !== '') {
            $sql .= ' WHERE d.student_id = ? OR LOWER(d.student_email) = ?';
            $params = [$studentId, mb_strtolower(trim($email))];
        } else {
            $sql .= ' WHERE d.student_id = ?';
            $params = [$studentId];
        }

        $sql .= ' ORDER BY d.created_at DESC, d.id DESC';
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);

        return array_map([$this, 'format'], $stmt->fetchAll());
    }

    private function format(array $row): array
    {
        $row['id'] = (int) $row['id'];
        $row['session_id'] = (int) $row['session_id'];
        $row['student_id'] = isset($row['student_id']) && $row['student_id'] !== null ? (int) $row['student_id'] : null;

        return $row;
    }
}

