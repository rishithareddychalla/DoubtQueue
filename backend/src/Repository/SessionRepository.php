<?php

declare(strict_types=1);

namespace DoubtQueue\Repository;

use PDO;

class SessionRepository
{
    private const SELECT = "SELECT s.*,
            (SELECT COUNT(*) FROM doubts d WHERE d.session_id = s.id AND d.status = 'WAITING') AS waiting_count
        FROM sessions s";

    public function __construct(private PDO $pdo)
    {
    }

    public function create(string $title, string $mentorName, string $status, string $createdAt, ?int $mentorId = null): array
    {
        $this->pdo->prepare(
            'INSERT INTO sessions (title, mentor_name, status, created_at, mentor_id) VALUES (?, ?, ?, ?, ?)'
        )->execute([$title, $mentorName, $status, $createdAt, $mentorId]);

        return $this->find((int) $this->pdo->lastInsertId());
    }

    public function find(int $id): ?array
    {
        $stmt = $this->pdo->prepare(self::SELECT . ' WHERE s.id = ?');
        $stmt->execute([$id]);
        $row = $stmt->fetch();

        return $row === false ? null : $this->format($row);
    }

    public function findAll(?string $status, ?int $mentorId = null): array
    {
        $sql = self::SELECT;
        $clauses = [];
        $params = [];

        if ($status !== null) {
            $clauses[] = 's.status = ?';
            $params[] = $status;
        }

        if ($mentorId !== null) {
            $clauses[] = 's.mentor_id = ?';
            $params[] = $mentorId;
        }

        if (!empty($clauses)) {
            $sql .= ' WHERE ' . implode(' AND ', $clauses);
        }

        $sql .= ' ORDER BY s.created_at DESC, s.id DESC';

        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);

        return array_map([$this, 'format'], $stmt->fetchAll());
    }

    public function close(int $id, string $closedAt): void
    {
        $this->pdo->prepare('UPDATE sessions SET status = ?, closed_at = ? WHERE id = ?')
            ->execute(['CLOSED', $closedAt, $id]);
    }

    private function format(array $row): array
    {
        $row['id'] = (int) $row['id'];
        $row['waiting_count'] = (int) $row['waiting_count'];
        $row['mentor_id'] = isset($row['mentor_id']) && $row['mentor_id'] !== null ? (int) $row['mentor_id'] : null;

        return $row;
    }
}

