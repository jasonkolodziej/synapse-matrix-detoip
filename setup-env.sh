echo "Setting up your environmental file..."
echo
{
echo POSTGRES_PASSWORD=$(openssl rand -base64 32) >> .env
echo FQDN=$1 >> .env # my.server.com
echo SYNAPSE_REPORT_STATS=$2 >> .env # `no` or `yes`
echo SYNAPSE_ENABLE_REGISTRATION=$3 >> .env # `True`, `1` or `False`, `0`
echo PROTOCOL=$4 >> .env  # http or https for production
} &> /dev/null
echo
echo "Please check the '.env' file created before continuing..."