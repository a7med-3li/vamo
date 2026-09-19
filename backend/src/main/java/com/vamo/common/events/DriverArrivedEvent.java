package com.vamo.common.events;

import java.util.UUID;
import com.vamo.common.entity.Location;

public record DriverArrivedEvent(
	String driverPhone,
	String vehicleNumber,
	Location pickUpLocation,
	UUID rideId
) {}
