# Worker Nodes Setup

## System Requirements for Worker Nodes

## Minimum Requirements
To ensure basic functionality of the Worker Node, your system should meet the following minimum specifications:

| **Hardware** | **Minimum Requirement** |
|--------------|-------------------------|
| **CPU**      | 8 VCPU Cores                 |
| **RAM**      | 16 GB RAM                   |
| **Disk**     | 300 GB SSD                 |
| **Port**| 5011 needs to be open (Can be changed to any Port)


**Register Acount**
https://workers.brinxai.com/register.php


# Useful command

Delete and Stop
```sh
pattern="admier/brinxai_nodes"
echo "Mencari kontainer dengan pola: ${pattern}"
containers=$(docker ps --format "{{.ID}} {{.Image}} {{.Names}}" | grep "${pattern}")
if [ -z "$containers" ]; then
    echo "Tidak ada kontainer yang sesuai ditemukan."
    exit 0
fi
echo "Kontainer yang ditemukan:"
echo "$containers"
container_ids=$(echo "$containers" | awk '{print $1}')
echo "ID kontainer yang ditemukan:"
echo "$container_ids"
docker stop $container_ids && docker rm $container_ids
```