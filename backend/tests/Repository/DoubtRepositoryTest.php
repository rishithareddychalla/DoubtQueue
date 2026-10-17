<?php

declare(strict_types=1);

namespace DoubtQueue\Tests\Repository;

use DoubtQueue\Database;
use DoubtQueue\DatabaseSetup;
use DoubtQueue\Repository\DoubtRepository;
use DoubtQueue\Repository\SessionRepository;
use PHPUnit\Framework\TestCase;

class DoubtRepositoryTest extends TestCase
{
    private DoubtRepository $doubts;
    private int $sessionId;

    protected function setUp(): void
    {
        $pdo = Database::memory();
        (new DatabaseSetup($pdo))->createTables();

        $session = (new SessionRepository($pdo))->create('Test', 'Mentor', 'OPEN', '2026-01-01 10:00:00');
        $this->sessionId = $session['id'];
        $this->doubts = new DoubtRepository($pdo);
    }

    public function testSaveStoresWaitingDoubt(): void
    {
        $doubt = $this->save('Asha', '2026-01-01 10:01:00');

        $this->assertSame('WAITING', $doubt['status']);
        $this->assertSame('Asha', $doubt['student_name']);
        $this->assertNull($doubt['started_at']);
        $this->assertSame($doubt, $this->doubts->find($doubt['id']));
    }

    public function testFindWaitingSkipsOtherStatuses(): void
    {
        $first = $this->save('Asha', '2026-01-01 10:01:00');
        $second = $this->save('Ben', '2026-01-01 10:02:00');
        $this->doubts->markStarted($first['id'], '2026-01-01 10:03:00');

        $waiting = $this->doubts->findWaiting($this->sessionId);

        $this->assertCount(1, $waiting);
        $this->assertSame($second['id'], $waiting[0]['id']);
    }

    public function testFindWaitingReturnsOldestFirst(): void
    {
        $late = $this->save('Late', '2026-01-01 10:05:00');
        $early = $this->save('Early', '2026-01-01 10:01:00');
        $middle = $this->save('Middle', '2026-01-01 10:03:00');

        $ids = array_column($this->doubts->findWaiting($this->sessionId), 'id');

        $this->assertSame([$early['id'], $middle['id'], $late['id']], $ids);
        $this->assertSame($early['id'], $this->doubts->findOldestWaiting($this->sessionId)['id']);
    }

    public function testPositionCountsWaitingDoubtsCreatedBefore(): void
    {
        $first = $this->save('Asha', '2026-01-01 10:01:00');
        $second = $this->save('Ben', '2026-01-01 10:02:00');
        $third = $this->save('Chitra', '2026-01-01 10:03:00');

        $this->assertSame(1, $this->doubts->position($first));
        $this->assertSame(2, $this->doubts->position($second));
        $this->assertSame(3, $this->doubts->position($third));

        $this->doubts->markStarted($first['id'], '2026-01-01 10:04:00');

        $this->assertSame(1, $this->doubts->position($second));
    }

    public function testPositionUsesIdWhenCreatedAtIsEqual(): void
    {
        $first = $this->save('Asha', '2026-01-01 10:01:00');
        $second = $this->save('Ben', '2026-01-01 10:01:00');

        $this->assertSame(1, $this->doubts->position($first));
        $this->assertSame(2, $this->doubts->position($second));
    }

    public function testCurrentInProgressReturnsOnlyActiveDoubt(): void
    {
        $first = $this->save('Asha', '2026-01-01 10:01:00');
        $this->assertNull($this->doubts->findCurrentInProgress($this->sessionId));

        $this->doubts->markStarted($first['id'], '2026-01-01 10:02:00');
        $current = $this->doubts->findCurrentInProgress($this->sessionId);

        $this->assertNotNull($current);
        $this->assertSame($first['id'], $current['id']);
        $this->assertSame('OPEN', $current['session_status']);

        $this->doubts->markFinished($first['id'], 'SOLVED', '2026-01-01 10:05:00', 'Solution note');
        $this->assertNull($this->doubts->findCurrentInProgress($this->sessionId));
    }

