#/bin/sh

set -e

export WORK=`pwd`

rm -rf ./out
mkdir -p ./out
export GOARCH=arm64
export GOOS=darwin

# Gvp
echo "Building gvp..."
rm -rf gvisor-tap-vsock
git clone https://github.com/containers/gvisor-tap-vsock.git
cd gvisor-tap-vsock
git checkout v0.7.5
eval "$(goenv init -)"
goenv install 1.22.0 -s
goenv shell 1.22.0
make gvproxy
mv ./bin/gvproxy $WORK/out/gvproxy

# krun
echo "Dwonloading krun..."
cd $WORK
rm -rf ./krunkit
mkdir -p krunkit
cd krunkit
gh release download v0.1.3 -R containers/krunkit --pattern "krunkit-*" --clobber
tar -zxvf krunkit-*.tgz -C ./
mv bin/krunkit $WORK/out/krunkit
mv lib/* $WORK/out/

cd $WORK

# codesign
echo "Signing gvproxy..."
codesign --force --sign $CODESIGN_IDENTITY --timestamp $WORK/out/gvproxy

echo "Signing krunkit..."
codesign --force --sign $CODESIGN_IDENTITY --timestamp --entitlements krunkit.entitlements $WORK/out/krunkit

find $WORK/out -name "*.dylib" -type f -exec sh -c "echo 'Signing {}...'; codesign --force --sign $CODESIGN_IDENTITY --timestamp {}" ';'

# pack
tar -czvf ./libexec-$GOOS-$GOARCH.tar.gz -C ./out/ .