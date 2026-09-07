package com.vamo.ride.dto;

import com.vamo.common.enums.RideStatus;

import java.time.Instant;
import java.util.UUID;

public record RideHistoryItem(
        UUID id,
        RideStatus status,
        Instant departureTime,
        Instant requestedAt,
        Instant completedAt
) {}
