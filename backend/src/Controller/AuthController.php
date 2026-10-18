<?php

declare(strict_types=1);

namespace DoubtQueue\Controller;

use DoubtQueue\Http\Request;
use DoubtQueue\Http\Response;
use DoubtQueue\Service\AuthService;

class AuthController
{
    public function __construct(private AuthService $auth)
    {
    }

    public function register(Request $request, array $params): Response
    {
        return new Response(201, $this->auth->register($request->body()));
    }

    public function login(Request $request, array $params): Response
    {
        return new Response(200, $this->auth->login($request->body()));
    }

    public function me(Request $request, array $params): Response
    {
        $user = $this->auth->requireUser($request);

        return new Response(200, ['user' => $this->auth->sanitizeUser($user)]);
    }

    public function logout(Request $request, array $params): Response
    {
        $this->auth->logout($request);

        return new Response(200, ['message' => 'Logged out successfully']);
    }
}
