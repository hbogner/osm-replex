#!/bin/bash
#

##web setup
WEB=/osm/www-data
mkdir $WEB 

##generic folders
mkdir $WEB/garmin
mkdir $WEB/gis_exports
mkdir $WEB/monthly
mkdir $WEB/poly
mkdir $WEB/osm
mkdir $WEB/osmand
mkdir $WEB/statistics

##country folders

for COUNTRY in albania bosnia-herzegovina bulgaria croatia hungary kosovo northmacedonia montenegro romania serbia slovenia 
do

	mkdir $WEB/$COUNTRY
	mkdir $WEB/$COUNTRY/daily
	mkdir $WEB/$COUNTRY/monthly
	mkdir $WEB/$COUNTRY/yearly
	mkdir $WEB/$COUNTRY/stats

done
