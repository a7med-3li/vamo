package com.vamo.dispatch.dto;

import java.util.UUID;
import com.vamo.common.entity.Location;

public record DriverArrived(
		String driverPhone,
		String vehicleNumber,
		Location pickUpLocation
) {}