    public function testSearchSolvedMatchesTopicQuestionOrNotes(): void
    {
        $doubt1 = $this->save('Asha', '2026-01-01 10:01:00');
        $this->doubts->markStarted($doubt1['id'], '2026-01-01 10:02:00');
        $this->doubts->markFinished($doubt1['id'], 'SOLVED', '2026-01-01 10:05:00', 'Use foreach loops for associative arrays');

        $doubt2 = $this->save('Ben', '2026-01-01 10:02:00');
        $this->doubts->markStarted($doubt2['id'], '2026-01-01 10:03:00');
        $this->doubts->markFinished($doubt2['id'], 'SKIPPED', '2026-01-01 10:06:00', null);

        $results = $this->doubts->searchSolved('foreach');
        $this->assertCount(1, $results);
        $this->assertSame($doubt1['id'], $results[0]['id']);
        $this->assertSame('Use foreach loops for associative arrays', $results[0]['resolution_notes']);

        $noResults = $this->doubts->searchSolved('nonexistent query');
        $this->assertEmpty($noResults);
    }

    public function testTopicIntelligenceGroupsCaseInsensitively(): void
    {
        $d1 = $this->doubts->save($this->sessionId, 'Asha', 'a@test.com', 'Arrays', 'Q1', '2026-01-01 10:00:00');
        $d2 = $this->doubts->save($this->sessionId, 'Ben', 'b@test.com', 'arrays ', 'Q2', '2026-01-01 10:01:00');
        $d3 = $this->doubts->save($this->sessionId, 'Carl', 'c@test.com', 'Widgets', 'Q3', '2026-01-01 10:02:00');

        $this->doubts->markStarted($d1['id'], '2026-01-01 10:05:00');
        $this->doubts->markFinished($d1['id'], 'SOLVED', '2026-01-01 10:10:00', 'Solved array');

        $this->doubts->markStarted($d2['id'], '2026-01-01 10:11:00');
        $this->doubts->markFinished($d2['id'], 'SKIPPED', '2026-01-01 10:12:00', null);

        $intel = $this->doubts->getTopicIntelligence($this->sessionId);
        $this->assertNotEmpty($intel);

        $arrayIntel = null;
        foreach ($intel as $item) {
            if ($item['normalized_topic'] === 'arrays') {
                $arrayIntel = $item;
                break;
            }
        }

        $this->assertNotNull($arrayIntel);
        $this->assertSame(2, $arrayIntel['total_doubts']);
        $this->assertSame(1, $arrayIntel['solved_count']);
        $this->assertSame(1, $arrayIntel['skipped_count']);
    }

    public function testFindSolvedCandidatesMatchesTokens(): void
    {
        $d1 = $this->doubts->save($this->sessionId, 'Asha', 'a@test.com', 'Flutter Layout', 'How to use Row and Expanded?', '2026-01-01 10:00:00');
        $this->doubts->markStarted($d1['id'], '2026-01-01 10:05:00');
        $this->doubts->markFinished($d1['id'], 'SOLVED', '2026-01-01 10:10:00', 'Expanded fills remaining space in Row');

        $candidates = $this->doubts->findSolvedCandidates(['expanded', 'layout'], $this->sessionId);
        $this->assertCount(1, $candidates);
        $this->assertSame($d1['id'], $candidates[0]['id']);

        $candidatesEmpty = $this->doubts->findSolvedCandidates(['completelyunrelated'], $this->sessionId);
        $this->assertEmpty($candidatesEmpty);
    }

    private function save(string $name, string $createdAt): array
    {
        return $this->doubts->save(
            $this->sessionId,
            $name,
            strtolower($name) . '@example.com',
            'Topic',
            'Question',
            $createdAt
        );
    }
}

