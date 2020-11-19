#!/bin/bash
# Command line arguments
if [ -z "$1" -o -z "$2" ]; then
   echo "Usage: $0 yyyymmdd hh extern_IBC extern_LBCs data_format nfcst nfcst_int"
   echo "yyymmdd and hh are required and other variables are optional"
   echo
   echo "fv3gfs: 6 hour forecast, hourly thru 120 hours, 3 hourly thru 385 hr (pgrb2 grib2)"
   echo "fv3gfs: 6 hour forecast, hourly thru 24 hours (atmf0${ifcst_hr}.nemsio)"
   echo "hrrr:  hourly forecast, hourly thru 36 hours for 6 hour forecasts (eg 6,12,18,24), 18 for intermediate(wrfnat)"
   echo "nam: 6 hourly forecast, hourly thru 60 hours (conusnest)"
   echo "rap: hourly forecast, hourly thru 21 hours (wfrnat)"
   echo
   echo "enter integers as 6 not 06"
   exit
fi

## date (year month day) and time (hour)
yyyymmdd=$1 #i.e. "20191224"
if [[ $2 -le 9 ]]; then
  export hh="0"$2
else
  export hh=$2
fi

echo reqdata= `date -d "$1 $2" "+%m %d %Y %H"`
export reqdata=`date -d "$1 $2" "+%s"`
echo reqdata = $reqdata

## file format (grib2 or nemsio), the default format is grib2
if [ "$#" -ge 4 ]; then
   data_format=$5
else 
   data_format="grib2"
fi
echo data_format = $data_format

### Check LBC (forecast)
### Set dataformat from $5
echo LBC $4 $5
export data_format=$5
case $4 in
  "fv3gfs"|"FV3GFS"|"GFSFV3"|"gfsfv3")
    echo 'using FV3GFS forecast' $4
    export fcst_model="gfsfv3"
    echo data_format ${data_format};;
#   if [[ ${data_format} == "grib2" || ${data_format} == "GRIB2" ]] ; then
#     echo "invalid data format ${data_format}; must use nemsio with fv3gfs"
#     exit;
#   fi;;
  "HRRR"|"hrrr")
    echo  'using HRRR forecast' $4
    export fcst_model="hrrr"
    echo data_format ${data_format};;
  "RAP"|"rap")
    echo 'using RAP forecast' $4
    export fcst_model="rap"
    echo data_format ${data_format};;
  "NAM"|"nam")
    echo 'using NAM forecast' $4
    export fcst_model="nam"
    echo data_format ${data_format};;
  *)
    echo 'unrecognized fcst model'
    echo 'use GFSFV3/HRRR/RAP/NAM'
    exit ;;
esac
## file format (grib2 or nemsio), the default format is grib2
case $data_format in
  "grib2"|"GRIB2")
     echo "grib2"
     export data_format="grib2";;
  "nemsio"|"NEMSIO")
     echo "nemsio"
     export data_format="nemsio";;
  *)
     echo 'unrecognized data format'
     echo 'use grib2 or nemsio'
     exit;;
esac

echo fcst_model= ${fcst_model}, data_format=${data_format}

### tea check that model is one of four
### check for IBC, set data_format to grib2 or nemsio
echo IBC $3
case $3 in
  "fv3gfs"|"FV3GFS"|"GFSFV3"|"gfsfv3")
    echo 'using FV3GFS IBC' $3
    export ibc_model="gfsfv3"
# if both models are GFSFV3, can use specified data_format, ie nemsio or grib2
    if  [[ $ibc_model == $fcst_model ]]; then
      export ibc_data_format=$data_format
    else
      export ibc_data_format="grib2"
    fi
    echo IBC_data_format ${ibc_data_format};;
#   if [[ ${ibc_data_format} == "grib2" || ${ibc_data_format} == "GRIB2" ]] ; then
#     echo "invalid data format ${ibc_data_format}; must use nemsio with fv3gfs"
#     exit;
#   fi;;
  "HRRR"|"hrrr")
    echo  'using HRRR IBC' $3
    export ibc_model="hrrr"
    export ibc_data_format="grib2"
    echo IBC_data_format ${ibc_data_format};;
  "RAP"|"rap")
    echo 'using RAP IBC' $3
    export ibc_model="rap"
    export ibc_data_format="grib2"
    echo IBC_data_format ${ibc_data_format};;
  "NAM"|"nam")
    echo 'using NAM IBC' $3
    export ibc_model="nam"
    export ibc_data_format="grib2"
    echo IBC_data_format ${ibc_data_format};;
  *)
    echo 'unrecognized IBC model'
    echo 'use GFSFV3/HRRR/RAP/NAM'
    exit ;;
esac

## forecast length, the default value are 6 hours
if [ "$#" -ge 6 ]; then
   nfcst=$6
else 
   nfcst=6
fi

echo forecast until $nfcst

## forecast interval, the default interval are 3 hours
if [ "$#" -ge 7 ]; then
   nfcst_int=$7
