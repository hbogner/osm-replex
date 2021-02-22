#!/bin/bash
#

#time setup
today=$(date +"%Y%m%d")
yesterday=$(date +"%Y%m%d" --date='yesterday')
daysago=$(date +"%Y%m%d" --date='2 day ago')
olddate=$(date +"%Y%m%d" --date='30 days ago')
#hour in day, needed for daiyl export vs regular export
hour=$(date +%H)
#simulates midnight for testing
#hour=00
#first day of month, needed for monthly export
dayom01=$(date +%d)
#simulates firsf of month for testing
#dayom01=01

#replex folders
REPLEX=/osm/osm-replex
EUROPE=$REPLEX/europe
DATA=$REPLEX/data
CACHE=$REPLEX/cache
POLY=$REPLEX/poly
STATS=$REPLEX/stats
#www-data folders
WEB=/osm/www-data
PBF=$WEB/osm
FLOODS=$WEB/floods
GIS=$WEB/gis_exports
#www-tms folders
TMS=/osm/www-tms
#aplikacije
osmosis=$REPLEX/bin/osmosis/bin/osmosis
osmconvert=$REPLEX/bin/osmconvert
osmfilter=$REPLEX/bin/osmfilter
MKGMAP=$REPLEX/bin/mkgmap/mkgmap.jar
SPLITTER=$REPLEX/bin/splitter/splitter.jar
OSMANDMC=$REPLEX/bin/osmandmc
OGR2OGR=/usr/bin/ogr2ogr
#Ram za java aplikacije
RAM=5G
#fajlovi
LOG=$REPLEX/replex.log
CHANGESET=changeset-hour.osc.gz
CHANGESETSIMPLE=changeset-hour-simple.osc.gz
#statistike
korisnici=$STATS/korisnici.txt
korisnici_n=$STATS/korisnici_n.txt
korisnici_wr=$STATS/korisnici_wr.txt
svikorisnici=$STATS/korisnici_svi.txt
korpod=$STATS/korisnici_podatci.txt
korstat1=$STATS/korisnici_statistike_1.txt
korstat2=$STATS/korisnici_statistike_2.txt
statistike=$STATS/statistike.htm

#OLDSTATE=state.txt
OLDTIMESTAMP=$(cat state.txt | grep timestamp | awk -F "=" '{print $2}')
OLDYEAR=${OLDTIMESTAMP:0:4}
OLDMONTH=${OLDTIMESTAMP:5:2}
OLDDAY=${OLDTIMESTAMP:8:2}
OLDHOUR=${OLDTIMESTAMP:11:2}
OLDMINUTE=${OLDTIMESTAMP:15:2}
OLDSECOND=${OLDTIMESTAMP:19:2}


echo "===== Replication S T A R T ====="  >> $LOG
echo `date +%Y-%m-%d\ %H:%M:%S`" - Starting script" >> $LOG
start_time0=`date +%s`

#print date from state.txt to log
echo `date +%Y-%m-%d\ %H:%M:%S`" - Stari state.txt:" >> $LOG
awk '{if (NR!=1) {print}}' $REPLEX/state.txt >> $LOG


############################################
## Downloading changeset from laste state.txt ##
############################################

#Downloading changeset and sorting
echo `date +%Y-%m-%d\ %H:%M:%S`" - Downloading changeset" >> $LOG
$osmosis --rri workingDirectory=$REPLEX --sort-change --wxc $REPLEX/$CHANGESET
EXITSTATUS=$?
echo `date +%Y-%m-%d\ %H:%M:%S`" - Exit state:" $EXITSTATUS >> $LOG

if [[ $EXITSTATUS -ne 0 ]] ; then
    echo `date +%Y-%m-%d\ %H:%M:%S`" - Prekidam procesiranje" >> $LOG
    cp $EUROPE/$OLDYEAR$OLDMONTH$OLDDAY-state.txt $REPLEX/state.txt
    exit 1
fi

