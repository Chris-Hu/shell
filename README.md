# A List of shell Utilities

# dirtools

dirtools is a shell script that helps you find directories using some filters

###### Removes or Archives directories, useable filters are Date, Size, Month
###### Usage   : dirtools.sh options                                               


### options
     -dir=DIRNAME remove or archive DIRNAME
     -from=Y-m-d -to=Y-m-d, pick directories using last directory modification date from date1 to date2
     -minsize=Size in MegaBytes, pick directories size greater than Size
     -month=Oct pick directories where Month of date equals Month
     -h shows Help


### Installation

```sh
git clone https://github.com/Chris-Hu/shell.git
sudo ln -s $PWD/shell/dirtools.sh /usr/local/bin/dirtools.sh

```
