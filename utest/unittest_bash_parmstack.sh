#!/bin/bash


. bash_parmstack.sh

#
# TEST bash_parmstack.sh Variable/Item Stack
#

set_dbglvl 2

declare -a valueArray=( "The Quick Brown Fox  " " Jumped over the lazy dog brown." )
echo "==========push Array=========="
parmstack_pushArray valueArray
echo "==========exited push Array=========="
declare -p valueArray
declare -p __retvalstack__

ptval=""
echo "==========peek Top Value=========="
parmstack_peekTopValue ptval
echo "==========exited peek Top Value=========="
echo "peektop:" $ptval
 
parmstack_pushValue "Nebuchadnezzar"
OldKing="Midas"
echo "==========pop Single Value=========="
parmstack_popValue OldKing
echo "==========exited pop single Value=========="
echo "OldKing=$OldKing"

dbg_assert_strcmp "Nebuchadnezzar" "$OldKing"

echo "==========peek Top Value=========="
parmstack_peekTopValue ptval
echo "==========exited peek Top Value=========="
echo "peektop:" $ptval

declare -a catchArray
echo "==========pop Array=========="
parmstack_popAArray catchArray
echo "==========exited pop array=========="
declare -p catchArray

declare -p __retvalstack__

echo "==========preparing push associative array=========="
echo "==========preparing push associative array=========="
declare -A foosums=( [wpess]="wangle norsk" [splortch]="mcSnoobess!" [squonk]="zoinks!"  [rabblefrabits]="@##*(&%&@@@!!!!&" )
declare -p foosums
declare -p __retvalstack__
echo "==========pushing associative array=========="
parmstack_pushAArray foosums
echo "==========exit push associative array=========="
declare -p foosums
declare -p __retvalstack__

echo "==========pushing string=========="
parmstack_pushValue "Sennecharib"
NewKing="Jehoiachim"
echo "==========popping string=========="
parmstack_popValue $NewKing
echo "NewKing=$NewKing"


echo "==========popping associative array=========="
unset catchAArray
declare -A catchAArray
parmstack_popAArray catchAArray
echo "==========exited popAArray=========="
dbg_displayAArray catchAArray
declare -p catchAArray
#dbg_displayArray __retvalstack__

#declare -p catchAArray
#declare -p __retvalstack__


