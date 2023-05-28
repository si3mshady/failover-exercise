#!/usr/bin/bash

# sudo su - 
sudo python3 -m venv venv 
source venv/bin/activate 
wget  https://github.com/si3mshady/failover-exercise/raw/main/flask_app.py 
pip3 install  -r https://raw.githubusercontent.com/si3mshady/failover-exercise/main/requirements.txt 
sudo python3 flask_app.py