end_time=`date +%s`
lasted="$(( $end_time - $start_time0 ))"
echo `date +%Y-%m-%d\ %H:%M:%S`" - Changeset finished in" $lasted "seconds." >> $LOG


#########################
## Simplyfy changeset ##
#########################

#Simplify changeset
echo `date +%Y-%m-%d\ %H:%M:%S`" - Simplyfy changeset" >> $LOG
start_time=`date +%s`
$osmosis --read-xml-change file="$REPLEX/$CHANGESET" --simplify-change --write-xml-change file="$REPLEX/$CHANGESETSIMPLE"
EXITSTATUS=$?
echo `date +%Y-%m-%d\ %H:%M:%S`" - Exit state:" $EXITSTATUS >> $LOG
end_time=`date +%s`
lasted="$(( $end_time - $start_time ))"
echo `date +%Y-%m-%d\ %H:%M:%S`" - Changeset simplified in" $lasted "seconds." >> $LOG

#NEWSTATE=state.txt
NEWTIMESTAMP=$(cat state.txt | grep timestamp | awk -F "=" '{print $2}')
NEWYEAR=${NEWTIMESTAMP:0:4}
NEWMONTH=${NEWTIMESTAMP:5:2}
NEWDAY=${NEWTIMESTAMP:8:2}
NEWHOUR=${NEWTIMESTAMP:11:2}
NEWMINUTE=${NEWTIMESTAMP:15:2}
NEWSECOND=${NEWTIMESTAMP:19:2}

#print date from state.txt to log
echo `date +%Y-%m-%d\ %H:%M:%S`" - Novi state.txt:" >> $LOG
awk '{if (NR!=1) {print}}' $REPLEX/state.txt >> $LOG

############################################
## Primjena changeseta uz rezanje granice ##
############################################

#Primjena changeseta uz rezanje granice
echo `date +%Y-%m-%d\ %H:%M:%S`" - Apply changeset to europe file" >> $LOG
start_time=`date +%s`
$osmosis --read-xml-change file="$REPLEX/$CHANGESETSIMPLE" --read-pbf file="$EUROPE/$OLDYEAR$OLDMONTH$OLDDAY-europe-east.osm.pbf" --apply-change --bounding-polygon clipIncompleteEntities="true" file="$POLY/europe-east.poly" --write-pbf file="$REPLEX/europe-east.osm.pbf"
EXITSTATUS=$?
echo `date +%Y-%m-%d\ %H:%M:%S`" - Exit state:" $EXITSTATUS >> $LOG
end_time=`date +%s`
lasted="$(( $end_time - $start_time ))"
echo `date +%Y-%m-%d\ %H:%M:%S`" - Changeset applied and cropped in" $lasted "seconds." >> $LOG


############################################
## backup europe-east.osm.pbf i state.txt ##
############################################
start_time=`date +%s`
#remove changesets
rm $REPLEX/$CHANGESET
rm $REPLEX/$CHANGESETSIMPLE
echo `date +%Y-%m-%d\ %H:%M:%S`" - Changesets removed." >> $LOG

#move new europe file over old one and copy it to web
mv $REPLEX/europe-east.osm.pbf $EUROPE/$NEWYEAR$NEWMONTH$NEWDAY-europe-east.osm.pbf
touch -a -m -t $NEWYEAR$NEWMONTH$NEWDAY$NEWHOUR$NEWMINUTE.$NEWSECOND $EUROPE/$NEWYEAR$NEWMONTH$NEWDAY-europe-east.osm.pbf
cp -p $EUROPE/$NEWYEAR$NEWMONTH$NEWDAY-europe-east.osm.pbf $PBF/europe-east.osm.pbf
#copy state file to web
touch -a -m -t $NEWYEAR$NEWMONTH$NEWDAY$NEWHOUR$NEWMINUTE.$NEWSECOND $REPLEX/state.txt
cp -p $REPLEX/state.txt $PBF/state.txt
cp -p $REPLEX/state.txt $EUROPE/$NEWYEAR$NEWMONTH$NEWDAY-state.txt
echo `date +%Y-%m-%d\ %H:%M:%S`" - Europe and state.txt copied to web." >> $LOG

