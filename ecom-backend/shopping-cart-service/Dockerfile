# Stage 1: Build the application
FROM eclipse-temurin:17-jdk-jammy AS builder

WORKDIR /app
COPY . .
RUN chmod +x ./mvnw && ./mvnw clean package -DskipTests

# Stage 2: Run the application
FROM eclipse-temurin:17-jdk-jammy

WORKDIR /app
COPY --from=builder /app/target/shopping-cart-service-0.0.1-SNAPSHOT.war /app/shopping-cart-service.war

CMD ["java", "-jar", "shopping-cart-service.war"]
