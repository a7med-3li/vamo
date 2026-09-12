package com.vamo.dispatch.controller;

import java.util.UUID;
import com.vamo.common.annotation.CurrentDriverId;
import com.vamo.dispatch.service.DriverConnectionManager;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

@RestController
@RequestMapping("/api/v1/dispatch")
@RequiredArgsConstructor
public class DispatchController {
	
	private final DriverConnectionManager driverConnectionManager;
	
	@GetMapping(value = "/drivers/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
	public SseEmitter streamDriverEvents(@CurrentDriverId UUID driverId) {
		return driverConnectionManager.createConnection(String.valueOf(driverId));
	}
}
