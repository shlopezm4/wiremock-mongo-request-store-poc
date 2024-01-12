# ------ Stage 1 ------

FROM node:18 as frontend-stage

# Create an application directory
RUN mkdir -p /app

# The /app directory should act as the main application directory
WORKDIR /app

# Copy the app package and package-lock.json file
COPY ./frontend/package*.json ./

# Copy or project directory (locally) in the current directory of our docker image (/app)
COPY ./frontend/ .

# Install
RUN npm install

# Build the app
RUN npm run build

# ------ Stage 2 ------
FROM gradle:8.5.0-jdk8 AS build-stage
COPY --chown=gradle:gradle . /home/gradle/src
WORKDIR /home/gradle/src
RUN ./gradlew --quiet clean build sample:shadowJar

# ------ Stage 3 ------
FROM openjdk:8-jre-slim AS run-stage

EXPOSE 8080

RUN mkdir /app

COPY --from=frontend-stage app/build/ core/src/main/resources/public/
COPY --from=build-stage /home/gradle/src/sample/build/libs/*.jar /app/sample-1.0-SNAPSHOT-all.jar
COPY --from=build-stage /home/gradle/src/sample /app

ENTRYPOINT ["java", "-jar", "/app/sample-1.0-SNAPSHOT-all.jar", "/app/sample/src/main/resources/requests/"]