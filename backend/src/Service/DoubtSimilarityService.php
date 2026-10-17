<?php

declare(strict_types=1);

namespace DoubtQueue\Service;

class DoubtSimilarityService
{
    private const STOP_WORDS = [
        'a', 'about', 'above', 'after', 'again', 'against', 'all', 'am', 'an', 'and', 'any',
        'are', 'as', 'at', 'be', 'because', 'been', 'before', 'being', 'below', 'between',
        'both', 'but', 'by', 'can', 'could', 'did', 'do', 'does', 'doing', 'down', 'during',
        'each', 'few', 'for', 'from', 'further', 'had', 'has', 'have', 'having', 'he', 'her',
        'here', 'hers', 'herself', 'him', 'himself', 'his', 'how', 'i', 'if', 'in', 'into',
        'is', 'it', 'its', 'itself', 'me', 'more', 'most', 'my', 'myself', 'no', 'nor', 'not',
        'of', 'off', 'on', 'once', 'only', 'or', 'other', 'ought', 'our', 'ours', 'ourselves',
        'out', 'over', 'own', 'same', 'she', 'should', 'so', 'some', 'such', 'than', 'that',
        'the', 'their', 'theirs', 'them', 'themselves', 'then', 'there', 'these', 'they',
        'this', 'those', 'through', 'to', 'too', 'under', 'until', 'up', 'very', 'was', 'we',
        'were', 'what', 'when', 'where', 'which', 'while', 'who', 'whom', 'why', 'with', 'would',
        'you', 'your', 'yours', 'yourself', 'yourselves',
    ];

    /**
     * Tokenize text into normalized content terms.
     *
     * @return string[]
     */
    public function tokenize(string $text): array
    {
        $normalized = mb_strtolower(trim($text));
        $clean = preg_replace('/[^\p{L}\p{N}]+/u', ' ', $normalized) ?? '';
        $tokens = preg_split('/\s+/', trim($clean), -1, PREG_SPLIT_NO_EMPTY) ?: [];

        $stopMap = array_flip(self::STOP_WORDS);
        $result = [];

        foreach ($tokens as $token) {
            if (mb_strlen($token) <= 1) {
                continue;
            }
            if (!isset($stopMap[$token])) {
                $result[] = $token;
            }
        }

        if (empty($result) && !empty($tokens)) {
            foreach ($tokens as $token) {
                if (mb_strlen($token) > 1) {
                    $result[] = $token;
                }
            }
        }

        return array_values(array_unique($result));
    }

    /**
     * Compute a similarity score between 0.0 and 1.0 for a query against a doubt.
     *
     * @param string[] $queryTokens
     * @param array $doubt Must contain 'topic', 'question', and optional 'resolution_notes'
     */
    public function calculateScore(array $queryTokens, array $doubt): float
    {
        if (empty($queryTokens)) {
            return 0.0;
        }

        $topicTokens = $this->tokenize($doubt['topic'] ?? '');
        $questionTokens = $this->tokenize($doubt['question'] ?? '');
        $notesTokens = $this->tokenize($doubt['resolution_notes'] ?? '');

        if (empty($topicTokens) && empty($questionTokens) && empty($notesTokens)) {
            return 0.0;
        }

        $topicMatch = $this->matchTokens($queryTokens, $topicTokens);
        $questionMatch = $this->matchTokens($queryTokens, $questionTokens);
        $notesMatch = $this->matchTokens($queryTokens, $notesTokens);

        $score = ($topicMatch * 0.35) + ($questionMatch * 0.45) + ($notesMatch * 0.20);

        $queryClean = mb_strtolower(trim(implode(' ', $queryTokens)));
        $topicClean = mb_strtolower(trim($doubt['topic'] ?? ''));
        if ($topicClean !== '' && (str_contains($queryClean, $topicClean) || str_contains($topicClean, $queryClean))) {
            $score = max($score, 0.40) + 0.15;
        }

        return round(min(1.0, max(0.0, $score)), 3);
    }

    /**
     * Rank an array of candidate doubts by similarity score descending.
     *
     * @param string $query
     * @param array[] $candidates
     * @param float $minScore
     * @return array[] Each candidate decorated with 'similarity_score'
     */
    public function rank(string $query, array $candidates, float $minScore = 0.15): array
    {
        $tokens = $this->tokenize($query);
        if (empty($tokens)) {
            return [];
        }

        $scored = [];
        foreach ($candidates as $candidate) {
            $score = $this->calculateScore($tokens, $candidate);
            if ($score >= $minScore) {
                $candidate['similarity_score'] = $score;
                $scored[] = $candidate;
            }
        }

        usort($scored, function (array $a, array $b): int {
            if ($a['similarity_score'] !== $b['similarity_score']) {
                return $a['similarity_score'] > $b['similarity_score'] ? -1 : 1;
            }

            $dateA = $a['finished_at'] ?? $a['created_at'] ?? '';
            $dateB = $b['finished_at'] ?? $b['created_at'] ?? '';
            if ($dateA !== $dateB) {
                return $dateB <=> $dateA;
            }

            return ($b['id'] ?? 0) <=> ($a['id'] ?? 0);
        });

        return $scored;
    }

    /**
     * Calculate how well a set of query tokens matches target tokens.
     *
     * @param string[] $queryTokens
     * @param string[] $targetTokens
     */
    private function matchTokens(array $queryTokens, array $targetTokens): float
    {
        if (empty($queryTokens) || empty($targetTokens)) {
            return 0.0;
        }

        $matches = 0.0;
        foreach ($queryTokens as $q) {
            $bestTokenMatch = 0.0;
            foreach ($targetTokens as $t) {
                if ($q === $t) {
                    $bestTokenMatch = 1.0;
                    break;
                }

                if (str_starts_with($t, $q) || str_starts_with($q, $t)) {
                    $bestTokenMatch = max($bestTokenMatch, 0.85);
                    continue;
                }

                $lenQ = mb_strlen($q);
                $lenT = mb_strlen($t);
                if (abs($lenQ - $lenT) <= 2) {
                    $dist = levenshtein($q, $t);
                    if ($dist === 1 && min($lenQ, $lenT) >= 4) {
                        $bestTokenMatch = max($bestTokenMatch, 0.75);
                    } elseif ($dist === 2 && min($lenQ, $lenT) >= 6) {
                        $bestTokenMatch = max($bestTokenMatch, 0.50);
                    }
                }
            }
            $matches += $bestTokenMatch;
        }

        return $matches / count($queryTokens);
    }
}