##montly backup of europe-east.osm.pbf
if [ $NEWDAY -eq 01 ]
 then
 #test if file $WEB/monthly/$OLDYEAR$OLDMONTH$OLDDAY-europe-east.osm.pbf doesn't exist copy
 if [[ ! -f $WEB/monthly/$OLDYEAR$OLDMONTH$OLDDAY-europe-east.osm.pbf ]]
   then
   #copy europe dated backup to web monthly folder
   cp -p $EUROPE/$OLDYEAR$OLDMONTH$OLDDAY-europe-east.osm.pbf $WEB/monthly/$OLDYEAR$OLDMONTH$OLDDAY-europe-east.osm.pbf
   cp -p $EUROPE/$OLDYEAR$OLDMONTH$OLDDAY-state.txt EUROPE/$OLDYEAR$OLDMONTH$OLDDAY-state.txt
   echo `date +%Y-%m-%d\ %H:%M:%S`" - Europe monthly archive copied to web." >> $LOG
 fi
fi

####################################################
### dnevni backup europe-east.osm.pbf i state.txt ##
####################################################
#
##only once a day at midnight instance
#if [ $hour -eq 00 ]
#  then
#  #create state.txt dated backup
#  cp -p $REPLEX/state.txt $EUROPE/$yesterday-state.txt
#  #create europe file dated backup and copy europe file to data for daily garmin generation
#  cp -p $EUROPE/europe-east.osm.pbf $EUROPE/$yesterday-europe-east.osm.pbf; cp -p $EUROPE/europe-east.osm.pbf $DATA/europe-east.osm.pbf
#  echo `date +%Y-%m-%d\ %H:%M:%S`" - Europe and state.txt backup created. Europe copied." >> $LOG
#
#  if [ $dayom01 -eq 01 ]
#   then
#   #copy europe dated backup to web monthly folder
#   cp -p $EUROPE/$yesterday-europe-east.osm.pbf $WEB/monthly/$yesterday-europe-east.osm.pbf
#   echo `date +%Y-%m-%d\ %H:%M:%S`" - Europe monthly archive copied to web." >> $LOG
#  fi
#  
#  #remove old dated europe backups
#  rm $EUROPE/$olddate-europe-east.osm.pbf
#fi
#
#chmod -R 755 $EUROPE
#
#end_time=`date +%s`
#lasted="$(( $end_time - $start_time ))"
#echo `date +%Y-%m-%d\ %H:%M:%S`" - Backup finished in" $lasted "seconds." >> $LOG



#####################
## osm.pbf exporti ##
#####################

echo `date +%Y-%m-%d\ %H:%M:%S`" - PBF export starting." >> $LOG

## Extracts countfy from europe##

