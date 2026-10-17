<?php

declare(strict_types=1);

namespace DoubtQueue\Controller;

use DoubtQueue\Http\Request;
use DoubtQueue\Http\Response;
use DoubtQueue\Service\DoubtService;

class DoubtController
{
    public function __construct(private DoubtService $doubts)
    {
    }

    public function join(Request $request, array $params): Response
    {
        return new Response(201, $this->doubts->join($params['id'], $request->body()));
    }

    public function current(Request $request, array $params): Response
    {
        return new Response(200, ['doubt' => $this->doubts->current($params['id'])]);
    }

    public function queue(Request $request, array $params): Response
    {
        return new Response(200, $this->doubts->queue($params['id']));
    }

    public function next(Request $request, array $params): Response
    {
        return new Response(200, $this->doubts->next($params['id']));
    }

    public function stats(Request $request, array $params): Response
    {
        return new Response(200, $this->doubts->stats((int) $params['id']));
    }

    public function intelligence(Request $request, array $params): Response
    {
        return new Response(200, $this->doubts->intelligence((int) $params['id']));
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
        return new Response(200, $this->doubts->get($params['id']));
    }

    public function solved(Request $request, array $params): Response
    {
        $body = $request->body();
        $notes = isset($body['resolution_notes']) && is_string($body['resolution_notes'])
            ? $body['resolution_notes']
            : null;

        return new Response(200, $this->doubts->markSolved($params['id'], $notes));
    }

    public function skipped(Request $request, array $params): Response
    {
        return new Response(200, $this->doubts->markSkipped($params['id']));
    }
}
