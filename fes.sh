#!/bin/bash

# Im ioBroker folgendes Script anlegen: ---------------------------------

# var result;
#
# createState("0_userdata.0.FES", async function () {
# });
# schedule("*/60 * * * *", async function () {
#   // $1 == Anzuzeigende künftige Leerungen
#   exec('/opt/iobroker/fes.sh 5', async function (error, result, stderr) {
#       console.log(result);
#     setState("0_userdata.0.FES"/*0_userdata.0.FES*/, result);
#   });
# });

# ENDE ioBroker Skript -----------------------------------------------------

# Muss man so nicht machen, mache ich aber so. Kannst es ja selbst schöner machen.
# FILE ist die Datei im Container. Jaja, net meckern.
FILE=/opt/iobroker/fes.url

# Deinen für Deine Adresse gültigen Kalender bekommst du unter
# https://www.fes-frankfurt.de/services/abfallkalender
curl -s https://www.fes-frankfurt.de/abfallkalender/XXXXXXXXXXX.ics > $FILE

HEUTE=$(date -d 'today 00:00:00' +%s)
MORGEN=$(date +%s -d '1 days')
UEBERMORGEN=$(date +%s -d '2 days')
LEERUNGEN=$1
ANGEZEIGT=1
AUSGABE=""

for LINE in $(cat $FILE | tr -cd '[:alnum:].:\n ') ; do
  if [[ "$LINE" == "SUMMARY"* ]] ; then LINE2=$(echo $LINE | cut -d":" -f2) ; fi
  if [[ "$LINE" == "DTSTART"* ]] ; then
    LINE1=$(echo $LINE | cut -d":" -f2)
    Y=${LINE1::4}
    M=${LINE1:4:2}
    T=${LINE1:6:2}
    ABHOLUNG=$(date +%s -d "${Y}-${M}-${T}")
  fi
  if [[ "$LINE" == "END"*  ]] ; then
    if (( $HEUTE > $ABHOLUNG )) ; then continue ; fi
    DATUM=$(echo "In $(( ( $ABHOLUNG - $HEUTE ) / 86400 )) Tagen: ")
    if [ $(( ( $ABHOLUNG - $HEUTE ) / 86400 )) -lt 3 ] ; then DATUM="Übermorgen: " ; fi
    if [ $(( ( $ABHOLUNG - $HEUTE ) / 86400 )) -lt 2 ] ; then DATUM="Morgen: " ; fi
    if [ $(( ( $ABHOLUNG - $HEUTE ) / 86400 )) -lt 1 ] ; then DATUM="Heute: " ; fi
    AUSGABE="${AUSGABE}${DATUM}${LINE2}"
    ANGEZEIGT=$(( $ANGEZEIGT +1 ))
    if [ $ANGEZEIGT -gt $LEERUNGEN ] ; then
      echo $AUSGABE
      exit
    fi
    AUSGABE="${AUSGABE}<br>"
  fi
done

exit
