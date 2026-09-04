# 1. Build Stage: 코드를 빌드하여 JAR 파일을 생성합니다.
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /build
# 소스 코드를 도커 내부로 복사합니다. (소스가 apps/payment-api 폴더에 있다면 경로를 맞춰주세요)
COPY . .
# Gradle을 이용해 빌드합니다. (실행 권한 부여 포함)
RUN chmod +x ./gradlew
RUN ./gradlew clean bootJar

# 2. Run Stage: 생성된 JAR 파일만 복사하여 최종 이미지를 가볍게 만듭니다.
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /build/build/libs/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
