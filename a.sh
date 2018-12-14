#!/bin/bash
workDir="$HOME/sportskeeda"
feedsDir="feeds"
masterCSV="$workDir/sk_csv_master.csv"
if [ ! -d "$workDir/$feedsDir" ]; then
	echo "[WARN] $workDir/$feedsDir is not present, creating it."
	mkdir -p "$workDir/$feedsDir"
fi
if [ ! -f "$masterCSV" ]; then
		echo "[WARN] $masterCSV is not present, creating it."
		touch $masterCSV
		echo -e "\"id\",\"post_title\",\"url\",\"category\",\"no_reads\"\n" > $masterCSV
fi
curFileName="sk_csv_`date '+%H:%M_%d_%m_%Y'`.csv"
output=`curl https://login.sportskeeda.com/en/feed?page=1`
if [ $? -eq 0 ]; then
		parsedOutput=`echo "$output" | jq -r '[.cards | .[] | {id: .ID, post_title: .title, url: .permalink, category: .category[], no_reads: .read_count}] |(.[0] | keys_unsorted) as $keys | ([$keys] + map([.[ $keys[]]])) [] | @csv'`
		if [ $? -eq 0 ]; then
			echo "$parsedOutput" > "$workDir/$feedsDir/$curFileName"
			parsedOutput=`echo "$parsedOutput" | tail -n +2`
			while IFS= read -r line; do
					id=`echo "$line" | cut -d ',' ,f 1`
					isPresent=`cat $masterCSV | grep "$id"`
					if [ -n "$isPresent" ]; then
							sed -i '/'"$id"'./c\'"$line" $masterCSV
						else
							sed -i "2i $line" $masterCSV
						fi
					done <<< "$parsedOutput"
				else
					echo "[ERROR] Failed to parse json response"
					exit 1
				fi
else
			echo "[ERROR] Failed to get any response fromthe site"
		fi
