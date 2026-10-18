<?php

declare(strict_types=1);

namespace DoubtQueue\Tests\Service;

use DoubtQueue\Database;
use DoubtQueue\DatabaseSetup;
use DoubtQueue\Exception\ForbiddenException;
use DoubtQueue\Exception\UnauthorizedException;
use DoubtQueue\Exception\ValidationException;
use DoubtQueue\Http\Request;
use DoubtQueue\Model\UserRole;
use DoubtQueue\Repository\AuthTokenRepository;
use DoubtQueue\Repository\UserRepository;
use DoubtQueue\Service\AuthService;
use PHPUnit\Framework\TestCase;

class AuthServiceTest extends TestCase
{
    private AuthService $auth;
    private UserRepository $users;
    private AuthTokenRepository $tokens;

    protected function setUp(): void
    {
        $pdo = Database::memory();
        (new DatabaseSetup($pdo))->run();

        $this->users = new UserRepository($pdo);
        $this->tokens = new AuthTokenRepository($pdo);
        $this->auth = new AuthService($this->users, $this->tokens);
    }

    public function testStudentRegistrationWorks(): void
    {
        $res = $this->auth->register([
            'name' => 'John Doe',
            'email' => 'john.doe@example.com',
            'password' => 'secret123',
            'role' => 'STUDENT',
            'department' => 'CS',
        ]);

        $this->assertArrayHasKey('user', $res);
        $this->assertArrayHasKey('token', $res);
        $this->assertSame('John Doe', $res['user']['name']);
        $this->assertSame('john.doe@example.com', $res['user']['email']);
        $this->assertSame('STUDENT', $res['user']['role']);
        $this->assertNotEmpty($res['token']);
    }

    public function testDuplicateEmailRegistrationThrows(): void
    {
        $this->expectException(ValidationException::class);
        $this->expectExceptionMessage('already exists');

        $this->auth->register([
            'name' => 'Arjun Sharma',
            'email' => 'student@doubtqueue.edu',
            'password' => 'secret123',
            'role' => 'STUDENT',
        ]);
    }

    public function testShortPasswordThrows(): void
    {
        $this->expectException(ValidationException::class);
        $this->expectExceptionMessage('at least 6 characters');

        $this->auth->register([
            'name' => 'Short Pwd',
            'email' => 'short@example.com',
            'password' => '123',
            'role' => 'STUDENT',
        ]);
    }

    public function testMentorRegistrationRequiresSecretKey(): void
    {
        $this->expectException(ValidationException::class);
        $this->expectExceptionMessage('Invalid mentor registration secret key');

        $this->auth->register([
            'name' => 'Hacker Mentor',
            'email' => 'hacker@example.com',
            'password' => 'secret123',
            'role' => 'MENTOR',
            'mentor_secret' => 'wrong_key',
        ]);
    }

    public function testMentorRegistrationWithCorrectSecretSucceeds(): void
    {
        $res = $this->auth->register([
            'name' => 'Authorized Mentor',
            'email' => 'auth.mentor@example.com',
            'password' => 'secret123',
            'role' => 'MENTOR',
            'mentor_secret' => 'MENTOR_SECRET_2026',
        ]);

        $this->assertSame('MENTOR', $res['user']['role']);
        $this->assertNotEmpty($res['token']);
    }

    public function testLoginWithValidCredentialsSucceeds(): void
    {
        $res = $this->auth->login([
            'email' => 'student@doubtqueue.edu',
            'password' => 'Password123!',
        ]);

        $this->assertSame('STUDENT', $res['user']['role']);
        $this->assertNotEmpty($res['token']);
    }

    public function testLoginWithInvalidPasswordThrows(): void
    {
        $this->expectException(ValidationException::class);
        $this->expectExceptionMessage('Invalid email or password');

        $this->auth->login([
            'email' => 'student@doubtqueue.edu',
            'password' => 'wrongpass',
        ]);
    }

    public function testStudentDeniedMentorPortalLogin(): void
    {
        $this->expectException(ForbiddenException::class);
        $this->expectExceptionMessage('Access denied: This account is registered as a Student. Please use the Student Portal.');

        $this->auth->login([
            'email' => 'student@doubtqueue.edu',
            'password' => 'Password123!',
            'portal' => 'MENTOR',
        ]);
    }

    public function testMentorDeniedStudentPortalLogin(): void
    {
        $this->expectException(ForbiddenException::class);
        $this->expectExceptionMessage('Access denied: This account is registered as a Mentor. Please use the Mentor Portal.');

        $this->auth->login([
            'email' => 'mentor@doubtqueue.edu',
            'password' => 'Password123!',
            'portal' => 'STUDENT',
        ]);
    }

    public function testBearerAuthenticationAndLogout(): void
    {
        $login = $this->auth->login([
            'email' => 'student@doubtqueue.edu',
            'password' => 'Password123!',
        ]);
        $token = $login['token'];

        $req = new Request('GET', '/api/auth/me', [], '', ['authorization' => 'Bearer ' . $token]);
        $user = $this->auth->authenticate($req);
        $this->assertNotNull($user);
        $this->assertSame('student@doubtqueue.edu', $user['email']);

        // Test requireUser with role
        $verified = $this->auth->requireUser($req, UserRole::Student);
        $this->assertSame('student@doubtqueue.edu', $verified['email']);

        // Test requireUser with wrong role throws ForbiddenException
        $this->expectException(ForbiddenException::class);
        $this->auth->requireUser($req, UserRole::Mentor);
    }

    public function testUnauthenticatedRequestThrowsUnauthorizedException(): void
    {
        $req = new Request('GET', '/api/auth/me');
        $this->expectException(UnauthorizedException::class);
        $this->auth->requireUser($req);
    }
}
