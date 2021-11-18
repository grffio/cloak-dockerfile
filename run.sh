#!/usr/bin/env bash

# Variables
prefix="CK_PROXYBOOK_"
ckserver="/usr/local/bin/ck-server"
confDir="/opt/cloak"
confFile="${confDir}/ckserver.json"

# Check environment variables
_checkEnv() {
    if ! (env | grep -q ${prefix}); then
        echo "Error: not found environment variables \"${prefix}*\", exiting..."
        exit 1
    fi

    if [ -z "${CK_BINDADDR}" ]; then
        CK_BINDADDR="0.0.0.0:443"
    fi
    if [ -z "${CK_REDIRADDR}" ]; then
        CK_REDIRADDR="bing.com"
    fi
    if [ -z "${CK_KEEPALIVE}" ]; then
        CK_KEEPALIVE="0"
    fi
    if [ -z "${CK_DATABASEPATH}" ]; then
        CK_DATABASEPATH="${confDir}/userinfo.db"
    fi
    if [ -z "${CK_ADMINUID}" ]; then
        CK_ADMINUID=$(${ckserver} -u)
    fi
    if [ -z "${CK_BYPASSUID}" ]; then
        CK_BYPASSUID=$(${ckserver} -u)
    fi
    if [ -z "${CK_PRIVATEKEY}" ]; then
        keys=$(${ckserver} -k)
        CK_PRIVATEKEY=$(echo ${keys} | cut -d , -f 2)
        CK_PUBLICKEY=$(echo ${keys} | cut -d , -f 1)
    fi
}

# Preparing system parameters
_sysPrep() {
    if [ ! -d ${confDir} ]; then
        mkdir -p ${confDir}
    fi
}

# Creating config file from variables
_configCreate() {
    proxyBook=""
    for pb in $(compgen -v ${prefix}); do
        # Environment variable is split into name (discarding the prefix) and value
        pbName=$(echo ${pb} | cut -d _ -f 3 | awk '{print tolower($0)}')
        pbValue=$(eval echo \$${pb})

        # Split into two parts by delimiter '://' and the first part is checked for the content of the protocol
        value=$(echo ${pbValue} | sed 's/:\/\//\n/g' | sed -n 1p)
        if [[ ${value} == "tcp" ]] || [[ ${value} == "udp" ]]; then
            proto=${value}
            # The protocol is removed and only the 'host:port' remains
            host=$(echo ${pbValue/'tcp://'})
        else
            proto="tcp"
            host=${value}
        fi

        if [ ! -z ${proxyBook} ]; then
            proxyBook+=" "
        fi

        proxyBook+="${pbName}=$(jo -a "${proto}" "${host}")"
    done

    bindAddr=$(echo ${CK_BINDADDR/,/' '})
    bypassUID=$(echo ${CK_BYPASSUID/,/' '})

    jo -p BindAddr=$(jo -a ${bindAddr})   \
          RedirAddr=${CK_REDIRADDR}       \
          ProxyBook=$(jo ${proxyBook})    \
          PrivateKey=${CK_PRIVATEKEY}     \
          AdminUID=${CK_ADMINUID}         \
          BypassUID=$(jo -a ${bypassUID}) \
          DatabasePath=${CK_DATABASEPATH} \
          KeepAlive=${CK_KEEPALIVE} > ${confFile}
}

# Print client config
_printClientConfig() {
    if [ ! -z ${CK_PUBLICKEY} ]; then
        echo -e "\n#=== Clients Configs Start ===#"
        for proxyMethod in ${proxyBook}; do
            for uid in ${CK_BYPASSUID/,/' '}; do
                jo -p UID=${uid}                 \
                    PublicKey=${CK_PUBLICKEY}  \
                    Transport=direct           \
                    ProxyMethod=$(echo ${proxyMethod} | cut -d '=' -f 1) \
                    EncryptionMethod=plain     \
                    ServerName=${CK_REDIRADDR} \
                    NumConn=4                  \
                    BrowserSig=chrome          \
                    StreamTimeout=300
            done
        done
        echo -e "#=== Clients Configs End ===#\n"
    fi
}

# Starting Cloak
_startCloak() {
    exec /usr/local/bin/ck-server -c ${confFile}
}

_checkEnv
_sysPrep
_configCreate
_printClientConfig
_startCloak
