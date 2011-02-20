while read line
do
	echo $line
	md5=$(md5 -s $line|cut -d ' ' -f 4)
	if ! test -f png/$md5.png 
	then
		bundle exec webshooter "$line" --output=png/$md5.png --delay=5
	else
		echo "cache $md5"
	fi	
done < "devops-urls.txt"
