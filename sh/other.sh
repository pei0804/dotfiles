# Google Cloud SDK
wget -O $HOME/google-cloud-sdk.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-159.0.0-darwin-x86_64.tar.gz
tar xvzf $HOME/google-cloud-sdk.tar.gz -C $HOME
sudo chmod -R 777 $HOME/google-cloud-sdk
$HOME/google-cloud-sdk/install.sh --quiet
gcloud components update
gcloud components install beta -q

# node.js
curl -L git.io/nodebrew | perl - setup
nodebrew install-binary v8
nodebrew use v8