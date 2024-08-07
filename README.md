# PlanetTiler OSM job

Download and process OSM pbfs from Geofabrik for a given area and upload the resulting mbtiles to S3.

## Variables

There are two variables that can be changed in this project:

- `AREA`: This variable defines the area to download and process. The default value is `planet`. The value can be changed to any area available in the Geofabrik website.
- `S3_PATH`: This variable specifies the S3 path to upload the mbtiles file. The default value is `ovh:kargo/data/MBTiles` 
- `WEBHOOK_URL`: This variable specifies the webhook URL for the project. The default value is in the secrets file. it can be overridden to any other value.

## Running the Project


### ⚠️ Requirements ⚠️
You will be asked for a SOPS key if the secrets files are encrypted. 
Your SOPS key should be in `$DEVELOPMENT_DIR/age/keys.txt` on your local machine
It begins with
```
AGE-SECRET-KEY-XXXXX...
```

To start the job, you can run the following commands:
```bash
git clone https://github.com/kalisio-nicolas/planetilerJob
cd planetilerJob
# change the variables if needed
# export AREA=planet
# export S3_PATH=ovh:kargo/data/MBTiles
# export WEBHOOK_URL=https://hooks.slack.com/services/no-webhooks

# Run the project
./run.sh
```


Fast one-liner (if no need to change the variables):

```bash
git clone https://github.com/kalisio-nicolas/planetilerJob && cd planetilerJob && ./run.bash
```