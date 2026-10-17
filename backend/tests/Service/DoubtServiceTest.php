<?php

declare(strict_types=1);

namespace DoubtQueue\Tests\Service;

use DoubtQueue\Database;
use DoubtQueue\DatabaseSetup;
use DoubtQueue\Exception\NotFoundException;
use DoubtQueue\Exception\SessionClosedException;
use DoubtQueue\Exception\ValidationException;
use DoubtQueue\Repository\DoubtRepository;
use DoubtQueue\Repository\SessionRepository;
use DoubtQueue\Service\DoubtService;
use DoubtQueue\Service\SessionService;
use PHPUnit\Framework\TestCase;

class DoubtServiceTest extends TestCase
{
    private DoubtService $doubts;
    private SessionService $sessions;

    protected function setUp(): void
    {
        $pdo = Database::memory();
        (new DatabaseSetup($pdo))->createTables();

        $sessionRepository = new SessionRepository($pdo);
        $this->sessions = new SessionService($sessionRepository);
        $this->doubts = new DoubtService(new DoubtRepository($pdo), $sessionRepository);
    }

    public function testJoiningOpenSessionWorks(): void
    {
        $session = $this->sessions->create(['title' => 'PHP', 'mentor_name' => 'Priya']);

        $doubt = $this->doubts->join($session['id'], $this->validData());

        $this->assertSame('WAITING', $doubt['status']);
        $this->assertSame(1, $doubt['position']);
        $this->assertSame('Asha', $doubt['student_name']);
    }

    public function testJoiningClosedSessionThrows(): void
    {
        $session = $this->sessions->create(['title' => 'PHP', 'mentor_name' => 'Priya']);
        $this->sessions->close($session['id']);

        $this->expectException(SessionClosedException::class);

        $this->doubts->join($session['id'], $this->validData());
    }

    public function testMissingQuestionThrows(): void
    {
        $session = $this->sessions->create(['title' => 'PHP', 'mentor_name' => 'Priya']);
        $data = $this->validData();
        unset($data['question']);

        $this->expectException(ValidationException::class);

        $this->doubts->join($session['id'], $data);
    }

    public function testInvalidEmailThrows(): void
    {
        $session = $this->sessions->create(['title' => 'PHP', 'mentor_name' => 'Priya']);

        $this->expectException(ValidationException::class);

        $this->doubts->join($session['id'], ['student_email' => 'not-an-email'] + $this->validData());
    }

    public function testNextTakesOldestWaitingDoubt(): void
    {
        $session = $this->sessions->create(['title' => 'PHP', 'mentor_name' => 'Priya']);
        $first = $this->doubts->join($session['id'], $this->validData());
        $second = $this->doubts->join($session['id'], ['student_name' => 'Ben'] + $this->validData());

        $taken = $this->doubts->next($session['id']);

        $this->assertSame($first['id'], $taken['id']);
        $this->assertSame('IN_PROGRESS', $taken['status']);
        $this->assertNotNull($taken['started_at']);
        $this->assertNull($taken['position']);
        $this->assertSame(1, $this->doubts->get($second['id'])['position']);
    }

    public function testSolvedAndSkippedSetFinishedAt(): void
    {
        $session = $this->sessions->create(['title' => 'PHP', 'mentor_name' => 'Priya']);
        $this->doubts->join($session['id'], $this->validData());
        $this->doubts->join($session['id'], $this->validData());

        $solved = $this->doubts->markSolved($this->doubts->next($session['id'])['id']);
        $skipped = $this->doubts->markSkipped($this->doubts->next($session['id'])['id']);

        $this->assertSame('SOLVED', $solved['status']);
        $this->assertNotNull($solved['finished_at']);
        $this->assertSame('SKIPPED', $skipped['status']);
        $this->assertSame(1, $this->doubts->stats($session['id'])['SOLVED']);
    }

    public function testFinishingDoubtThatIsNotInProgressThrows(): void
    {
        $session = $this->sessions->create(['title' => 'PHP', 'mentor_name' => 'Priya']);
        $doubt = $this->doubts->join($session['id'], $this->validData());

        $this->expectException(ValidationException::class);

        $this->doubts->markSolved($doubt['id']);
    }

    public function testTakingNextWhenAnotherDoubtIsInProgressThrows(): void
    {
        $session = $this->sessions->create(['title' => 'PHP', 'mentor_name' => 'Priya']);
        $this->doubts->join($session['id'], $this->validData());
        $this->doubts->join($session['id'], ['student_name' => 'Ben'] + $this->validData());

        $this->doubts->next($session['id']);

        $this->expectException(ValidationException::class);
        $this->doubts->next($session['id']);
    }

    public function testTakingNextOnClosedSessionThrows(): void
    {
        $session = $this->sessions->create(['title' => 'PHP', 'mentor_name' => 'Priya']);
        $this->doubts->join($session['id'], $this->validData());
        $this->sessions->close($session['id']);

        $this->expectException(SessionClosedException::class);
        $this->doubts->next($session['id']);
    }

