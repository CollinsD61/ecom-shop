# Stage 1: Build the application
FROM eclipse-temurin:17-jdk-jammy AS builder

WORKDIR /app
COPY . .
RUN chmod +x ./mvnw && ./mvnw clean package -DskipTests

# Stage 2: Run the application
FROM eclipse-temurin:17-jdk-jammy

WORKDIR /app
COPY --from=builder /app/target/user-service-0.0.1-SNAPSHOT.war /app/user-service.war

CMD ["java", "-jar", "user-service.war"]
