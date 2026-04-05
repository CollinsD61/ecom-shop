package com.techcareer.userservice.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

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
    @Value("${cognito.hosted_ui_login_url:}")
    String cognitoHostedUiLoginUrl;

    @Value("${cognito.hosted_ui_signup_url:}")
    String cognitoHostedUiSignupUrl;

    @Autowired
    UserRepository userRepository;

    @Autowired
    RestTemplate restTemplate;

    public ResponseEntity<?> authenticateUser(LoginRequest loginRequest) {
        String loginHint = cognitoHostedUiLoginUrl == null || cognitoHostedUiLoginUrl.isBlank()
                ? "Cognito Hosted UI login URL is not configured."
                : "Login via Cognito Hosted UI: " + cognitoHostedUiLoginUrl;

        return ResponseEntity.status(HttpStatus.NOT_IMPLEMENTED)
                .body(new MessageResponse("Local signin is disabled. " + loginHint));
    }

    public ResponseEntity<?> registerUser(SignupRequest signUpRequest) {
        String signupHint = cognitoHostedUiSignupUrl == null || cognitoHostedUiSignupUrl.isBlank()
                ? "Cognito Hosted UI signup URL is not configured."
                : "Signup via Cognito Hosted UI: " + cognitoHostedUiSignupUrl;

        return ResponseEntity.status(HttpStatus.NOT_IMPLEMENTED)
                .body(new MessageResponse("Local signup is disabled. " + signupHint));
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

            // Password is managed by Cognito, user-service only maintains local profile attributes.
            if (updateUserRequest.getPassword() != null && !updateUserRequest.getPassword().isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(new MessageResponse("Password updates must be done in Cognito."));
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
