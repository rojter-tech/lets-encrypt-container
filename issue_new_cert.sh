#!/bin/bash
echo "Execution timestamp: $(date)"
THISPW=$(cat $HOME/.pw)
HTML_DIR=/var/dockerdata/www_data
LOCALVOL=/var/lib/docker/volumes/certs/_data
TARGETVOL=/var/dockerdata/certs

DOMAIN=rojter.tech
LOCAL=$LOCALVOL/$DOMAIN
TARGET=$TARGETVOL/$DOMAIN

echo "Initializing docker engine to renew cert ..."
docker run -i --rm \
	-v certs:/acme.sh \
    	-v $HTML_DIR:/www-data \
    	rojtertech/acme --issue \
	-d $DOMAIN \
	-d code.$DOMAIN \
	-d dns.$DOMAIN \
	-d nas.$DOMAIN \
	-d www.$DOMAIN \
	-w /www-data

sleep 30
sudo mkdir -p $TARGET
sudo chmod 777 $TARGET
sudo chown $USER:$USER $TARGET
sudo cp -r $LOCAL $TARGETVOL
sudo chmod 777 $TARGET
sudo find $TARGET -exec sudo chmod 777 {} \;
sudo find $TARGET -exec sudo chown $USER:$USER {} \;

sudo mv $TARGET/ca.cer $TARGET/chain.pem
sudo mv $TARGET/$DOMAIN.conf $TARGET/domain.conf
sudo mv $TARGET/$DOMAIN.csr.conf $TARGET/domain.csr.conf
sudo mv $TARGET/fullchain.cer $TARGET/fullchain.pem
sudo mv $TARGET/$DOMAIN.cer $TARGET/cert.pem
sudo mv $TARGET/$DOMAIN.csr $TARGET/domain.csr
sudo mv $TARGET/$DOMAIN.key $TARGET/privkey.pem

sudo openssl pkcs12 -export -nodes \
	-in $TARGET/fullchain.pem \
	-inkey $TARGET/privkey.pem \
	-out $TARGET/plex.pfx \
	-name "plex/pfx" \
	-passout pass:$THISPW

sudo find $TARGET -exec sudo chmod 777 {} \;
sudo find $TARGET -exec sudo chown $USER:$USER {} \;
rsync -av $TARGET/* dreuter@debian.rojter.lo:$TARGET/
