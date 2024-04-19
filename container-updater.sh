#!/bin/bash

REGISTRY=""

SERV_LIST=("<Image Name> <Host Post>:<Port> <Host Path to mount>:<Path>")

FORMAT_DATE=`date '+%Y-%m-%d %H:%M:%S' `

check_latest_image() {
    local image_name=$1

    old_image_info=$(docker images "$image_name" --format "{{.ID}}")

    docker pull "$image_name" --quiet

    new_image_info=$(docker images "$image_name" --format "{{.ID}}")

    if [ "$old_image_info" != "$new_image_info" ]; then
        return 0 # latest
    else
        return 1
    fi
}

run_container() {
    local image=$1
    local container_name=$2
    local port_mapping=$3
    local mount=$4

    ## TODO optmize to check running container image version whether latest
    
    # check exist
    if docker ps -a --format '{{.Names}}' | grep -q "^$container_name$"; then
        docker rm -f $container_name
    fi
    docker run --name $container_name -d -p $port_mapping -v $mount --restart unless-stopped $image
}

for item in "${SERV_LIST[@]}"; do
    IMAGE=$(awk '{print $1}' <<< "$item")
    PORT_MAPPING=$(awk '{print $2}' <<< "$item")
    MOUNT=$(awk '{print $3}' <<< "$item")

    printf "${FORMAT_DATE} \e[32m Check service:\e[0m [$IMAGE] \n"

    if check_latest_image "${REGISTRY}/${IMAGE}"; then
        echo "Update docker image"
        docker pull ${REGISTRY}/${IMAGE}
        # docker stop $IMAGE
        # docker rm $IMAGE
        # echo "run: $IMAGE"
        # docker run --name $serv -d -p $PORT_MAPPING --restart unless-stopped $REGISTRY/$IMAGE
        run_container ${REGISTRY}/${IMAGE} ${IMAGE} ${PORT_MAPPING} ${MOUNT}
    fi
done

exit
