# PlanetTiler OSM job

Download and process OSM pbfs from Geofabrik for a given area and upload the resulting mbtiles to S3.

## Variables

There are two variables that can be changed in this project:

| Variable     | Description                                                                                     | Default Value                  |
|--------------|-------------------------------------------------------------------------------------------------|--------------------------------|
| `AREA`       | This variable defines the area to download and process. The default value is `planet`.         | `planet`                       |
| `S3_PATH`    | This variable specifies the S3 path to upload the mbtiles file. The default value is `ovh:kargo/data/MBTiles`. | `ovh:kargo/data/MBTiles`       |
| `WEBHOOK_URL`| This variable specifies the webhook URL for the project. The default value is in the secrets file and can be overridden. | Secrets file value |
| `SOPS_AGE_KEY`| This variable specifies the SOPS age key. It will be prompted during the program execution if the secrets files are encrypted. To avoid waiting for the prompt, you can directly set this variable in the environment. | None |

## Running the Project


### ⚠️ Requirements ⚠️
You will need a AGE SOPS key to decrypt the secrets file in case they are still encrypted.

Wait for the prompt to enter the key or set the `SOPS_AGE_KEY` variable in the environment.

Your SOPS key should be in `$DEVELOPMENT_DIR/age/keys.txt` on your local machine.

The key should look like this:
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
git clone https://github.com/kalisio-nicolas/planetilerJob && cd planetilerJob && ./run.sh
```