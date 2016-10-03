#!/bin/env perl

use strict;
use warnings;
use DBI;
use DBD::Oracle qw(:ora_session_modes);
use Getopt::Long;

my $dbhost = undef;
my $dbuser = undef;
my $dbpass = undef;
my $dbconn = undef;
my $inst_id= 1;
my $dba    = undef;

my $sid =  $ENV{'ORACLE_SID'};


my $begin       = -1;
my $end         = -1;
my $begin2      = undef;
my $end2        = undef;
my $begin_date  = undef;
my $end_date    = undef;
my $begin_date2 = undef;
my $end_date2   = undef;
my $o_file      = "output.html";
my $usage;
my $global;
my $text;

my $usage_txt = qq{
awr.pl -- A perl wrapper for AWR Report. (C) 2016 Max Lambertini (m.lambertini\@gmail.com)

USAGE: ./awr.pl [options]
    --dbuser=[user]  : Oracle user
    --dbpass=[pass]  : Oracle password
    --dbinst=[num]   : DB Instance (default = 1)
    --dbhost=[host]  : TNS Alias, if needed

    --begin=[num]    : starting awr snapshot id
    --begind=[date]  : begin interval date
    --end=[num]      : ending awr snapshot id
    --endd=[date]    : end interval date

    --begind2=[date] : begin 2nd interval date (for awr comparison)
    --endd2=[date]   : end 2nd interval date (for awr comparison)

    NOTE: Dates must comply to this mask: YYYYMMDD_HH24:MI:SS. For instance, 20160920_19:34:41
    
    --output[fname]  : output filename. A standard filename will be generated if empty
    
    Flags:
    
    --dba            : connect as sysdba
    --global         : when generating reports on a RAC, generates a global report
    --text           : generate a text report instead of an HTML one

    --help           : show this screen
    
Sample usage:
-------------

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
    
};



GetOptions("begin=i"  => \$begin,
           "begin2=i" => \$begin2,
           "begind=s" => \$begin_date,
           "begind2=s"=> \$begin_date2,
           "endd=s"   => \$end_date,
           "endd2=s"  => \$end_date2
           "end=i"    => \$end,
           "end2=i"   => \$end2,
           "dbuser=s" => \$dbuser,
           "dbpass=s" => \$dbpass,
           "dbinst=i" => \$inst_id,
           "dbhost=s" => \$dbhost,
           "output=s" => \$o_file,
           "dba"      => \$dba,
           "global"   => \$global,
           "text"     => \$text,
           "help"     => \$usage)
or die ("Error in command line argument. awr.pl --help for usage info \n");

# if true, then generate awr report compare
if ($text) { $text="txt"; } else { $text="html"; }

if ($usage) {
        print $usage_txt;
        die("\n");
}

$dbhost = $dbhost ? "dbi:Oracle:" : "dbi:Oracle:" . $dbhost;

print "Host is $dbhost\n";

my $dbh;
if ($dba) {
    $dbh = DBI->connect(
      $dbhost,
      $dbuser,
      $dbpass,
      { ora_session_mode => ORA_SYSDBA }
    );
} else {
    $dbh = DBI->connect(
      $dbhost,
      $dbuser,
      $dbpass);
}

if ($dbh) {
  print "Connected\n";
} else {
  die $DBI::errstr;
}

my @data;
my $sth1 = $dbh->prepare ("select dbid from v\$database") or die ("Cannot get DBID\n");
$sth1->execute();
@data = $sth1->fetchrow_array();
my $dbid  = $data[0];
$sth1->finish();

print "DB ID is $dbid\n";

if ($begin == -1 || $end == -1)  {
        $sth1 = $dbh->prepare ("select max(snap_id) from dba_hist_snapshot") or die ("Cannot get Snap id\n");
        $sth1->execute();
        @data = $sth1->fetchrow_array();
        $end = $data[0];
        $begin = $end-1;
        $sth1->finish();
}

if ($begin_date && $end_date) {
        my $the_sql = qq{
                select a.begin_snap, b.end_snap
                from (select max(snap_id) begin_snap
          from dba_hist_snapshot
                 where begin_interval_time <= to_date('$begin_date','YYYY-MM-DD_HH24:MI:SS')) a,
                (select min(snap_id) end_snap
          from dba_hist_snapshot
                 where end_interval_time >= to_date('$end_date','YYYY-MM-DD_HH24:MI:SS')) b
        };
        $sth1 = $dbh->prepare ($the_sql);
        $sth1->execute();
        @data = $sth1->fetchrow_array();
        $end = $data[1];
        $begin = $data[0];
        $sth1->finish();
}


if ($begin_date2 && $end_date2) {
        my $the_sql = qq{
                select a.begin_snap, b.end_snap
                from (select max(snap_id) begin_snap
          from dba_hist_snapshot
                 where begin_interval_time <= to_date('$begin_date2','YYYY-MM-DD_HH24:MI:SS')) a,
                (select min(snap_id) end_snap
          from dba_hist_snapshot
                 where end_interval_time >= to_date('$end_date2','YYYY-MM-DD_HH24:MI:SS')) b
        };
        $sth1 = $dbh->prepare ($the_sql);
        $sth1->execute();
        @data = $sth1->fetchrow_array();
        $end2 = $data[1];
        $begin2 = $data[0];
        $sth1->finish();
}


if ($begin == -1 || $end == -1)  {
        $sth1 = $dbh->prepare ("select max(snap_id) from dba_hist_snapshot") or die ("Cannot get Snap id\n");
        $sth1->execute();
        @data = $sth1->fetchrow_array();
        $end = $data[0];
        $begin = $end-1;
        $sth1->finish();
}

my $compare_reports = ($begin_date2 && $end_date2);


if (!$compare_reports) {
    if ( ($begin != -1 && $end != -1) && ($o_file eq "output.html"))
    {
        if (!$global) {
            $o_file = "awr_".$inst_id."_".$sid."_".$begin."_".$end.".".$text;
        } else {
            $o_file = "awrg_".$inst_id."_".$sid."_".$begin."_".$end.".".$text;
        }     
    }
} else {
    if (!$global) {
        $o_file = "awr_c_".$inst_id."_".$sid."_".$begin."_".$end."_".$begin2."_".$end2.".".$text;
    } else {
        $o_file = "awrg_c_".$inst_id."_".$sid."_".$begin."_".$end."_".$begin2."_".$end2.".".$text;
    }     
}    


my $sql;
if (!$compare_reports) {
    if ($global) {
         $sql = "select output from table(dbms_workload_repository.awr_global_report_$text ('$dbid','',$begin,$end))";
        print "$sql\n";
    } else {
        $sql = "select output from table(dbms_workload_repository.awr_report_$text ('$dbid',$inst_id,$begin,$end))";
    }   
} else {
    if ($global) {
         $sql = "select output from table(dbms_workload_repository.awr_global_report_$text ('$dbid','',$begin,$end,$dbid,'', $begin2, $end2))";
        print "$sql\n";
    } else {
        $sql = "select output from table(dbms_workload_repository.awr_diff_report_$text ($dbid,$inst_id,$begin,$end,$dbid,$inst_id, $begin2, $end2))";
    }   
}

print "Writing snapshot data from $begin to $end on $o_file\n\n";

$sth1 = $dbh->prepare ($sql);
$sth1->execute();
my $output = "";
my $f;  open ($f,">", $o_file) or die ("Cannot create file $o_file\n");
while (@data = $sth1->fetchrow_array()) {
        $output = $data[0];
        print $f "$output\n" if ($output);
}


$dbh->disconnect;
print "<!-- that's all -->\n";



