package com.vamo.driver.service;

import com.vamo.common.enums.ApprovalStatus;
import com.vamo.common.exception.NotFoundException;
import com.vamo.common.events.DriverRegisteredEvent;
import com.vamo.driver.dto.ActivateCorridorRequest;
import com.vamo.driver.dto.DriverProfileResponse;
import com.vamo.driver.entity.DriverProfile;
import com.vamo.driver.repository.DriverProfileRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionalEventListener;

import java.math.BigDecimal;
import java.util.UUID;

@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class DriverService {

    private final DriverProfileRepository driverProfileRepository;

    @Async
    @TransactionalEventListener
    public void onDriverRegistered(DriverRegisteredEvent event) {
        log.info("Driver registered event received for user: {}", event.user().getId());
        DriverProfile profile = DriverProfile.builder()
                .user(event.user())
                .nationalId(event.registerDriverRequest().nationalId())
                .licenseNumber(event.registerDriverRequest().licenseNumber())
                .walletBalance(BigDecimal.ZERO)
                .isOnShift(false)
                .approvalStatus(ApprovalStatus.PENDING)
                .build();
        driverProfileRepository.save(profile);
    }

    public DriverProfileResponse getProfile(UUID userId) {
        DriverProfile profile = driverProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new NotFoundException("Driver profile not found"));

        return new DriverProfileResponse(
                profile.getId(),
                profile.getNationalId(),
                profile.getLicenseNumber(),
                profile.isOnShift(),
                profile.getActiveCorridor() != null ? profile.getActiveCorridor().getId() : null,
                profile.getApprovalStatus()
        );
    }

    public void activateCorridor(UUID userId, ActivateCorridorRequest request) {
        DriverProfile profile = driverProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new NotFoundException("Driver profile not found"));

        if (profile.getApprovalStatus() != ApprovalStatus.APPROVED) {
            throw new IllegalStateException("Driver account not approved yet");
        }

        profile.setOnShift(request.onShift());
        driverProfileRepository.save(profile);
    }

    public void toggleShift(UUID userId, boolean onShift) {
        DriverProfile profile = driverProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new NotFoundException("Driver profile not found"));

        profile.setOnShift(onShift);
        driverProfileRepository.save(profile);
    }
}
