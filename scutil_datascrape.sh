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

. bash_parmstack.sh
. dbg_printf.sh

# datascrape.sh
# support for scraping variable data from
# formatted text
#
# simple (not bulletproof) output parse specification
# identifies static/fixed text from dynamic/data text
# prepared parse format identifies key names for scraped data
# parser builds Associative Array database of scraped text data
#


# to datascrape_captureResponse...
# 1. build an array of filter-words
# 2. build an egrep or grep-e command to filter all the lines
# 3. filter the lines to a result file
# 4. scan the result file line by line
# 5. when a filter key matches a line, extract the data
# 6. for each datum extracted, append to the response Assoc Array
# 7. done.

datascrape_LFS='~'
datascrape_varPrefix='~@'
datascrape_staticTextPrefix='^'
datascrape_lineiDstart='^'
datascrape_varStart='@'


##================ PARSING SYNTAX =============================##
## The parser for the command confirmation and data born
## within command responses identifies response line segments
## these following prefixes identify string segments:
## "^"    : line-identifying key bounded by the next '~' or EOL
## "~@"    : dynamic-text a.k.a 'variable'
## "~[^~@]": static text bounded by next '~'
##================ PARSING SYNTAX =============================##
datascrape_captureResponse () {
    # filterArray has the filter specification strings
    # for the data bearing lines of command output
    declare -n filterAArray=$1
 
    
    # responseAArray is to be filled with data gathered
    # from the command
    declare  -n dataAArray=$2
    dbg_displayAArray dataAArray
    
    # file at pathname cmd_output_file
    # has output from the targeted command
    cmd_output_file="$3"
    local -a cmdout_lines
    readarray -t cmdout_lines < "$cmd_output_file"
    
    local -a scan_array
    
    dbg_printf "filterAArray contents: %s" "\"${filterAArray[@]}\""
    
    for filter_string in "${filterAArray[@]}"
        do
        varname_tokens="${filter_string//[^@]}"
        varname_count="${#varname_tokens}"

        dbg_printf "varname tokens: %s    varname_count: %d" $varname_tokens $varname_count
        
        # break filter string into parts
        # static text and named-variable parts
        pushIFS "~"
        scan_array=( $filter_string )
        popIFS
        
        # initially, suffix&prefix are undefined
        local prefix
        local suffix
        local variable_name
        local parts_count="${#scan_array[@]}"
        pushIFS ''
        for (( index=0;index<parts_count && varname_count>0;index++ ))
            do  #scrape variable(s) per filter string
            part="${scan_array[$index]}"
            if [ $index -eq 0 ]; then
                variable_name=""
                prefix=""
                suffix=""
            fi

            case "${part:0:1}" in
                "@")
                    #prefix of variable name
                    variable_name="${part:1}"
                    dbg_printf "varstart. varname=\"%s\"" $variable_name
                    continue
                       ;;
                "^")
                    #variable-bearing line-ID
                    lineID="${part:1}"
                    prefix="$lineID"
                    dbg_printf "lineIDstart. lineiD=\"%s\"" $lineID
                    continue
                        ;;
                "\0")
                    #Null item
                    dbg_printf "NULL part detected"
                    continue
                    ;;
                *)  #static text
                    #identify static text prefix/suffix to variable(name)
                    dbg_printf "static text part:\"%s\"" $part
                    
                    if [ "$variable_name" == "" ]; then
                        prefix="$part"
                        dbg_printf "no varname, prefix=\"%s\"" $part
                    else
                        suffix="$part"
                        # identify variable containing line from cmd output
                        line_count="${#cmdout_lines[@]}"
                        #for ((linendx=0;linendx<line_count;linendx++))
                        for line_key in "${!cmdout_lines[@]}"
                            do
                            #dbg_printf "******* line_key: %s" $line_key
                            scanline="${cmdout_lines[$line_key]}"
                            #dbg_printf "lineID:%s   scanline:%s" $lineID "\"$scanline\""
                            
                            if [[  "${scanline#"$lineID"}" == "$scanline" ]]; then
                                # wanted cmd output line not yet found
                                 #dbg_printf "scanline skipped"
                                continue
                            else
                                # delete extracted cmd output line
                                # shorten subsequent scan processing
                                if [ "$varname_count" -eq 1 ]; then
                                    unset cmdout_lines[$line_key]
                                fi
                            fi
                            
                            
                            if [ "$prefix" == "" ]; then
                                substring=$scanline
                            else
                                substring="${scanline#*"$prefix"}"
                            fi

                            if [ "$suffix" != "" ]; then
                                varstring="${substring%"$suffix"*}"
                            else
                                varstring=$substring
                            fi

                            dataAArray[$variable_name]=$varstring
                            done
                                 
                        # read variable done
                        varname_count=$(( varname_count - 1 ))
                        prefix="$suffix"
                        suffix=""
                        variable=""
                    fi
            esac
            done    #scrape variable(s) per filter string
        done    #scrape variable(s) per all filter strings
        popIFS
       
}



