docker-phabricator
=========

Dockerfile and associated files for setting up Phabricator in a Docker container.

I put this together by referencing various other docker setups and of course the Phabricator documentation.

For the database I use a linked MySQL container running the official MySQL 5.6 image.

This is the run command I use in a bash script to start the container:

```
docker run \
    -p $SSHPORT:22 -p $PORT:80 \
    -v $basedir/repo:/var/repo \
    -v $basedir/storage:/var/storage \
    -v $basedir/conf:/opt/phabricator/conf \
    --link mysql:mysql \
    --restart=unless-stopped \
    --name phabricator \
    -d phabricator
```

As can be seen from this command, I've made the external ssh port and web port configurable.  I've also chosen to map the repo and storage directories as volumes from the local directory.  Additionally the phabricator config files are stored locally and mapped into the container.  The MySQL container is linked as I mentioned above.
