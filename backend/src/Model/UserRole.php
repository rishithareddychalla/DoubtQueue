<?php

declare(strict_types=1);

namespace DoubtQueue\Model;

enum UserRole: string
{
    case Student = 'STUDENT';
    case Mentor = 'MENTOR';
}
