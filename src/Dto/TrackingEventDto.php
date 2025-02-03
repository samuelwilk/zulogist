<?php

declare(strict_types=1);

namespace App\Dto;

use Symfony\Component\Validator\Constraints as Assert;

class TrackingEventDto
{
    #[Assert\NotBlank]
    #[Assert\Choice(choices: ['click', 'input', 'pageview'], message: 'Invalid event type')]
    public string $type;

    #[Assert\NotBlank]
    #[Assert\Type("integer")]
    #[Assert\GreaterThan(0)]
    public int $timestamp;

    #[Assert\NotBlank]
    #[Assert\Type("string")]
    public string $sessionId;

    #[Assert\Type("integer")]
    #[Assert\PositiveOrZero]
    public ?int $userId = null;

    #[Assert\Type("array")]
    public array $details;

    public function __construct(array $data)
    {
        $this->type = $data['type'] ?? '';
        $this->timestamp = $data['timestamp'] ?? 0;
        $this->sessionId = $data['sessionId'] ?? '';
        $this->userId = $data['userId'] ?? null;
        $this->details = $data;
    }
}