build_infoCmdFilters () {
    local platform_type="$1"
    local -a datascrapeA_infoCmdResponse

    unset datascrapeAA_infoCmdResponse
    unset linefilterA_infoCmdID
    unset datascrapeAA_infoCmdID
    unset linefilterA_shellConnect

    
    # save linefilter strings in one array item, no breakups
    pushIFS ''
        
    linefilterA_shellConnect=( "\"USING UDP on\"" )
    linefilterA_shellConnect=( "\"Connection establishment\"" )
    linefilterA_shellConnect=( "\"Shell>\"" )
    
    
    linefilterA_infoCmdID=( "\"Aurix Tricore TC297 Bare metal OS\"" )
    linefilterA_infoCmdID+=( "\"Running Image:\"" )

    datascrapeA_infoCmdResponse=( "\"^Using UDP on ('~@BOARD_IP~', ~@BOARD_IP_PORT~)\"" )  
    datascrapeA_infoCmdResponse+=( "\"^Compiled for platform ~@PLATFORM_TYPE~~\"" )
    datascrapeA_infoCmdResponse+=( "\"^Firmware Version Number :~@FW_VERSION~~\"" )
    datascrapeA_infoCmdResponse+=( "\"^Revision Branch : ~@BRANCH_REV~~\"" )
    datascrapeA_infoCmdResponse+=( "\"^Build Date and Time:  ~@BUILD_TIMEDATE~~\"" )
    datascrapeA_infoCmdResponse+=( "\"^GIT-SHA : ~@GIT_SHA~~\"" )
    datascrapeA_infoCmdResponse+=( "\"^BUILD-ID : ~@BUILD_ID~~\"" )
    datascrapeA_infoCmdResponse+=( "\"^BUILD-TYPE : ~@BUILD_TYPE~~\"" )
    datascrapeA_infoCmdResponse+=( "\"^COMPILER : ~@COMPILER~~")
    datascrapeA_infoCmdResponse+=( "\"^Boot Reason: ~@BOOT_REASON~~\"" )
    datascrapeA_infoCmdResponse+=( "\"^Board Version: ~@BOARD_VERSION~~\"" )
    datascrapeA_infoCmdResponse+=( "\"^Running Image: ~@RUNNING_IMAGE_NAME~~\"" )
    datascrapeA_infoCmdResponse+=( "\"^Bootloader Build-ID: ~@BOOTLDR_BUILD_ID~~\"" )
    datascrapeA_infoCmdResponse+=( "\"^UID: ~@UID1~ ~@UID2~~\"" )
    datascrapeA_infoCmdResponse+=( "\"^Flash FPGA_FLASH, ID: ~@FPGA_FLASH_ID~~\"" )
    datascrapeA_infoCmdResponse+=( "\"^Flash MCU_FLASH, ID: ~@MCU_FLASH_ID~~\"" )
    datascrapeA_infoCmdResponse+=( "\"^MAC address: ~@MAC~~\"" )
    datascrapeA_infoCmdResponse+=( "\"^IP Address:  ~@IP_ADDR~~\"" )
    datascrapeA_infoCmdResponse+=( "\"^Netmask:    ~@NETMASK~~\"" )
    datascrapeA_infoCmdResponse+=( "\"^Gateway:    ~@GATEWAY~~\"" )
 
    local linendx=0
    for line in "${datascrapeA_infoCmdResponse[@]}";
        do
        datascrapeAA_infoCmdResponse[$linendx]=$line
        linendx=$(( linendx + 1 ))
        done
        
    dbg_displayArray datascrapeA_infoCmdResponse
        
    dbg_displayAArray datascrapeAA_infoCmdResponse   
    popIFS
}


declare -a __ifs_stack__
function pushIFS () {

    saveIFS=$IFS
    IFS=''
    __ifs_stack__+=( $saveIFS ) 
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

set_dbglvl 3

declare -a datascrapeA_cmdIdFilter
declare -a datascrapeA_cmdStoreResponseLineFilter
declare -A datascrapeAA_infoCmdData
declare -A datascrapeAA_infoCmdResponse


dbg_printf "do datascrape_captureResponse"
#parmstack_pushArray datascrapeA_infoCmdResponse

build_infoCmdFilters

#datascrapeAA_infoCmdData=( [wompus]="root"  [sweezle]="swozzle" )
parmstack_pushAArray datascrapeAA_infoCmdData
parmstack_topIsAArray
dbg_assert_nonzero "$?"

datascrape_captureResponse  datascrapeAA_infoCmdResponse datascrapeAA_infoCmdData "/home/rfhonea/devproject/scriptdev/cli_shell_output.log"
#parmstack_popAArray datascrapeAA_infoCmdData
pushIFS ''
dbg_displayAArray datascrapeAA_infoCmdData
popIFS
