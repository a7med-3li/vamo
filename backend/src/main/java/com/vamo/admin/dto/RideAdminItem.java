package com.vamo.admin.dto;

import com.vamo.common.enums.RideStatus;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record RideAdminItem(
        UUID id,
        UUID passengerId,
        UUID driverId,
        RideStatus status,
        String pin,
        Instant departureTime,
        Instant requestedAt,
        Instant startedAt,
        Instant completedAt,
        BigDecimal estimatedFare,
        BigDecimal finalFare
) {}
