<?php

declare(strict_types=1);

namespace DoubtQueue\Service;

use DoubtQueue\Config;
use DoubtQueue\Exception\ForbiddenException;
use DoubtQueue\Exception\UnauthorizedException;
use DoubtQueue\Exception\ValidationException;
use DoubtQueue\Http\Request;
use DoubtQueue\Model\UserRole;
use DoubtQueue\Repository\AuthTokenRepository;
use DoubtQueue\Repository\UserRepository;

class AuthService
{
    public function __construct(
        private UserRepository $users,
        private AuthTokenRepository $tokens
    ) {
    }

    public function register(array $data): array
    {
        $name = $this->requiredText($data, 'name', 255);
        $email = $this->requiredText($data, 'email', 255);

        if (filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
            throw new ValidationException('email must be a valid email address');
        }

        $email = mb_strtolower(trim($email));
        if ($this->users->findByEmail($email) !== null) {
            throw new ValidationException('An account with this email address already exists');
        }

        $password = $data['password'] ?? '';
        if (!is_string($password) || mb_strlen($password) < 6) {
            throw new ValidationException('password must be at least 6 characters');
        }

        $roleInput = strtoupper(trim((string) ($data['role'] ?? 'STUDENT')));
        $role = UserRole::tryFrom($roleInput);
        if ($role === null) {
            throw new ValidationException('role must be STUDENT or MENTOR');
        }

        if ($role === UserRole::Mentor) {
            $secret = trim((string) ($data['mentor_secret'] ?? ''));
            $expectedKey = Config::get('MENTOR_REGISTRATION_KEY', 'MENTOR_SECRET_2026');
            if ($secret === '' || !hash_equals($expectedKey, $secret)) {
                throw new ValidationException(
                    'Invalid mentor registration secret key. Mentor accounts require explicit authorization.'
                );
            }
        }

        $department = trim((string) ($data['department'] ?? 'Computer Science & Engineering'));
        if ($department === '') {
            $department = 'Computer Science & Engineering';
        }

        $passwordHash = password_hash($password, PASSWORD_BCRYPT);
        $user = $this->users->create($name, $email, $passwordHash, $role->value, $department);

        $token = bin2hex(random_bytes(32));
        $this->tokens->createToken($user['id'], $token);

        return [
            'user' => $this->sanitizeUser($user),
            'token' => $token,
        ];
    }

    public function login(array $data): array
    {
        $email = $this->requiredText($data, 'email', 255);
        $password = (string) ($data['password'] ?? '');

        if ($password === '') {
            throw new ValidationException('password is required');
        }

        $user = $this->users->findByEmail(mb_strtolower(trim($email)));
        if ($user === null || !password_verify($password, $user['password_hash'])) {
            throw new ValidationException('Invalid email or password');
        }

        $portal = $data['portal'] ?? $data['expected_role'] ?? null;
        if (is_string($portal) && trim($portal) !== '') {
            $expected = strtoupper(trim($portal));
            if ($user['role'] !== $expected) {
                $roleLabel = $user['role'] === UserRole::Mentor->value ? 'Mentor' : 'Student';
                $portalLabel = $user['role'] === UserRole::Mentor->value ? 'Mentor Portal' : 'Student Portal';
                throw new ForbiddenException(
                    "Access denied: This account is registered as a $roleLabel. Please use the $portalLabel."
                );
            }
        }

        $token = bin2hex(random_bytes(32));
        $this->tokens->createToken($user['id'], $token);

        return [
            'user' => $this->sanitizeUser($user),
            'token' => $token,
        ];
    }

    public function authenticate(Request $request): ?array
    {
        $token = $request->bearerToken();
        if ($token === null) {
            return null;
        }

        return $this->tokens->findUserByToken($token);
    }

    public function requireUser(Request $request, ?UserRole $role = null): array
    {
        $user = $this->authenticate($request);
        if ($user === null) {
            throw new UnauthorizedException('Authentication required. Please log in.');
        }

        if ($role !== null && $user['role'] !== $role->value) {
            throw new ForbiddenException('Forbidden: Action requires ' . strtolower($role->value) . ' role');
        }

        return $user;
    }

    public function logout(Request $request): void
    {
        $token = $request->bearerToken();
        if ($token !== null) {
            $this->tokens->revokeToken($token);
        }
    }

    public function sanitizeUser(array $user): array
    {
        return [
            'id' => (int) $user['id'],
            'name' => $user['name'],
            'email' => $user['email'],
            'role' => $user['role'],
            'status' => $user['status'] ?? 'ACTIVE',
            'department' => $user['department'] ?? 'Computer Science & Engineering',
            'created_at' => $user['created_at'],
        ];
    }

    private function requiredText(array $data, string $field, int $maxLength): string
    {
        $value = $data[$field] ?? null;
        $value = is_string($value) ? trim($value) : '';

        if ($value === '') {
            throw new ValidationException("$field is required");
        }

        if (mb_strlen($value) > $maxLength) {
            throw new ValidationException("$field must be $maxLength characters or fewer");
        }

        return $value;
    }
}
