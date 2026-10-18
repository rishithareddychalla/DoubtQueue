<?php

declare(strict_types=1);

namespace DoubtQueue\Service;

use DoubtQueue\Exception\ForbiddenException;
use DoubtQueue\Exception\NotFoundException;
use DoubtQueue\Exception\SessionClosedException;
use DoubtQueue\Exception\ValidationException;
use DoubtQueue\Model\DoubtStatus;
use DoubtQueue\Model\SessionStatus;
use DoubtQueue\Repository\DoubtRepository;
use DoubtQueue\Repository\SessionRepository;

class DoubtService
{
    private DoubtSimilarityService $similarity;

    public function __construct(
        private DoubtRepository $doubts,
        private SessionRepository $sessions,
        ?DoubtSimilarityService $similarity = null
    ) {
        $this->similarity = $similarity ?? new DoubtSimilarityService();
    }

    public function join(int $sessionId, array $data, ?array $student = null): array
    {
        $session = $this->findSession($sessionId);

        if ($session['status'] !== SessionStatus::Open->value) {
            throw new SessionClosedException("Session with id $sessionId is closed");
        }

        if ($student !== null) {
            $name = $student['name'];
            $email = $student['email'];
            $studentId = (int) $student['id'];
        } else {
            $name = $this->requiredText($data, 'student_name', 255);
            $email = $this->requiredText($data, 'student_email', 255);
            $studentId = isset($data['student_id']) ? (int) $data['student_id'] : null;
        }

        if (filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
            throw new ValidationException('student_email must be a valid email address');
        }

        $doubt = $this->doubts->save(
            $sessionId,
            $name,
            $email,
            $this->requiredText($data, 'topic', 255),
            $this->requiredText($data, 'question', 2000),
            gmdate('Y-m-d H:i:s'),
            $studentId
        );

        return $this->withPosition($doubt);
    }

    public function get(int $id, ?array $user = null): array
    {
        $doubt = $this->findDoubt($id);

        if ($user !== null) {
            if ($user['role'] === 'STUDENT') {
                $isOwner = ($doubt['student_id'] !== null && $doubt['student_id'] === (int) $user['id'])
                    || mb_strtolower($doubt['student_email']) === mb_strtolower($user['email']);
                if (!$isOwner) {
                    throw new ForbiddenException('You are not authorized to view this doubt');
                }
            } elseif ($user['role'] === 'MENTOR') {
                $session = $this->findSession($doubt['session_id']);
                if ($session['mentor_id'] !== null && $session['mentor_id'] !== (int) $user['id']) {
                    throw new ForbiddenException('You are not authorized to view this doubt');
                }
            }
        }

        return $this->withPosition($doubt);
    }

    public function myDoubts(array $student): array
    {
        $list = $this->doubts->findByStudent((int) $student['id'], $student['email']);

        return array_map([$this, 'withPosition'], $list);
    }

    public function current(int $sessionId): ?array
    {
        $this->findSession($sessionId);
        $doubt = $this->doubts->findCurrentInProgress($sessionId);

        return $doubt === null ? null : $this->withPosition($doubt);
    }

    public function queue(int $sessionId, ?array $user = null): array
    {
        $this->findSession($sessionId);
        $queue = $this->doubts->findWaiting($sessionId);

        if ($user !== null && $user['role'] === 'STUDENT') {
            return array_map(function (array $doubt) use ($user): array {
                $isOwner = ($doubt['student_id'] !== null && $doubt['student_id'] === (int) $user['id'])
                    || mb_strtolower($doubt['student_email']) === mb_strtolower($user['email']);
                if (!$isOwner) {
                    $doubt['student_email'] = '';
                }
                return $doubt;
            }, $queue);
        }

        return $queue;
    }

