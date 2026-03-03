FROM maven:3.9.9-eclipse-temurin-21 AS build
WORKDIR /workspace

COPY pom.xml ./
COPY ljwx-platform-core/pom.xml ljwx-platform-core/pom.xml
COPY ljwx-platform-security/pom.xml ljwx-platform-security/pom.xml
COPY ljwx-platform-data/pom.xml ljwx-platform-data/pom.xml
COPY ljwx-platform-web/pom.xml ljwx-platform-web/pom.xml
COPY ljwx-platform-app/pom.xml ljwx-platform-app/pom.xml

COPY ljwx-platform-core/src ljwx-platform-core/src
COPY ljwx-platform-security/src ljwx-platform-security/src
COPY ljwx-platform-data/src ljwx-platform-data/src
COPY ljwx-platform-web/src ljwx-platform-web/src
COPY ljwx-platform-app/src ljwx-platform-app/src

RUN mvn -B -ntp -q -pl ljwx-platform-app -am package -DskipTests

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /workspace/ljwx-platform-app/target/*.jar /app/app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
