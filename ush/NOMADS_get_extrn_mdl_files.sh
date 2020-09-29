#!/bin/bash
# Command line arguments
if [ -z "$1" -o -z "$2" ]; then
   echo "Usage: $0 yyyymmdd hh fcst_model file_fmt nfcst nfcst_int"
   echo "yyymmdd and hh are required and other variables are optional"
   exit
fi
## date (year month day) and time (hour)
yyyymmdd=$1 #i.e. "20191224"
hh=$2 #i.e. "12"
echo reqdata= `date -d "$1 $2" "+%m %d %Y %H"`
export reqdata=`date -d "$1 $2" "+%s"`
echo reqdata = $reqdata
##
### tea check that model is one of four
echo model $3 format $4
export data_format=$4
case $3 in
  "fv3gfs"|"FV3GFS"|"GFSFV3"|"gfsfv3")
    echo 'using FV3GFS forecast' $3
    set fcst_model="fv3gfs"
    echo data_format ${data_format}
    if [[ ${data_format} != "grib2" && ${data_format} != "GRIB2" ]] ; then
      echo "invalid data format ${data_format}; must use grib2 with fv3gfs"
      exit;
    fi;;
  "HRRR"|"hrrr")
    echo  'using HRRR forecast' $3
    set fcst_model="hrrr";;
  "RAP"|"rap")
    echo 'using RAP forecast' $3
    set fcst_model="rap";;
  "NAM"|"nam")
    echo 'using NAM forecast' $3
    set fcst_model="nam";;
  *)
    echo 'unrecognized model'
    echo 'use GFSFV3/HRRR/RAP/NAM'
    exit ;;
esac
echo fcst_model= ${fcst_model}, data_format=${data_format}

### tea check time is multiple of 6 and not older than 3 days
check_request_time() {

   echo $1 $2
   echo reqdata = $reqdata

# check that forecast hour is valid
   echo forecast_hour=$2
   export forecast_hour=$2
   echo $forecast_hour
   modtime=`(($forecast_hour % 3))`
   echo modtime=$modtime
   set zero = 0

   if (($modtime == $zero));then
     echo 'valid forecast hour'
   else
     echo 'forecast hour must be 00,06,12,18'
     return 1
   fi

# check that date is no more than 3 days old
   read month day year hour < <(date -u "+%m %d %Y %H")
   echo now `date $month $day $year $hour "+%m %D %Y %z"`
   nowtime=$(date "+%s")
   echo nowtime = $nowtime
   echo reqdata = $reqdata
   echo cutoff `date -d "3 days ago" "+%m %D %Y %z"`
   cutoff=$(date -d "3 days ago" +%s)
   echo cutoff = $cutoff

# diff=`expr $reqdata - $cutoff`
   let difference="$reqdata - $cutoff"
   echo reqdata $reqdata $cutoff difference $difference
   echo diff=$difference

   set zero = 0

# if [ $difference <= 0 ]
   if ((difference < zero));
   then
     echo "requested data older than 3 days"
     return 1
   fi

   echo "requested data less than 3 days old"
   return 0
}

check_forecast_length() {

   echo forecast_length=$1
   let modtime=$(($1%3))
   echo mod=$modtime
   set zero = 0

   if [[$modtime == $zero]];then
     echo 'valid forecast length'
   else
     echo 'forecast length must multiple of 3'
     return 1
   fi

   return 0
}

check_forecast_int() {

   echo forecast_int=$1
   let modtime=$(($1%3))
   echo mod=$modtime
   set zero = 0

   if [[$modtime == $zerol];then
     echo 'valid forecast interval'
   else
     echo 'forecast interval must be multiple of 3'
     return 1
   fi

   return 0
}

## file format (grib2 or nemsio), the default format is grib2
if [ "$#" -ge 4 ]; then
   file_fmt=$4
else 
   file_fmt="grib2"
fi
## forecast length, the default value are 6 hours
if [ "$#" -ge 5 ]; then
   nfcst=$5
else 
   nfcst=6
fi

## forecast interval, the default interval are 3 hours
if [ "$#" -ge 6 ]; then
   nfcst_int=$6
else 
   nfcst_int=3
fi

echo "check_request_time $yyyymmdd $hh"
check_request_time $yyyymmdd $hh
check_forecast_length $nfcst
check_forecast_int $nfcst_int

echo $1 $2 $3 $4 $5 $6
exit

# Get the data (do not need to edit anything after this point!)
yyyymm=$((yyyymmdd/100))
#din_loc_ic=`./xmlquery DIN_LOC_IC --value`
mkdir -p gfs.$yyyymmdd/$hh
echo "Download files to $din_loc_ic/$yyyymm/$yyyymmdd ..."
cd gfs.$yyyymmdd/$hh

#getting online analysis data
if [ $file_fmt == "grib2" ] || [ $file_fmt == "GRIB2" ]; then
   wget -c https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.$yyyymmdd/$hh/gfs.t${hh}z.pgrb2.0p25.f000
else
   wget -c https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.$yyyymmdd/$hh/gfs.t${hh}z.atmanl.nemsio
   wget -c https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.$yyyymmdd/$hh/gfs.t${hh}z.sfcanl.nemsio
fi

#getting online forecast data
ifcst=$nfcst_int
while [ $ifcst -le $nfcst ] 
do
echo $ifcst
  if [ $ifcst -le 99 ]; then 
     if [ $ifcst -le 9 ]; then
        ifcst_str="00"$ifcst
     else
        ifcst_str="0"$ifcst
     fi
  else
        ifcst_str="$ifcst"
 fi
 echo $ifcst_str
#
if [ $file_fmt == "grib2" ] || [ $file_fmt == "GRIB2" ]; then
  wget -c https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.$yyyymmdd/$hh/gfs.t${hh}z.pgrb2.0p25.f${ifcst_str}
else
  wget -c https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.$yyyymmdd/$hh/gfs.t${hh}z.atmf${ifcst_str}.nemsio
  wget -c https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.$yyyymmdd/$hh/gfs.t${hh}z.sfcf${ifcst_str}.nemsio
fi
#
ifcst=$[$ifcst+$nfcst_int]
done
