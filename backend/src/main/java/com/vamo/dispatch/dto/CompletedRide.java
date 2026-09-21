package com.vamo.dispatch.dto;

import java.math.BigDecimal;
import java.util.UUID;
import com.vamo.common.entity.Location;
import com.vamo.common.enums.VehicleType;

public record CompletedRide(
	UUID rideId,
	UUID passengerId,
	String driverName,
	String driverPhone,
	String vehicleNumber,
	VehicleType vehicleType,
	Location pickUpLocation,
	Location dropOffLocation,
	BigDecimal fare,
	double distanceInKm,
	Long duration
) {}
