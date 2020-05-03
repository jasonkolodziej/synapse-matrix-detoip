_both=0
_ran_init=0
# Script to check the alias output
shopt -s expand_aliases
alias docker-compose='docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD:$PWD" \
    -w="$PWD" \
    docker/compose:latest'

if [ $# -eq 0 ]
then
    echo "No argument supplied, initializing ALL servers."
    _both=1
fi

if [[ $1 == "nginx" || $_both -eq 1 ]]
then
    echo "Initializing nginx server..."
    docker-compose -f docker-compose.init-nginx.yml up -d
    _ran_init=1
fi

if [[ $1 == "matrix" || $_both -eq 1 ]]
then
    echo "Initializing matrix server..."
    source '.env'
    docker run -it --rm -v /${PWD}/files:/data \
     -e SYNAPSE_SERVER_NAME=${FQDN} \
     -e SYNAPSE_REPORT_STATS=${SYNAPSE_REPORT_STATS} \
     -e SYNAPSE_ENABLE_REGISTRATION=${SYNAPSE_ENABLE_REGISTRATION} \
     -e POSTGRES_DB=postgres \
     -e POSTGRES_USER=matrix_synapse \
     -e SYNAPSE_NO_TLS=1 \
     -e SYNAPSE_MAX_UPLOAD_SIZE=100M \
     matrixdotorg/synapse:latest generate
    echo
    echo "WARNING:"
    echo "At this time please edit the './files/homeserver.yaml' config file"
    echo "Before continuing to run the matrix-synapse server image..."
    echo
    echo
    _ran_init=1
fi

if [ $_ran_init -eq 0 ]
then
    echo "Did not initialize any servers..."
else
    echo "Server(s) initialized..."
fi