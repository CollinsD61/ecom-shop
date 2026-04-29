package com.techcareer.userservice.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

import com.techcareer.userservice.entity.ShoppingCart;
import com.techcareer.userservice.entity.User;
import com.techcareer.userservice.payload.request.LoginRequest;
import com.techcareer.userservice.payload.request.SignupRequest;
import com.techcareer.userservice.payload.request.UpdateUserRequest;
import com.techcareer.userservice.payload.response.MessageResponse;
import com.techcareer.userservice.repository.UserRepository;

import jakarta.persistence.EntityNotFoundException;

@Service
public class UserService {

    @Autowired
    UserRepository userRepository;

    @Autowired
    RestTemplate restTemplate;

    public ResponseEntity<?> authenticateUser(LoginRequest loginRequest) {
        Optional<User> userOptional = userRepository.findByUsername(loginRequest.getUsername());
        if (userOptional.isPresent()) {
            User user = userOptional.get();
            if (user.getPassword().equals(loginRequest.getPassword())) {
                Map<String, Object> response = new HashMap<>();
                response.put("accessToken", "local-jwt-token-for-" + user.getUsername());
                response.put("id", user.getId());
                response.put("username", user.getUsername());
                response.put("email", user.getEmail());
                return ResponseEntity.ok(response);
            }
        }
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(new MessageResponse("Error: Invalid username or password!"));
    }

    public ResponseEntity<?> registerUser(SignupRequest signUpRequest) {
        if (userRepository.existsByUsername(signUpRequest.getUsername())) {
            return ResponseEntity.badRequest()
                    .body(new MessageResponse("Error: Username is already taken!"));
        }

        if (userRepository.existsByEmail(signUpRequest.getEmail())) {
            return ResponseEntity.badRequest()
                    .body(new MessageResponse("Error: Email is already in use!"));
        }

        // Create new user account with local database storage
        User user = new User(signUpRequest.getUsername(),
                signUpRequest.getEmail(),
                signUpRequest.getPassword());

        userRepository.save(user);

        return ResponseEntity.ok(new MessageResponse("User registered successfully!"));
    }

    public ResponseEntity<?> deleteUser(Long userId) {
        try {
            // Check if the user exists
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new EntityNotFoundException("User not found!"));

            try {
                // Check user's shopping cart
                ShoppingCart shoppingCart = restTemplate.getForObject(
                        "http://SHOPPING-CART-SERVICE/api/shopping-cart/by-name/" + user.getUsername(),
                        ShoppingCart.class);

                restTemplate.delete("http://SHOPPING-CART-SERVICE/api/shopping-cart/" + shoppingCart.getId());
            } catch (Exception e) {
                // If shopping cart not found, continue with user deletion
            }

            // Delete the user
            userRepository.delete(user);

            return ResponseEntity.ok(new MessageResponse("User account deleted successfully!"));
        } catch (EntityNotFoundException e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().body(new MessageResponse("Internal Server Error"));
        }
    }

    public ResponseEntity<?> updateUser(Long userId, UpdateUserRequest updateUserRequest) {
        try {
            // Check if the user exists
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new EntityNotFoundException("User not found!"));

            // Update password if provided
            if (updateUserRequest.getPassword() != null && !updateUserRequest.getPassword().isEmpty()) {
                user.setPassword(updateUserRequest.getPassword());
            }

            // Update email if provided
            if (updateUserRequest.getEmail() != null && !updateUserRequest.getEmail().isEmpty()) {
                if (userRepository.existsByEmail(updateUserRequest.getEmail())) {
                    return ResponseEntity.badRequest().body(new MessageResponse("Email is already in use!"));
                }
                user.setEmail(updateUserRequest.getEmail());
            }

            // Save the updated user
            userRepository.save(user);

            return ResponseEntity.ok(new MessageResponse("User account updated successfully!"));
        } catch (EntityNotFoundException e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().body(new MessageResponse("Internal Server Error"));
        }
    }
}
