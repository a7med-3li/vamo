package com.vamo.user.service;

import com.vamo.common.enums.ApprovalStatus;
import com.vamo.common.enums.Gender;
import com.vamo.common.enums.UserRole;
import com.vamo.common.events.DriverRegisteredEvent;
import com.vamo.common.events.PassengerRegisteredEvent;
import com.vamo.common.exception.UserNotFoundException;
import com.vamo.common.mapper.Mappers;
import com.vamo.common.dto.DriverRegisterRequest;
import com.vamo.common.dto.PassengerRegisterRequest;
import com.vamo.driver.entity.DriverProfile;
import com.vamo.driver.repository.DriverProfileRepository;
import com.vamo.passenger.entity.PassengerProfile;
import com.vamo.passenger.repository.PassengerProfileRepository;
import com.vamo.user.dto.UpdateUserRequest;
import com.vamo.user.dto.UserInfo;
import com.vamo.user.dto.UserResponse;
import com.vamo.user.entity.User;
import com.vamo.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;
import static com.vamo.common.util.Helpers.mapToResponse;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@Validated
@Transactional
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final Mappers mappers;
    private final PasswordEncoder passwordEncoder;
    private final DriverProfileRepository driverProfileRepository;
    private final PassengerProfileRepository passengerProfileRepository;
    
    @Transactional
    public void registerPassenger(PassengerRegisterRequest req) {
        User user = userRepository.findByPhoneNumber(req.phoneNumber())
                .orElseGet(() -> createBaseUser(req.phoneNumber(), req.firstName(),req.lastName(), UserRole.PASSENGER, req.password(),req.gender()));
        
        if (user.getRole() == UserRole.DRIVER) {
            user.setRole(UserRole.BOTH);
        }
        onPassengerRegistered(new PassengerRegisteredEvent(user, req));
        System.out.println("Passenger registered event published for user: " + user.getId());
    }
    
    @Transactional
    public void registerDriver(DriverRegisterRequest req) {
        User user = userRepository.findByPhoneNumber(req.phoneNumber())
                .orElseGet(() -> createBaseUser(req.phoneNumber(), req.firstName(), req.lastName(), UserRole.DRIVER, req.password(), req.gender()));

        if (user.getRole() == UserRole.PASSENGER) {
            user.setRole(UserRole.BOTH);
        }
        onDriverRegistered(new DriverRegisteredEvent(user, req));
        System.out.println("Driver registered event published for user: " + user.getId());
    }
    
    private User createBaseUser(String phone, String firstName, String lastName, UserRole role, String password, Gender gender) {
        User user = new User();
        user.setPhoneNumber(phone);
        user.setFirstName(firstName);
        user.setLastName(lastName);
        user.setRole(role);
        user.setDeleted(false);
        user.setCreatedAt(Instant.now());
        user.setGender(gender);
        user.setPasswordHash(passwordEncoder.encode(password));
        return userRepository.save(user);
    }
    
    // todo: needs to be refactored to map based on the user role. (response dto TBD)
    // it should call the passenger/ driver service to get the user info based on the role
    public UserInfo getUserInfo(UUID id){
        User user = userRepository.findById(id)
                .orElseThrow(() -> new UserNotFoundException("User not found with id: " + id));
        return mappers.userToUserInfo(user);
    }

    @Transactional
    public void deleteUser(UUID id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new UserNotFoundException("User not found with id: " + id));

        if (user.isDeleted()) { return;}
        
        userRepository.delete(user);
    }

    // note: needs logic review
    public UserResponse restoreUser(UUID id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new UserNotFoundException("User not found with id: " + id));

        if (!user.isDeleted()) {
            throw new IllegalStateException("User is not deleted");
        }

        user.setDeleted(false);
        user.setDeletedAt(null);

        User restoredUser = userRepository.save(user);

        // todo: create a mapper
        return mapToResponse(restoredUser);
    }

    // todo: this should be altered to get by phone number and for ADMIN only.
    public UserResponse getUserById(UUID id){
        User user = userRepository.findById(id).orElseThrow(
                () -> new UserNotFoundException("User not found with id:" + id));
        // todo: replace with object mapper
        return mapToResponse(user);
    }

    // note: for admins only
    public List<UserResponse> getAllUsers(){
        List<User> users = userRepository.findAll();
        List<UserResponse> userResponseList = new ArrayList<>();
        for(User user : users){
            userResponseList.add(mapToResponse(user));
        }
        return userResponseList;
    }
    // todo: rewrite this to follow the best practice
    public UserInfo updateUser(UUID id, UpdateUserRequest request) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new UserNotFoundException("User not found"));
        mappers.updateUserFromRequest(request, user);

        return mappers.userToUserInfo(userRepository.save(user));
    }
    
    private void onDriverRegistered(DriverRegisteredEvent event) {
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
    
    public void onPassengerRegistered(PassengerRegisteredEvent event) {
        passengerProfileRepository.save(new PassengerProfile(event.user().getId(), event.user(), List.of()));
    }
}
