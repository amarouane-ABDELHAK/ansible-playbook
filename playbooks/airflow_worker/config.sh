#!/bin/bash

set -e

# Define variables
AIRFLOW_VERSION=2.8.4
UNAME=airflow
CUID=50000
CGID=0
AIRFLOW_HOME=/opt/airflow

# Create group and user
groupadd -g "$CGID" -o "$UNAME"
useradd -m -u "$CUID" -g "$CGID" -o -s /bin/bash "$UNAME"

# Create and set permissions for the AIRFLOW_HOME directory
mkdir -p "$AIRFLOW_HOME"
chown "$UNAME:$GID" "$AIRFLOW_HOME"

# Update and install required system packages
apt-get -y update
apt-get install -y --no-install-recommends \
    gcc libc6-dev libcurl4-openssl-dev libssl-dev
apt-get autoremove -yqq --purge
apt-get clean
rm -rf /var/lib/apt/lists/*

# Switch to the Airflow user and run setup commands
su - "$UNAME" <<EOF

# Define environment variables for the Airflow user
export AIRFLOW_HOME=${AIRFLOW_HOME}

# Create Miniconda directory and install Miniconda
mkdir -p /home/"$UNAME"/miniconda3
curl -o /home/"$UNAME"/miniconda3/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash /home/"$UNAME"/miniconda3/miniconda.sh -b -u -p /home/"$UNAME"/miniconda3
rm /home/"$UNAME"/miniconda3/miniconda.sh

# Install Python 3.11
/home/"$UNAME"/miniconda3/bin/conda create -n py11 --yes python=3.11

# Set PATH for conda environment
export PATH=\$PATH:/home/"$UNAME"/miniconda3/envs/py11/bin

# Upgrade pip and install Airflow and its dependencies
pip install --upgrade pip
pip install "apache-airflow[celery,amazon]==${AIRFLOW_VERSION}" --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-3.11.txt"

EOF

# # Copy files as root and set ownership for the Airflow user
# cp -r airflow_worker/requirements.txt "${AIRFLOW_HOME}/requirements.txt"
# cp -r dags "${AIRFLOW_HOME}/dags"
# cp -r plugins "${AIRFLOW_HOME}/plugins"
# cp -r infrastructure/configuration "${AIRFLOW_HOME}/configuration"
# cp -r scripts "${AIRFLOW_HOME}/scripts"
# cp "${AIRFLOW_HOME}/configuration/airflow.cfg"* "${AIRFLOW_HOME}/."
# chown -R "$UNAME:$GID" "$AIRFLOW_HOME"

# # Export environment variables for the session
# export AIRFLOW_HOME=${AIRFLOW_HOME}
# export TZ=UTC
# export PYTHONPATH=/opt/airflow

# # Print success message
# echo "Airflow setup is complete. You can now start using Airflow!"

# # Open a bash shell for user interaction
# exec /bin/bash