else 
   nfcst_int=3
fi
echo forecast every $nfcst_int

echo '1-7' $1 $2 $3 $4 $5 $6
### tea check time is not older than 3 days
### for fv3gfs and NAM check it is every 6 hours (6, 12, 18, 24)
check_request_time() {

   echo 'in check_request_time'
   echo reqdata = $reqdata

# check that forecast hour is valid
   export forecast_hour=$2
   export model=$3
   export ibcmodel=$4
   echo "forecast: ",$model," ibc:",$ibcmodel
   echo forecast_hour=$forecast_hour $model
   if [[ $model == "gfsfv3" ]] || [[ $ibcmodel == "gfsfv3" ]]; then
     modtime=$(( forecast_hour % 6 ))
   elif [[ $model == "nam" ]] || [[ $ibcmodel == "nam" ]]; then
     modtime=$(( forecast_hour % 6 ))
   else
     modtime=$(( forecast_hour % 1 ))
   fi
   echo modtime=$modtime
   export zero=0
   echo zero=$zero
   if [[ $modtime == $zero ]];then
     echo $model $modtime
     echo 'valid forecast hour'
   else
     echo $model $modtime
     echo 'forecast hour must be 00,06,12,18 for nam,gfsfv3'
     exit 1
   fi

# check that date is not in the future
#  echo date=`date -u "+%m %d %Y %H"`
   read month day year hour minute < <(date -u "+%m %d %Y %H %M")
   echo "now" $month $day $year $hour $minute
   nowtime=$(date "+%s")
   echo nowtime = $nowtime
   echo reqdata = $reqdata
   if [[ $reqdata -gt $nowtime ]]; then
     echo "forecast cannot start in the future"
     exit 1
   fi

#check that data is not more than 3 days old
   echo cutoff `date -d "3 days ago" "+%m %d %Y %z"`
   cutoff=$(date -d "3 days ago" +%s)
   echo cutoff = $cutoff

   let difference="$reqdata - $cutoff"
   echo reqdata $reqdata $cutoff difference $difference
   echo diff=$difference

   set zero = 0

   if [[ $difference -lt $zero ]]; then
     echo "requested data older than 3 days"
     exit 1
   fi

   echo "requested data less than 3 days old"
   return 0
}

check_forecast_length() {

   echo forecast_length=$1
   export modtime=$(( $1 % 3 ))
   echo mod=$modtime
   set zero = 0

   if [[ $modtime -eq $zero ]];then
     echo 'valid forecast length'
   else
     echo 'forecast length must multiple of 3'
     exit 1
   fi

   return 0
}

check_forecast_int() {

   echo forecast_int=$1
   export modtime=$(( $1 % 3))
   echo mod=$modtime
   set zero = 0

   if [[ $modtime -eq $zero ]];then
     echo 'valid forecast interval'
   else
     echo 'forecast interval must be multiple of 3'
     exit 1
   fi

   return 0
}

echo "check_request_time ${fcst_model} $yyyymmdd $hh"
check_request_time $1 $2 ${fcst_model} ${ibc_model}
#check_forecast_length $nfcst
#check_forecast_int $nfcst_int

# Get the data (do not need to edit anything after this point!)
yyyymm=$((yyyymmdd/100))
#din_loc_ic=`./xmlquery DIN_LOC_IC --value`
echo fcst_model= ${fcst_model}, data_format=${data_format}
case $fcst_model in
  "gfsfv3")
      echo 'using FV3GFS forecast' $3
      echo data_format ${data_format}
      mkdir -p gfs.$yyyymmdd/$hh
      echo "Download files to $din_loc_ic/$yyyymm/$yyyymmdd ..."
      cd gfs.$yyyymmdd/$hh ;;
  "hrrr")
      echo  'using HRRR forecast' $3
      echo data format ${data_format}
      mkdir -p hrrr.$yyyymmdd/$hh
      echo "Download files to $din_loc_ic/$yyyymm/$yyyymmdd ..."
      cd hrrr.$yyyymmdd/$hh ;;
  "rap")
      echo 'using RAP forecast' $3
      echo data format ${data_format}
      mkdir -p rap.$yyyymmdd/$hh
      echo "Download files to $din_loc_ic/$yyyymm/$yyyymmdd ..."
      cd rap.$yyyymmdd/$hh ;;
  "nam")
      echo 'using NAM forecast' $3
      mkdir -p nam.$yyyymmdd/$hh
      echo "Download files to $din_loc_ic/$yyyymm/$yyyymmdd ..."
      cd nam.$yyyymmdd/$hh ;;
  *)
      echo 'unrecognized model/data combination'
      echo 'use GFSFV3/HRRR/RAP/NAM'
      exit 1 ;;
esac

#### need case statements build around wget and while
#### check rap, hrrr, and nam for fcast hours, intervals

case $ibc_model in
  "gfsfv3") 
