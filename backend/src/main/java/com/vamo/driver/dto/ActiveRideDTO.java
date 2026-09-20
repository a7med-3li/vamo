package com.vamo.driver.dto;

import java.math.BigDecimal;
import java.util.UUID;
import com.vamo.common.entity.Location;

public record ActiveRideDTO(
		UUID rideId,
		String passengerName,
		String passengerPhone,
		Location pickUp,
		Location dropOff,
		BigDecimal fare,
		double distanceInKm,
		long duration
) {}
