# Stage 1: Build stage
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /app

# Copy các file build của Gradle vào trước để tận dụng Docker cache
COPY gradlew .
COPY gradle gradle
COPY build.gradle .
COPY settings.gradle .

# Cấp quyền thực thi cho gradlew và tải dependencies (tránh tải lại mỗi lần sửa code)
RUN chmod +x gradlew
RUN ./gradlew dependencies --no-daemon

# Copy mã nguồn và đóng gói file JAR
COPY src src
RUN ./gradlew bootJar -x test --no-daemon

# Stage 2: Runtime stage
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Tạo một user riêng để chạy ứng dụng (không dùng root để tránh rủi ro bảo mật)
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Copy file JAR từ Stage 1 sang Stage 2
# Tên file JAR mặc định của Gradle là {name}-{version}.jar, ta đổi tên thành app.jar cho gọn
COPY --from=build /app/build/libs/*.jar app.jar

# Khai báo Port ứng dụng
EXPOSE 8080

# Cấu hình các thông số JVM tối ưu cho container
ENTRYPOINT ["java", \
            "-Djava.security.egd=file:/dev/./urandom", \
            "-Xmx512m", \
            "-jar", \
            "app.jar"]