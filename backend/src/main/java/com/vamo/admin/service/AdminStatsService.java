package com.vamo.admin.service;

import com.vamo.admin.dto.*;
import com.vamo.common.enums.ApprovalStatus;
import com.vamo.common.enums.RideStatus;
import com.vamo.common.enums.SubscriptionPlan;
import com.vamo.common.enums.SubscriptionStatus;
import com.vamo.common.enums.UserRole;
import com.vamo.common.exception.NotFoundException;
import com.vamo.driver.entity.DriverDeposit;
import com.vamo.driver.entity.DriverProfile;
import com.vamo.driver.repository.DriverDepositRepository;
import com.vamo.driver.repository.DriverProfileRepository;
import com.vamo.driver.repository.DriverTransactionRepository;
import com.vamo.driver.service.DriverWalletService;
import com.vamo.passenger.repository.PassengerProfileRepository;
import com.vamo.ride.entity.Ride;
import com.vamo.ride.repository.RideRepository;
import com.vamo.subscription.entity.Subscription;
import com.vamo.subscription.repository.SubscriptionRepo;
import com.vamo.user.entity.User;
import com.vamo.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminStatsService {

    private final UserRepository userRepository;
    private final DriverProfileRepository driverProfileRepository;
    private final DriverDepositRepository depositRepository;
    private final DriverTransactionRepository transactionRepository;
    private final RideRepository rideRepository;
    private final SubscriptionRepo subscriptionRepo;
    private final PassengerProfileRepository passengerProfileRepository;
    private final DriverWalletService walletService;

    @Transactional(readOnly = true)
    public AdminStatsResponse getStats() {
        long totalUsers = userRepository.count();
        long drivers = userRepository.countByRole(UserRole.DRIVER)
                + userRepository.countByRole(UserRole.BOTH);
        long approved = driverProfileRepository.countByApprovalStatus(ApprovalStatus.APPROVED);
        long pending = driverProfileRepository.countByApprovalStatus(ApprovalStatus.PENDING);

        LocalDate today = LocalDate.now(ZoneId.of("Africa/Cairo"));
        Instant dayStart = today.atStartOfDay(ZoneId.of("Africa/Cairo")).toInstant();
        Instant dayEnd = today.atTime(LocalTime.MAX).atZone(ZoneId.of("Africa/Cairo")).toInstant();

        long ridesToday = rideRepository.countByRequestedAtBetween(dayStart, dayEnd);
        long activeSubs = subscriptionRepo.countByStatus(SubscriptionStatus.ACTIVE);
        long totalSubs = subscriptionRepo.count();
        //BigDecimal revenue = subscriptionRepo.totalRevenue();

        long booked = rideRepository.countByStatus(RideStatus.BOOKED);
        long inProgress = rideRepository.countByStatus(RideStatus.IN_PROGRESS);
        long completed = rideRepository.countByStatus(RideStatus.COMPLETED);
        long cancelled = rideRepository.countByStatus(RideStatus.CANCELLED);
        long noShow = rideRepository.countByStatus(RideStatus.NO_SHOW);

        return new AdminStatsResponse(
                totalUsers, drivers, approved, pending, ridesToday,
                activeSubs, totalSubs,
                booked, inProgress, completed, cancelled, noShow
        );
    }

    @Transactional(readOnly = true)
    public List<RideAdminItem> getRides(RideStatus status, UUID driverId, UUID passengerId) {
        List<Ride> rides;

        if (driverId != null) {
            rides = rideRepository.findByDriverIdOrderByDepartureTimeAsc(driverId);
        } else if (status != null) {
            rides = rideRepository.findByStatusOrderByRequestedAtDesc(status);
        } else {
            rides = rideRepository.findAllByOrderByRequestedAtDesc();
        }

        if (passengerId != null) {
            rides = rides.stream()
                    .filter(r -> r.getPassengerId().equals(passengerId))
                    .toList();
        }

        return rides.stream()
                .map(r -> new RideAdminItem(
                        r.getId(), r.getPassengerId(), r.getDriverId(), r.getStatus(), r.getPin(),
                        r.getDepartureTime(), r.getRequestedAt(), r.getStartedAt(),
                        r.getCompletedAt(),
                        r.getEstimatedFare(), r.getFinalFare()))
                .toList();
    }

    @Transactional(readOnly = true)
    public RideAdminItem getRideDetail(UUID rideId) {
        Ride r = rideRepository.findById(rideId)
                .orElseThrow(() -> new NotFoundException("Ride not found"));
        return new RideAdminItem(
                r.getId(), r.getPassengerId(), r.getDriverId(), r.getStatus(), r.getPin(),
                r.getDepartureTime(), r.getRequestedAt(), r.getStartedAt(),
                r.getCompletedAt(),
                r.getEstimatedFare(), r.getFinalFare());
    }

    @Transactional(readOnly = true)
    public List<DriverAdminItem> getDrivers(ApprovalStatus approvalStatus) {
        List<DriverProfile> profiles;

        if (approvalStatus != null) {
            profiles = driverProfileRepository.findByApprovalStatus(approvalStatus);
        } else {
            profiles = driverProfileRepository.findAll();
        }

        Map<UUID, User> userMap = userRepository.findAllActive().stream()
                .collect(Collectors.toMap(User::getId, u -> u));

        return profiles.stream()
                .map(p -> {
                    User user = userMap.get(p.getUser().getId());
                    String name = user != null ? user.getFirstName() + " " + user.getLastName() : "Unknown";
                    String phone = user != null ? user.getPhoneNumber() : "Unknown";
                    String corridor = p.getActiveCorridor() != null ? p.getActiveCorridor().getTitle() : null;
                    return new DriverAdminItem(
                            p.getId(), p.getUser().getId(), name, phone,
                            p.getNationalId(), p.getLicenseNumber(), p.isOnShift(),
                            corridor, p.getWalletBalance(), p.getApprovalStatus());
                })
                .toList();
    }

    @Transactional
    public void approveDriver(UUID profileId) {
        DriverProfile profile = driverProfileRepository.findById(profileId)
                .orElseThrow(() -> new NotFoundException("Driver profile not found"));
        profile.setApprovalStatus(ApprovalStatus.APPROVED);
        driverProfileRepository.save(profile);
    }

    @Transactional
    public void rejectDriver(UUID profileId) {
        DriverProfile profile = driverProfileRepository.findById(profileId)
                .orElseThrow(() -> new NotFoundException("Driver profile not found"));
        profile.setApprovalStatus(ApprovalStatus.REJECTED);
        driverProfileRepository.save(profile);
    }

    @Transactional(readOnly = true)
    public List<DepositItem> getDeposits(Boolean approved) {
        List<DriverDeposit> deposits;

        if (approved != null) {
            deposits = depositRepository.findByIsApprovedOrderByReceiveDateDesc(approved);
        } else {
            deposits = depositRepository.findAllByOrderByReceiveDateDesc();
        }

        return deposits.stream()
                .map(d -> new DepositItem(
                        d.getId(), d.getDriver().getId(), d.getAmount(),
                        d.getReceiveDate(), d.isApproved(), d.isRefunded(),
                        d.getRefundReason(), d.getRefundDate()))
                .toList();
    }

    @Transactional
    public void approveDeposit(Long depositId) {
        walletService.approveDeposit(depositId);
    }

    @Transactional
    public void forfeitDeposit(Long depositId, String reason) {
        walletService.forfeitDeposit(depositId, reason);
    }

@Transactional(readOnly = true)
    public SubscriptionSalesStats getSubscriptionStats() {
        return new SubscriptionSalesStats(
                subscriptionRepo.countByStatus(SubscriptionStatus.ACTIVE),
                subscriptionRepo.countByStatus(SubscriptionStatus.EXPIRED),
                subscriptionRepo.countByStatus(SubscriptionStatus.CANCELLED),
                subscriptionRepo.countByStatus(SubscriptionStatus.SUSPENDED)
                //subscriptionRepo.countByPlan(SubscriptionPlan.STUDENT_BASIC),
               // subscriptionRepo.countByPlan(SubscriptionPlan.STUDENT_PLUS),
               // subscriptionRepo.countByPlan(SubscriptionPlan.CORPORATE_COMMUTER),
               // subscriptionRepo.totalRevenue()
        );
    }

    @Transactional(readOnly = true)
    public List<PendingSubscriptionItem> getPendingSubscriptions() {
        return subscriptionRepo.findByStatusOrderByCreatedAtDesc(SubscriptionStatus.PENDING)
                .stream()
                .map(s -> {
                    User passenger = s.getPassenger().getUser();
                    String passengerName = passenger.getFirstName() + " " + passenger.getLastName();
                    return new PendingSubscriptionItem(
                            s.getId(),
                            s.getPassenger().getId(),
                            passengerName,
                            passenger.getPhoneNumber(),
                            s.getCorridor().getId(),
                            s.getCorridor().getTitle(),
                            s.getCorridor().getPrice(),
                            s.getStartDate(),
                            s.getEndDate(),
                            s.getStatus()
                    );
                })
                .toList();
    }

    @Transactional(readOnly = true)
    public List<RideAdminItem> getNoShowRides() {
        return rideRepository.findByStatusOrderByRequestedAtDesc(RideStatus.NO_SHOW)
                .stream()
                .map(r -> new RideAdminItem(
                        r.getId(), r.getPassengerId(), r.getDriverId(), r.getStatus(), r.getPin(),
                        r.getDepartureTime(), r.getRequestedAt(), r.getStartedAt(),
                        r.getCompletedAt(),
                        r.getEstimatedFare(), r.getFinalFare()))
                .toList();
    }
    
}
