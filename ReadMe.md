# Jupyter kernel for DeltaQ

A customized Jupyter iHaskell kernel for use with the [dq-revamp](https://github.com/DeltaQ-SD/dq-revamp) tool.


# Running a Jupyter server using Nix

Launch Jupyter with the iHaskell kernel including the `deltaq` and `probability-polynomial` packages:

```bash
nix run
```


## Docker


### Building a docker image using Nix

First build the image.

```console
$ nix build -o deltaq-jupyter-docker.tar.gz .#docker

$ docker load --quiet < deltaq-jupyter-docker.tar.gz
Loaded image: localhost/jupyter-deltaq:rzx6x5vnkz3my987higzf5rcmkfasss5
```


### Push to docker registry

You can push the image to a registry.

```bash
docker push localhost/jupyter-deltaq:rzx6x5vnkz3my987higzf5rcmkfasss5 \
            docker.io/bwbush/jupyter-deltaq:rzx6x5vnkz3my987higzf5rcmkfasss5
```


### Run the server in docker.

You can run the local image, exposing the service on port 9999 for example.

```bash
docker run --publish 9999:8888 localhost/jupyter-deltaq:rzx6x5vnkz3my987higzf5rcmkfasss5
```

The default password is `deltaq`. You can change this by visiting http://localhost:9999/lab in a web browser. Alternatively, you can use with the default password by visiting http://localhost:9999/lab?token=deltaq.
