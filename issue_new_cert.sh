#!/bin/bash
THISPW=$(cat $HOME/.pw)
HTML_DIR=/var/dockerdata/www_data
LOCALVOL=/var/lib/docker/volumes/certs/_data
TARGETVOL=/var/dockerdata/certs

DOMAIN=rojter.tech
LOCAL=$LOCALVOL/$DOMAIN
TARGET=$TARGETVOL/$DOMAIN

docker run -it --rm \
    -v certs:/acme.sh \
    -v $HTML_DIR:/www-data \
    rojtertech/acme --issue \
	-d $DOMAIN \
	-d code.$DOMAIN \
	-d dns.$DOMAIN \
	-d nas.$DOMAIN \
	-d www.$DOMAIN \
	-w /www-data

sleep 10
sudo mkdir -p $TARGET
sudo cp -r $LOCAL $TARGETVOL
sudo chmod 777 $TARGET
sudo find $TARGET -exec sudo chmod 777 {} \;

mv $TARGET/ca.cer $TARGET/chain.pem
mv $TARGET/$DOMAIN.conf $TARGET/domain.conf
mv $TARGET/$DOMAIN.csr.conf $TARGET/domain.csr.conf
mv $TARGET/fullchain.cer $TARGET/fullchain.pem
mv $TARGET/$DOMAIN.cer $TARGET/cert.pem
mv $TARGET/$DOMAIN.csr $TARGET/domain.csr
mv $TARGET/$DOMAIN.key $TARGET/privkey.pem

sudo openssl pkcs12 -export -nodes \
	-in $TARGET/fullchain.pem \
	-inkey $TARGET/privkey.pem \
	-out $TARGET/plex.pfx \
	-name "plex/pfx" \
	-passout pass:$THISPW

sudo find $TARGET -exec sudo chmod 777 {} \;
rsync -av $TARGET/* dreuter@debian.rojter.lo:$TARGET/
