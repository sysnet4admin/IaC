FROM openjdk:8
LABEL description="Echo IP Java Application"
RUN git clone https://github.com/iac-source/inbuilder.git
RUN chmod 755 inbuilder/mvnw
RUN ./inbuilder/mvnw clean package
COPY inbuilder/target/app-in-host.jar /opt/app-in-image.jar
WORKDIR /opt
EXPOSE 18080
ENTRYPOINT [ "java", "-jar", "app-in-image.jar" ]
