
function install_openjdk() {
    OPENJDK_VERSION=$1
    echo "Installing OpenJDK ${OPENJDK_VERSION}"
    JDK_OS=linux
    COMPONENTS_TO_STRIP=1 # e.g. openjdk-11.0.3+7/bin/java
    DOWNLOAD_URL=$(curl --silent -X GET "https://api.adoptopenjdk.net/v3/assets/feature_releases/${OPENJDK_VERSION}/ga?architecture=x64&heap_size=normal&image_type=jdk&jvm_impl=hotspot&os=${JDK_OS}&page=0&page_size=1&project=jdk&sort_method=DEFAULT&sort_order=DESC&vendor=adoptopenjdk" \
        -H "accept: application/json" \
        | jq -r ".[0].binaries[0].package.link")
    OPENJDK_ARCHIVE=$(basename ${DOWNLOAD_URL})
    CACHE_DIR=${HOME}/.cache/openjdk
    TARGET_DIR=${HOME}/openjdk${OPENJDK_VERSION}
    mkdir -p ${CACHE_DIR}
    mkdir -p ${TARGET_DIR}
    if [ ! -e ${CACHE_DIR}/${OPENJDK_ARCHIVE} ]; then
        echo "Downloading from ${DOWNLOAD_URL} to ${CACHE_DIR}"
        curl --location --output ${CACHE_DIR}/${OPENJDK_ARCHIVE} "${DOWNLOAD_URL}"
    else
        echo "Skipped download, file ${CACHE_DIR}/${OPENJDK_ARCHIVE} already exists"
    fi
    tar --extract --file ${CACHE_DIR}/${OPENJDK_ARCHIVE} -C ${TARGET_DIR} --strip-components=${COMPONENTS_TO_STRIP}
    export JAVA_HOME="${TARGET_DIR}"
    export PATH="${TARGET_DIR}/bin:${PATH}"
    java -version
    echo "Java is available at ${TARGET_DIR}"
}
