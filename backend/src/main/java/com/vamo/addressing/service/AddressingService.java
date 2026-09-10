package com.vamo.addressing.service;

import com.vamo.addressing.dto.AutoCompleteResponse;
import com.vamo.addressing.entity.Address;
import com.vamo.addressing.repository.AddressingRepository;
import com.vamo.ride.service.interfaces.RoutingService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.Collections;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AddressingService {
    private final AddressingRepository addressingRepository;
    private final RoutingService routingService;

    public AutoCompleteResponse autoComplete(String address) {
        try {
            return new AutoCompleteResponse(
                    "internal",
                    addressingRepository.queryAddressesByTitleContaining(address)
            );
        } catch (Exception e) {
            return new AutoCompleteResponse("internal", Collections.emptyList());
        }
    }
    
    public List<Address> search(String address) {
        List<Address> addresses = searchMap(address);
        addressingRepository.saveAll(addresses);
        return addresses;
    }
    
    private List<Address> searchMap(String address) {
        return routingService.search(address);
    }
}
