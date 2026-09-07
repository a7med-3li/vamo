package com.vamo.driver.entity;

import com.vamo.common.enums.ApprovalStatus;
import com.vamo.common.enums.VehicleType;
import com.vamo.corridor.entity.Corridor;
import com.vamo.user.entity.User;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "driver_profile")
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Getter
@Setter
public class DriverProfile {
    
    @Id
    @GeneratedValue
    private UUID id;
    
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;
    
    private String nationalId;
    private String licenseNumber;
    @Enumerated(EnumType.STRING)
    private VehicleType vehicleType;
    
    @OneToMany(mappedBy = "driver", fetch = FetchType.LAZY)
    private List<DriverDeposit> depositList;
    
    private BigDecimal walletBalance;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "active_corridor_id")
    private Corridor activeCorridor;
    
    private boolean isOnShift;
    
    @Enumerated(EnumType.STRING)
    private ApprovalStatus approvalStatus;  // PENDING, APPROVED, REJECTED
}
