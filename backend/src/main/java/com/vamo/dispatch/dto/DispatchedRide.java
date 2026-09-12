package com.vamo.dispatch.dto;

import java.math.BigDecimal;
import com.vamo.common.entity.Location;
import com.vamo.common.enums.RideStatus;

public record DispatchedRide (
		String rideId,
		String passengerId,
		Location pickUp,
		Location dropOff,
		BigDecimal estimatedFare,
		double distanceInKm,
		Long duration,
		RideStatus status
) {}
