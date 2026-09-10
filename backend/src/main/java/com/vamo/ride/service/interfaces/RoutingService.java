package com.vamo.ride.service.interfaces;

import java.util.List;
import com.vamo.addressing.entity.Address;
import com.vamo.ride.dto.RideRequestDto;
import com.vamo.ride.dto.RoutingResponse;

public interface RoutingService {
    
    List<RoutingResponse> getRideOptions(RideRequestDto rideRequestDto);
    List<Address> search(String location);

}
