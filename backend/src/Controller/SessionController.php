<?php

declare(strict_types=1);

namespace DoubtQueue\Controller;

use DoubtQueue\Http\Request;
use DoubtQueue\Http\Response;
use DoubtQueue\Model\UserRole;
use DoubtQueue\Service\AuthService;
use DoubtQueue\Service\SessionService;

class SessionController
{
    public function __construct(
        private SessionService $sessions,
        private ?AuthService $auth = null
    ) {
    }

    public function create(Request $request, array $params): Response
    {
        $mentor = null;
        if ($this->auth !== null) {
            $mentor = $this->auth->requireUser($request, UserRole::Mentor);
        }

        return new Response(201, $this->sessions->create($request->body(), $mentor));
    }

    public function list(Request $request, array $params): Response
    {
        $status = $request->query['status'] ?? null;
        $mentorId = isset($request->query['mentor_id']) && is_numeric($request->query['mentor_id'])
            ? (int) $request->query['mentor_id']
            : null;

        if ($mentorId === null && isset($request->query['mine']) && $request->query['mine'] === 'true' && $this->auth !== null) {
            $user = $this->auth->authenticate($request);
            if ($user !== null && $user['role'] === UserRole::Mentor->value) {
                $mentorId = (int) $user['id'];
            }
        }

        return new Response(200, $this->sessions->list(is_string($status) ? $status : null, $mentorId));
    }

    public function get(Request $request, array $params): Response
    {
        return new Response(200, $this->sessions->get($params['id']));
    }

    public function close(Request $request, array $params): Response
    {
        $user = null;
        if ($this->auth !== null) {
            $user = $this->auth->requireUser($request, UserRole::Mentor);
        }

        return new Response(200, $this->sessions->close($params['id'], $user));
    }
}