    public function next(int $sessionId, ?array $user = null): array
    {
        $session = $this->findSession($sessionId);

        if ($user !== null) {
            if ($user['role'] !== 'MENTOR') {
                throw new ForbiddenException('Only mentors can take the next doubt');
            }
            if ($session['mentor_id'] !== null && $session['mentor_id'] !== (int) $user['id']) {
                throw new ForbiddenException('You are not authorized to manage this session');
            }
        }

        if ($session['status'] !== SessionStatus::Open->value) {
            throw new SessionClosedException("Session with id $sessionId is closed");
        }

        $active = $this->doubts->findCurrentInProgress($sessionId);
        if ($active !== null) {
            throw new ValidationException("Cannot take next doubt while doubt #{$active['id']} is currently in progress");
        }

        $doubt = $this->doubts->findOldestWaiting($sessionId);

        if ($doubt === null) {
            throw new NotFoundException("Session with id $sessionId has no waiting doubts");
        }

        $this->doubts->markStarted($doubt['id'], gmdate('Y-m-d H:i:s'));

        return $this->get($doubt['id']);
    }

    public function markSolved(int $id, ?string $notes = null, ?array $user = null): array
    {
        $doubt = $this->findDoubt($id);

        if ($user !== null) {
            if ($user['role'] === 'STUDENT') {
                $isOwner = ($doubt['student_id'] !== null && $doubt['student_id'] === (int) $user['id'])
                    || mb_strtolower($doubt['student_email']) === mb_strtolower($user['email']);
                if (!$isOwner) {
                    throw new ForbiddenException('You cannot resolve another student\'s doubt');
                }
                if ($notes !== null) {
                    throw new ForbiddenException('Students cannot set mentor resolution notes');
                }
            } elseif ($user['role'] === 'MENTOR') {
                $session = $this->findSession($doubt['session_id']);
                if ($session['mentor_id'] !== null && $session['mentor_id'] !== (int) $user['id']) {
                    throw new ForbiddenException('You are not authorized to resolve doubts for this session');
                }
            }
        }

        if ($notes !== null) {
            $notes = trim($notes);
            if ($notes === '') {
                $notes = null;
            } elseif (mb_strlen($notes) > 2000) {
                throw new ValidationException('resolution_notes must be 2000 characters or fewer');
            }
        }

        return $this->finish($id, DoubtStatus::Solved, $notes);
    }

    public function markSkipped(int $id, ?array $user = null): array
    {
        $doubt = $this->findDoubt($id);

        if ($user !== null) {
            if ($user['role'] !== 'MENTOR') {
                throw new ForbiddenException('Only mentors can skip doubts');
            }
            $session = $this->findSession($doubt['session_id']);
            if ($session['mentor_id'] !== null && $session['mentor_id'] !== (int) $user['id']) {
                throw new ForbiddenException('You are not authorized to skip doubts for this session');
            }
        }

        return $this->finish($id, DoubtStatus::Skipped);
    }


    public function searchSolved(string $query, ?int $sessionId = null): array
    {
        $trimmed = trim($query);
        if ($trimmed === '') {
            return [];
        }

        if (mb_strlen($trimmed) > 255) {
            throw new ValidationException('query must be 255 characters or fewer');
        }

        if ($sessionId !== null) {
            $this->findSession($sessionId);
        }

        $tokens = $this->similarity->tokenize($trimmed);
        $candidates = $this->doubts->findSolvedCandidates($tokens, $sessionId);

        if (empty($candidates)) {
            $candidates = $this->doubts->searchSolved($trimmed, $sessionId);
        }

        $ranked = $this->similarity->rank($trimmed, $candidates);

        if (empty($ranked) && !empty($candidates)) {
            $ranked = array_slice($candidates, 0, 10);
        }

        return array_map([$this, 'sanitizeSolvedDoubt'], array_slice($ranked, 0, 10));
    }

