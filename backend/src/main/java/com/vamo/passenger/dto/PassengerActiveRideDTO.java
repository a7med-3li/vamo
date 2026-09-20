package com.vamo.passenger.dto;

import java.math.BigDecimal;
import java.util.UUID;
import com.vamo.common.entity.Location;

public record PassengerActiveRideDTO(
		UUID rideId,
		String driverName,
		String driverPhone,
		String vehicleNumber,
		Location pickUp,
		Location dropOff,
		BigDecimal fare,
		double distanceInKm,
		long duration
) {}
