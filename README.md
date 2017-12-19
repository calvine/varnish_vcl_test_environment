# This is a simple docker-compose based VCL test environment

## The Varnish version used in this is 2.1.5 which is the version most compatible with fastly's custom version of Varnish.

### This is just using docker-compose, so you can easily operate it that way, or you can use the bash scripts I have included.

#### Note: The vcls folder in the varnish folder is mounted as a volume to the varnish container, so you can modify the files and the changes are reflected in the varnish container.

```bash
./restart_system.sh # This script shuts the docker-compose containers down and forces the rebuild of the containers, and the starts up the all of the docker-compose containers.
```

```bash
./rebuild_containers.sh # This script shuts down the docker-compose containers and forces the rebuild of the containers.
```

```bash
./run_varnish_log.sh # This script will run the varnishlog utility on the varnish container while the docker-compose containers are running.
```


```bash
./start_system_with_bash_prompt_for_varnish.sh # This scrit starts the docker-compose containers individually and starts the varnish container with a bash prompt instead of starting the caching servie.
```