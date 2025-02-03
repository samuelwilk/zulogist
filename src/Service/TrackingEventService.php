<?php

namespace App\Domain;

use App\DTO\TrackingEventDTO;
use App\Entity\TrackingEvent;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\Mercure\HubInterface;
use Symfony\Component\Mercure\Update;

class TrackingEventService
{
    private EntityManagerInterface $entityManager;
    private HubInterface $hub;

    public function __construct(EntityManagerInterface $entityManager, HubInterface $hub)
    {
        $this->entityManager = $entityManager;
        $this->hub = $hub;
    }

    public function processEvent(TrackingEventDTO $dto): array
    {
        $event = new TrackingEvent();
        $event->setType($dto->type);
        $event->setTimestamp(new \DateTimeImmutable('@' . ($dto->timestamp / 1000)));
        $event->setSessionId($dto->sessionId);
        $event->setUserId($dto->userId);
        $event->setDetails(json_encode($dto->details));

        $this->entityManager->persist($event);
        $this->entityManager->flush();

        // Publish event to Mercure
        $update = new Update(
            'user_tracking/' . $dto->sessionId,
            json_encode($dto->details)
        );
        $this->hub->publish($update);

        return [
            'id' => $event->getId(),
            'type' => $event->getType(),
            'sessionId' => $event->getSessionId(),
            'timestamp' => $event->getTimestamp()->format('Y-m-d H:i:s'),
        ];
    }
}
