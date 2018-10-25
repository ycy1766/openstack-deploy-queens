#!/bin/bash


DOWNLOAD_URL="https://cloud.centos.org/centos/7/images"
IMG_ZIP="CentOS-7-x86_64-GenericCloud-1801-01.raw.tar.gz"
IMG_NAME="CentOS-7-x86_64-GenericCloud-1801-01.raw"
HASH_TXT="sha256sum.txt"

GLANCE_NAME="CentOS7_1801"

DOWNLOAD_DIR="/tmp/"
IMG_LOCAL_PATH="${DOWNLOAD_DIR}/${IMG_ZIP}"


unset LANG
unset LANGUAGE
LC_ALL=C
export LC_ALL

for i in curl openstack; do
    if [[ ! $(type ${i} 2>/dev/null) ]]; then
        if [ "${i}" == 'curl' ]; then
            echo -e "\e[31mPlease install ${i} before proceeding\e[0m"
        else
            echo -e "\e[31mPlease install python-${i}client before proceeding\e[0m"
        fi
        exit
    fi
done

# Test for credentials set
if [[ "${OS_USERNAME}" == "" ]]; then
    echo -e "\e[31mNo Keystone credentials specified.  Try running source openrc\e[31m"
    exit
fi

# Test to ensure configure script is run only once
if openstack image list | grep -q ${GLANCE_NAME}; then
    echo -e "\e[31mThe ${GLANCE_NAME} image is already existed\e[31m"
    exit
fi

echo -e "\e[32mDownloading glance image.\e[0m"
if ! [ -f "${IMG_LOCAL_PATH}" ]; then
    curl -L -o ${DOWNLOAD_DIR}/${IMG_ZIP} ${DOWNLOAD_URL}/${IMG_ZIP}
fi

if ! [ -f "${HASH_TXT}" ]; then
    curl -L -o ${DOWNLOAD_DIR}/${HASH_TXT} ${DOWNLOAD_URL}/${HASH_TXT}
fi

IMG_HASH=$(egrep ${IMG_ZIP} ${DOWNLOAD_DIR}/${HASH_TXT} | awk '{print $1}')
IMG_HASH_DOWNLOADED=$(sha256sum ${DOWNLOAD_DIR}/${IMG_ZIP} | awk '{print $1}')


if [[  ${IMG_HASH} != ${IMG_HASH_DOWNLOADED} ]]; then
    echo "Downloading image is wrong... Plz, try again."
    exit 1
fi
echo "Complete to download image file"

echo -e "\e[32mUntar ${IMG_ZIP}\e[0m"
tar xfz ${DOWNLOAD_DIR}/${IMG_ZIP} \
    --directory ${DOWNLOAD_DIR}/

echo -e "\e[32mCreating glance image.\e[0m"
openstack image create \
    --disk-format raw \
    --container-format bare \
    --public \
    --file ${DOWNLOAD_DIR}/${IMG_NAME} ${GLANCE_NAME}

echo -e "\e[32mDelete ${DOWNLOAD_DIR}/${IMG_NAME}\e[0m"
rm -f ${DOWNLOAD_DIR}/${IAG_NAME}
