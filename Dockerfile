# Step 1: Build the application using Maven and Java 17
FROM maven:3.8.4-eclipse-temurin-17 AS build
COPY . .
RUN mvn clean package -DskipTests

# Step 2: Run the application using a stable Java 17 runtime
FROM eclipse-temurin:17-jre-alpine
COPY --from=build /target/*.jar app.jar
EXPOSE 10000
ENTRYPOINT ["java","-jar","/app.jar","--server.port=10000"]