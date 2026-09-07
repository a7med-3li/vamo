package com.vamo.ride.repository;

import com.vamo.common.enums.RideStatus;
import com.vamo.ride.entity.Ride;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface RideRepository extends JpaRepository<Ride, UUID> {

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
