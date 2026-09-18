package com.vamo.ride.dto;

import java.math.BigDecimal;
import java.util.UUID;
import com.vamo.common.entity.Location;
import com.vamo.common.enums.VehicleType;

public record PublishedRideDTO(
		UUID rideId,
		Location pickUp,
		Location dropOff,
		BigDecimal estimatedFare,
		double distanceInKm,
		VehicleType vehicleType,
		double duration
) {}
