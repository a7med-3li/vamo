package com.vamo.common.exception;

public class RideAlreadyTakenException extends RuntimeException {
	
	public RideAlreadyTakenException(String message) {
		super(message);
	}
}
