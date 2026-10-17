<?php

declare(strict_types=1);

use DoubtQueue\Controller\DoubtController;
use DoubtQueue\Controller\SessionController;
use DoubtQueue\Database;
use DoubtQueue\DatabaseSetup;
use DoubtQueue\Exception\NotFoundException;
use DoubtQueue\Exception\SessionClosedException;
use DoubtQueue\Exception\ValidationException;
use DoubtQueue\Http\Request;
use DoubtQueue\Http\Response;
use DoubtQueue\Repository\DoubtRepository;
use DoubtQueue\Repository\SessionRepository;
use DoubtQueue\Router;
use DoubtQueue\Service\DoubtService;
use DoubtQueue\Service\SessionService;

require __DIR__ . '/../vendor/autoload.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PATCH, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    return;
}

try {
    $pdo = Database::connect();
    (new DatabaseSetup($pdo))->run();

    $sessionRepository = new SessionRepository($pdo);
    $sessionService = new SessionService($sessionRepository);
    $doubtService = new DoubtService(new DoubtRepository($pdo), $sessionRepository);
    $sessions = new SessionController($sessionService);
    $doubts = new DoubtController($doubtService);

    $router = new Router();
    $router->add('GET', '/', fn () => new Response(200, ['status' => 200, 'message' => 'DoubtQueue API is running']));
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
    $router->add('GET', '/api/doubts/{id}', [$doubts, 'get']);
    $router->add('PATCH', '/api/doubts/{id}/solved', [$doubts, 'solved']);
    $router->add('PATCH', '/api/doubts/{id}/skipped', [$doubts, 'skipped']);

    $response = $router->dispatch(Request::fromGlobals());
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
