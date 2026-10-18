<?php

declare(strict_types=1);

namespace DoubtQueue\Controller;

use DoubtQueue\Http\Request;
use DoubtQueue\Http\Response;
use DoubtQueue\Model\UserRole;
use DoubtQueue\Service\AuthService;
use DoubtQueue\Service\DoubtService;

class DoubtController
{
    public function __construct(
        private DoubtService $doubts,
        private ?AuthService $auth = null
    ) {
    }

    public function join(Request $request, array $params): Response
    {
        $student = null;
        if ($this->auth !== null) {
            $student = $this->auth->requireUser($request, UserRole::Student);
        }

        return new Response(201, $this->doubts->join($params['id'], $request->body(), $student));
    }

    public function myDoubts(Request $request, array $params): Response
    {
        $student = null;
        if ($this->auth !== null) {
            $student = $this->auth->requireUser($request, UserRole::Student);
        } else {
            $student = ['id' => 1, 'name' => 'Student', 'email' => 'student@doubtqueue.edu', 'role' => 'STUDENT'];
        }

        return new Response(200, $this->doubts->myDoubts($student));
    }

    public function current(Request $request, array $params): Response
    {
        return new Response(200, ['doubt' => $this->doubts->current($params['id'])]);
    }

    public function queue(Request $request, array $params): Response
    {
        $user = $this->auth !== null ? $this->auth->authenticate($request) : null;

        return new Response(200, $this->doubts->queue($params['id'], $user));
    }

    public function next(Request $request, array $params): Response
    {
        $mentor = null;
        if ($this->auth !== null) {
            $mentor = $this->auth->requireUser($request, UserRole::Mentor);
        }

        return new Response(200, $this->doubts->next($params['id'], $mentor));
    }

    public function stats(Request $request, array $params): Response
    {
        return new Response(200, $this->doubts->stats((int) $params['id']));
    }

    public function intelligence(Request $request, array $params): Response
    {
        $mentor = null;
        if ($this->auth !== null) {
            $mentor = $this->auth->requireUser($request, UserRole::Mentor);
        }

        return new Response(200, $this->doubts->intelligence((int) $params['id'], $mentor));
    }

    public function search(Request $request, array $params): Response
    {
        $query = $request->query['q'] ?? '';
        $sessionId = isset($request->query['session_id']) && is_numeric($request->query['session_id'])
            ? (int) $request->query['session_id']
            : null;

        return new Response(200, $this->doubts->searchSolved(is_string($query) ? $query : '', $sessionId));
    }

    public function get(Request $request, array $params): Response
    {
        $user = $this->auth !== null ? $this->auth->authenticate($request) : null;

        return new Response(200, $this->doubts->get($params['id'], $user));
    }

    public function solved(Request $request, array $params): Response
    {
        $user = null;
        if ($this->auth !== null) {
            $user = $this->auth->requireUser($request);
        }

        $body = $request->body();
        $notes = isset($body['resolution_notes']) && is_string($body['resolution_notes'])
            ? $body['resolution_notes']
            : null;

        return new Response(200, $this->doubts->markSolved($params['id'], $notes, $user));
    }

    public function skipped(Request $request, array $params): Response
    {
        $mentor = null;
        if ($this->auth !== null) {
            $mentor = $this->auth->requireUser($request, UserRole::Mentor);
        }

        return new Response(200, $this->doubts->markSkipped($params['id'], $mentor));
    }
}

