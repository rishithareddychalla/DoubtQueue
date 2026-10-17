<?php

declare(strict_types=1);

namespace DoubtQueue\Tests\Service;

use DoubtQueue\Service\DoubtSimilarityService;
use PHPUnit\Framework\TestCase;

class DoubtSimilarityServiceTest extends TestCase
{
    private DoubtSimilarityService $similarity;

    protected function setUp(): void
    {
        $this->similarity = new DoubtSimilarityService();
    }

    public function testTokenizeFiltersPunctuationAndStopWords(): void
    {
        $tokens = $this->similarity->tokenize('How do I loop through an array?');
        $this->assertEqualsCanonicalizing(['loop', 'array'], $tokens);
    }

    public function testTokenizeRetainsWordsIfAllAreStopWords(): void
    {
        $tokens = $this->similarity->tokenize('what is it');
        $this->assertContains('what', $tokens);
        $this->assertContains('is', $tokens);
        $this->assertContains('it', $tokens);
    }

    public function testWordOrderIndependence(): void
    {
        $doubt = [
            'topic' => 'Arrays',
            'question' => 'How do I loop over an associative array?',
            'resolution_notes' => 'Use a foreach loop.',
        ];

        $scoreOrdered = $this->similarity->calculateScore(
            $this->similarity->tokenize('loop associative array'),
            $doubt
        );

        $scoreReversed = $this->similarity->calculateScore(
            $this->similarity->tokenize('array associative loop'),
            $doubt
        );

        $this->assertGreaterThan(0.5, $scoreOrdered);
        $this->assertSame($scoreOrdered, $scoreReversed);
    }

    public function testTypoToleranceWithLevenshtein(): void
    {
        $doubt = [
            'topic' => 'Async',
            'question' => 'What does await do in Flutter?',
            'resolution_notes' => 'Pauses execution until the future completes.',
        ];

        // "asynk" instead of "async"
        $score = $this->similarity->calculateScore(
            $this->similarity->tokenize('asynk await'),
            $doubt
        );

        $this->assertGreaterThan(0.35, $score);
    }

    public function testRankOrdersByRelevanceDescending(): void
    {
        $doubt1 = [
            'id' => 1,
            'topic' => 'Widgets',
            'question' => 'When do I use StatelessWidget?',
            'resolution_notes' => 'When state is immutable.',
        ];
        $doubt2 = [
            'id' => 2,
            'topic' => 'Widgets',
            'question' => 'When do I use StatefulWidget?',
            'resolution_notes' => 'When state needs to update dynamically.',
        ];

        $ranked = $this->similarity->rank('StatefulWidget dynamic updates', [$doubt1, $doubt2]);

        $this->assertNotEmpty($ranked);
        $this->assertSame(2, $ranked[0]['id']);
        $this->assertGreaterThan($ranked[1]['similarity_score'] ?? 0, $ranked[0]['similarity_score']);
    }
}
