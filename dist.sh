cd "$( dirname "$0" )"
xcodebuild
cd build/Release
zip -vr mcsm.zip MCServMan.app
/Users/tigra/Desktop/Coding/Sparkle\ 1.5b6/Extras/Signing\ Tools/sign_update.rb mcsm.zip /Users/tigra/Desktop/Coding/Sparkle\ 1.5b6/Extras/Signing\ Tools/dsa_priv.pem > sign.txt
ls -l mcsm.zip >> sign.txt
rm -r *.app
rm *.dSYM
open .