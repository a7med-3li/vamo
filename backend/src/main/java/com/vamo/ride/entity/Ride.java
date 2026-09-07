package com.vamo.ride.entity;

import com.vamo.common.entity.Location;
import com.vamo.common.enums.RideStatus;
import com.vamo.common.enums.VehicleType;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "ride")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Ride {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(updatable = false, nullable = false)
    private UUID id;

    @Column(nullable = false)
    private UUID passengerId;

    private UUID driverId;

    @Embedded
    @AttributeOverrides({
            @AttributeOverride(name = "latitude", column = @Column(name = "pickup_lat")),
            @AttributeOverride(name = "longitude", column = @Column(name = "pickup_lng")),
            @AttributeOverride(name = "addressName", column = @Column(name = "pickup_address"))
    })
    private Location pickUp;

    @Embedded
    @AttributeOverrides({
            @AttributeOverride(name = "latitude", column = @Column(name = "dropoff_lat")),
            @AttributeOverride(name = "longitude", column = @Column(name = "dropoff_lng")),
            @AttributeOverride(name = "addressName", column = @Column(name = "dropoff_address"))
    })
    private Location dropOff;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private RideStatus status;

    private BigDecimal estimatedFare;
    
    private double distanceInKm = 0.0;

    private BigDecimal finalFare;
    
    private VehicleType vehicleType;

    private Long duration = 0L;
    
    private Instant departureTime;

    private Instant requestedAt;

    private Instant acceptedAt;

    private Instant startedAt;

    private Instant completedAt;
    
    //corridor-based rides
    @Column(length = 4)
    private String pin;
}
