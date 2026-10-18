<?php

declare(strict_types=1);

namespace DoubtQueue\Repository;

use PDO;

class UserRepository
{
    private const SELECT = 'SELECT id, name, email, password_hash, role, status, department, created_at FROM users';

    public function __construct(private PDO $pdo)
    {
    }

    public function create(
        string $name,
        string $email,
        string $passwordHash,
        string $role,
        string $department = 'Computer Science & Engineering',
        string $status = 'ACTIVE',
        ?string $createdAt = null
    ): array {
        $createdAt ??= gmdate('Y-m-d H:i:s');
        $stmt = $this->pdo->prepare(
            'INSERT INTO users (name, email, password_hash, role, status, department, created_at)
             VALUES (?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $name,
            mb_strtolower(trim($email)),
            $passwordHash,
            $role,
            $status,
            $department,
            $createdAt,
        ]);

        return $this->findById((int) $this->pdo->lastInsertId()) ?? [];
    }


    public function findByEmail(string $email): ?array
    {
        $stmt = $this->pdo->prepare(self::SELECT . ' WHERE LOWER(email) = ? LIMIT 1');
        $stmt->execute([mb_strtolower(trim($email))]);
        $row = $stmt->fetch();

        return $row === false ? null : $this->format($row);
    }

    public function findById(int $id): ?array
    {
        $stmt = $this->pdo->prepare(self::SELECT . ' WHERE id = ? LIMIT 1');
        $stmt->execute([$id]);
        $row = $stmt->fetch();

        return $row === false ? null : $this->format($row);
    }

    private function format(array $row): array
    {
        $row['id'] = (int) $row['id'];
        return $row;
    }
}
