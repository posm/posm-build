### Mock Test

```
# Get data
curl -L -o /tmp/data.zip https://github.com/posm/posm-replay-server/files/4863291/data.zip
unzip /tmp/data.zip -d /tmp/

# Start the containers
docker-compose up

# Copy to container
docker cp /tmp/Jawalakhel docker_replay-tool-server_1:/aoi
docker cp replay-tool/mock_data.json docker_replay-tool-server_1:/code

# Load data inside container (docker-compose exec replay-tool-server bash)
docker-compose exec replay-tool-server bash -c 'python3 manage.py loaddata mock_data.json && rm mock_data.json'
# Goto replay-tool.posm.io and hit retry
```
