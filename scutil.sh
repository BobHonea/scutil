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


#
#
# Utility Functions
# "scutil.sh"


# need Bash 4.3 level functionality
MinBashVersion="4.3.48"



pyauto_lt=255
pyauto_eq=0
pyauto_gt=1



function scutil_cmpMultipoint() {

    local multipoint_a=$1
    local multipoint_b=$2
    local -i a_vs_b
    local -a a_parts
    local -a b_parts
    local -a signlist
    signlist[0]='x'

    pushIFS '.'
    a_parts=( $multipoint_a )   
    b_parts=( $multipoint_b )
    popIFS

    a_count=${#a_parts[@]}
    b_count=${#b_parts[@]}
    
    local -i a_is_longest
    local -i b_is_longest
    local -i equal_counts
    local -i mincount
    local -i maxcount
    
    if (( a_count == b_count ))
    then
        equal_counts=1
        a_is_longest=b_is_longest=0
        maxcount=mincount=a_count
    else
        equal_counts=0
        
        if (( a_count > b_count ))
        then
            a_is_longest=1
            b_is_longest=0
            maxcount=a_count
            mincount=b_count
        else
            b_is_longest=1
            a_is_longest=0
            maxcount=b_count
            mincount=a_count
        fi
    fi
     
    partndx=0
    while (( partndx < mincount))
    do
        # process comparision between multipoint parts   
        part_a=${a_parts[$partndx]}
        part_b=${b_parts[$partndx]}
        if (( $part_a > $part_b )); then
            a_vs_b=$pyauto_gt
        elif (( $part_a < $part_b )); then
            a_vs_b=$pyauto_lt
        else
            a_vs_b=$pyauto_eq
        fi
 
        sign_list[$partndx]=$a_vs_b
        partndx=$(( partndx + 1 ))

        if [[ $a_vs_b -ne $pyauto_eq ]]; then
            break
        fi
                
        #increment counter
        if [[ $equal_counts -eq 1 ]] || [[ $partndx -lt $mincount ]]; then
            continue
        fi
         
        ## dprintf "process long multipoint" 
        # uneven multipoint lengths:
        # if shortest multipoint is exhausted
        # compare remaining multipoint parts to zeroes
        for (( ;(( partndx >= mincount )) && (( partndx < maxcount )); partndx++ )) 
        do  # process end of shortest multipoint
            if [ $a_is_longest -eq 1 ]; then
                if [ ${a_parts[$partndx]} -gt 0 ]; then
                    a_vs_b=$pyauto_gt
                fi
            elif [ ${b_parts[$partndx]} -gt 0 ]; then
                a_vs_b=$pyauto_lt
            fi

            sign_list[$partndx]=$a_vs_b
            if [ $a_vs_b -ne $pyauto_eq ]; then
                break;
            fi
        done
    done

    local signchar
    
    case $a_vs_b in
        $pyauto_lt )
            signchar='<'
            ;;
        $pyauto_gt )
            signchar='>'
            ;;
        $pyauto_eq )
            signchar='='
            ;;
        *)
    esac
    
    #dbg_printf "(a: %ss) (a?b:  %ss ) (b: %ss)" $multipoint_a  $signchar  $multipoint_b 
    return $a_vs_b      

}

function scutil_verifyBashVersion () {
    
    bash_version=$BASH_VERSION
    bash_version=${bash_version%s(*}
    dbg_printf "%ss : %ss" $MinBashVersion $bash_version

    if [ "$SHELL" != "/bin/bash" ]; then
        dbg_printf "FATAL: Shell is %ss, should be %ss" $SHELL "/bin/bash"
        exit 255
    fi

    pyauto_cmpMultipoint $MinBashVersion $bash_version
    if [ "$?" -eq 1 ]
    then
        dbg_printf "FATAL: Bash Version %ss is unsupported" $bash_version
        exit 255
    fi
    
    return 1
}



scutil_setCheckWD () {
    cd $1
    initial_pwd_response=$(pwd)
    if [ "$initial_pwd_response" != "$1" ]; then
        cd $1
        pwd_response=$(pwd)
        if [ "$pwd_response" == "$1" ]; then
            printf  "pwd=%ss\n" $pwd_response
            return 1
        else
            dbg_printf "FATAL: cd %ss fails" $1
            dbg_printf "initial pwd = $initial_pwd_response"
            exit 255
        fi
    else
        printf "pwd=%ss\n" $initial_pwd_response
        return 1
    fi
}




