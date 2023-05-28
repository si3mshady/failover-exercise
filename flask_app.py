
from flask import Flask, jsonify
import requests

app = Flask(__name__)

@app.route("/")
def get_instance_data():
    instance_ip = requests.get('http://169.254.169.254/latest/meta-data/public-ipv4').text
    instance_id = requests.get('http://169.254.169.254/latest/meta-data/instance-id').text
    region = requests.get('http://169.254.169.254/latest/meta-data/placement/availability-zone').text[:-1]
    
    return jsonify({
        'Instance IP': instance_ip,
        'Instance ID': instance_id,
        'Region': region
    })


@app.route("/instance")
def get_instance_info():
    instance_ip = requests.get('http://169.254.169.254/latest/meta-data/public-ipv4').text
    instance_id = requests.get('http://169.254.169.254/latest/meta-data/instance-id').text
    region = requests.get('http://169.254.169.254/latest/meta-data/placement/availability-zone').text[:-1]
    
    return jsonify({
        'Instance IP': instance_ip,
        'Instance ID': instance_id,
        'Region': region
    })


@app.route("/health")
def get_instance_health():
    return jsonify({"status": "ok"}), 200


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)