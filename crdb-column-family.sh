LIB=/Users/rslee/gitHub/crdb-column-family
BIN=~/bin

find $BIN -name "cockroach-*-amd64" | while read dir; do
  version=`echo $dir | awk -F'-' 'NF==4 {print $2} NF==5 {print $2"-"$3}'`
  echo $dir $version

  cp $dir/cockroach $BIN/.
  pkill -9 roachdemo
  pkill -9 cockroach
  rm -rf cockroach-data
  roachdemo -n 3 &
  RDPID=$!

  sleep 10
  cockroach version
  cockroach sql --insecure -e "create database md; set cluster setting rocksdb.min_wal_sync_interval='0ms';"

  rm x.csv
  ~/bin/apache-jmeter-3.2/bin/jmeter -n -t colfam-update-cr.jmx -l x.csv
  awk -F"," -v version=$version 'NR==1 {print "db,scenario," $0 ",threadName2,label2"} NR != 1 { split($3, l, "[- ]"); split($6, t, "[- ]"); print version ",update," $0 "," t[1] "," l[1]}' x.csv > $version-update-cr.csv
  rm x.csv
  ~/bin/apache-jmeter-3.2/bin/jmeter -n -t colfam-upsert-cr.jmx -l x.csv
  awk  -F"," -v version=$version 'NR==1 {print "db,scenario," $0 ",threadName2,label2"} NR != 1 { split($3, l, "[- ]"); split($6, t, "[- ]"); print version ",upsert," $0 "," t[1] "," l[1]}' x.csv > $version-upsert-cr.csv

  kill $RDPID
  pkill -9 cockroach
  rm -rf cockroach-data
done

rm x.csv

test() {
  crdb=`netstat -an | grep -i listen | grep 26257 | wc -l`
  while [[ "$crdb" == "" || $crdb < 1 ]]; do
    echo "waiting for DB to start"
    sleep 1
    crdb=`netstat -an | grep -i listen | grep 26257 | wc -l`
  done

}
