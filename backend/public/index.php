<?php

declare(strict_types=1);

use DoubtQueue\Controller\AuthController;
use DoubtQueue\Controller\DoubtController;
use DoubtQueue\Controller\SessionController;
use DoubtQueue\Database;
use DoubtQueue\DatabaseSetup;
use DoubtQueue\Exception\ForbiddenException;
use DoubtQueue\Exception\NotFoundException;
use DoubtQueue\Exception\SessionClosedException;
use DoubtQueue\Exception\UnauthorizedException;
use DoubtQueue\Exception\ValidationException;
use DoubtQueue\Http\Request;
use DoubtQueue\Http\Response;
use DoubtQueue\Repository\AuthTokenRepository;
use DoubtQueue\Repository\DoubtRepository;
use DoubtQueue\Repository\SessionRepository;
use DoubtQueue\Repository\UserRepository;
use DoubtQueue\Router;
use DoubtQueue\Service\AuthService;
use DoubtQueue\Service\DoubtService;
use DoubtQueue\Service\SessionService;

require __DIR__ . '/../vendor/autoload.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PATCH, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    return;
}

try {
    $pdo = Database::connect();
    (new DatabaseSetup($pdo))->run();

    $userRepository = new UserRepository($pdo);
    $authTokenRepository = new AuthTokenRepository($pdo);
    $authService = new AuthService($userRepository, $authTokenRepository);
    $authController = new AuthController($authService);

    $sessionRepository = new SessionRepository($pdo);
    $sessionService = new SessionService($sessionRepository);
    $doubtService = new DoubtService(new DoubtRepository($pdo), $sessionRepository);
    $sessions = new SessionController($sessionService, $authService);
    $doubts = new DoubtController($doubtService, $authService);

    $router = new Router();
    $router->add('GET', '/', fn () => new Response(200, ['status' => 200, 'message' => 'DoubtQueue API is running']));
    $router->add('POST', '/api/auth/register', [$authController, 'register']);
    $router->add('POST', '/api/auth/login', [$authController, 'login']);
    $router->add('GET', '/api/auth/me', [$authController, 'me']);
    $router->add('POST', '/api/auth/logout', [$authController, 'logout']);

    $router->add('POST', '/api/sessions', [$sessions, 'create']);
    $router->add('GET', '/api/sessions', [$sessions, 'list']);
    $router->add('GET', '/api/sessions/{id}', [$sessions, 'get']);
    $router->add('PATCH', '/api/sessions/{id}/close', [$sessions, 'close']);
    $router->add('POST', '/api/sessions/{id}/doubts', [$doubts, 'join']);
    $router->add('GET', '/api/sessions/{id}/current', [$doubts, 'current']);
    $router->add('GET', '/api/sessions/{id}/queue', [$doubts, 'queue']);
    $router->add('POST', '/api/sessions/{id}/next', [$doubts, 'next']);
    $router->add('GET', '/api/sessions/{id}/stats', [$doubts, 'stats']);
    $router->add('GET', '/api/sessions/{id}/intelligence', [$doubts, 'intelligence']);
    $router->add('GET', '/api/doubts/search', [$doubts, 'search']);
    $router->add('GET', '/api/doubts/my', [$doubts, 'myDoubts']);
    $router->add('GET', '/api/doubts/{id}', [$doubts, 'get']);
    $router->add('PATCH', '/api/doubts/{id}/solved', [$doubts, 'solved']);
    $router->add('PATCH', '/api/doubts/{id}/skipped', [$doubts, 'skipped']);

    $response = $router->dispatch(Request::fromGlobals());
} catch (UnauthorizedException $e) {
    $response = Response::error(401, $e->getMessage());
} catch (ForbiddenException $e) {
    $response = Response::error(403, $e->getMessage());
} catch (NotFoundException $e) {
    $response = Response::error(404, $e->getMessage());
} catch (ValidationException $e) {
    $response = Response::error(400, $e->getMessage());
} catch (SessionClosedException $e) {
    $response = Response::error(409, $e->getMessage());
} catch (Throwable $e) {
    error_log((string) $e);
    $response = Response::error(500, 'Something went wrong');
}


$response->send();
