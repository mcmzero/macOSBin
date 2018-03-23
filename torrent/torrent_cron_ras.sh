# /etc/cron.d/torrent: crontab fragment for torrent
#  This purges session files in session.save_path older than X,
#  where X is defined in seconds as the largest value of
#  session.gc_maxlifetime from all your SAPI php.ini files
#  or 24 minutes if not defined.  The script triggers only
#  when session.save_handler=files.
#
#  WARNING: The scripts tries hard to honour all relevant
#  session PHP options, but if you do something unusual
#  you have to disable this script and take care of your
#  sessions yourself.
MAILTO=""

# m h dom mon dow user  command
51 */6		* * *		pi	/usr/local/bin/upgrade.sh

# Clean up magnet list
07 */2		* * *		pi	/usr/local/torrent/build_bbc_news_m3u.sh

# Look for and purge old sessions every 5 minutes
*/2 *		* * *		pi	/usr/local/torrent/torrent.sh purge
*/2  *		* * *		pi	/usr/local/torrent/torrent.sh dispose
00 */12		* * *		pi	/usr/local/torrent/torrent.sh login

# 예능, 드라마
00,30 16-23,0-9	* * 1-5		pi	/usr/local/torrent/torrent.sh cor ent 1
00,30 *		* * 6,7		pi	/usr/local/torrent/torrent.sh cor ent 1
00,30 16-23,0-9	* * 1-5		pi	/usr/local/torrent/torrent.sh cor drama 1
00,30 *		* * 6,7		pi	/usr/local/torrent/torrent.sh cor drama 1

10,40 16-23,0-9    * * 1-5         pi      /usr/local/torrent/torrent.sh kim ent 1
10,40 *            * * 6,7         pi      /usr/local/torrent/torrent.sh kim ent 1
10,40 16-23,0-9    * * 1-5         pi      /usr/local/torrent/torrent.sh kim drama 1
10,40 *            * * 6,7         pi      /usr/local/torrent/torrent.sh kim drama 1

20,50 16-23,0-9    * * 1-5         pi      /usr/local/torrent/torrent.sh pon ent 1
20,50 *            * * 6,7         pi      /usr/local/torrent/torrent.sh pon ent 1
20,50 16-23,0-9    * * 1-5         pi      /usr/local/torrent/torrent.sh pon drama 1
20,50 *            * * 6,7         pi      /usr/local/torrent/torrent.sh pon drama 1

# 일일
00 11-15	* * 1-5		pi	/usr/local/torrent/torrent.sh cor 4 1 1 720 TV소설
20 11-15	* * 1-5		pi	/usr/local/torrent/torrent.sh kim 4 1 1 720 TV소설
40 11-15	* * 1-5		pi	/usr/local/torrent/torrent.sh pon 4 1 1 720 TV소설
10 11-15	* * 1-5		pi	/usr/local/torrent/torrent.sh cor 4 1 1 720 인간극장
30 11-15	* * 1-5		pi	/usr/local/torrent/torrent.sh kim 4 1 1 720 인간극장
50 11-15	* * 1-5		pi	/usr/local/torrent/torrent.sh pon 4 1 1 720 인간극장

# 수요일(3)
# download kim count start_page end_page quality search
00 01		* * 4,5		pi	/usr/local/torrent/torrent.sh cor 4 1 1 360 영재발굴단
05 01		* * 4,5		pi	/usr/local/torrent/torrent.sh kim 4 1 1 360 영재발굴단
10 01		* * 4,5		pi	/usr/local/torrent/torrent.sh pon 4 1 1 360 영재발굴단

# 금요일(5)
*/20 21-23	* * 5		pi	/usr/local/torrent/torrent.sh kim 4 1 1 720 Comedy TV 맛있는 녀석들.E
00 01-02	* * 6,7		pi	/usr/local/torrent/torrent.sh kim 4 1 1 720 Comedy TV 맛있는 녀석들.E
*/20 21-23	* * 5		pi	/usr/local/torrent/torrent.sh pon 4 1 1 720 Comedy TV 맛있는 녀석들.E
10 01-02	* * 6,7		pi	/usr/local/torrent/torrent.sh pon 4 1 1 720 Comedy TV 맛있는 녀석들.E
