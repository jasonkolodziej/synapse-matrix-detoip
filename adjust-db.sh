_file=homeserver.yaml
_db_user_name=matrix_synapse
echo "Adjusting the DB tag in './files/homeserver.yaml'..."
echo
echo "Adding to $_file file..."
source '.env'
{
sudo cat <<-EOF >> ${PWD}/files/homeserver.yaml

database:
    name: psycopg2
    args:
        user: $_db_user_name
        password: ${POSTGRES_PASSWORD}
        database: $_db_user_name
        host: db
        cp_min: 5
        cp_max: 10

EOF
}&> /dev/null

echo
echo "Done. Please check..."