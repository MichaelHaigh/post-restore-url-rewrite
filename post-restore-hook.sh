#!/bin/sh

REGION1="us.gcr.io"
REGION2="eu.gcr.io"

# Loop through non-"astra-hook-deployment" deployments
deploys=$(kubectl get deployments -o json | jq -r '.items[].metadata | select(.name != "astra-hook-deployment") | .name')
for d in ${deploys}; do

    # Loop through the containers within a deployment
    containerNames=$(kubectl get deployment demo-deployment -o json | jq -r '.spec.template.spec.containers[].name')
    for c in ${containerNames}; do

        # Get the image and image region
        full_image=$(kubectl get deployment demo-deployment -o json | jq -r --arg con "$c" '.spec.template.spec.containers[] | select(.name == $con) | .image')
        region=$(echo ${full_image} | cut -d "/" -f -1)
        base_image=$(echo ${full_image} | cut -d "/" -f 2-)

        # Swap the region
        if [[ ${region} == ${REGION1} ]] ; then
            new_region=${REGION2}
        else
            new_region=${REGION1}
        fi

        # Rebuild the image string
        new_full_image=$(echo ${new_region}/${base_image})

        # Update the image
        kubectl set image deployment/${d} ${c}=${new_full_image}
    done
done
