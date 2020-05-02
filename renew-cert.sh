_domain_to_renew=
if [ $# -eq 0 ]
  then
	echo
    echo "No arguments supplied, i.e. 'my.example.com'"
	echo "checking '.env' file for FQDN"
	echo
	source '.env'
	if [ -z "${FQDN}" ]
	  then
	  	echo "There is no such evironmental variable 'FQDN'"
		echo "This is needed to continue...good bye!"
		exit -1
	  else
	  	_domain_to_renew=${FQDN}
	fi
  else
	_domain_to_renew=$1
fi
echo "running docker to update ~> $_domain_to_renew"
docker run -it --rm \
	-v /${PWD}/certs:/etc/letsencrypt \
	-v /${PWD}/certs-data:/data/letsencrypt \
	deliverous/certbot       certonly \
	--webroot --webroot-path=/data/letsencrypt -d $_domain_to_renew
