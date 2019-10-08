#!/bin/bash

# lowest level of debug activity (level 1):
# dbg_assert_strcmp
# dbg_assert_nonzero
# dbg_assert_cmp
# 
# second optional debug activity (level 2) :
# dbg_printf
#
# highest optional debug activity (level 3) :
# dbg_displayAArray
# dbg_displayArray
# dbg_displayAArrayKeys
# 
#


DBGLVL=2
DBGLVL0=0
DBGLVL1=1
DBGLVL2=2
DBGLVL3=3
DBGLVLMAX=$DBGLVL3


nodebug () {
    if [ "$DBGLVL" -eq 0 ]; then
        return 1
    else
        return 0
    fi
}

set_dbglvl () {
    if [ "$#" -ne 1 ]; then
        printf "FATAL dbglvl parameter error"
        exit 255
    fi
    
    case "$1" in
        "$DBGLVL0" ) 
            DBGLVL=$DBGLVL0
            ;;
        "$DBGLVL1" ) 
            DBGLVL=$DBGLVL1
            ;;
        "$DBGLVL2" ) 
            DBGLVL=$DBGLVL2
            ;;
        "$DBGLVL3" ) 
            DBGLVL=$DBGLVL3
            ;;
        *) 
            dbg_printf "Unknown debug level setting: No Effect"
            ;;
    esac
}

dbglvl_0 () {
    if [ $DBGLVL0 -le $DBGLVL ]; then
        return 1
    fi
    return 0
}

dbglvl_1 () {
    if [ $DBGLVL1 -le $DBGLVL ]; then
        return 1
    fi
    return 0
}

dbglvl_2 () {
    if [ $DBGLVL2 -le $DBGLVL ]; then
        return 1
    fi
    return 0
}

dbglvl_3 () {
    if [ $DBGLVL3 -le $DBGLVL ]; then
        return 0
    fi
    return 0
}


#********************************************
# debug printf function
# dbg_printf <format> [ arg2 [ arg3 [ ... ]] 
#********************************************

lastfunc=""
lastfile=""


function dbg_printf () {
	#bash frame index of caller is n+1
    dbglvl_1
    pushIFS ''
    
    #args=()
    #for i in "$@";
    #do
        #args+=("$i")
    #done
    #set -- "${args[@]}"
    
    echo "args: $@"
    
    if [ "$?" -eq 1 ]; then
        __err_printf_n__ 1 $@
    fi
    popIFS
}

function err_printf () {
	__err_printf_n__ 1 "\"$@\""
}

function __setvar_parent_line__ () {
	#echo "line: $@"
	local parent_level=$(( $1 + 1 ))
	local -n parent_line=$2
	parent_line=${BASH_LINENO[$parent_level]}
    #echo "parent_line: $parent_line"
}

function __setvar_parent_source__ () {
	#echo "source: $@"
	local parent_level=$(( $1 + 1 ))
	local -n parent_source=$2
	parent_source=${BASH_SOURCE[$parent_level]}
	#echo "parent_source=$parent_source"
}

function __setvar_parent_func__ () {
	#echo "func: $@"
    local parent_level=$(( $1 + 1 ))
    local -n parent_func=$2
    parent_func=${FUNCNAME[$parent_level]}
    #echo "parent func: $parent_func"
}

function __setvar_parent_frame__ () {
	#bash frame index of caller is
	#from dbg_printf, err_printf:__err_printf__: n+3
	#from __err_printf_n_: depends on usage
	
	local parent_line_level=$1
	local parent_func_level=$(( $1 + 1 ))
	shift
	local -n parent_script=$1
	local -n parent_func=$2
	local -n parent_line=$3
	__setvar_parent_source__ $parent_func_level parent_script
	__setvar_parent_func__ $parent_func_level parent_func
	__setvar_parent_line__ $parent_line_level parent_line
}

function display_parent_frame () {
	local parent_line_level=$(( $1 + 1 ))
	__setvar_parent_frame__ $parent_line_level _parent_script _parent_func _parent_line
	#echo "parent_frame: $_parent_script::$_parent_func[$_parent_line]"
}

function __err_printf_n__ () {
	#bash frame index of caller is
	#from dbg_printf: n+2
	#from direct call: n+1

    # set parent location signifiers
    local parent_line_level=$1
    __setvar_parent_frame__ $parent_line_level call_script call_func call_line

    shift
    local sprintbuf
    local location
    if [ "$call_func" == "$lastfunc" ]; then
        fmt=""
    else
        fmt="func"
        lastfunc=$call_func
    fi
    if ! [ "$call_script" == "$lastfile" ]; then
        fmt="$fmt""file"
        lastfile=$call_script
    fi
    pushIFS ' '
    
    case $fmt in
        "funcfile") 
            format="[%s::%s]\n[%04d] "
            printf -v location "$format" $call_script $call_func $call_line
            ;;
        
        "file")
            format="[%s::%s]\n[%04d] "
            printf -v location "$format" $call_script $call_func $call_line
            ;;
            
        "func")
            format="[::%s]\n[%04d] "
            printf -v location "$format" $call_func $call_line
            ;;
        
        *)  format="[%04d] "
            printf -v location "$format" $call_line
            ;;
    esac
 

    if [ "$#" -gt 0 ]; then
        #echo "count:$#  content:$@\n"
        #
        display_parent_frame $(( parent_line_level + 1 ))
        #echo "$badcall call is suspect"
        #echo "sprintbuf: $sprintbuf"
        
        printf -v sprintbuf ${@:1}
        sprintbuf=$location$sprintbuf
    else
        sprintbuf=$location
    fi
    
    popIFS
    echo "$sprintbuf"
}

function dbg_assert_nonzero () {
    __dbg_assert__ "$1"
}

function dbg_assert_cmp () {
    local result=0
    if [ "$1" -eq "$2" ]; then
        result=1
    fi
    __dbg_assert__ $result
}

function dbg_assert_strcmp () {
    echo "1: $1   2:  $2"
    local result=0
    if [ "$1" == "$2" ]; then
        result=1
    fi
    __dbg_assert__ $result
}

function __dbg_assert__ () {
    if [ $1 -eq 0 ]; then
        call_line=${BASH_LINENO[1]}
        call_script=${BASH_SOURCE[2]%.*}
        call_func=${FUNCNAME[2]#*_}
        local sprintbuf
        local location
        local format="[%s::%s#%04d]"
        printf -v location "$format" "$call_script" "$call_func" "$call_line"
        printf "$location assert error\n"
        exit 255
    fi
}


function dbg_displayArray () {
    local -n simpleA_array=$1
    local item_index
    local item_value
    local item_count="${#simpleA_array[@]}"

    pushIFS ''
    for ((item_index=0;item_index<item_count; item_index++))
    do
        item_value="${simpleA_array[$item_index]}"
        echo "ddA item= -$item_value-"
        dbg_printf "[%02d]=%s" "\"$item_value\"" 
    done
    popIFS
}


function dbg_displayAArray () {
    local -n simpleAA_array="$1"
    local item_value
       
    pushIFS ''
    for infokey in "${!simpleAA_array[@]}"
    do
       item_value="${simpleAA_array[$infokey]}"
       dbg_printf "[%s]=%s" $infokey "\"$item_value\""
    done
    popIFS
}

function dbg_displayAArrayKeys () {
    local -n simpleAA_array="$1"
       
    for infokey in "${!simpleAA_array[@]}"
    do
        dbg_printf "infokey=$infokey\n"
    done
}
