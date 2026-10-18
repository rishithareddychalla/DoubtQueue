<?php

declare(strict_types=1);

namespace DoubtQueue\Repository;

use PDO;

class AuthTokenRepository
{
    public function __construct(private PDO $pdo)
    {
    }

    public function createToken(int $userId, string $token, ?string $createdAt = null, ?string $expiresAt = null): void
    {
        $createdAt ??= gmdate('Y-m-d H:i:s');
        $stmt = $this->pdo->prepare(
            'INSERT INTO auth_tokens (user_id, token, created_at, expires_at) VALUES (?, ?, ?, ?)'
        );
        $stmt->execute([$userId, $token, $createdAt, $expiresAt]);
    }

    public function findUserByToken(string $token): ?array
    {
        $now = gmdate('Y-m-d H:i:s');
        $stmt = $this->pdo->prepare(
            'SELECT u.id, u.name, u.email, u.role, u.status, u.department, u.created_at, t.token, t.expires_at
             FROM auth_tokens t
             JOIN users u ON u.id = t.user_id
             WHERE t.token = ? AND (t.expires_at IS NULL OR t.expires_at > ?)
             LIMIT 1'
        );
        $stmt->execute([$token, $now]);
        $row = $stmt->fetch();

        if ($row === false) {
            return null;
        }

        $row['id'] = (int) $row['id'];
        return $row;
    }

    public function revokeToken(string $token): void
    {
        $stmt = $this->pdo->prepare('DELETE FROM auth_tokens WHERE token = ?');
        $stmt->execute([$token]);
    }

    public function revokeAllForUser(int $userId): void
    {
        $stmt = $this->pdo->prepare('DELETE FROM auth_tokens WHERE user_id = ?');
        $stmt->execute([$userId]);
    }
}
