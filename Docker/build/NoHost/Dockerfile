FROM openjdk:8
LABEL description="Echo IP Java Application"
RUN git clone https://github.com/iac-source/inbuilder.git
WORKDIR inbuilder
RUN chmod 755 mvnw
RUN ./mvnw clean package
RUN cp target/app-in-host.jar /opt/app-in-image.jar
WORKDIR /opt
EXPOSE 18080
ENTRYPOINT [ "java", "-jar", "app-in-image.jar" ]