for COUNTRY in albania #bosnia-herzegovina bulgaria croatia hungary kosovo northmacedonia montenegro romania serbia slovenia 
do
  echo `date +%Y-%m-%d\ %H:%M:%S`" - "$COUNTRY" export started" >> $LOG
  start_time=`date +%s`
  $osmosis --read-pbf file="$EUROPE/$NEWYEAR$NEWMONTH$NEWDAY-europe-east.osm.pbf" --bounding-polygon clipIncompleteEntities="true" file="$POLY/$COUNTRY.poly" --write-pbf file="$DATA/$COUNTRY.osm.pbf"
  touch -a -m -t $NEWYEAR$NEWMONTH$NEWDAY$NEWHOUR$NEWMINUTE.$NEWSECOND $DATA/$COUNTRY.osm.pbf
  cp -p $DATA/$COUNTRY.osm.pbf $PBF/$COUNTRY.osm.pbf
  if [ $NEWDAY -eq 01 ]; then
    if [[ ! -d $WEB/$COUNTRY/archive/$NEWYEAR/ ]]; then
      mkdir $WEB/$COUNTRY/archive/$NEWYEAR/
      echo `date +%Y-%m-%d\ %H:%M:%S`" - "$COUNTRY $NEWYEAR" folder created" >> $LOG
    fi
    if [[ ! -f $WEB/$COUNTRY/archive/$OLDYEAR$OLDMONTH$OLDDAY-$COUNTRY.osm.pbf ]]; then
      cp -p $PBF/$COUNTRY.osm.pbf $WEB/$COUNTRY/archive/$OLDYEAR$OLDMONTH$OLDDAY-$COUNTRY.osm.pbf
      echo `date +%Y-%m-%d\ %H:%M:%S`" - "$COUNTRY $NEWYEAR" monthly export created" >> $LOG
    #touch -a -m -t $NEWYEAR$NEWMONTH$NEWDAY$NEWHOUR$NEWMINUTE.$NEWSECOND $WEB/$COUNTRY/archive/$NEWYEAR/$NEWYEAR$NEWMONTH$NEWDAY-$COUNTRY.osm.pbf
  fi
  end_time=`date +%s`
  lasted="$(( $end_time - $start_time ))"
  echo `date +%Y-%m-%d\ %H:%M:%S`" - "$COUNTRY" PBF export finished in" $lasted "seconds." >> $LOG
done

