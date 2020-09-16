#!/bin/bash
# Command line arguments
if [ -z "$1" -o -z "$2" ]; then
   echo "Usage: $0 yyyymmdd hh file_fmt nfcst nfcst_int"
   echo "yyymmdd and hh are required and other variables are optional"
   exit
fi
## date (year month day) and time (hour)
yyyymmdd=$1 #i.e. "20191224"
hh=$2 #i.e. "12"
##
### tea check time is multiple of 6 and not older than 3 days
check_request_time() {

   echo $1 $2
   reqdata=`date "+%s" --date="$1 $2:00:00"`
   echo reqdata = $reqdata

# check that forecast hour is valid
   echo forecast_hour=$2
   let mod=$(($2%3))
   echo mod=$mod
   set zero = 0

   if ((mod == zero));then
     echo 'valid forecast hour'
   else
     echo 'forecast hour must be 00,06,12,18'
     return 1
   fi


# check that date is no more than 3 days old
   read month day year hour < <(date -u "+%m %d %Y %H")
   echo $month $day $year $hour5
# nowtime=$(date -d "$month/$day/$year $hour:00:00" +%s)
   nowtime=$(date "+%s")
   echo nowtime = $nowtime
   cutoff=$(date -d "3 days ago" +%s)
   echo cutoff = $cutoff

# diff=`expr $reqdata - $cutoff`
   let difference="reqdata - cutoff"
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
   let mod=$(($1%3))
   echo mod=$mod
   set zero = 0

   if ((mod == zero));then
     echo 'valid forecast length'
   else
     echo 'forecast length must multiple of 3'
     return 1
   fi

   return 0
}

check_forecast_int() {

   echo forecast_int=$1
   let mod=$(($1%3))
   echo mod=$mod
   set zero = 0

   if ((mod == zero));then
     echo 'valid forecast interval'
   else
     echo 'forecast interval must be multiple of 3'
     return 1
   fi

   return 0
}

## file format (grib2 or nemsio), the default format is grib2
if [ "$#" -ge 3 ]; then
   file_fmt=$3
else 
   file_fmt="grib2"
fi
## forecast length, the default value are 6 hours
if [ "$#" -ge 4 ]; then
   nfcst=$4
else 
   nfcst=6
fi

## forecast interval, the default interval are 3 hours
if [ "$#" -ge 5 ]; then
   nfcst_int=$5
else 
   nfcst_int=3
fi

check_request_time $1 $2 
check_forecast_length $nfcst
check_forecast_int $nfcst_int

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
