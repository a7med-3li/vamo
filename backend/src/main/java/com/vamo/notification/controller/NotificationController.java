package com.vamo.notification.controller;

import com.vamo.common.dto.ApiResponse;
import com.vamo.notification.dto.NotificationResponseDto;
import com.vamo.notification.entity.Notification;
import com.vamo.notification.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/notifications")
public class NotificationController {

    private final NotificationService notificationService;

    @PreAuthorize("hasAnyRole('PASSENGER', 'DRIVER', 'ADMIN', 'BOTH')")
    @GetMapping
    public ResponseEntity<List<NotificationResponseDto>> getAllNotifications(
            @AuthenticationPrincipal String userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        UUID passengerId = UUID.fromString(userId);
        List<Notification> notifications = notificationService.findAllByReceiverId(passengerId, page, size)
                .getContent();

        return ResponseEntity.ok(
                notifications.stream()
                        .map(NotificationResponseDto::from)
                        .toList()
        );
    }

    @PreAuthorize("hasAnyRole('PASSENGER', 'DRIVER', 'ADMIN', 'BOTH')")
    @GetMapping("/unread-count")
    public ResponseEntity<Long> getUnreadCount(@AuthenticationPrincipal String userId) {
        UUID passengerId = UUID.fromString(userId);
        return ResponseEntity.ok(notificationService.countUnreadByUserId(passengerId));
    }
    
    @PreAuthorize("hasAnyRole('PASSENGER', 'DRIVER', 'ADMIN', 'BOTH')")
    @PostMapping("/{id}/read")
    public ResponseEntity<ApiResponse> markAsRead(@PathVariable UUID id) {
        notificationService.markAsRead(id);
        return ResponseEntity.ok(new ApiResponse(true, "Notification marked as read"));
    }
}
