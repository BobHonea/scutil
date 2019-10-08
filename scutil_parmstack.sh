#!/bin/bash
#
# Copyright (C) 2019 by Bob Honea (bob.honea@gmail.com)
# Released under GPL - The GNU General Public License
#
#### ---BEGIN GPL DECLARATION
#### This file is part of bash_scriptlib.
#### bash_scriptlib is free software: you can redistribute it and/or modify
#### it under the terms of the GNU General public License as published by
#### the Free Software Foundation, either version 3 of the License, or
#### any later version.
####
#### This program is distributed in the hope that it will be useful,
#### but WITHOUT ANY WARRANTY; without even the implied warranty of
#### MERCHANTIBILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#### GNU Public License for more details.
####
#### You should have received a copy of the GNU General Public License
#### along with this program. If not, see <https://www.gnu.org/licenses/>
####
#### ---END SOFTWARE LICENSE DECLARATION



# USAGE:
#       terms: singleVar is:
#                  string
#                  int
#                  float
#
#              item is:
#                  array
#                  associative array (not implemented)
#
#    FUNCTIONS:
#       PUSH single variable onto parameter stack:
#           parmstack_pushValue <VarName>
#           returns nothing
#
#       POP single variable from parameter stack
#       parmstack_popValue <VarName>
#
#       PUSH Array onto parameter stack:
#       parmstack_pushArray <ArrayName>
#
#       POP Array onto parameter stack:
#       parmstack_popArray <ArrayName>
#
#       TEST if next stacked parameter is an array
#       parmstack_topIsArray
#       returns 1 or 0 (true/false)
#
#       COPY singleVar from Top, stack not changed
#       parmstack_peekTopValue
#       ---this "may" be a formatting entry rather than
#          a variable
#
#       REPORT if parmstack has contents
#       parmstack_nonEmpty
#       returns integer 0 or larger
#
#       REPORT # of filled singleVar positions in Stack
#       parmstack_singleVarCount
#       returns integer 0 or larger
#
#       REPORT an array is/is-not nest on stack top
#       parmstack_topIsArray
#       returns 1 or 0  (true or false)
#
#       DISCARD singleVar or Array from stackTop
#       parmstack_discardTopItem
#       returns 1 or 0, 1 if a discard was possible
#       0 if stack was empty
#
#       DISCARD SingleVar from stackTop
#       parmstack_discardTopSingleValue
#       returns 1 or 0, 1 if a discard was possible
#       WARNING: may discard formatting info, corrupting stack
#
#

. dbg_printf.sh

parmstack_included=1



__pstkvtype_VAR__="_psV_"
__pstkvtype_ARRAY__="_psA_"
__pstkvtype_AARRAY__="_psAA_"

array_size_tag=$__pstkvtype_ARRAY__
aarray_size_tag=$__pstkvtype_AARRAY__

declare -a __retvalstack__
declare -a __ifs_stack__

function pushIFS () {

    saveIFS=$IFS
    IFS=''
    __ifs_stack+=( $saveIFS ) 
    IFS=$1
}


