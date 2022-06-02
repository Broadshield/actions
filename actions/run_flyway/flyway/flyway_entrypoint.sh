#!/usr/bin/env bash
set -e

function get_aws_jdbc_driver() {
  if [ -d "${JDBC_DRIVER_PATH}" ] && [ -n "${AWS_MYSQL_DRIVER_VERSION}" ]; then
    JDBC_DRIVER_DOWNLOAD_URL="https://github.com/awslabs/aws-mysql-jdbc/releases/download/${AWS_MYSQL_DRIVER_VERSION}/aws-mysql-jdbc-${AWS_MYSQL_DRIVER_VERSION}.jar"
    if wget -q "${JDBC_DRIVER_DOWNLOAD_URL}" -O "${JDBC_DRIVER_PATH}/aws-mysql-jdbc.jar"; then
      ## Default MySQL-Connector-J JDBC
      # FLYWAY_DRIVER=com.mysql.cj.jdbc.Driver
      ## AWS MySQL-Connector-J JDBC
      export FLYWAY_DRIVER=software.aws.rds.jdbc.mysql.Driver
      echo "JDBC driver is: ${FLYWAY_DRIVER} version ${AWS_MYSQL_DRIVER_VERSION}"
    else
      echo "Failed to download JDBC driver from ${JDBC_DRIVER_DOWNLOAD_URL}"
      if [[ ${JDBC_URL_TYPE} == "jdbc:mysql:aws:" ]]; then
        export JDBC_URL_TYPE="jdbc:mysql:"
        echo "::error::Falling back to default mysql-connector-java JDBC url type ${JDBC_URL_TYPE}"
      fi
      if [[ ${FLYWAY_DRIVER} == "software.aws.rds.jdbc.mysql.Driver" ]]; then
        export FLYWAY_DRIVER=com.mysql.cj.jdbc.Driver
        echo "::error::Falling back to default mysql-connector-java JDBC driver: ${FLYWAY_DRIVER}"
      fi
    fi
  fi
}
get_aws_jdbc_driver
if [ -n "${REPAIR_FIRST}" ]; then
  echo "Repairing database first"
  flyway "$@" repair -v
fi
echo "Running migrations"
flyway "$@" "${FLYWAY_COMMAND:-info}"
