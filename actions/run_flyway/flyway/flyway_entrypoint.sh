#!/usr/bin/env bash
set -e
cat <<EOF >/flyway/conf/flyway.conf
flyway.url=${JDBC_URL_TYPE}//${JDBC_HOST}:${JDBC_PORT}?${JDBC_URL_OPTIONS}
flyway.connectRetries=1
flyway.validateOnMigrate=false
flyway.cleanDisabled=false
EOF
function get_aws_jdbc_driver() {
	if [ -d "${JDBC_DRIVER_PATH}" ] && [ -n "${AWS_MYSQL_DRIVER_VERSION}" ]; then
		JDBC_DRIVER_DOWNLOAD_URL="https://github.com/awslabs/aws-mysql-jdbc/releases/download/${AWS_MYSQL_DRIVER_VERSION}/aws-mysql-jdbc-${AWS_MYSQL_DRIVER_VERSION}.jar"
		wget -q "${JDBC_DRIVER_DOWNLOAD_URL}" -O "${JDBC_DRIVER_PATH}/aws-mysql-jdbc.jar"
		## Default MySQL-Connector-J JDBC
		# FLYWAY_DRIVER=com.mysql.cj.jdbc.Driver
		## AWS MySQL-Connector-J JDBC
		export FLYWAY_DRIVER=software.aws.rds.jdbc.mysql.Driver
		echo "JDBC driver is: ${FLYWAY_DRIVER} version ${AWS_MYSQL_DRIVER_VERSION}"
	fi
}
get_aws_jdbc_driver || export FLYWAY_DRIVER=com.mysql.cj.jdbc.Driver
if [ -n "${REPAIR_FIRST}" ]; then
echo "Repairing database first"
	flyway "$@" repair -v
fi
echo "Running migrations"
flyway "$@" "${FLYWAY_COMMAND:-info}"