    public function intelligence(int $sessionId, ?array $user = null): array
    {
        $session = $this->findSession($sessionId);

        if ($user !== null) {
            if ($user['role'] !== 'MENTOR') {
                throw new ForbiddenException('Only mentors can view topic intelligence');
            }
            if ($session['mentor_id'] !== null && $session['mentor_id'] !== (int) $user['id']) {
                throw new ForbiddenException('You are not authorized to view intelligence for this session');
            }
        }

        $topicStats = $this->doubts->getTopicIntelligence($sessionId);


        $recurringTopics = [];
        $hotspots = [];

        foreach ($topicStats as $row) {
            $total = (int) $row['total_doubts'];
            $solved = (int) $row['solved_count'];
            $skipped = (int) $row['skipped_count'];
            $waiting = (int) $row['waiting_count'];
            $inProgress = (int) $row['in_progress_count'];

            $unresolvedCount = $skipped + $waiting;
            $unresolvedRate = $total > 0 ? round($unresolvedCount / $total, 2) : 0.0;
            $isHotspot = ($total >= 2 && ($skipped >= 1 || $unresolvedRate >= 0.4)) || $skipped >= 2;

            $item = [
                'topic' => $row['topic'],
                'normalized_topic' => $row['normalized_topic'],
                'total_doubts' => $total,
                'solved_count' => $solved,
                'skipped_count' => $skipped,
                'waiting_count' => $waiting,
                'in_progress_count' => $inProgress,
                'unresolved_rate' => $unresolvedRate,
                'is_hotspot' => $isHotspot,
            ];

            $recurringTopics[] = $item;
            if ($isHotspot) {
                $hotspots[] = $item;
            }
        }

        $solvedDoubts = $this->doubts->findSolvedWithNotes($sessionId, 30);
        $solutionsByTopic = [];
        foreach ($solvedDoubts as $solved) {
            $norm = mb_strtolower(trim($solved['topic']));
            if (!isset($solutionsByTopic[$norm])) {
                $solutionsByTopic[$norm] = [];
            }
            if (count($solutionsByTopic[$norm]) < 2) {
                $solutionsByTopic[$norm][] = [
                    'id' => (int) $solved['id'],
                    'topic' => $solved['topic'],
                    'question' => $solved['question'],
                    'resolution_notes' => $solved['resolution_notes'],
                ];
            }
        }

        $topSolutions = [];
        foreach ($solutionsByTopic as $topicSolutions) {
            foreach ($topicSolutions as $sol) {
                $topSolutions[] = $sol;
            }
        }

        return [
            'session_id' => $sessionId,
            'session_title' => $session['title'],
            'total_topics' => count($recurringTopics),
            'recurring_topics' => $recurringTopics,
            'hotspots' => $hotspots,
            'top_solutions' => $topSolutions,
        ];
    }

    private function sanitizeSolvedDoubt(array $doubt): array
    {
        return [
            'id' => (int) $doubt['id'],
            'session_id' => (int) $doubt['session_id'],
            'topic' => $doubt['topic'],
            'question' => $doubt['question'],
            'status' => $doubt['status'],
            'resolution_notes' => $doubt['resolution_notes'] ?? null,
            'similarity_score' => isset($doubt['similarity_score']) ? (float) $doubt['similarity_score'] : null,
            'created_at' => $doubt['created_at'],
            'finished_at' => $doubt['finished_at'] ?? null,
        ];
    }

    public function stats(int $sessionId): array
    {
        $this->findSession($sessionId);
        $counts = $this->doubts->countByStatus($sessionId);
        $stats = [];

        foreach (DoubtStatus::cases() as $status) {
            $stats[$status->value] = $counts[$status->value] ?? 0;
        }

        return $stats;
    }


    private function finish(int $id, DoubtStatus $status, ?string $notes = null): array
    {
        $doubt = $this->findDoubt($id);

        if ($doubt['status'] !== DoubtStatus::InProgress->value) {
            throw new ValidationException('Only a doubt that is in progress can be finished');
        }

        $this->doubts->markFinished($id, $status->value, gmdate('Y-m-d H:i:s'), $notes);

        return $this->get($id);
    }

    private function findSession(int $id): array
    {
        $session = $this->sessions->find($id);

        if ($session === null) {
            throw new NotFoundException("Session with id $id not found");
        }

        return $session;
    }

    private function findDoubt(int $id): array
    {
        $doubt = $this->doubts->find($id);

        if ($doubt === null) {
            throw new NotFoundException("Doubt with id $id not found");
        }

        return $doubt;
    }

    private function withPosition(array $doubt): array
    {
        $isWaiting = $doubt['status'] === DoubtStatus::Waiting->value;
        $doubt['position'] = $isWaiting ? $this->doubts->position($doubt) : null;

        return $doubt;
    }

    private function requiredText(array $data, string $field, int $maxLength): string
    {
        $value = $data[$field] ?? null;
        $value = is_string($value) ? trim($value) : '';

        if ($value === '') {
            throw new ValidationException("$field is required");
        }

        if (mb_strlen($value) > $maxLength) {
            throw new ValidationException("$field must be $maxLength characters or fewer");
        }

        return $value;
    }
}
