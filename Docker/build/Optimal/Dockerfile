FROM gcr.io/distroless/java:8
LABEL description="Echo IP Java Application"
COPY ./target/app-in-host.jar /opt/app-in-image.jar
WORKDIR /opt
EXPOSE 18080
ENTRYPOINT [ "java", "-jar", "app-in-image.jar" ]