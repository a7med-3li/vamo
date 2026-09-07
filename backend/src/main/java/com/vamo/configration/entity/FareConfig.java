package com.vamo.configration.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Data
@Table(name = "fare_configs")
public class FareConfig {
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;
	
	private String vehicleType;
	private String city= "BENI_SUEF";
	
	private BigDecimal baseFare;
	private BigDecimal perKmRate;
	private BigDecimal perMinuteRate;
	private BigDecimal minimumFare;
	private BigDecimal waitingRatePerMinute;
	
	private BigDecimal surgeMultiplier = BigDecimal.ONE;
	
	private boolean active;
	private LocalDateTime effectiveFrom;
	private LocalDateTime createdAt;
}
