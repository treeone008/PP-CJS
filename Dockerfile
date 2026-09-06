# 1. Build Stage
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /build
# 전체 레포지토리 소스를 컨테이너의 /build로 복사
COPY . .

# ⭐️ gradlew가 존재하는 하위 폴더로 작업 디렉토리 변경
WORKDIR /build/apps/payment-api

RUN chmod +x ./gradlew
RUN ./gradlew clean bootJar

# 2. Run Stage
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
# ⭐️ JAR 파일을 가져올 때도 변경된 하위 폴더 경로를 명시
COPY --from=builder /build/apps/payment-api/build/libs/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
