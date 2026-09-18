package com.vamo.ride.repository;

import com.vamo.common.enums.RideStatus;
import com.vamo.ride.entity.Ride;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RideRepository extends JpaRepository<Ride, UUID> {
    
    @Modifying
    @Query("UPDATE Ride r SET r.status = 'MATCHED', r.driverId = :driverId , " +
            "r.acceptedAt = :acceptedAt " +
            "WHERE r.id = :rideId AND r.status = 'REQUESTED'")
    int acceptRide(@Param("rideId") UUID rideId, @Param("driverId") UUID driverId, @Param("acceptedAt") Instant acceptedAt);
    
    Optional<Ride> findByIdAndPassengerId(UUID rideId, UUID passengerId);
    
    List<Ride> findByPassengerIdOrderByRequestedAtDesc(UUID passengerId);

    List<Ride> findByDriverIdOrderByDepartureTimeAsc(UUID driverId);

    List<Ride> findByStatusAndDepartureTimeBefore(RideStatus status, Instant now);

    long countByPassengerIdAndStatus(UUID passengerId, RideStatus status);

    List<Ride> findAllByOrderByRequestedAtDesc();

    List<Ride> findByStatusOrderByRequestedAtDesc(RideStatus status);

    List<Ride> findByRequestedAtBetween(Instant from, Instant to);

    long countByStatus(RideStatus status);

    long countByRequestedAtBetween(Instant from, Instant to);
}
