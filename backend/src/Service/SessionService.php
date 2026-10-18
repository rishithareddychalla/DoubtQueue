<?php

declare(strict_types=1);

namespace DoubtQueue\Service;

use DoubtQueue\Exception\ForbiddenException;
use DoubtQueue\Exception\NotFoundException;
use DoubtQueue\Exception\ValidationException;
use DoubtQueue\Model\SessionStatus;
use DoubtQueue\Repository\SessionRepository;

class SessionService
{
    public function __construct(private SessionRepository $sessions)
    {
    }

    public function create(array $data, ?array $mentor = null): array
    {
        $title = $this->requiredText($data, 'title');
        $mentorName = $mentor['name'] ?? ($data['mentor_name'] ?? null);
        $mentorName = is_string($mentorName) ? trim($mentorName) : '';

        if ($mentorName === '') {
            throw new ValidationException('mentor_name is required');
        }

        if (mb_strlen($mentorName) > 255) {
            throw new ValidationException('mentor_name must be 255 characters or fewer');
        }

        $mentorId = $mentor !== null ? (int) $mentor['id'] : (isset($data['mentor_id']) ? (int) $data['mentor_id'] : null);

        return $this->sessions->create($title, $mentorName, SessionStatus::Open->value, gmdate('Y-m-d H:i:s'), $mentorId);
    }

    public function list(?string $status, ?int $mentorId = null): array
    {
        if ($status !== null && SessionStatus::tryFrom($status) === null) {
            throw new ValidationException('status must be OPEN or CLOSED');
        }

        return $this->sessions->findAll($status, $mentorId);
    }

    public function get(int $id): array
    {
        $session = $this->sessions->find($id);

        if ($session === null) {
            throw new NotFoundException("Session with id $id not found");
        }

        return $session;
    }

    public function close(int $id, ?array $user = null): array
    {
        $session = $this->get($id);

        if ($user !== null) {
            if ($user['role'] !== 'MENTOR') {
                throw new ForbiddenException('Only mentors can close sessions');
            }
            if ($session['mentor_id'] !== null && $session['mentor_id'] !== (int) $user['id']) {
                throw new ForbiddenException('You are not authorized to close this session');
            }
        }

        if ($session['status'] === SessionStatus::Open->value) {
            $this->sessions->close($id, gmdate('Y-m-d H:i:s'));
        }

        return $this->get($id);
    }


    private function requiredText(array $data, string $field): string
    {
        $value = $data[$field] ?? null;
        $value = is_string($value) ? trim($value) : '';

        if ($value === '') {
            throw new ValidationException("$field is required");
        }

        if (mb_strlen($value) > 255) {
            throw new ValidationException("$field must be 255 characters or fewer");
        }

        return $value;
    }
}
