FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update 
RUN apt-get install -y openjdk-25-jdk  
RUN apt-get install -y  curl  
RUN apt-get install -y  bash  
RUN apt-get install -y  python3 
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME environment variable
ENV JAVA_HOME=/usr/lib/jvm/java-25-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:$PATH"

# Verify installation
RUN java -version

# Install a pinned upstream Maven instead of the Ubuntu package (apt's Maven 3.6.3 bundles an old
# Guava that triggers JDK 24+ sun.misc.Unsafe deprecation warnings). Keep this version in sync with
# any Maven Wrapper or CI config if one is added later.
ENV MAVEN_VERSION=3.9.16
RUN curl -fsSL -o /tmp/maven.tar.gz \
      https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
 && test "$(sha512sum /tmp/maven.tar.gz | cut -d' ' -f1)" = \
      "$(curl -fsSL https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz.sha512 | cut -d' ' -f1)" \
 && tar -xzf /tmp/maven.tar.gz -C /opt \
 && ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven \
 && rm /tmp/maven.tar.gz
ENV MAVEN_HOME=/opt/maven
ENV PATH="$MAVEN_HOME/bin:$PATH"
RUN mvn -version

WORKDIR /app

# Verify installation
RUN java -version
RUN curl --version

ENV NODE_VERSION=24.21.0
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"

RUN . "$NVM_DIR/nvm.sh" && nvm --version
RUN node --version
RUN npm --version

COPY . /home/app

RUN mvn --no-transfer-progress -B -Pproduction -DskipTests -f /home/app/pom.xml clean package

RUN ["chmod", "+x", "/home/app/startup.sh"]
ENTRYPOINT ["/home/app/startup.sh","/home/app/target/diningcachingproxy-0.0.1.jar"]