function popIFS () {
	if [ ${#__ifs_stack__[@]} -lt 1 ]; then
	    echo "FATAL: IFS Stack Underflow"
	    exit 255
	fi

	saveIFS=${__ifs_stack__[-1]}
	unset __ifs_stack__[-1]
    IFS=$saveIFS
}


function parmstack_peekTopValue () {
    local -n singleValue=$1
    singleValue=${__retvalstack__[-1]}
}           


function parmstack_nonEmpty () {
    local stack_size=${#__retvalstack__[@]}
    if [ "$stack_size" -gt 0 ]; then
        return 1
    else
        return 0
    fi
}


function parmstack_itemCount() {
    return ${#__retvalstack__[@]}
}

function parmstack_topIsArray () {
    local peekTop
    parmstack_peekTopValue peekTop
    if [[ "$peekTop" =~ $__pstkvtype_ARRAY__ ]]; then
       return 1
    else
       return 0
    fi
}

function parmstack_topIsAArray () {
    local peekTop
    parmstack_peekTopValue peekTop
    if [[ "$peekTop" =~ "$__pstkvtype_AARRAY__" ]]; then
       return 1
    else
       return 0
    fi
}


function parmstack_discardTopItem () {
    
    if [ ! parmstack_nonEmpty ]; then
        return 0
    elif [ parmstack_topIsArray ]; then
        declare -a catchArray
        parmstack_popArray catchArray
        unset catchArray
    elif [ parmstack_topIsAArray ]; then
        declare -A catchAArray
        parmstack_popAArray catchAArray
        unset catchAArray
    else
        parmstack_discardTopItem
    fi
    
    return 1
}

function parmstack_discardTopSingleValue () {
    unset __retvalstack__[-1]
}

function parmstack_pushValue () {
    if [[ "$1" == $__pstkvtype_ARRAY__* ]]; then
        # variable value matching tag-prefix breaks design
        __err_printf_n__ 1 "Parameter Stack Error: Illegal Variable Name"
        exit 255
    fi
    local singleValue=$1
    __retvalstack__+=( "." )
    __retvalstack__[-1]="$1"
}

function parmstack_popValue () {
    # pop through nameref

    local count=${#__retvalstack__[@]}

    if [ $count -gt 0 ]; then
        local singleValue
        declare -n singleValue=$1
        singleValue=${__retvalstack__[-1]}
        unset __retvalstack__[-1]
    else
        local badcall
        __setvar_parent_func__ 0 badcall
        __err_printf_n__ 1 "$badcall call is fatal"
        err_printf "FATAL: Parmstack Underflow"
        exit 255
    fi
}

function parmstack_pushArray () {
    declare -n __valuesArray__=$1
    
    # put array startTag onto Stack
    local element_count=${#__valuesArray__[@]}
    local valstack_index=${#__retvalstack__[@]}
    local element_index=0

    while [ "$element_index" -lt "$element_count" ]
        do
        __retvalstack__[$valstack_index]="${__valuesArray__[$element_index]}"
        element_index=$(( element_index + 1 ))
        valstack_index=$(( valstack_index + 1 ))
        done

    # put array sizeTag onto stack      
    __retvalstack__[$valstack_index]="$array_size_tag$element_count"
    
    declare -p __retvalstack__
}

function parmstack_popArray () {
    declare -n __valuesArray__=$1
    
    # pop count tag
    local count_tag=${__retvalstack__[-1]}
    unset __retvalstack__["-1"]

    # evaluate count tag, stack integrity
    local array_tag=${count_tag%[0-9]*}
    local element_count=${count_tag##*_}
    
    local array_size
    array_size=${#__retvalstack__[@]}
    local first_element_index=$(( array_size - element_count ))
    
    if [ "$first_element_index" -lt 0 ]; then
        local badcall
        __setvar_parent_func__ 0 badcall
        __err_printf_n__ 1 "$badcall call is fatal"
        err_printf  "FATAL: Parmstack Underflow"
        exit 255
    fi
     
    dbg_printf "     array_size= $array_size"
    dbg_printf "  element_count= $element_count"
    dbg_printf "      array_tag= $array_tag"
    dbg_printf "      countFlag= $count_tag"

    if [[ "$array_tag" =~ "$array_size_tag" ]]; then
        while [ "$element_count" -gt 0 ];
        do
            element_count=$(( element_count - 1 ))
            __valuesArray__[$element_count]=${__retvalstack__[-1]}
            unset '__retvalstack__[-1]'
        done
    else
        local badcall
        __setvar_parent_func__ 0 badcall
        __err_printf_n__ 1 "$badcall call is fatal"
        err_printf "FATAL: illegal attempt to read array parameter\n" \
                   "       no array size marker! Corrupt stack?"
    fi
}
    

function parmstack_pushAArray () {
    unset __valuesAArray__
    declare -n __valuesAArray__=$1
    
    pushIFS ''
    local -a itemArray=( ${__valuesAArray__[@]} )
    local  -a subscriptArray=( ${!__valuesAArray__[@]} )
    popIFS

    local element_count=${#subscriptArray[@]}
    local valstack_index=${#__retvalstack__[@]}
    local element_index=0

   
    while [ "$element_index" -lt "$element_count" ]; do
        __retvalstack__[$valstack_index]=${itemArray[$element_index]}
        valstack_index=$(( valstack_index + 1 ))
        __retvalstack__[$valstack_index]=${subscriptArray[$element_index]}
        valstack_index=$(( valstack_index + 1 ))
    
        element_index=$(( element_index + 1 ))
        done

    # put associative array sizeTag onto stack      
    __retvalstack__+=("$__pstkvtype_AARRAY__$element_count")
    unset itemArray
    unset subscriptArray
}


function parmstack_popAArray () {
    declare -n __valuesAArray__="$1"

    # pop count tag
    local count_tag="${__retvalstack__[-1]}"
    unset __retvalstack__[-1]

    # evaluate array type tag, count tag, stack integrity
    local array_tag=${count_tag%[0-9]*}
    local element_count=${count_tag##*_}
    
    local parmstack_size
    parmstack_size=${#__retvalstack__[@]}
    local first_element_index=$(( parmstack_size - element_count ))
    

     
    dbg_printf " parmstack_size= $parmstack_size"
    dbg_printf "  element_count= $element_count"
    dbg_printf "      array_tag= $array_tag"
    dbg_printf "     count_flag= $count_tag"

    if [ "$first_element_index" -lt 0 ]; then
        local badcall
        __setvar_parent_func__ 0 badcall
        __err_printf_n__ 1 "$badcall call is fatal"
        err_printf "FATAL: negative parameter stack index - underflow"
        exit 255
    fi
        
    pushIFS ''
    if [[ "$array_tag" =~ "$aarray_size_tag" ]]; then
        while [ "$element_count" -gt 0 ];
        do
            element_count=$(( element_count - 1 ))
            subscript_value=${__retvalstack__[-1]}
            unset __retvalstack__[-1]
            itemValue=${__retvalstack__[-1]}
#            dbg_printf "[%s]=%s" $subscript_value "\"$itemValue\""
#            __valuesAArray__["$subscript_value"]="$itemValue"
#            dbg_printf "[%s]=%s\n" $subscript_value "${__valuesAArray__["$subscript_value"]}"

            if ! [[ "${__valuesarray__["$subscript_value"]}" == "$itemvalue" ]]; then
                local badcall
                __setvar_parent_func__ 0 badcall
                __err_printf_n__ 1 "$badcall call is fatal"
                err_printf "Stack Pop Fault"
                exit 255
            fi
            unset __retvalstack__[-1]
        done
    else
        local badcall
        __setvar_parent_func__ 0 badcall
        __err_printf_n__ 1 "$badcall call is fatal"
        err_printf "FATAL: illegal attempt to read array parameter\n" \
                   "       no array size marker! Corrupt stack!!"
    fi
    popIFS
}
    
    
