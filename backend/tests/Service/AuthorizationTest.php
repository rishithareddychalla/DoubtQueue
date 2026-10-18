<?php

declare(strict_types=1);

namespace DoubtQueue\Tests\Service;

use DoubtQueue\Database;
use DoubtQueue\DatabaseSetup;
use DoubtQueue\Exception\ForbiddenException;
use DoubtQueue\Exception\ValidationException;
use DoubtQueue\Http\Request;
use DoubtQueue\Model\UserRole;
use DoubtQueue\Repository\AuthTokenRepository;
use DoubtQueue\Repository\DoubtRepository;
use DoubtQueue\Repository\SessionRepository;
use DoubtQueue\Repository\UserRepository;
use DoubtQueue\Service\AuthService;
use DoubtQueue\Service\DoubtService;
use DoubtQueue\Service\SessionService;
use PHPUnit\Framework\TestCase;

class AuthorizationTest extends TestCase
{
    private AuthService $auth;
    private SessionService $sessions;
    private DoubtService $doubts;
    private array $mentor1;
    private array $mentor2;
    private array $student1;
    private array $student2;
    private array $session1;
    private array $session2;

    protected function setUp(): void
    {
        $pdo = Database::memory();
        (new DatabaseSetup($pdo))->run();

        $userRepo = new UserRepository($pdo);
        $tokenRepo = new AuthTokenRepository($pdo);
        $this->auth = new AuthService($userRepo, $tokenRepo);

        $sessionRepo = new SessionRepository($pdo);
        $this->sessions = new SessionService($sessionRepo);

        $doubtRepo = new DoubtRepository($pdo);
        $this->doubts = new DoubtService($doubtRepo, $sessionRepo);

        // Fetch seeded users
        $this->mentor1 = $userRepo->findByEmail('mentor@doubtqueue.edu');
        $this->student1 = $userRepo->findByEmail('student@doubtqueue.edu');

        // Create second mentor and second student
        $resM2 = $this->auth->register([
            'name' => 'Mentor Two',
            'email' => 'mentor2@doubtqueue.edu',
            'password' => 'Password123!',
            'role' => 'MENTOR',
            'mentor_secret' => 'MENTOR_SECRET_2026',
        ]);
        $this->mentor2 = $resM2['user'];

        $resS2 = $this->auth->register([
            'name' => 'Student Two',
            'email' => 'student2@doubtqueue.edu',
            'password' => 'Password123!',
            'role' => 'STUDENT',
        ]);
        $this->student2 = $resS2['user'];

        // Create sessions
        $this->session1 = $this->sessions->create(['title' => 'Mentor 1 Session'], $this->mentor1);
        $this->session2 = $this->sessions->create(['title' => 'Mentor 2 Session'], $this->mentor2);
    }

    public function testStudentCannotCloseSession(): void
    {
        $this->expectException(ForbiddenException::class);
        $this->expectExceptionMessage('Only mentors can close sessions');

        $this->sessions->close($this->session1['id'], $this->student1);
    }

    public function testMentorCannotCloseAnotherMentorsSession(): void
    {
        $this->expectException(ForbiddenException::class);
        $this->expectExceptionMessage('You are not authorized to close this session');

        $this->sessions->close($this->session1['id'], $this->mentor2);
    }

    public function testMentorCanCloseOwnSession(): void
    {
        $closed = $this->sessions->close($this->session1['id'], $this->mentor1);
        $this->assertSame('CLOSED', $closed['status']);
    }

    public function testStudentCannotTakeNextDoubt(): void
    {
        $this->expectException(ForbiddenException::class);
        $this->expectExceptionMessage('Only mentors can take the next doubt');

        $this->doubts->next($this->session1['id'], $this->student1);
    }

    public function testMentorCannotTakeNextDoubtFromOtherMentorsSession(): void
    {
        $this->doubts->join($this->session1['id'], [
            'topic' => 'Arrays',
            'question' => 'How to index?',
        ], $this->student1);

        $this->expectException(ForbiddenException::class);
        $this->expectExceptionMessage('You are not authorized to manage this session');

        $this->doubts->next($this->session1['id'], $this->mentor2);
    }

    public function testStudentCannotViewOtherStudentsPrivateDoubt(): void
    {
        $doubt = $this->doubts->join($this->session1['id'], [
            'topic' => 'Secrets',
            'question' => 'My secret question',
        ], $this->student1);

        $this->expectException(ForbiddenException::class);
        $this->expectExceptionMessage('You are not authorized to view this doubt');

        $this->doubts->get($doubt['id'], $this->student2);
    }

    public function testStudentCanViewOwnDoubt(): void
    {
        $doubt = $this->doubts->join($this->session1['id'], [
            'topic' => 'My Doubt',
            'question' => 'My question',
        ], $this->student1);

        $fetched = $this->doubts->get($doubt['id'], $this->student1);
        $this->assertSame($doubt['id'], $fetched['id']);
    }

    public function testMyDoubtsReturnsOnlyStudentOwnDoubts(): void
    {
        $d1 = $this->doubts->join($this->session1['id'], [
            'topic' => 'Student 1 Topic',
            'question' => 'Question 1',
        ], $this->student1);

        $d2 = $this->doubts->join($this->session1['id'], [
            'topic' => 'Student 2 Topic',
            'question' => 'Question 2',
        ], $this->student2);

        $s1Doubts = $this->doubts->myDoubts($this->student1);
        $s1Ids = array_column($s1Doubts, 'id');
        $this->assertContains($d1['id'], $s1Ids);
        $this->assertNotContains($d2['id'], $s1Ids);

        $s2Doubts = $this->doubts->myDoubts($this->student2);
        $s2Ids = array_column($s2Doubts, 'id');
        $this->assertContains($d2['id'], $s2Ids);
        $this->assertNotContains($d1['id'], $s2Ids);
    }

    public function testStudentCannotSetMentorResolutionNotes(): void
    {
        $doubt = $this->doubts->join($this->session1['id'], [
            'topic' => 'Topic',
            'question' => 'Question',
        ], $this->student1);

        $this->doubts->next($this->session1['id'], $this->mentor1);

        $this->expectException(ForbiddenException::class);
        $this->expectExceptionMessage('Students cannot set mentor resolution notes');

        $this->doubts->markSolved($doubt['id'], 'Hacked resolution notes', $this->student1);
    }

    public function testStudentCannotAccessMentorIntelligence(): void
    {
        $this->expectException(ForbiddenException::class);
        $this->expectExceptionMessage('Only mentors can view topic intelligence');

        $this->doubts->intelligence($this->session1['id'], $this->student1);
    }

    public function testMentorCannotAccessIntelligenceForOtherMentorsSession(): void
    {
        $this->expectException(ForbiddenException::class);
        $this->expectExceptionMessage('You are not authorized to view intelligence for this session');

        $this->doubts->intelligence($this->session1['id'], $this->mentor2);
    }

    public function testStudentViewingQueueHasOtherStudentEmailsMasked(): void
    {
        $this->doubts->join($this->session1['id'], [
            'topic' => 'Topic 1',
            'question' => 'Q1',
        ], $this->student1);

        $this->doubts->join($this->session1['id'], [
            'topic' => 'Topic 2',
            'question' => 'Q2',
        ], $this->student2);

        $queue = $this->doubts->queue($this->session1['id'], $this->student1);
        $this->assertCount(2, $queue);

        // Student 1 sees own email
        $this->assertSame($this->student1['email'], $queue[0]['student_email']);
        // Student 1 sees student 2's email masked/empty
        $this->assertSame('', $queue[1]['student_email']);
    }
}
