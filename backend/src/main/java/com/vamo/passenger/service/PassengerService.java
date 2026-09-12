package com.vamo.passenger.service;

import java.util.UUID;
import com.vamo.passenger.entity.PassengerProfile;
import com.vamo.passenger.repository.PassengerProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class PassengerService {
	// TODO: implement passenger-related logic
	
	private final PassengerProfileRepository passengerProfileRepository;
	
	public PassengerProfile findById(UUID id) {
		return passengerProfileRepository.findByUserId(id)
				.orElseThrow(() -> new RuntimeException("Passenger not found"));
	}
	
}
