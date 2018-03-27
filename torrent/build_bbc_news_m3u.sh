#!/bin/bash
# build_bbc_news_m3u.sh <changmin811@gmail.com>

COOKIE_BBC=/usr/local/torrent/cookie_bbc

if [ "$1" == "login" ]; then
    #curl -s https://www.giniko.com/signout.php -b /usr/local/torrent/cookie_bbc
    #curl -c $COOKIE_BBC -s http://www.giniko.com/login.php -d 'username=mcmlast@gmail.com' -d 'password=ofaids'
    #cat $COOKIE_BBC
    exit
fi

curl -s http://www.giniko.com/watch.php?id=216|grep playlist.m3u8|head -n1|sed -e 's/.*src="//' -e 's/">//' > /mnt/rasPiTorrent/torrent/방송/"BBC World News.m3u"
echo '#EXTINF:-1 tvg-id="id1" tvg-name="BBC World News" group-title="BBC",BBC World News' > /mnt/rasPiTorrent/torrent/방송/BBC.m3u
cat /mnt/rasPiTorrent/torrent/방송/"BBC World News.m3u" >> /mnt/rasPiTorrent/torrent/방송/BBC.m3u

curl -s http://www.giniko.com/watch.php?id=27|grep playlist.m3u8|head -n1|sed -e 's/.*src="//' -e 's/">//' > /mnt/rasPiTorrent/torrent/방송/"BBC News.m3u"
echo '#EXTINF:-1 tvg-id="id2" tvg-name="BBC News" group-title="BBC",BBC News' >> /mnt/rasPiTorrent/torrent/방송/BBC.m3u
cat /mnt/rasPiTorrent/torrent/방송/"BBC News.m3u" >> /mnt/rasPiTorrent/torrent/방송/BBC.m3u

#curl -b $COOKIE_BBC -s http://www.giniko.com/watch.php?id=189|grep playlist.m3u8|head -n1|sed -e 's/.*src="//' -e 's/">//' > /mnt/rasPiTorrent/torrent/방송/"BBC One.m3u"
#echo '#EXTINF:-1 tvg-id="id6" tvg-name="BBC One" group-title="BBC",BBC One' >> /mnt/rasPiTorrent/torrent/방송/BBC.m3u
#cat /mnt/rasPiTorrent/torrent/방송/"BBC One.m3u" >> /mnt/rasPiTorrent/torrent/방송/BBC.m3u

curl -s http://www.giniko.com/watch.php?id=190|grep playlist.m3u8|head -n1|sed -e 's/.*src="//' -e 's/">//' > /mnt/rasPiTorrent/torrent/방송/"BBC Two.m3u"
echo '#EXTINF:-1 tvg-id="id3" tvg-name="BBC Two" group-title="BBC",BBC Two' >> /mnt/rasPiTorrent/torrent/방송/BBC.m3u
cat /mnt/rasPiTorrent/torrent/방송/"BBC Two.m3u" >> /mnt/rasPiTorrent/torrent/방송/BBC.m3u

curl -s http://www.giniko.com/watch.php?id=191|grep playlist.m3u8|head -n1|sed -e 's/.*src="//' -e 's/">//' > /mnt/rasPiTorrent/torrent/방송/"BBC Three.m3u"
echo '#EXTINF:-1 tvg-id="id4" tvg-name="BBC Three" group-title="BBC",BBC Three' >> /mnt/rasPiTorrent/torrent/방송/BBC.m3u
cat /mnt/rasPiTorrent/torrent/방송/"BBC Three.m3u" >> /mnt/rasPiTorrent/torrent/방송/BBC.m3u

#curl -b $COOKIE_BBC -s http://www.giniko.com/watch.php?id=26|grep playlist.m3u8|head -n1|sed -e 's/.*src="//' -e 's/">//' > /mnt/rasPiTorrent/torrent/방송/"CNN International.m3u"
#echo '#EXTINF:-1 tvg-id="id5" tvg-name="CNN International" group-title="CNN",CNN International' >> /mnt/rasPiTorrent/torrent/방송/BBC.m3u
#cat /mnt/rasPiTorrent/torrent/방송/"CNN International.m3u" >> /mnt/rasPiTorrent/torrent/방송/BBC.m3u

cp -a /mnt/rasPiTorrent/torrent/방송/BBC.m3u /mnt/rasPiTorrent/torrent/Kodi/BBC.m3u
