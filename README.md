# awr-reporter

`awr-reporter` is a perl script to quickly generate AWR reports via shell, thus enabling the creation of shell scripts and AWR reports automatization. 

This script uses Oracle's perl interpreter, which comes with a full-fledged Perl::DBI library. It's meant to be executed on the same server hosting the `$ORACLE_HOME`. If you plan to use it on a different host, make sure that `Getopt::Long, Perl::DBI and DBD::Oracle` are installed. 


### Setup Oracle Perl Interpreter

If you plan to use Oracle's Perl, you must instruct your OS to use it in case you have another Perl set as default.

Included in this repository there's a profile file named `perl.profile`, which performs all of the incantations needed to setup Oracle's Perl. 

Just open a shell and source the profile file this way:

~~~
$ source perl.profile
~~~

And then you're set.

### Usage

```
awr.pl -- A perl wrapper for AWR Report. (C) 2016 Max Lambertini (m.lambertini\@gmail.com)


USAGE: ./awr.pl [options]
    -u, --dbuser=[user]  : Oracle user
    -p, --dbpass=[pass]  : Oracle password
    -n, --dbinst=[num]   : DB Instance (default = 1)
    -h, --dbhost=[host]  : TNS Alias, if needed
    -s, --begin=[num]    : starting awr snapshot id
    -b, --begind=[date]  : begin interval date
    -f, --end=[num]      : ending awr snapshot id
    -e, --endd=[date]    : end interval date
    -c, --begind2=[date] : begin 2nd interval date (for awr comparison)
    -k, --endd2=[date]   : end 2nd interval date (for awr comparison)

    NOTE: Dates must comply to this mask: YYYYMMDD_HH24:MI:SS. For instance, 20160920_19:34:41
    
    -o, --output[fname]  : output filename. A standard filename will be generated if empty
    
    Flags:
    
    -a, --dba            : connect as sysdba
    -G, --global         : when generating reports on a RAC, generates a global report
    -t, --text           : generate a text report instead of an HTML one
    -h, --help           : show this screen
    
Sample usage:

Generate an awr report between two dates as sysba 
 awr.pl --dba --begind=20160927_11:50:00 --endd=20160927_14:15:00 

Same report in a text format
 awr.pl --dba --begind=20160927_11:50:00 --endd=20160927_14:15:00 --text
    
Same report on rac instance 2
 awr.pl --dba --begind=20160927_11:50:00 --endd=20160927_14:15:00 --dbinst=2
    
Same date interval, global RAC report
 awr.pl --dba --begind=20160927_11:50:00 --endd=20160927_14:15:00 --global
    
Same report using system user, specifiying a tnsnames alias and a custom output file
 awr.pl --begind=20160927_11:50:00 --endd=20160927_14:15:00 --dbuser=system --dbpass=Password01 --dbhost=ORA12 --output=custom.html


```


