package com.vamo.ride.dto;

import java.math.BigDecimal;
import com.vamo.common.entity.Location;
import com.vamo.common.enums.VehicleType;

public record RideRequestDto(
		Location pickUp,
		Location dropOff,
		Long duration,
		Long distance,
		VehicleType vehicleType,
		BigDecimal price
) {}