echo `date +%Y-%m-%d\ %H:%M:%S`" - PBF export finished." >> $LOG
#
##uvjet da se izvršava samo u ponoć
#if [ $hour -eq 00 ]
#  start_time=`date +%s`
#  then
#  ##kopira croatia sa datumom ######################
#  cp -p $PBF/croatia.osm.pbf $WEB/croatia/archive/$yesterday-croatia.osm.pbf
#  echo `date +%Y-%m-%d\ %H:%M:%S`" - Croatia daily archive created." >> $LOG
#  ## izvlaci dnevni changeset ######################
#  $osmosis --read-pbf file="$WEB/croatia/archive/$daysago-croatia.osm.pbf" --read-pbf file="$WEB/croatia/archive/$yesterday-croatia.osm.pbf" --derive-change --write-xml-change compressionMethod=gzip file="$WEB/croatia/archive/$daysago-$yesterday-croatia.osc.gz"
#  end_time=`date +%s`
#  lasted="$(( $end_time - $start_time ))"
#  echo `date +%Y-%m-%d\ %H:%M:%S`" - Croatia diff finished in" $lasted "seconds." >> $LOG
#  if [ $dayom01 -eq 01 ]
#   then
#   for COUNTRY in albania bosnia-herzegovina bulgaria hungary kosovo northmacedonia montenegro romania serbia slovenia
#    do
#      #copy COUNTRY monthly backup
#      cp -p $PBF/$COUNTRY.osm.pbf $WEB/$COUNTRY/archive/$yesterday-$COUNTRY.osm.pbf
#      echo `date +%Y-%m-%d\ %H:%M:%S`" - "$COUNTRY" monthly archive created." >> $LOG
#    done
#  fi
#fi
#
######################
### gpkg exporti ##
######################
#
#echo `date +%Y-%m-%d\ %H:%M:%S`" - GPKG export starting." >> $LOG
#
#for COUNTRY in albania bosnia-herzegovina bulgaria croatia hungary kosovo northmacedonia montenegro romania serbia slovenia 
#do
#  echo `date +%Y-%m-%d\ %H:%M:%S`" - "$COUNTRY" GPKG export started" >> $LOG
#  start_time=`date +%s`
#  $OGR2OGR -f GPKG $CACHE/$COUNTRY.gpkg $DATA/$COUNTRY.osm.pbf
#  zip -m -j $CACHE/$COUNTRY.gpkg.zip $CACHE/$COUNTRY.gpkg
#  mv $CACHE/$COUNTRY.gpkg.zip $GIS/
#  end_time=`date +%s`
#  lasted="$(( $end_time - $start_time ))"
#  echo `date +%Y-%m-%d\ %H:%M:%S`" - "$COUNTRY" GPKG export finished in" $lasted "seconds." >> $LOG
#done
#
#echo `date +%Y-%m-%d\ %H:%M:%S`" - GPKG export finished." >> $LOG
#
#
#
#####################
### Garmin exporti ##
#####################
#
##uvjet da se izvršava samo u ponoć
#if [ $hour -eq 00 ]
#  then
#  echo `date +%Y-%m-%d\ %H:%M:%S`" - Garmin export starting." >> $LOG
#  mapid=90000001
#  for COUNTRY in europe-east albania bosnia-herzegovina bulgaria croatia hungary kosovo northmacedonia montenegro romania serbia slovenia
#  do
#    echo `date +%Y-%m-%d\ %H:%M:%S`" - "$COUNTRY" garmin export started" >> $LOG
#    start_time=`date +%s`
#    rm $CACHE/*
#    java -Xmx$RAM -jar $SPLITTER --output-dir=$CACHE --mapid=$mapid --cache=$CACHE $DATA/$COUNTRY.osm.pbf 
#    java -Xmx$RAM -jar $MKGMAP --output-dir=$CACHE --index --gmapsupp --series-name="OSM $COUNTRY - d1" --family-name="OSM $COUNTRY" --country-name="$COUNTRY" --remove-short-arcs --net --route --generate-sea:no-sea-sectors,extend-sea-sectors $CACHE/90*.osm.pbf
#    mv $CACHE/gmapsupp.img $WEB/garmin/$COUNTRY-gmapsupp.img
#    zip -j $DATA/$COUNTRY-garmin.zip $CACHE/*90*.img $CACHE/osmmap.*
#    mv $DATA/$COUNTRY-garmin.zip $WEB/garmin/$COUNTRY-garmin.zip
#    mapid=$(($mapid + 10000))
#    end_time=`date +%s`
#    lasted="$(( $end_time - $start_time ))"
#    echo `date +%Y-%m-%d\ %H:%M:%S`" - "$COUNTRY" Garmin export finished in" $lasted "seconds." >> $LOG
#  done
#
#  ##spajanje topo i gmapsupp
#  rm $CACHE/*
#  java -Xmx$RAM -jar $MKGMAP --output-dir=$CACHE --gmapsupp $WEB/garmin/$COUNTRY-gmapsupp.img $WEB/garmin/croatia-topo25m.img
#  mv $CACHE/gmapsupp.img $WEB/garmin/croatia-topo25m-gmapsupp.img
#  echo `date +%Y-%m-%d\ %H:%M:%S`" - Croatia topo25 finished." >> $LOG
#  rm $CACHE/*
#  java -Xmx$RAM -jar $MKGMAP --output-dir=$CACHE --gmapsupp $WEB/garmin/$COUNTRY-gmapsupp.img $WEB/garmin/croatia-topo10m.img
#  mv $CACHE/gmapsupp.img $WEB/garmin/croatia-topo10m-gmapsupp.img
#  echo `date +%Y-%m-%d\ %H:%M:%S`" - Croatia topo10 finished." >> $LOG
#
#  #deleting europe because we don't want it in osmand generation
#  rm $DATA/europe-east.osm.pbf
#  
#  echo `date +%Y-%m-%d\ %H:%M:%S`" - Garmin export finished." >> $LOG
#fi
#
#####################
### OsmAnd exporti ##
#####################
#
##uvjet da se izvršava samo u ponoć
#if [ $hour -eq 00 ]
#  then
#  #osmand karte 
#  start_time=`date +%s`
#
#  echo `date +%Y-%m-%d\ %H:%M:%S`" - OsmAnd export starting." >> $LOG
# 
#  #cd $OSMANDMCMC
#  #java -Djava.util.logging.config.file=$REPLEX/logging.properties -Xms64M -Xmx$RAM -cp "$OSMANDMC/OsmAndMapCreator.jar:$OSMANDMC/lib/OsmAnd-core.jar:$OSMANDMC/lib/*.jar" net.osmand.data.index.IndexBatchCreator $REPLEX/batch.xml
#  java -Xmx$RAM -cp "$OSMANDMC/OsmAndMapCreator.jar:$OSMANDMC/lib/OsmAnd-core.jar:$OSMANDMC/lib/*.jar" net.osmand.util.IndexBatchCreator $REPLEX/osmandmc.xml
#  mv $DATA/*.obf* $WEB/osmand
#
#  end_time=`date +%s`
#  lasted="$(( $end_time - $start_time ))"
#  echo `date +%Y-%m-%d\ %H:%M:%S`" - OsmAnd export finished in" $lasted "seconds." >> $LOG
#fi
#
#rm $CACHE/*