#getting online analysis data
#use grib for IBCs if NAM, RAP, HRRR
    if [[ $data_format == "grib2" ]] || [[ $ibc_data_format = "grib2" ]]; then
      wget -c https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.$yyyymmdd/$hh/gfs.t${hh}z.pgrb2.0p25.f000
#     curl -L -O https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.$yyyymmdd/$hh/gfs.t${hh}z.pgrb2.0p25.f000
    elif [[ $data_format == "nemsio" ]]; then
      wget -c https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.$yyyymmdd/$hh/gfs.t${hh}z.atmanl.nemsio
      wget -c https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.$yyyymmdd/$hh/gfs.t${hh}z.sfcanl.nemsio
    else
      echo "IBC unrecognized data format"
      echo "use grib2 or nemsio for fv3gfs"
      exit 1
    fi ;;
  "rap")
    if [[ $ibc_data_format == "grib2" ]]; then
      wget -c https://nomads.ncep.noaa.gov/pub/data/nccf/com/rap/prod/rap.$yyyymmdd/rap.t${hh}z.wrfnatf00.grib2
    else
      echo "IBC use grib2 for rap" $ibc_data_format
      exit
    fi;;
  "nam")
    if [ $ibc_data_format == "grib2" ]; then
      wget -c https://nomads.ncep.noaa.gov/pub/data/nccf/com/nam/prod/nam.$yyyymmdd/nam.t${hh}z.conusnest.hiresf00.tm00.grib2
    else
      echo "IBC use grib2 for nam" $ibc_data_format
      exit
    fi;;
  "hrrr")
    if [ $ibc_data_format == "grib2" ]; then
      wget -c https://nomads.ncep.noaa.gov/pub/data/nccf/com/hrrr/prod/hrrr.$yyyymmdd/conus/hrrr.t${hh}z.wrfnatf00.grib2
    else
      echo "IBC use grib2 for hrrr" $ibc_data_format
      exit
    fi;;
  *)
    echo "unrecognized IBC model" $ibc_model
    echo "use gfsfv3, nam, rap, or hrrr"
    exit;;
esac

#getting online forecast data
ifcst=$nfcst_int
echo IFCST $ifcst
echo NFCST $nfcst
while [ $ifcst -le $nfcst ] 
do
#
case $fcst_model in
  "gfsfv3") 
    echo $ifcst
    if [[ $ifcst -le 99 ]]; then 
      if [[ $ifcst -le 9 ]]; then
        ifcst_str="00"$ifcst
      else
        ifcst_str="0"$ifcst
      fi
    else
      ifcst_str="$ifcst"
    fi
    echo $ifcst_str
    if [ $data_format == "grib2" ] || [ $data_format == "GRIB2" ]; then
      wget -c https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.$yyyymmdd/$hh/gfs.t${hh}z.pgrb2.0p25.f${ifcst_str}
    elif [ $data_format == "nemsio" ]; then
      wget -c https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.$yyyymmdd/$hh/gfs.t${hh}z.atmf${ifcst_str}.nemsio
    else
      echo 'unrecognized data format'
      echo 'use grib2 or nemsio for gfsfv3 data'
      exit
    fi;;
  "hrrr")
    echo $ifcst
    if [[ $ifcst -le 9 ]]; then
      ifcst_str="0"$ifcst
    else
      ifcst_str="$ifcst"
    fi
    echo $ifcst_str
    if [ $data_format == "grib2" ] || [ $data_format == "GRIB2" ]; then
      wget -c https://nomads.ncep.noaa.gov/pub/data/nccf/com/hrrr/prod/hrrr.$yyyymmdd/conus/hrrr.t${hh}z.wrfnatf${ifcst_str}.grib2
    else
      echo 'use grib2 for hrrr data'
      exit
    fi;;
  "nam")
    echo $ifcst
    if [ $ifcst -le 9 ]; then
      ifcst_str="0"$ifcst
    else
      ifcst_str="$ifcst"
    fi
    echo $ifcst_str
    if [ $data_format == "grib2" ] || [ $data_format == "GRIB2" ]; then
      wget -c https://nomads.ncep.noaa.gov/pub/data/nccf/com/nam/prod/nam.$yyyymmdd/nam.t${hh}z.conusnest.hiresf${ifcst_str}.tm00.grib2
    else
      echo 'use grib2 for nam data'
      exit
    fi;;
  "rap")
    echo $ifcst
    if [ $ifcst -le 9 ]; then
      ifcst_str="0"$ifcst
    else
      ifcst_str="$ifcst"
    fi
    echo $ifcst_str
    if [ $data_format == "grib2" ] || [ $data_format == "GRIB2" ]; then
      wget -c https://nomads.ncep.noaa.gov/pub/data/nccf/com/rap/prod/rap.$yyyymmdd/rap.t${hh}z.wrfnatf${ifcst_str}.grib2
    else
      echo 'use grib2 for rap data'
      exit
    fi;;
  *)
    echo $fcst_model not recognized
    exit;;
esac
  
#
ifcst=$[$ifcst+$nfcst_int]
done
