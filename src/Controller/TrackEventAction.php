<?php

declare(strict_types=1);

namespace App\Controller;

use App\Dto\TrackingEventDto;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Attribute\AsController;
// use Symfony\Component\HttpKernel\Attribute\Cache;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Validator\Validator\ValidatorInterface;

/**
 * @see TrackEventActionTest
 */
#[AsController]
// #[Cache(maxage: 3600, public: true)]
final class TrackEventAction extends AbstractController
{
    public function __construct(private readonly ValidatorInterface $validator, )
    {
    }

    /**
     * Simple page with some content.
     */
    #[Route(path: '/track-event', name: self::class)]
    public function __invoke(Request $request): Response
    {
        $data = json_decode($request->getContent(), true);
        $dto = new TrackingEventDto($data);

        // Validate DTO
        $violations = $this->validator->validate($dto);
        if (count($violations) > 0) {
            $errors = [];
            foreach ($violations as $violation) {
                $errors[$violation->getPropertyPath()] = $violation->getMessage();
            }
            return $this->responder->error('Invalid data', 400, $errors);
        }

        $result = $this->trackingEventService->processEvent($dto);

        return new JsonResponse(['success' => true, 'data' => $result], 200);
    }
}