######################
## Daily statistics ##
######################

for COUNTRY in albania #bosnia-herzegovina bulgaria croatia hungary kosovo northmacedonia montenegro romania serbia slovenia
do
  if [[ ! -f $WEB/$COUNTRY/stats/$COUNTRY-daily.txt ]]; then
  echo "Date,Size,Nodes,Ways,Relations" >> $WEB/$COUNTRY/stats/$COUNTRY-daily.txt
  fi
  if [[ ! -f $WEB/$COUNTRY/stats/$COUNTRY-monthly.txt ]]; then
  echo "Date,Size,Nodes,Ways,Relations" >> $WEB/$COUNTRY/stats/$COUNTRY-monthly.txt
  fi
  if [ $NEWDAY -eq 01 ]; then 
    tail -n 1 $WEB/$COUNTRY/stats/$COUNTRY-daily.txt >> $WEB/$COUNTRY/stats/$COUNTRY-monthly.txt
  fi
  TOTAL_SIZE=`wc -c $PBF/$COUNTRY.osm.pbf | awk '{print $1}'`
  $osmconvert --out-statistics $PBF/$COUNTRY.osm.pbf > $STATS/$COUNTRY-stats.txt
  TOTAL_NODE=`cat $STATS/$COUNTRY-stats.txt | grep nodes | awk -F ' ' '{print $2}'`
  TOTAL_WAY=`cat $STATS/$COUNTRY-stats.txt | grep ways | awk -F ' ' '{print $2}'`
  TOTAL_RELATION=`cat $STATS/$COUNTRY-stats.txt | grep relations | awk -F ' ' '{print $2}'`
  #country total stats
  #check if statitstics exist and create it if not
  echo $NEWYEAR$NEWMONTH$NEWDAY','$TOTAL_SIZE','$TOTAL_NODE','$TOTAL_WAY','$TOTAL_RELATION >> $WEB/$COUNTRY/stats/$COUNTRY-daily.txt
  #next 2lines to be replaced with symlink on server
  #cp -p $WEB/$COUNTRY/stats/$COUNTRY-total.txt $WEB/$COUNTRY/$COUNTRY-total.txt
  #cp -p $WEB/$COUNTRY/stats/$COUNTRY-total.txt $WEB/statistics/$COUNTRY-total.txt
echo `date +%Y-%m-%d\ %H:%M:%S`" - "$COUNTRY" csv files created and copied to web." >> $LOG
done

######################
## Plot daily stats ##
######################

#for TYPE in Nodes Ways Relations
#do
#if [ $TYPE -eq Nodes ]
#then
#PLOT= $(plot "$WEB/$COUNTRY/stats/$COUNTRY-daily.txt" using 1:2 w l)
#elif [ $TYPE -eq Ways ]
#then
#PLOT= $(plot "$WEB/$COUNTRY/stats/$COUNTRY-daily.txt" using 1:3 w l)
#else
#PLOT= $(plot "$WEB/$COUNTRY/stats/$COUNTRY-daily.txt" using 1:4 w l)
#fi
#echo $PLOT

