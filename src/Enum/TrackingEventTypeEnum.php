<?php

declare(strict_types=1);

namespace App\Enum;

enum TrackingEventTypeEnum: int
{
    case click = 1;
    case input = 2;
    case page_view = 3;
}
