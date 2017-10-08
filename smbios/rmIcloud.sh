cd ~/Library/Caches
rm -rf com.apple.iCloudHelper*
rm -rf com.apple.imfoundation.IMRemoteURLConnectionAgent*
rm -rf com.apple.Message*

cd ~/Library/Preferences
sudo rm -rf com.apple.iChat.*
sudo rm -rf com.apple.icloud.*
sudo rm -rf com.apple.imagent.*
sudo rm -rf com.apple.imessage.*
sudo rm -rf com.apple.imservice.*
sudo rm -rf com.apple.ids.service*
sudo rm -rf com.apple.identityserviced*
sudo rm -rf com.apple.security.*

echo ==============
echo cd /Library/Preferences/SystemConfiguration
echo sudo rm -f NetworkInterfaces.plist
echo sudo rm -f preferences.plist
