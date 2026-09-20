package com.vamo.common.entity;

import jakarta.persistence.Embeddable;
import lombok.Getter;
import lombok.Setter;

@Embeddable
@Getter
@Setter
public class Location {
    
    public Location(double latitude, double longitude, String title) {
        this.addressName = title;
        this.latitude = latitude;
        this.longitude = longitude;
    }
    private String addressName;
    private Double latitude;
    private Double longitude;
    
    
    
    public Location() {
    
    }
}
