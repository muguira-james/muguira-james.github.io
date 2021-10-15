

for OUTPUT  in $(ls source/_drafts)
do
	S0="$(echo $OUTPUT | cut -d'.' -f1)"
	hexo publish $S0
done