    public function testCurrentReturnsActiveDoubtOrNull(): void
    {
        $session = $this->sessions->create(['title' => 'PHP', 'mentor_name' => 'Priya']);
        $this->assertNull($this->doubts->current($session['id']));

        $doubt = $this->doubts->join($session['id'], $this->validData());
        $this->assertNull($this->doubts->current($session['id']));

        $this->doubts->next($session['id']);
        $current = $this->doubts->current($session['id']);
        $this->assertNotNull($current);
        $this->assertSame($doubt['id'], $current['id']);

        $this->doubts->markSolved($doubt['id'], 'Fixed.');
        $this->assertNull($this->doubts->current($session['id']));
    }

    public function testMarkSolvedStoresResolutionNotes(): void
    {
        $session = $this->sessions->create(['title' => 'PHP', 'mentor_name' => 'Priya']);
        $doubt = $this->doubts->join($session['id'], $this->validData());
        $this->doubts->next($session['id']);

        $solved = $this->doubts->markSolved($doubt['id'], 'Use array_keys() to get keys.');
        $this->assertSame('Use array_keys() to get keys.', $solved['resolution_notes']);
    }

    public function testSearchSolvedReturnsMatchingDoubts(): void
    {
        $session = $this->sessions->create(['title' => 'PHP', 'mentor_name' => 'Priya']);
        $doubt = $this->doubts->join($session['id'], $this->validData());
        $this->doubts->next($session['id']);
        $this->doubts->markSolved($doubt['id'], 'Use a foreach loop.');

        $matches = $this->doubts->searchSolved('foreach');
        $this->assertCount(1, $matches);
        $this->assertSame($doubt['id'], $matches[0]['id']);

        $empty = $this->doubts->searchSolved('nonexistent');
        $this->assertEmpty($empty);
    }

    public function testSearchSolvedSanitizesStudentPII(): void
    {
        $session = $this->sessions->create(['title' => 'PHP', 'mentor_name' => 'Priya']);
        $doubt = $this->doubts->join($session['id'], $this->validData());
        $this->doubts->next($session['id']);
        $this->doubts->markSolved($doubt['id'], 'Use a foreach loop.');

        $matches = $this->doubts->searchSolved('loop array');
        $this->assertNotEmpty($matches);
        $this->assertArrayNotHasKey('student_name', $matches[0]);
        $this->assertArrayNotHasKey('student_email', $matches[0]);
        $this->assertArrayHasKey('topic', $matches[0]);
        $this->assertArrayHasKey('question', $matches[0]);
        $this->assertArrayHasKey('resolution_notes', $matches[0]);
        $this->assertNotNull($matches[0]['similarity_score']);
    }

    public function testSearchSolvedWithTypoMatches(): void
    {
        $session = $this->sessions->create(['title' => 'PHP', 'mentor_name' => 'Priya']);
        $doubt = $this->doubts->join($session['id'], [
            'student_name' => 'Asha',
            'student_email' => 'asha@example.com',
            'topic' => 'Async',
            'question' => 'How does await work with Future?',
        ]);
        $this->doubts->next($session['id']);
        $this->doubts->markSolved($doubt['id'], 'Await pauses until Future resolves.');

        // "asynk" typo
        $matches = $this->doubts->searchSolved('asynk await');
        $this->assertCount(1, $matches);
        $this->assertSame($doubt['id'], $matches[0]['id']);
    }

    public function testIntelligenceReturnsTopicAggregationAndHotspots(): void
    {
        $session = $this->sessions->create(['title' => 'PHP', 'mentor_name' => 'Priya']);

        // 2 solved doubts on Arrays
        $d1 = $this->doubts->join($session['id'], ['topic' => 'Arrays', 'question' => 'Looping associative array'] + $this->validData());
        $this->doubts->next($session['id']);
        $this->doubts->markSolved($d1['id'], 'Use foreach ($arr as $k => $v)');

        $d2 = $this->doubts->join($session['id'], ['topic' => 'arrays', 'question' => 'Sorting keys'] + $this->validData());
        $this->doubts->next($session['id']);
        $this->doubts->markSolved($d2['id'], 'Use ksort($arr)');

        // 2 doubts on Async (1 skipped, 1 waiting -> hotspot)
        $d3 = $this->doubts->join($session['id'], ['topic' => 'Async', 'question' => 'Futures in PHP'] + $this->validData());
        $this->doubts->next($session['id']);
        $this->doubts->markSkipped($d3['id']);

        $d4 = $this->doubts->join($session['id'], ['topic' => 'Async', 'question' => 'Fibers in PHP'] + $this->validData());

        $intel = $this->doubts->intelligence($session['id']);

        $this->assertSame($session['id'], $intel['session_id']);
        $this->assertCount(2, $intel['recurring_topics']);

        // Check hotspot
        $this->assertNotEmpty($intel['hotspots']);
        $this->assertSame('Async', $intel['hotspots'][0]['topic']);
        $this->assertTrue($intel['hotspots'][0]['is_hotspot']);

        // Check top solutions
        $this->assertNotEmpty($intel['top_solutions']);
        $this->assertEqualsIgnoringCase('Arrays', $intel['top_solutions'][0]['topic']);
    }


    public function testMissingDoubtThrows(): void
    {

        $this->expectException(NotFoundException::class);

        $this->doubts->get(999);
    }

    private function validData(): array
    {
        return [
            'student_name' => 'Asha',
            'student_email' => 'asha@example.com',
            'topic' => 'Arrays',
            'question' => 'How do I loop over an array?',
        ];
    }
}
