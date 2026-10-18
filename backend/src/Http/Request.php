<?php

declare(strict_types=1);

namespace DoubtQueue\Http;

use DoubtQueue\Exception\ValidationException;

class Request
{
    public function __construct(
        public readonly string $method,
        public readonly string $path,
        public readonly array $query = [],
        private readonly string $rawBody = '',
        public readonly array $headers = []
    ) {
    }

    public static function fromGlobals(): self
    {
        $path = (string) parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);

        $headers = [];
        if (function_exists('apache_request_headers')) {
            $apacheHeaders = apache_request_headers();
            if (is_array($apacheHeaders)) {
                foreach ($apacheHeaders as $key => $val) {
                    $headers[strtolower((string) $key)] = (string) $val;
                }
            }
        }

        foreach ($_SERVER as $key => $val) {
            if (str_starts_with($key, 'HTTP_')) {
                $headerName = strtolower(str_replace('_', '-', substr($key, 5)));
                $headers[$headerName] = (string) $val;
            } elseif (in_array($key, ['CONTENT_TYPE', 'CONTENT_LENGTH', 'AUTHORIZATION'], true)) {
                $headerName = strtolower(str_replace('_', '-', $key));
                $headers[$headerName] = (string) $val;
            }
        }

        return new self(
            strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET'),
            $path === '/' ? $path : rtrim($path, '/'),
            $_GET,
            (string) file_get_contents('php://input'),
            $headers
        );
    }

    public function header(string $name): ?string
    {
        return $this->headers[strtolower($name)] ?? null;
    }

    public function bearerToken(): ?string
    {
        $auth = $this->header('authorization');
        if ($auth === null || !preg_match('/Bearer\s+(\S+)/i', $auth, $matches)) {
            return null;
        }

        return $matches[1];
    }

    public function body(): array
    {
        if (trim($this->rawBody) === '') {
            return [];
        }

        $data = json_decode($this->rawBody, true);

        if (!is_array($data)) {
            throw new ValidationException('Request body must be valid JSON');
        }

        return $data;
    }
}

