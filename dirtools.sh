#!/usr/bin/env bash
#title           :dirtools.sh
#description     :This script is a small tool that helps you find some directories using some options.
#author		     :Chris-Hu
#date            :20161102
#version         :1.0
#usage		     :bash dirtools.sh or make it executable
#bash_version    :4.3.42(1)-release
#==============================================================================

R='\033[0;31m'
G='\033[0;32m'
NC='\033[0m'
__dispUsage() {
    printf "${G}"
    echo "============================================================================="
    echo "* Removes or Archives directories, useable filters are Date, Size, Month    *"
    echo "* Usage   : dirtools options                                                *"
    echo "============================================================================="
    echo
    echo "options : -dir=DIRNAME remove or archive DIRNAME"
    echo "          -from=Y-m-d -to=Y-m-d, pick directories using last directory modification date from date1 to date2"
    echo "          -minsize=Size in MegaBytes, pick directories size greater than Size"
    echo "          -month=Oct pick directories where Month of date equals Month"
    echo
    printf "${NC}"
    exit
}

__diskSpace() {
    #echo -e not working on all systems
    echo; echo $(df -h | head -1) | tr ' ' '\t'
    echo $(df -h | grep -E "/$")  | tr ' ' '\t'; echo
}

__findByMonth() {
       ls -lF $1 | grep -E "/$"
}

__dispDirList () {
    for d in $1 ;do
        t=$( stat -c %U" "%x  $d)
        s=$(__getDirSize $d "h")
        printf "%s \t %s \n" $d $s
    done
}

__getDirSize() {
    [ "$2" = "h" ]  && { opt="-cbh" ; } || { opt="-cb" ; }
    echo $(du $opt $1 | grep total) | cut -d " " -f 1
}

__getBySizeFromList() {
    local s_Lst="$@"
    local dsize=$(__getSizePar $s_Lst)
    local ref_size=$(echo | awk -v size=$dsize '{ print size*1024*1024 }')
    local lst_sized

    for dir in $s_Lst ;do
        [ -d $dir ] && {
            csz=$(__getDirSize $dir)
            re='^[0-9.?]+$'
            [[ $csz =~ $re && $ref_size =~ $re ]] && {

               [ "$csz" -gt "$ref_size" ]  && { lst_sized=$lst_sized" "$dir; }
            }
        }
    done

    echo $lst_sized
}

__getCurDir() {
    dd=$(echo $@ | grep -Eo  "\-dir=[/[A-Za-z_0-9.*^\s+]+" | cut -d "=" -f 2)
    [ ! -d $dd ] && { exit 10; } || { echo $dd; }
}

__getSizePar() {
    dsize=$(echo $@ | grep -Eo "\-minsize=[0-9]+[\.]?[0-9]*M?" | cut -d "=" -f 2 | grep -Eo "[0-9]+[\.]?[0-9]*")
    echo $dsize
}

__dispErrors() {
    echo "ERROR : "$1 ; echo ; exit 10
}

__needHelp() {
     needHelp=$(echo $@ | grep -Eo "\-h")
     [[ ! -z $needHelp || -z $1 ]] && { __dispUsage ; }
}

__getDirList() {
    local from=$(echo $@ | grep -Eo "\-from=[0-9-]+" | cut -d "=" -f 2)
    local to=$(echo $@ | grep -Eo "\-to=[0-9-]+" | cut -d "=" -f 2)
    local dir_size=$(__getSizePar "$@")
    local month=$(echo $@ | grep -Eo "\-month=[A-Za-z]+" | cut -d "=" -f 2)
    local cur_dir=$(__getCurDir "$@")

    # getting matching directories from to
    [ ! -z $from ]  && {
        [ "$from$to" = "$from" ] && { exit 20 ; } || {
            from_Lst=$(find $cur_dir -maxdepth 1 -type d -newermt $from ! -newermt $to)
        }
    }


    [ ! -z $month ] && {
        from_Lst=$(find $cur_dir -maxdepth 1 -type d)
    }

    [ ! -z $dir_size ] && {
        # getting matching directories from date to date which size corresponds to filter
        [ ! -z "$from_Lst" ] && {
            local lst_sized=$(__getBySizeFromList $from_Lst "-minsize=$dir_size")
            echo $lst_sized
            } || {  # getting matching directories which size corresponds to filter without considering date
            current_D_Lst=$(find $cur_dir -maxdepth 1 -type d)
            lst_sized=$(__getBySizeFromList $current_D_Lst "-minsize=$dir_size")
        }
    }


    [ ! -z "$lst_sized" ] && {
        echo $lst_sized
    } || {
        [ -z "$from_Lst" ] && { echo $cur_dir ; } || { echo $from_Lst ; }
    }
}

__needHelp "$@"

curdir=$(__getCurDir "$@")
[ $? -eq 10 ] && { __dispErrors "Directory does not exist !" ; }

total=$(__getDirSize $curdir "h")

__diskSpace

echo "TOTAL USAGE ON Directory : $curdir " $total ;echo


dirlist=$(__getDirList "$@")
[ $? -eq 20 ] && {  __dispErrors "From to mismatched !" ; }
echo "Found Directories : "$( echo $dirlist | grep -o $curdir | wc -l )
echo "==================="; echo
__dispDirList "$dirlist"

printf "${G}"
echo "------------------------------------------------------------------------"
read -p "What 's next ? (R:  Remove, A: Archive, L: List, Q: Quit) " ans
echo "------------------------------------------------------------------------"
printf "${NC}"

case $ans in
    R*)
        [ ! -z "$dirlist" ] && {
            cd $curdir
            echo "Remove $dirlist "
            printf "${R}"
            read -p "Action is irreversible Are you sure ?  (Y/N) " rma
            printf "${NC}"
            [ "$rma" = "Y" ] && { rm -rf $dirlist ; }
        }
    ;;
    A*)
        [ ! -z "$dirlist" ] && {
            echo "Archive $dirlist "
            read -p "Enter Archive Path and Filename :" ara
            [ ! -z $ara ] && {
                echo "Archiving to : "$ara.tar.gz
                read -p "Execute ? (Y/N) " ear
                [ "$ear" = "Y" ] && {
                    tar -zcvf $ara.tar.gz $dirlist
                }
            }
        }
    ;;
    L*)
        [ ! -z "'$dirlist'" ] && {
            echo "Listing --- "
            __dispDirList "$dirlist"
        }
    ;;
    *)
    exit
    ;;
esac

#echo -e not working on all systems
echo; echo "DIRTOOLS Exiting..."

exit