gnuplot << EOF
set datafile separator ","
set key autotitle columnhead
set terminal png
set output "$WEB/$COUNTRY/stats/daily-nodes.png"
set xlabel "Date"
#set ylabel "Values"
set title "Nodes"
#set xrange [ 0 : 20 ]
#set yrange [ 0 : 2 ]
#set mxtics 5
#set mytics 5
set format y '%.0f'
set xtics rotate
set xdata time
set timefmt "%Y%m%d"
set xtics format "%Y-%m-%d"
#set xtics 5
#set ytics 0.5
#plot "$STATS" using 1:2 w l, "$STATS" using 1:3 w l, "$STATS" using 1:4 w l, "$STATS" using 1:5 w l
plot "$WEB/$COUNTRY/stats/$COUNTRY-daily.txt" using 1:2 w l
EOF

gnuplot << EOF
set datafile separator ","
set key autotitle columnhead
set terminal png
set output "$WEB/$COUNTRY/stats/daily-ways.png"
set xlabel "Date"
set title "Ways"
set format y '%.0f'
set xtics rotate
set xdata time
set timefmt "%Y%m%d"
set xtics format "%Y-%m-%d"
plot "$WEB/$COUNTRY/stats/$COUNTRY-daily.txt" using 1:3 w l
EOF

gnuplot << EOF
set datafile separator ","
set key autotitle columnhead
set terminal png
set output "$WEB/$COUNTRY/stats/daily-relations.png"
set xlabel "Date"
set title "Relations"
set format y '%.0f'
set xtics rotate
set xdata time
set timefmt "%Y%m%d"
set xtics format "%Y-%m-%d"
plot "$WEB/$COUNTRY/stats/$COUNTRY-daily.txt" using 1:4 w l
EOF

#done

########################
## Plot monthly stats ##
########################

if [ $NEWDAY -eq 01 ]; then

gnuplot << EOF
set datafile separator ","
set key autotitle columnhead
set terminal png
set output "$WEB/$COUNTRY/stats/monthly-nodes.png"
set xlabel "Date"
set title "Nodes"
set format y '%.0f'
set xtics rotate
set xdata time
set timefmt "%Y%m%d"
set xtics format "%Y-%m-%d"
plot "$WEB/$COUNTRY/stats/$COUNTRY-monthly.txt" using 1:2 w l
EOF

gnuplot << EOF
set datafile separator ","
set key autotitle columnhead
set terminal png
set output "$WEB/$COUNTRY/stats/monthly-ways.png"
set xlabel "Date"
set title "Ways"
set format y '%.0f'
set xtics rotate
set xdata time
set timefmt "%Y%m%d"
set xtics format "%Y-%m-%d"
plot "$WEB/$COUNTRY/stats/$COUNTRY-monthly.txt" using 1:3 w l
EOF

gnuplot << EOF
set datafile separator ","
set key autotitle columnhead
set terminal png
set output "$WEB/$COUNTRY/stats/monthly-relations.png"
set xlabel "Date"
set title "Relations"
set format y '%.0f'
set xtics rotate
set xdata time
set timefmt "%Y%m%d"
set xtics format "%Y-%m-%d"
plot "$WEB/$COUNTRY/stats/$COUNTRY-monthly.txt" using 1:4 w l
EOF

fi


echo `date +%Y-%m-%d\ %H:%M:%S`" - "$COUNTRY" gnuplot done." >> $LOG

echo `date +%Y-%m-%d\ %H:%M:%S`" - All statistics finished." >> $LOG

chmod -R 755 $WEB

#complete duration of the script
end_time=`date +%s`
lasted="$(( $end_time - $start_time0 ))"
echo `date +%Y-%m-%d\ %H:%M:%S`" - Complete script finished in" $lasted "seconds." >> $LOG    
echo "===== Replication E N D====="  >> $LOG
