package com.vamo.ride.service;

import com.vamo.common.enums.RideStatus;
import com.vamo.common.events.RideRequestedEvent;
import com.vamo.common.events.RideTakenEvent;
import com.vamo.common.exception.BadRequestException;
import com.vamo.common.exception.NotFoundException;
import com.vamo.common.exception.RideAlreadyTakenException;
import com.vamo.dispatch.service.DriverConnectionManager;
import com.vamo.ride.dto.PublishedRideDTO;
import com.vamo.ride.dto.RideHistoryItem;
import com.vamo.ride.dto.RideRequestDto;
import com.vamo.ride.entity.Ride;
import com.vamo.ride.repository.RideRepository;
import com.vamo.user.service.UserService;
import com.vamo.driver.service.DriverWalletService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class RideService {

    private final RideRepository rideRepository;
    private final UserService userService;
    private final DriverWalletService driverWalletService;
    private final ApplicationEventPublisher eventPublisher;
    private final DriverConnectionManager driverConnectionManager;
    
    @Transactional
    public PublishedRideDTO publishRideRequest(UUID passengerId, RideRequestDto request) {
        Ride ride = Ride.builder()
                .passengerId(passengerId)
                .pickUp(request.pickUp())
                .dropOff(request.dropOff())
                .status(RideStatus.REQUESTED)
                .estimatedFare(request.price())
                .distanceInKm(request.distance())
                .vehicleType(request.vehicleType())
                .duration(request.duration())
                .requestedAt(Instant.now())
                .build();
        
        Ride publishedRide = rideRepository.save(ride);
        
        eventPublisher.publishEvent(new RideRequestedEvent(ride));
	    return new PublishedRideDTO(
                publishedRide.getId(),
                publishedRide.getPickUp(),
                publishedRide.getDropOff(),
                publishedRide.getEstimatedFare(),
                publishedRide.getDistanceInKm(),
                publishedRide.getVehicleType(),
                publishedRide.getDuration()
        );
    }
    
    @Transactional
    public void acceptRide(UUID rideId, UUID driverId) {
        int updated = rideRepository.acceptRide(rideId, driverId, Instant.now());
        if (updated == 0) {
            throw new RideAlreadyTakenException("Ride no longer available");
        }
        publishRideTakenEvent(rideId);
    }
    
    public void publishRideTakenEvent(UUID rideId){
        eventPublisher.publishEvent(new RideTakenEvent(rideId));
    }
    
    @Transactional
    public void confirmBoarding(UUID driverId, UUID rideId, String pin) {
        Ride ride = rideRepository.findById(rideId)
                .orElseThrow(() -> new NotFoundException("Ride not found"));

        if (ride.getStatus() != RideStatus.BOOKED) {
            throw new BadRequestException("Ride is not in booked status");
        }
        if (!pin.equals(ride.getPin())) {
            throw new BadRequestException("Invalid PIN");
        }

        ride.setDriverId(driverId);
        ride.setStatus(RideStatus.IN_PROGRESS);
        ride.setStartedAt(Instant.now());
        rideRepository.save(ride);

        driverWalletService.addPayout(driverId, rideId);
    }

    @Transactional
    public void completeRide(UUID rideId, UUID driverId) {
        Ride ride = rideRepository.findById(rideId)
                .orElseThrow(() -> new NotFoundException("Ride not found"));

        if (!driverId.equals(ride.getDriverId())) {
            throw new BadRequestException("This ride is not assigned to you");
        }
        if (ride.getStatus() != RideStatus.IN_PROGRESS) {
            throw new BadRequestException("Ride is not in progress");
        }

        ride.setStatus(RideStatus.COMPLETED);
        ride.setCompletedAt(Instant.now());
        rideRepository.save(ride);
    }

    //note: needs to be atomic, like the acceptRide method.
    public void cancelRide(UUID rideId, UUID userId) {
        Ride ride = rideRepository.findByIdAndPassengerId(rideId, userId)
                .orElseThrow(() -> new NotFoundException("Ride not found"));

        if (ride.getStatus() == RideStatus.MATCHED) {
            driverConnectionManager.pushCancelledRideToDriver(ride.getDriverId(), ride.getId());
        }
        if(ride.getStatus() == RideStatus.REQUESTED || ride.getStatus() == RideStatus.MATCHED) {
            eventPublisher.publishEvent(new RideTakenEvent(rideId));
        } else {
            throw new BadRequestException("Ride cannot be cancelled at this stage");
        }
        ride.setStatus(RideStatus.CANCELLED);
        rideRepository.save(ride);
    }
    
    public List<RideHistoryItem> getPassengerHistory(UUID passengerId) {
        return rideRepository.findByPassengerIdOrderByRequestedAtDesc(passengerId)
                .stream()
                .map(r -> new RideHistoryItem(
                        r.getId(), r.getStatus(),
                        r.getDepartureTime(), r.getRequestedAt(), r.getCompletedAt()
                ))
                .toList();
    }
    
    //note: why does this exist? we should be able to get the
    // driver history from the passenger history,
    // since the passenger history contains all rides,
    // including those with drivers.
    // maybe this is for a driver dashboard?
    public List<RideHistoryItem> getDriverHistory(UUID driverId) {
        return rideRepository.findByDriverIdOrderByDepartureTimeAsc(driverId)
                .stream()
                .map(r -> new RideHistoryItem(
                        r.getId(), r.getStatus(),
                        r.getDepartureTime(), r.getRequestedAt(), r.getCompletedAt()
                ))
                .toList();
    }
    
    @Transactional
    public void markNoShows() {
        Instant threshold = Instant.now().minusSeconds(3600);
        List<Ride> expired = rideRepository.findByStatusAndDepartureTimeBefore(
                RideStatus.BOOKED, threshold);
        for (Ride ride : expired) {
            ride.setStatus(RideStatus.NO_SHOW);
            rideRepository.save(ride);
        }
    }
}
