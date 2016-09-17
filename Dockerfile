# Docker container for Jacbsmarket
# (c) Tom Wiesing 2015

FROM ruby:2.2.1

MAINTAINER Tom Wiesing <tkw01536@gmail.com>

# Install MySQL
RUN apt-get update && \
    echo "mysql-server mysql-server/root_password password root" | debconf-set-selections && \
    echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections && \
    apt-get -y install mysql-server mysql-client libmysqlclient-dev

# Install git + stuff
RUN apt-get -y install git nodejs

# Install ruby deps
RUN gem install rails -v 4.2.1 --verbose

# Clone the repo and install it. 
RUN git clone https://github.com/aoripov/JacobsMKT.git
RUN cd JacobsMKT && bundle install --retry 5 --verbose

# Setup config and run more setup stuff
VOLUME /var/lib/mysql/

# Create database jacobsmarket
RUN service mysql start && sleep 5 && \
    mysql -u root --password=root -e "create database jacobsmarket; show databases; " && \
    service mysql stop && sleep 5

VOLUME /JacobsMKT/public/uploads

ADD config.yml /JacobsMKT/config/database.yml
RUN service mysql start && sleep 5 && \
    cd JacobsMKT && \
    RAILS_ENV=production rake db:create:all --verbose && \
    RAILS_ENV=production rake db:migrate --verbose && \
    service mysql stop && sleep 5

EXPOSE 3000
ENTRYPOINT ["/bin/bash", "-c", "cd /JacobsMKT/; service mysql start; export SECRET_KEY_BASE=$(RAILS_ENV=production rake secret); export RAILS_ENV=production; bash"]
