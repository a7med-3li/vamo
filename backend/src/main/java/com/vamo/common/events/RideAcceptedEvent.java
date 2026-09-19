package com.vamo.common.events;

import java.math.BigDecimal;
import java.util.UUID;
import com.vamo.common.entity.Location;
import com.vamo.common.enums.RideStatus;
import com.vamo.common.enums.VehicleType;

public record RideAcceptedEvent(
	UUID rideId,
	String driverName,
	String driverPhone,
	String vehicleNumber,
	UUID passengerId,
	VehicleType vehicleType,
	Location pickUpLocation,
	Location dropOffLocation,
	BigDecimal estimatedFare,
	double distanceInKm,
	long duration,
	RideStatus status
) {}
