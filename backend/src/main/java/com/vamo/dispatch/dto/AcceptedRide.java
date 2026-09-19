package com.vamo.dispatch.dto;

import java.math.BigDecimal;
import java.util.UUID;
import com.vamo.common.entity.Location;
import com.vamo.common.enums.RideStatus;
import com.vamo.common.enums.VehicleType;

public record AcceptedRide(
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
	Long duration,
	RideStatus status
) {}
