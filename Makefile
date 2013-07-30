berlin-inhabitants.png: top10women.dat
	@gnuplot berlininhabitants.plt
	@convert -rotate 90 $@ $@
	@rm -f berlininhabitants-dirty.csv berlininhabitants-dos.csv berlininhabitants-dos.zip
 
top10women.dat: berlininhabitants-2011.dat
	@awk '{if ($$2 ~ f){A[$$1] += count[$$2]++} next} END {for(i in A){ print i, A[i] }}' $< | \
	 sort -nr -k2 | \
   head -10 > $@

berlininhabitants-2011.dat: berlininhabitants-2011.csv
	@awk -F'";"' '{print $$2 "  " $$3}' $< | \
	 sed -e 's/"//g' \
	     -e '1d' > $@

berlininhabitants-2011.csv: berlininhabitants-dirty.csv
	@cut -d";" -f2,4-8 $< | \
	 sed 's/"1"/"m"/;s/"2"/"f"/' | \
	 awk -F';' '{ print $$1 ";" $$2 ";" $$3 ";" $$4 ";" $$5 ";" "\"" $$6 "\"";}' | \
	 sed -e '1d' \
	     -e '2i "official_district";"district";"gender";"nationality";"age";"quantity"' \
	      > $@

berlininhabitants-dirty.csv: berlininhabitants-dos.csv
	@tr -d '\r' < $< | \
	 iconv -f iso-8859-1 -t utf-8 > $@

berlininhabitants-dos.csv:
	@wget --no-check-certificate \
	  https://www.statistik-berlin-brandenburg.de/produkte/opendata/EWR_Ortsteile_2011-12-31.zip \
	  -O berlininhabitants-dos.zip 2>/dev/null || true
	@unzip -p berlininhabitants-dos.zip > $@

clean:
	rm -f berlininhabitants-dirty.*
	rm -f berlininhabitants-dos.*
	rm -f berlininhabitants-2011.*
	rm -f berlin-inhabitants.png
