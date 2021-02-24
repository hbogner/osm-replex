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
mkdir $WEB/albania
mkdir $WEB/albania/stats
mkdir $WEB/bosnia-herzegovina
mkdir $WEB/bosnia-herzegovina/stats
mkdir $WEB/bulgaria
mkdir $WEB/bulgaria/stats
mkdir $WEB/croatia/
mkdir $WEB/croatia/stats
mkdir $WEB/hungary
mkdir $WEB/hungary/stats
mkdir $WEB/kosovo
mkdir $WEB/kosovo/stats
mkdir $WEB/northmacedonia
mkdir $WEB/northmacedonia/stats
mkdir $WEB/montenegro
mkdir $WEB/montenegro/stats
mkdir $WEB/romania
mkdir $WEB/romania/stats
mkdir $WEB/serbia
mkdir $WEB/serbia/stats
mkdir $WEB/slovenia
mkdir $WEB/slovenia/stats
